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
  imagepath = get_image("http://www.imdb.com/title/#{imdbid}")
  open(imagepath.nil? ? "http://i.media-imdb.com/images/SFaa265aa19162c9e4f3781fbae59f856d/nopicture/medium/film.png" : imagepath)
end

get %r{/(nm[0-9]+)} do |imdbid|
  # matches "GET /nm0000170"
  
  content_type "image/jpeg"
  imagepath = get_image("http://www.imdb.com/name/#{imdbid}")
  open(imagepath.nil? ? "http://i.media-imdb.com/images/SF984f0c61cc142e750d1af8e5fb4fc0c7/nopicture/small/name.png" : imagepath)
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



