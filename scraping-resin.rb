require 'open-uri'
require 'open_uri_redirections'
require 'nokogiri'
require 'csv'

def page_content(url)
  Nokogiri::HTML(URI.open(url, "User-Agent"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:78.0) Gecko/20100101 Firefox/78.0", :allow_redirections => :all))
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


#TODO: allow user input
state_url     = "https://weedmaps.com/dispensaries/in/united-states/michigan/"
state_content = page_content(state_url)
township_urls = township_urls(state_content)
csv = CSV.open("output.csv", "a+")

headers = ["name", "phone", "email", "site"]
CSV.open("output.csv", "a+") do |row|
  row << headers
end

for township_url in township_urls
  township_content = page_content(township_url)
  dispensary_urls  = dispensary_urls(township_content)
  for dispensary_url in dispensary_urls
    dispensary_content = page_content(dispensary_url)
    data = dispensary_data(dispensary_content)
    data_row = [data["name"], data["phone"], data["email"], data["site"]]
    CSV.open("output.csv", "a+") do |row|
      row << data_row
    end
  end
end
