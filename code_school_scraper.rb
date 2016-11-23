require 'nokogiri'
require 'watir'
require 'open-uri'
require 'open_uri_redirections'

class CodeSchoolDownloader
  attr_reader :browser
  DOWNLOAD_LOCATION = Dir.home + '/Desktop/Codeschool'
  TIMEOUT = 0

  def initialize(username = '', password = '')
    @browser = Watir::Browser.new
    login username, password
    create_dir DOWNLOAD_LOCATION
  end

  def download_videos
    deal_with_screencasts
    deal_with_courses
  end

  def login(username, password)
    browser.goto 'https://www.codeschool.com/users/sign_in'
    t = browser.text_field id: 'user_login'
    t.set username
    t = browser.text_field id: 'user_password'
    t.set password
    browser.button(class: 'form-btn').click
  end

  def deal_with_screencasts
    dir_name = DOWNLOAD_LOCATION + '/screencasts'
    create_dir dir_name
    puts "\nScreencasts"
    LinkGenerator.screencast_urls(browser).each do |url|
      file_name = url.split('/').last.gsub('-', ' ')
      download_screencasts url, dir_name, file_name
    end
  end

  def deal_with_courses
    dir_name = DOWNLOAD_LOCATION + '/courses'
    create_dir dir_name
    puts "\nCourse"
    LinkGenerator.course_urls(browser).each do |url|
      download_course url, dir_name
    end
  end

  def download_course(course_url, dir_name, passed_in_filename = nil)
    browser.goto course_url
    html = browser.html
    page = Nokogiri::HTML.parse(html)
    course_name = page.css('h1').text.gsub('Screencast', '').
                    strip.gsub(/\W/, ' ').gsub(/\s+/, ' ').gsub(/\s/, '-')
    sub_dir_name = dir_name + '/' + course_name
    create_dir sub_dir_name
    filenames = page.css('.tct').map(&:text)
    links = browser.links(:class, 'js-level-open')
    videos_total = links.size
    videos_total.times do |index|
      begin
        browser.goto course_url
        html = browser.html
        page = Nokogiri::HTML.parse(html)
        links = browser.links(:class, 'js-level-open')
        link = links[index]
        link.click
        sleep 1
        video_page = Nokogiri::HTML.parse(browser.html)
        sleep 1
        url = video_page.css('div#level-video-player video').attribute('src').value
        name = passed_in_filename ? passed_in_filename : "#{(index + 1).to_s.ljust 2}- #{filenames[index]}"
        filename = "#{sub_dir_name}/#{name}.mp4"
        File.open(filename, 'wb') do |f|
          f.write(open(url, allow_redirections: :all).read)
          puts "  #{name}"
        end
      rescue => e
        p e
      end
    end
  end

  def download_screencasts url, dir_name, passed_in_filename = nil
    browser.goto url
    html = browser.html
    page = Nokogiri::HTML.parse(html)
    file_name = page.css('h1 .has-tag--heading').text
    directory = page.css('h1 .tag').text.gsub(/\W/, '-')
    sub_dir_name = dir_name + '/' + directory
    create_dir sub_dir_name
    filename = (sub_dir_name + '/' + file_name + '.mp4').gsub(/[^\w\/\.]+/, '-')
    begin
      sleep 1
      video_page = Nokogiri::HTML.parse(browser.html)
      sleep 1
      video_div = video_page.css('div#code-school-screencasts video')
      video_url = video_div && video_div.any? && video_div.attribute('src') &&
                  video_div.attribute('src').value
      browser.back
      return unless video_url
      File.open(filename, 'wb') do |f|
        puts "  #{url}"
        f.write(open(video_url, allow_redirections: :all).read)
      end
    rescue => e
      p e
    end
  end

  def create_dir(filename)
    unless File.exists? filename
      FileUtils.mkdir filename
    end
  end

  def timeout
    TIMEOUT + rand(5)
  end
end

class LinkGenerator

  def self.screencast_urls_from_page(browser)
    screencast_page = Nokogiri::HTML.parse(browser.html)
    screencast_page.css('.twl').map do |element|
      'https://www.codeschool.com' + element.attributes['href'].value
    end
  end

  def self.screencast_urls(browser)
    screencast_urls = []
    screencast_url = 'https://www.codeschool.com/screencasts'
    browser.goto screencast_url
    sleep 1
    screencast_urls << screencast_urls_from_page(browser)
    links = browser.links(class: 'video-page-link')
    loop do
      links = browser.links(class: 'video-page-link')
      next_button = links.select {|i| i.text == 'Next→' }.first
      break unless next_button
      next_button.click
      sleep 2
      screencast_urls << screencast_urls_from_page(browser)
    end
    screencast_urls.flatten.uniq
  end

  def self.course_urls(browser)
    course_url = 'https://www.codeschool.com/courses'
    course_selector = '.course-title-link'
    course_urls = []
    course_page = Nokogiri::HTML.parse(open(course_url))
    course_page.css(course_selector).each do |element|
      course_urls << 'https://www.codeschool.com' + element.attributes['href'].value + '/videos'
    end
    course_urls
  end
end

CodeSchoolDownloader.new(*ARGV).download_videos
