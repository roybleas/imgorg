require 'sinatra'
require 'slim'
require 'sinatra/reloader'
require "sinatra/cookies"

require_relative('imgorg.rb')


set :views, File.dirname(__FILE__) + '/imgorg_templates'
set :public_folder, File.dirname(__FILE__) + '/imgorg_myfiles'
set :port, 9810
set :slim, :pretty => true
set :environment, :development
set :cookie_options, :expires => Time.local(2016,"dec",1)
use Rack::Session::Cookie, :secret => 'thisismyimageorganisationexampleprogram'
set :session_secret, 'thisismysiteninvspinpirpvpsiojrpa'

enable :logging
#enable :sessions
# 								did ot seem to maintain session value - not sure why so set Rack Session Pool
use Rack::Session::Pool, :expire_after => 60*60*2 #seconds for a couple of hours




def load_pictures
  imgsuffix = '*.{JPG}' 
  file_list = Dir.glob(File.join(LOCATION,imgsuffix))
  
  file_list.each do |img|
  	img.sub!(/#{LOCATION}\//, '')
	end
	file_list.sort
end

configure :development do
	LOCATION = File.join(File.dirname(__FILE__), 'imgorg_myfiles','gallery')
	SAVED = "save"
	Last_creation_date.instance.creationtime = Time.now
end

configure :production do
	LOCATION = File.join(File.dirname(__FILE__), 'imgorg_myfiles','gallery')
	SAVED = "save"
	Last_creation_date.instance.creationtime = Time.now
end

before do
	@selectionindex = 0 # set default index
	@imagefilesupdated = false
	logger.info("== >>> session[:fred]= #{session[:fred]	}")
	logger.info(" == >> sesion id #{session[:session_id]}")
	if session[:fred].nil?
		logger.info("== >>> Set FRED ")
		session[:fred] = " ###### FRED #{Time.now}" 
	
	end
	
	
	if session[:gallerylist].nil?
		session[:gallerylist] = Imagelist.new(load_pictures,LOCATION)
		logger.info("== >>> session[:gallerylist].nil?")
	else
		logger.info("=== >>> session[:gallerylist] is not nil!!")
		logger.info(session[:gallerylist].created.inspect)
		last_saved = Last_creation_date.instance
		logger.info(last_saved.creationtime.inspect)
		if last_saved.updated?(session[:gallerylist].created)
			session[:gallerylist] = Imagelist.new(load_pictures,LOCATION)
			@imagefilesupdated = true
		end
	end
  @gallerylist = session[:gallerylist]
end


get '/' do
	@imagecount = @gallerylist.list.size
	@fileprefix = @gallerylist.filename_prefix
	@initial_sequence_number = @gallerylist.initial_sequence_number
	slim :index
end

get '/organise/' do
		redirect "/organise/0"
end

get '/organise/:selectionindex' do
	selectionindex = 0
		
	selectionindex = params[:selectionindex].to_i
		
	@selectionindex = selectionindex
	@gallerycount = @gallerylist.list.size
		
	slim :organise
end

get '/moveright/:selectionindex' do
	selectionindex = params[:selectionindex].to_i
	@gallerylist.move_next(selectionindex)
	
	redirect "/organise/#{selectionindex}"
end

get '/moveleft/:selectionindex' do
	selectionindex = params[:selectionindex].to_i
	@gallerylist.move_previous(selectionindex)
	
	redirect "/organise/#{selectionindex}"
end

get '/gallery/' do
		redirect "/gallery/0"
end

get '/gallery/:selectionindex' do
	selectionindex = 0
		
	selectionindex = params[:selectionindex].to_i
		
	@selectionindex = selectionindex
	@gallerycount = @gallerylist.list.size
	slim :gallery
end

get '/save' do
	@gallerylist.save
	Last_creation_date.instance.creationtime = Time.now
	
	session[:gallerylist] = Imagelist.new(load_pictures,LOCATION)
	@gallerylist = session[:gallerylist]
	redirect "/organise/"
	
end

post '/set' do
		filename = params[:filename]
		if filename.strip != ""
			#sanitise the file name a bit
			filename.gsub! /[^a-z0-9\-]+/i, '_' 
			@gallerylist.filename_prefix = filename
		end
		#convert string to an integer and force to be at least 1
		seq_no = params[:seq].to_i
		if seq_no > 0 
			@gallerylist.initial_sequence_number = seq_no
		end
		
		redirect "/"
end

post '/load' do
	
	case params[:samples]
	when "example"
		filename = "exampleimage_001_*.jpg"
	when "cats"
		filename = "cats_*.jpg"
	when "india"
		filename = "img_*.jpg"
	else
		filename = "unknown"
	end
	
	file_list = Dir[File.join(LOCATION,SAVED ,filename)]
	if file_list.size > 0
		# empty gallery folder
		Dir.glob(File.join(LOCATION,"*.jpg")) {|f| File.delete(f) }
	 	
	 	FileUtils.cp file_list, LOCATION
	 	redirect "/refresh"
	else
	 	redirect "/"
	end
end
	
get '/refresh' do
	session[:gallerylist] = Imagelist.new(load_pictures,LOCATION)
	redirect '/'
end

get '/admin' do
	slim :admin
end