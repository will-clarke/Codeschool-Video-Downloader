Codeschool Video Downloader
============================

Uses Nokogiri &amp; Watir to download all the Code School Screencasts & Courses.

This assumes you've got a codeschool account.

### Usage

Run this script from the command line with your codeschool username & password:

    # install homebrew:
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew install chromedriver

    gem install bundler  # get bundler to install gems automatically
    bundle install       # install the dependencies

    ruby code_school_scraper.rb *your_username* *your_password*

It will, by default, shove all the files on your desktop into sensibly-named folders (assuming you're on a mac...)

Note: You'll have to have a paid plan in order to download all the videos available.

If you get any SSL-related error messages, check out [this page](http://railsapps.github.io/openssl-certificate-verify-failed.html) to update / install openSSL
