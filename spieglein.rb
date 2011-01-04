require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'nokogiri'
require 'dm-core'
require 'dm-validations'
require 'dm-migrations'

## CONFIGURATION
configure :development do
  DataMapper.setup(:default, {
    :adapter  => 'mysql',
    :host     => 'localhost',
    :username => 'root' ,
    :password => 'password',
    :encoding => 'utf-8',
    :database => 'spieglein_development'})  

  DataMapper::Logger.new(STDOUT, :debug)
end

configure :production do
  DataMapper.setup(:default, ENV['DATABASE_URL']+"?encoding=ISO-8859-1")  
end

## MODELS
class Image
  include DataMapper::Resource
  property :imdbid,     String, :length=>30, :key=>true
  property :picture,    Binary, :lazy=>false
  property :created_at, DateTime
  property :updated_at, DateTime

  validates_presence_of :picture
  
  def need_update
    return true if self.picture.nil?
    false
  end
end



get '/' do
  # matches "GET /"
  DataMapper.auto_migrate!
  "Spieglein is running!"  
end

get %r{/(tt[0-9]+)} do |imdbid|
  # matches "GET /tt9999999"
  content_type "image/jpeg"
  render_image(imdbid,"http://www.imdb.com/title/","http://i.media-imdb.com/images/SFaa265aa19162c9e4f3781fbae59f856d/nopicture/medium/film.png")
end

get %r{/(nm[0-9]+)} do |imdbid|
  # matches "GET /nm0000170"
  
  content_type "image/jpeg"
  render_image(imdbid,"http://www.imdb.com/name/","http://i.media-imdb.com/images/SF984f0c61cc142e750d1af8e5fb4fc0c7/nopicture/small/name.png")
end

private 
  def render_image(imdbid,url,default_image)
    image = Image.first_or_create(:imdbid=>imdbid)
  
    if image.need_update
      imagepath = get_image("#{url}#{imdbid}")
      image.picture = open(imagepath || default_image).read
      image.save!
    end
    
    image.picture
  end
  
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



