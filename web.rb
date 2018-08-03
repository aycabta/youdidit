require 'bundler'
require 'sinatra'
require 'slim'
require 'omniauth'
require 'omniauth-github'
require 'uri'
require './model'

configure :production do
  DataMapper.setup(:default, ENV['DATABASE_URL'])
  database_upgrade!
end

configure :test, :development do
  DataMapper.setup(:default, 'yaml:///tmp/youdidit')
  database_upgrade!
end

get '/' do
  if session[:logged_in]
    @me = User.first(:user_id => session[:user_id])
  end
  slim :index
end

get '/auth/:provider/callback' do
  auth = request.env['omniauth.auth']
  user = User.first(user_id: auth['uid'].to_i)
  if user
    user.update(
      email: auth['info']['email'],
      name: auth['info']['name'],
      nickname: auth['info']['nickname']
    )
  else
    user = User.create(
      user_id: auth['uid'].to_i,
      email: auth['info']['email'],
      name: auth['info']['name'],
      nickname: auth['info']['nickname']
    )
  end
  session[:user_id] = user.user_id
  session[:logged_in] = true
  redirect '/', 302
end

post '/logout' do
  session.clear
  redirect '/', 302
end

configure do
  set :root, File.dirname(__FILE__)
  set :static, true
  set :public_folder, "#{File.dirname(__FILE__)}/public"
  enable :run
  enable :sessions
  set :session_secret, ENV["SESSION_SECRET"]
  use Rack::Session::Cookie,
    :key => 'rack.session',
    :path => '/',
    :expire_after => 60 * 60 * 24 * 90,
    :secret => ENV['SESSION_SECRET']
  use OmniAuth::Builder do
    provider :github, ENV['CLIENT_ID'], ENV['CLIENT_SECRET']
  end
end