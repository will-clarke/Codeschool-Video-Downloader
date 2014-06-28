require 'nokogiri'
require 'watir-webdriver'

url = 'https://www.codeschool.com/code_tv'
selector = '.bucket-header--truncate a'
urls = []

page = Nokogiri::HTML.parse(open(url))

page.css(selector).each do |element|
    urls <<  'http://www.codeschool.com' + element.attributes['href'].value
end


b = Watir::Browser.new



# LOGGING IN
# ========================================================

b.goto 'http://www.codeschool.com'
b.a(class:'form--authMini-toggle').click

t = b.text_field :id => 'user_login'
t.exists?
t.set 'wmmclarke'

t = b.text_field :id => 'user_password'
t.exists?
t.set 'password'

b.input(class: 'btn--submit').click


# LOOPING
# ========================================================

# urls = File.open('screencasts.txt').read
# urls = urls.split(/\n/)

urls.each do |url|

	p url
	b.goto url
	l = b.div(class: 'video-download').links[0] #was links[1]
	l.click if l.exists?
	sleep 30 + rand(20)
end




# b.goto 'http://www.codeschool.com/code_tv/cocoapods'

# l = b.div(class: 'video-download').links[1]
# l.click if l.exists?









# require 'mechanize'

# @agent = Mechanize.new
# @agent.ssl_version= false

# username = 'wmmclarke'
# password = 'password'


# page = @agent.get 'http://www.codeschool.com'
# form = page.forms[0]
# form['user[login]'] = username
# form['user[password]'] = password
# # 
# next_page = @agent.submit form

# ########## We've now logged in....

# @agent.get 'http://www.codeschool.com/code_tv/cocoapods'

# urls = File.open('screencasts.txt').read
# urls = urls.split(/\n/)

# urls.each do |url|
# 	page = @agent.get url
# 	page.search
# end

# # Mechanize.new{|a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE}
