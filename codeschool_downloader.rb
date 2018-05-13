require 'nokogiri'
require 'watir'
require 'open-uri'
require 'open_uri_redirections'

SLEEP_TIME = 2
DOWNLOAD_LOCATION = Dir.home + '/Desktop/Codeschool'

# Main class to start everything off
class CodeSchoolDownloader
  attr_reader :browser

  def initialize(username = '', password = '')
    if no_authentication?(username, password)
      raise "\n\nPlease supply your codeschool username & password:\n\nEg:\n  $ ruby codeschool_downloader.rb **USERNAME** **PASSWORD**\n\n"
    end
    @browser = Watir::Browser.new
    login username, password
  end

  def download
    Downloader.new(browser: browser).download_all_videos
  end

  private

  def login(username, password)
    browser.goto 'https://www.codeschool.com/users/sign_in'
    sleep SLEEP_TIME
    t = browser.text_field id: 'user_login'
    t.set username
    t = browser.text_field id: 'user_password'
    t.set password
    browser.button(class: 'form-btn').click
    sleep SLEEP_TIME
  end

  def no_authentication?(username, password)
    username == '' && password == ''
  end
end

# Helper Utils
module FileStuff
  def create_dir(file_path)
    FileUtils.mkdir file_path unless File.exist? file_path
  end
end

class Downloader
  include FileStuff
  attr_reader :browser

  def initialize(browser: nil)
    @browser = browser
    create_dir(DOWNLOAD_LOCATION)
  end

  def download_all_videos
    download :courses
    download :screencasts
  end

  private

  def download(category)
    singular_type = category.to_s.gsub(/s$/, '')
    link_generator_method = "#{singular_type}_urls".to_sym
    create_dir dir_name(category)
    puts "\n#{category.to_s.capitalize}"

    download_all_category_videos(link_generator_method, browser, category)
  end

  def download_all_category_videos(link_generator_method, browser, category)
    LinkGenerator.send(link_generator_method, browser).each do |url|
      klass = klass_for(category)
      downloader = klass.new(browser: browser,
                             url: url,
                             base_directory: dir_name(category))
      downloader.download_all
    end
  end

  def klass_for(category)
    singular_category = category.to_s.gsub(/s$/, '')
    Object.const_get(singular_category.capitalize)
  end

  def dir_name(category)
    base_path = DOWNLOAD_LOCATION
    "#{base_path}/#{category.to_s.downcase}"
  end
end

# Superclass for specific downloaders
class VideoDownloader
  include FileStuff
  attr_reader :url, :base_directory, :browser, :file_name

  def initialize(browser: nil, url: nil, base_directory: nil)
    @url = url
    @base_directory = base_directory
    @browser = browser
    @file_name = url.split('/').last || ''
    # create_dir directory_name
  end

  def file_path(name = file_name)
    "#{directory_name}/#{name}.mp4".gsub(/[^\w\/\.]+/, '-')
  end

  def directory_name
    "#{base_directory}/#{video_directory}"
  end

  def save_file(file_path: nil, video_url: nil)
    return unless file_path && video_url
    create_dir directory_name
    File.open(file_path, 'wb') do |f|
      f.write(open(video_url, allow_redirections: :all).read)
      puts "  #{file_name}"
    end
  end

  def page_html
    html = browser.html
    Nokogiri::HTML.parse(html)
  end

  def goto_url
    sleep SLEEP_TIME
    browser.goto url
    sleep SLEEP_TIME
  end
end

class Course < VideoDownloader

  def download_all
    goto_url
    links.size.times do |index|
      download_single(index)
    end
  end

  def download_single(index = 0)
    goto_url
    click_link(index)
    save_file(file_path: file_path(index), video_url: video_url)
  rescue => e
    p e
  end

  def video_url
    page_html.css('div#level-video-player video').attribute('src').value
  end

  def file_path(index)
    name = "#{(index + 1).to_s.ljust 2}- #{filenames[index]}"
    super(name)
  end

  def video_directory
    page_html.css('h1').text.gsub('Screencast', '').gsub('C#', 'C-Sharp').
    strip.gsub(/\W/, ' ').gsub(/\s+/, ' ').gsub(/\s/, '-')
  end

  def click_link(index)
    links = browser.links(:class, 'js-level-open')
    link = links[index]
    link.click
    sleep SLEEP_TIME
  end

  def filenames
    page_html.css('.tct').map(&:text)
  end

  def links
    browser.links(:class, 'js-level-open')
  end

  def file_name
    url.split('/')[-2]
  end
end

class Screencast < VideoDownloader

  def download_all
    download_single
  end

  def download_single
    goto_url
    save_file(file_path: file_path, video_url: video_url)
  rescue # => e
    # p e
  end

  def video_url
    video_div = page_html.css('div#code-school-screencasts video')
    video_div &&
      video_div.any? &&
      video_div.attribute('src') &&
      video_div.attribute('src').value
  end

  def video_directory
    page_html.css('h1 .tag').text.gsub(/\W/, '-')
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
    sleep SLEEP_TIME
    screencast_urls << screencast_urls_from_page(browser)
    links = browser.links(class: 'video-page-link')
    sleep SLEEP_TIME
    loop do
      links = browser.links(class: 'video-page-link')
      next_button = links.select { |i| i.text == 'Next→' }.first
      break unless next_button
      next_button.click
      sleep SLEEP_TIME
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

CodeSchoolDownloader.new(*ARGV).download
