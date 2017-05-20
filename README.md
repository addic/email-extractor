# Ruby Email Extractor

## What is it?
It is a small ruby class I wrote for myself when I needed to grab some emails from websites. The logic of the script is pretty basic and simple, however it does the job in most of the cases. It is not 100% reliable (this was good enough for me), thus I recommend to manually check the results before using them for something more serious.

## How it works?
First it opens the given URL and searches for mailto links, if that fails, it searches for email like strings in the text of the whole page. If that fails, it checks for links containing words "contacts" or "contact" in a few languages in the website navigation. Finally, when all fails, it crawls all internal page links and repeats the same actions there until it finds at least one email adress or none.

## What can I use it for?
Feel free to use it for anything you wish - inspiration/learning/development/production. I am not responsible for anything you might do with this.


It is not fully finished, so feel free to contribute if you do anything with it.a

## Dependencies
[Nokogiri](https://github.com/sparklemotion/nokogiri)
```
gem install nokogiri
```

## Demo
You have to include the ruby gems and then simply initialize an instance of the EmailExtractor class. Provide an initial URL to be parsed by the extractor and choose if the mode should be silent or not and debug on/off.

Silent mode - all exceptions are ignored, so the script continues to run and does not break after an error.
Debug mode - you can find logged details in the console.

    require 'rubygems'
    require 'nokogiri'
    require 'open-uri'
    require 'open_uri_redirections'
    require 'openssl'
    require_relative 'email_extractor'

    ee = EmailExtractor.new 'http://www.somepage.com', true, true
    email = ee.find_email
    p '-------------------------------------------'
    p "EMAIL FOUND: #{email}" if email
    p '-------------------------------------------'
