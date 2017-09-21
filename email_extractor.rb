# This class finds and extracts email addresses from a given website
class EmailExtractor
  CONTACT_LINK_TRANSLATIONS = [
    'contacts',
    'contact',
    'contact us',
    'get in touch',
    'contatti',
    'kontaktai',
    'kontakt',
    'kontakter',
    'contacto',
    'kontakti'
  ].freeze

  EMAIL_REGEX = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}/

  # ignore social links, javascript links and possibly links to other domains
  IGNORE_LINKS = %r{
    #|
    facebook|linkedin|google|twitter|youtube|flickr|
    javascript|
    http|www/
  }x

  def initialize(url, silent_mode = true, debug = false, result_separator = ',')
    @main_url = url
    @silent_mode = silent_mode
    @debug = debug
    @multiple_result_separator = result_separator
  end

  def find_email
    @page = try_open_page @main_url
    return if @page.nil?

    begin
      perform_search
    rescue FoundEmail => e
      debug(">>> Found email in: #{e.location} <<<") unless e.location.nil?
      return e.message
    end
    debug('>>> Email not found anywhere <<<')
    false
  end

  private

  def perform_search
    search_for_mailto_links
    search_email_in_text
    search_menu_for_contacts_link
    scan_all_web_links
  end

  def search_for_mailto_links(page = nil)
    debug('>>> searching for mailto links..')
    page = @page || page
    links = page.css('a[href^="mailto:"]')
    return if links.nil? || links.empty?

    emails = links.map do |link|
      link.text =~ EMAIL_REGEX ? link.text : link['href'][EMAIL_REGEX]
    end
    raise FoundEmail.new('mailto links'), emails.uniq.join("#{@multiple_result_separator} ")
  end

  def search_email_in_text(page = nil)
    debug('>>> searching for email in whole page text..')
    page = @page if page.nil?
    emails = page.to_html.scrub.scan EMAIL_REGEX
    return if emails.nil? || emails.empty?
    emails.reject { |e| e =~ /ajax-loader@2x.gif/ }
    return if emails.empty?
    raise FoundEmail.new('whole page text'), emails.uniq.join("#{@multiple_result_separator} ")
  end

  def search_menu_for_contacts_link
    debug('>>> searching menu for contacts link..')
    contact_link_translations.each do |word|
      result = @page.xpath("//a[contains(text(), '#{word}')]")
      next if result.empty? || result.nil?

      url = result[0]['href']
      switch_page_and_search url unless url =~ /#/
    end
  end

  def scan_all_web_links
    debug('>>> crawling all links..')
    @page.css('a').each do |link|
      url = link['href']
      next if url =~ IGNORE_LINKS

      search_for_mailto_links if url =~ /mailto:/
      switch_page_and_search url
    end
  end

  def switch_page_and_search(url)
    debug(">>> switching page to: #{url}")
    page = try_open_page absolute_url(url)
    return if page.nil?

    search_for_mailto_links page
    search_email_in_text page
  end

  def try_open_page(url)
    open_page(url)
  rescue OpenSSL::SSL::SSLError,
         Errno::ENOENT, Errno::ECONNREFUSED,
         URI::InvalidURIError, OpenURI::HTTPError,
         Net::ReadTimeout, Net::OpenTimeout,
         SocketError, Zlib::DataError => e
    raise unless @silent_mode
    debug(">>> Error: #{e.message}")
    nil
  rescue RuntimeError => e
    raise unless @silent_mode || e.message.scan('HTTP redirection loop').empty?
    debug(">>> Error: #{e.message}")
    nil
  end

  def open_page(url)
    return if url.nil? || url.empty?
    debug(">>> opening page: #{url}")
    Nokogiri::HTML open(url, allow_redirections: :all)
  end

  def absolute_url(url)
    url = url =~ /http|https|www/ ? url : "#{@main_url}/#{url}"
    url.gsub %r{(?<=.{7})//+}, '/'
  end

  def contact_link_translations
    return @_contact_link_translations if @_contact_link_translations
    @_contact_link_translations = CONTACT_LINK_TRANSLATIONS.map do |word|
      [word, word.upcase, word.capitalize]
    end.flatten
  end

  def debug(message)
    p message if @debug
  end

  # This exception is raised when the email address is extracted
  class FoundEmail < StandardError
    attr_reader :location
    def initialize(location = nil)
      @location = location
    end
  end
end
