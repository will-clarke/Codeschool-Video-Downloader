require 'nokogiri'
require 'watir-webdriver'
require 'open-uri'

# Todo :
# Don't bother using watir (although it's fun mucking around with it).
# Find the links to download hidden in the HTML with nokogiri
# projector.codeschool.com/videos

class CodeSchoolDownloader
  attr_accessor :browser

  TIMEOUT = 40
  def initialize
    @browser = Watir::Browser.new
    login
    download_screencasts
  end

  def download_screencasts
    deal_with_courses
    deal_with_screencasts
  end

  def login
    @browser.goto 'http://www.codeschool.com/users/sign_in'

    t = @browser.text_field :id => 'user_login'
    t.exists?
    p 'Please put in your username:'
    username = gets.chomp
    t.set username

    t = @browser.text_field :id => 'user_password'
    t.exists?
    p 'Please put in your password:'
    password = gets.chomp
    t.set password

    @browser.button(class: 'form-btn').click
  end

  def deal_with_screencasts
    LinkGenerator.screencast_urls.each do |url|
      p url
      @browser.goto url
      l = @browser.div(class: 'video-controls--download').links[0] #was links[1]
      l.click if l.exists?
      l = @browser.a(text: "Standard Definition")
      l.click if l.exists?

      sleep timeout
    end
  end

  def deal_with_courses
    LinkGenerator.course_urls.each do |url|
      p url
      @browser.goto url
      link = nil
      count = 0
      while(link == nil) do
        begin
          video_link = @browser.elements(css: '.sticker--video')[count]
          video_link.click if video_link.exists?
          count += 1
          l = @browser.div(class: 'video-controls--download').links[0] #was links[1]
          l.click if l.exists?
          l = @browser.a(text: "Standard Definition")
          l.click if l.exists?
          sleep timeout
        rescue => e
          require 'pry'; binding.pry
        end
      end
    end
  end

  def timeout
    1
    # TIMEOUT + rand(20)
  end
end


class LinkGenerator
  def self.screencast_urls
    screencast_url = 'https://www.codeschool.com/screencasts/all'
    screencast_selector = '.screencast-cover'
    screencast_urls = []
    screencast_page = Nokogiri::HTML.parse(open(screencast_url))

    screencast_page.css(screencast_selector).each do |element|
      screencast_urls << 'http://www.codeschool.com' + element.attributes['href'].value
    end
    screencast_urls
  end


  def self.course_urls
    course_url = 'https://www.codeschool.com/courses'
    course_selector = '.course-title-link'
    course_urls = []
    course_page = Nokogiri::HTML.parse(open(course_url))

    course_page.css(course_selector).each do |element|
      course_urls << 'http://www.codeschool.com' + element.attributes['href'].value + '/videos'
    end
    course_urls
  end
end

CodeSchoolDownloader.new
