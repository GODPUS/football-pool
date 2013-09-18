require 'sinatra'
require 'data_mapper'
require 'time'
require 'rack-flash'
require 'sinatra/redirect_with_flash'
require  'dm-migrations'	

SITE_TITLE = "Bovill Football Pool Party!"
SITE_DESCRIPTION = "pssshhht"

enable :sessions
use Rack::Flash, :sweep => true

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db")

class User
	include DataMapper::Resource
	property :id, Serial
	property :content, Text, :required => true
	property :complete, Boolean, :required => true, :default => 0
	property :created_at, DateTime
	property :updated_at, DateTime

	has n, :weeks
end

class Week
	include DataMapper::Resource
	property :id, Serial
	property :content, Text, :required => true
	property :complete, Boolean, :required => true, :default => 0
	property :start_at, DateTime
	property :end_at, DateTime

	belongs_to :user
end

DataMapper.auto_upgrade!

helpers do
	include Rack::Utils
	alias_method :h, :escape_html
end

# 
# Application
#

get '/users' do
	@users = User.all :order => :id.desc
	@title = 'All Users'
	if @users.empty?
		flash[:error] = 'No users found. Add your first below.'
	end 
	erb :home
end

post '/users' do
	n = User.new
	n.attributes = {
		:content => params[:content],
		:created_at => Time.now,
		:updated_at => Time.now
	}

	for i in 1..15
   w = n.weeks.new
   w.attributes = {
		:content => i
	}
	end

	if n.save
		redirect '/users', :notice => 'User created successfully.'
	else
		redirect '/users', :error => 'Failed to save user.'
	end
end

get '/users/:id' do
	@user = User.get params[:id]
	@title = "Edit user ##{params[:id]}"
	if @user
		erb :edit
	else
		redirect '/users', :error => "Can't find that user."
	end
end

put '/users/:id' do
	n = User.get params[:id]
	unless n
		redirect '/users', :error => "Can't find that user."
	end
	n.attributes = {
		:content => params[:content],
		:complete => params[:complete] ? 1 : 0,
		:updated_at => Time.now
	}
	if n.save
		redirect '/users', :notice => 'User updated successfully.'
	else
		redirect '/users', :error => 'Error updating user.'
	end
end

get '/users/:id/delete' do
	@user = User.get params[:id]
	@title = "Confirm deletion of user ##{params[:id]}"
	if @user
		erb :delete
	else
		redirect '/users', :error => "Can't find that user."
	end
end

delete '/users/:id' do
	n = User.get params[:id]
	if n.destroy
		redirect '/users', :notice => 'User deleted successfully.'
	else
		redirect '/users', :error => 'Error deleting user.'
	end
end

get '/users/:id/complete' do
	n = User.get params[:id]
	unless n
		redirect '/users', :error => "Can't find that user."
	end
	n.attributes = {
		:complete => n.complete ? 0 : 1, # flip it
		:updated_at => Time.now
	}
	if n.save
		redirect '/users', :notice => 'User marked as complete.'
	else
		redirect '/users', :error => 'Error marking user as complete.'
	end
end
