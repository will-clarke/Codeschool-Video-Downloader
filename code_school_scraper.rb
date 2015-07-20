require 'nokogiri'
require 'watir-webdriver'
require 'open-uri'
require 'open_uri_redirections'

class CodeSchoolDownloader
  attr_accessor :browser
  DOWNLOAD_LOCATION = Dir.home + '/Desktop/Codeschool'
  TIMEOUT = 40

  def initialize username, password
    @browser = Watir::Browser.new
    login username, password
    create_dir DOWNLOAD_LOCATION
    download_videos
  end

  def download_videos
    deal_with_screencasts
    deal_with_courses
  end

  def login username, password
    @browser.goto 'http://www.codeschool.com/users/sign_in'

    t = @browser.text_field :id => 'user_login'
    t.set username

    t = @browser.text_field :id => 'user_password'
    t.set password

    @browser.button(class: 'form-btn').click
  end

  def deal_with_screencasts
    dir_name = DOWNLOAD_LOCATION + '/screencasts'
    create_dir dir_name
    LinkGenerator.screencast_urls.each do |url|
      download url, dir_name, url.split('/').last.gsub('-', ' ')
    end
  end

  def deal_with_courses
    dir_name = DOWNLOAD_LOCATION + '/courses'
    create_dir dir_name
    LinkGenerator.course_urls.each do |url|
      download url, dir_name
    end
  end

  def download url, dir_name, passed_in_filename = nil
    p url
    @browser.goto url
    html = @browser.html
    page = Nokogiri::HTML.parse(html)
    sub_dir_name =  dir_name + '/' + page.css('h1').text.gsub('Screencast', '').strip.gsub(/\W/, ' ').gsub(/\s+/, ' ').gsub(/\s/, '-')
    create_dir sub_dir_name
    filenames = page.css('.tct').map(&:text)
    page.css('.cs-video-player').map.with_index do |link, index|
      begin
        url = link.children[3].attributes['src'].value
        name = passed_in_filename ? passed_in_filename : "#{index.to_s.ljust 2}- #{filenames[index]}"
        filename = "#{sub_dir_name}/#{name}.mp4"
        File.open(filename, 'wb') do |f|
          f.write(open(url, allow_redirections: :all).read)
        end
      rescue => e
        p e
      end
      sleep timeout
    end

  end

  def create_dir filename
    unless File.exists? filename
      FileUtils.mkdir filename
    end
  end

  def timeout
    TIMEOUT + rand(20)
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

CodeSchoolDownloader.new(*ARGV)
