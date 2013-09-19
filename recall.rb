require 'sinatra'
require 'data_mapper'
require 'time'
require 'rack-flash'
require 'sinatra/redirect_with_flash'
require  'dm-migrations'	
require 'ostruct'

SITE_TITLE = "Wat"
SITE_DESCRIPTION = "pssshhht"

enable :sessions
use Rack::Flash, :sweep => true

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db")

class User
	include DataMapper::Resource
	property :id, Serial
	property :username, String, :required => true
	property :password, String, :required => true
	property :wins, Integer
	property :losses, Integer

	has n, :picks
end

class Pick
	include DataMapper::Resource
	property :id, Serial
	property :num, Integer
	property :week_num, String
	property :team, String

	belongs_to :user
end

class Week
	include DataMapper::Resource
	property :id, Serial
	property :num, Integer
	property :complete, Boolean
	property :start_at, DateTime
	property :end_at, DateTime

	has n, :matchups
end

class Matchup
	include DataMapper::Resource
	property :id, Serial
	property :num, Integer
	property :start_at, DateTime

	belongs_to :week
	has n, :teams
end

class Team
	include DataMapper::Resource
	property :id, Serial
	property :name, String, :required => true
	property :homefield, Boolean
	property :is_winner, Boolean

	belongs_to :matchup
end


DataMapper.auto_migrate!
#DataMapper.auto_upgrade!

helpers do
	include Rack::Utils
	alias_method :h, :escape_html
end

configure do
  TEAMS = OpenStruct.new(
  	:ARI => 'Arizona Cardinals',
		:ATL => 'Atlanta Falcons',
		:BAL => 'Baltimore Ravens',
		:BUF => 'Buffalo Bills',
		:CAR => 'Carolina Panthers',
		:CHI => 'Chicago Bears',
		:CIN => 'Cincinnati Bengals',
		:CLE => 'Cleveland Browns',
		:DAL => 'Dallas Cowboys',
		:DEN => 'Denver Broncos',
		:DET => 'Detroit Lions',
		:GB => 'Green Bay Packers',
		:HOU => 'Houston Texans',
		:IND => 'Indianapolis Colts',
		:JAX => 'Jacksonville Jaguars',
		:KC => 'Kansas City Chiefs',
		:MIA => 'Miami Dolphins',
		:MIN => 'Minnesota Vikings',
		:NE => 'New England Patriots',
		:NO => 'New Orleans Saints',
		:NYG => 'New York Giants',
		:NYJ => 'New York Jets',
		:OAK => 'Oakland Raiders',
		:PHI => 'Philadelphia Eagles',
		:PIT => 'Pittsburgh Steelers',
		:SD => 'San Diego Chargers',
		:SEA => 'Seattle Seahawks',
		:SF => 'San Francisco 49ers',
		:STL => 'Saint Louis Rams',
		:TB => 'Tampa Bay Buccaneers',
		:TEN => 'Tennessee Titans',
		:WAS => 'Washington Redskins'
  )

  DATA = 
  {'weeks'=>[
		{'num'=> 1, 'matchups'=>[
			{'num'=> 1, 'start_at'=> 10, 'teams'=>[{ 'name'=> TEAMS.ARI, 'homefield'=> false }, { 'name'=> TEAMS.STL, 'homefield'=> true }]},
			{'num'=> 2, 'start_at'=> 10, 'teams'=>[{ 'name'=> TEAMS.NE, 'homefield'=> false }, { 'name'=> TEAMS.SEA, 'homefield'=> true }]}
	  ]}
  ]}
end

# 
# Application
#

#add data to db
for i in 0 ... DATA['weeks'].size
  w = Week.new
  w.attributes = { :num => DATA['weeks'][i]['num'] }

  for j in 0 ... DATA['weeks'][i]['matchups'].size
  	m = Matchup.new :week => w
  	m.attributes = { 
  		:num => DATA['weeks'][i]['matchups'][j]['num'],
  		:start_at => DATA['weeks'][i]['matchups'][j]['start_at'] 
  	}

  	for k in 0 ... DATA['weeks'][i]['matchups'][j]['teams'].size
  		t = Team.new :matchup => m
  		t.attributes = {
				:name => DATA['weeks'][i]['matchups'][j]['teams'][k]['name'],
				:homefield => DATA['weeks'][i]['matchups'][j]['teams'][k]['homefield']
			}
			t.save

		end
		m.save
  end
  w.save
end

get '/weeks' do
	@weeks = Week.all :order => :id.desc
	erb :weeks
end 

#
# Admin
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
		:username => params[:username],
		:password => params[:password]
	}
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
		:username => params[:username],
		:password => params[:password]
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
