require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'nokogiri'
require 'dm-core'
require 'dm-validations'
require 'dm-migrations'
require 'go_picasa_go'

## CONFIGURATION
configure :development do
  DataMapper.setup(:default, {
    :encoding => 'iso-8859-1',
    :port     => 5432,
    :adapter  => 'postgres',
    :host     => '10.96.0.4',
    :username => 'postgres' ,
    :password => 'password',
    :database => 'spieglein_development'})  

  DataMapper::Logger.new(STDOUT, :debug)

end

configure :production do
  DataMapper.setup(:default, ENV['DATABASE_URL']+"?encoding=iso-8859-1")  
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

class User < Picasa::DefaultUser
  def picasa_id
    "moviescatalogonrails"
  end
  
  def auth_token
    "DQAAALwAAAB6jXxSXE6ohv7btQq5-XurlMAzpmd4DL9HWIxXvSnL3fOlPIcGyl8ELldUplG9xPdKwu-eay_dCmZCnypgKUSMs9bKBZouT7lAT2eTLr_KcoVrQPz7heBDbsa_JOdjDG3nZCEwWUIW0nKmkcfWQhtulu4cjBOPvRZcssLDBYUZh503geDZNARKXhbZtxzH4jrkRRqCAUlPwz7upxgh8oyZYOAUcIm2UNcXbRIfEROUaEAdyLI-k6z9CaDagQ9l0kk"
  end
end


get '/' do
  # matches "GET /"
  DataMapper.auto_migrate!
  "Spieglein is running!"  
end

get %r{/(tt[0-9]+)/?(small|tiny|normal)?} do |imdbid,size|
  # matches "GET /tt9999999"
  # matches "GET /tt9999999/"
  # matches "GET /tt9999999/small"
  # matches "GET /tt9999999/tiny"
  # matches "GET /tt9999999/normal"
  
  #content_type "image/jpeg"
  redirect render_image(imdbid,"http://www.imdb.com/title/","http://i.media-imdb.com/images/SFaa265aa19162c9e4f3781fbae59f856d/nopicture/medium/film.png",size)
end

get %r{/(nm[0-9]+)/?(small|tiny|normal)} do |imdbid,size|
  # matches "GET /nm9999999"
  # matches "GET /nm9999999/"
  # matches "GET /nm9999999/small"
  # matches "GET /nm9999999/tiny"
  # matches "GET /nm9999999/normal"
  
  #content_type "image/jpeg"
  redirect render_image(imdbid,"http://www.imdb.com/name/","http://i.media-imdb.com/images/SF984f0c61cc142e750d1af8e5fb4fc0c7/nopicture/small/name.png",size)
end

private 
  def render_image(imdbid,url,default_image,size)
    user = User.new

    if(user.albums.nil? || user.albums.empty?)
      album = Picasa::DefaultAlbum.new
      album.user = user
      album.title = "Images"
      album.access = 'private'
      album.picasa_save!
    end
    
    album = user.albums[0]
    
    photo = album.photos.select{|p| p.description == imdbid}.first
    
    #image = Image.first_or_create(:imdbid=>imdbid)
    data = nil
    #image = Image.new(:imdbid=>imdbid)
    # FIX:Arrumar or problemas de encoding no PG  
    if photo.nil?
      imagepath = get_image("#{url}#{imdbid}")
      data = open(imagepath || default_image)
      
      photo = Picasa::DefaultPhoto.new
      photo.album = album
      photo.description = imdbid
      photo.file = data
      photo.picasa_save!
      #image.picture = data
      #image.save
    end
    
    size_map = {"tiny" => "media_thumbnail_url1","small" => "media_thumbnail_url2", "normal" => "media_thumbnail_url3", nil => "media_content_url"}
    
    photo.send("#{size_map[size]}")
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
