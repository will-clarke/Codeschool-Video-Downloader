Codeschool Video Downloader
============================

Uses Nokogiri &amp; Watir to download all the Code School Screencasts & Courses.

This assumes you've got a codeschool account.

### Usage

Run this script from the command line with your codeschool username & password:

    gem install nokogiri
    gem install watir-webdriver
    gem install open_uri_redirections

    ruby code_school_scraper.rb *your_username* *your_password*

It will, by default, shove all the files on your desktop into sensibly-named folders.

If you get any SSL-related error messages, check out [this page](http://railsapps.github.io/openssl-certificate-verify-failed.html) to update / install openSSL
