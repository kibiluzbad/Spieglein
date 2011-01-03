require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'nokogiri'

get '/' do
  # matches "GET /"
  "Spieglein is running!"
end

get %r{/(tt[0-9]+)} do |imdbid|
  # matches "GET /tt9999999"
  
  content_type "image/jpeg"
  open(get_image("http://www.imdb.com/title/#{imdbid}"))
end

get %r{/(nm[0-9]+)} do |imdbid|
  # matches "GET /nm0000170"
  
  content_type "image/jpeg"
  open(get_image("http://www.imdb.com/name/#{imdbid}"))
end

private 
  
  def get_image(url)
    doc = Nokogiri::HTML(open(url))do |config|
      config.noblanks
    end
  
    image = nil
      doc.xpath('//td[@id="img_primary"]//img').each do|v|
        image = v
    end
    
    image.attributes["src"].value unless image.nil?
  end



