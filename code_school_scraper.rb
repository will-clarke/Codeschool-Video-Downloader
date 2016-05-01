require 'nokogiri'
require 'watir-webdriver'
require 'open-uri'
require 'open_uri_redirections'

class CodeSchoolDownloader
  attr_accessor :browser
  DOWNLOAD_LOCATION = Dir.home + '/Desktop/Codeschool'
  TIMEOUT = 0

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
    @browser.goto 'https://www.codeschool.com/users/sign_in'

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
      download_screencasts url, dir_name, url.split('/').last.gsub('-', ' ')
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
    puts "\nCourse"
    p url
    puts

    @browser.goto url
    html = @browser.html
    page = Nokogiri::HTML.parse(html)
    sub_dir_name =  dir_name + '/' + page.css('h1').text.gsub('Screencast', '').strip.gsub(/\W/, ' ').gsub(/\s+/, ' ').gsub(/\s/, '-')
    create_dir sub_dir_name
    filenames = page.css('.tct').map(&:text)
    counter = 0
    links = @browser.links(:class, "js-level-open")
    videos_total = links.size
    links.each do |course|
      begin
        puts "Opening video..."
        if videos_total - counter - 1 == 0
          puts "This is the last lesson from this course"
        else
          puts "Videos left #{(videos_total - counter - 1).to_s}"
        end
        course.when_present.fire_event("click")
        sleep 1
        video_page = Nokogiri::HTML.parse(@browser.html)
        url = video_page.css('div#level-video-player video').attribute('src').value
        puts "URL retrieved"
        puts "Closing video..."
        @browser.links(:class, "modal-close")[3].when_present.fire_event("click")
        name = passed_in_filename ? passed_in_filename : "#{(counter + 1).to_s.ljust 2}- #{filenames[counter]}"
        filename = "#{sub_dir_name}/#{name}.mp4"
        File.open(filename, 'wb') do |f|
          puts "Downloading video #{name}..."
          f.write(open(url, allow_redirections: :all).read)
          puts "Saving #{filename}..."
        end
      rescue => e
        p e.inspect
      end
      counter += 1
    end
  end


  def download_screencasts url, dir_name, passed_in_filename = nil
    puts "\nCourse"
    p url
    puts

    @browser.goto url
    html = @browser.html
    page = Nokogiri::HTML.parse(html)
    sub_dir_name =  dir_name + '/' + page.css('h1 span:last').text.gsub(/\//,'-')
    #binding.pry
    create_dir sub_dir_name
    begin
      puts "Opening video..."
      video_page = Nokogiri::HTML.parse(@browser.html)
      video_url = video_page.css('div#code-school-screencasts video').attribute('src').value
      puts "VIDEO URL retrieved"
      puts "Closing video..."
      @browser.back
      name = page.css('h1').text.gsub('Screencast', '').strip.gsub(/\W/, ' ').gsub(/\s+/, ' ').gsub(/\s/, '-')
      filename = "#{sub_dir_name}/#{name}.mp4"
      File.open(filename, 'wb') do |f|
        puts "Downloading video #{name}..."
        f.write(open(video_url, allow_redirections: :all).read)
        puts "Saving #{filename}..."
      end
    rescue => e
      p e.inspect
    end
  end

  def create_dir filename
    unless File.exists? filename
      FileUtils.mkdir filename
    end
  end

  def timeout
    TIMEOUT + rand(5)
  end
end


class LinkGenerator
  def self.screencast_urls
    screencast_url = 'https://www.codeschool.com/screencasts/all'
    screencast_selector = 'article.screencast a'
    screencast_urls = []
    screencast_page = Nokogiri::HTML.parse(open(screencast_url))

    screencast_page.css(screencast_selector).each do |element|
      screencast_urls << 'https://www.codeschool.com' + element.attributes['href'].value
    end
    screencast_urls
  end


  def self.course_urls
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

CodeSchoolDownloader.new(*ARGV)
