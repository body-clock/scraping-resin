require 'open-uri'
require 'open_uri_redirections'
require 'nokogiri'
require 'csv'
require 'openssl'
require 'dotenv/load'

def page_content(url)
  attempt_count = 0
  max_attempts  = 3
  request_headers = {
    "User-Agent"                     => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:78.0) Gecko/20100101 Firefox/78.0",
    :allow_redirections              => :all,
    :proxy_http_basic_authentication => [URI.parse("http://proxy.crawlera.com:8010"), ENV['CRAWLERA_KEY'], ""],
    :ssl_verify_mode                 => OpenSSL::SSL::VERIFY_NONE,
    :read_timeout                    => 60
  }
  begin
    attempt_count += 1
    puts "Attempt: #{attempt_count}" if attempt_count > 1
    content        = URI.open(url, request_headers)
  rescue OpenURI::HTTPError => e
    puts "HTTP Error: #{e}"
  rescue SocketError, Net::ReadTimeout => e
    puts "Read Timeout: #{e}"
    sleep 3
    retry if attempt_count < max_attempts
  else
    Nokogiri::HTML(content)
  end
end

def township_urls(state_html) 
  nodeset = state_html.css(".hvdMfp")
  hrefs   = nodeset.map {|element| element["href"]}.compact
  hrefs.map{|href| "https://weedmaps.com#{href}"}
end

def dispensary_urls(township_html)
  nodeset = township_html.css(".cnqeNi")
  hrefs   = nodeset.map {|element| element["href"]}.compact
  hrefs.map{|href| "https://weedmaps.com#{href}/about"}
end

def dispensary_data(dispensary_html)
  data = {}
  data["name"]  = dispensary_html.css("h1.text__Text-fif1uk-0").text
  data["phone"] = dispensary_html.css("div.styled-components__DetailGridItem-d53rlt-0:nth-child(2) > a:nth-child(1)").text
  data["email"] = dispensary_html.css("div.styled-components__DetailGridItem-d53rlt-0:nth-child(4) > a:nth-child(1)").text
  data["site"]  = dispensary_html.css("div.styled-components__DetailGridItem-d53rlt-0:nth-child(5) > a:nth-child(1)").text
  data
end

puts "Enter a state:"
state_input   = gets
state         = state_input.chomp.downcase
state_url     = "https://weedmaps.com/dispensaries/in/united-states/#{state}/"
state_content = page_content(state_url)
township_urls = township_urls(state_content)

headers = ["name", "phone", "email", "site"]
CSV.open("#{state}.csv", "a+") do |row|
  row << headers
end

for township_url in township_urls
  puts township_url
  township_content = page_content(township_url)
  dispensary_urls  = dispensary_urls(township_content)
  for dispensary_url in dispensary_urls
    puts "...#{dispensary_url}"
    dispensary_content = page_content(dispensary_url)
    data               = dispensary_data(dispensary_content)
    data_row           = [data["name"], data["phone"], data["email"], data["site"]]
    CSV.open("#{state}.csv", "a+") do |row|
      row << data_row
    end
  end
end

puts "done!"
