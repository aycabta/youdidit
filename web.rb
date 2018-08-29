require 'bundler'
require 'sinatra'
require 'slim'
require 'omniauth'
require 'omniauth-github'
require 'uri'
require_relative 'model'
require_relative 'date_range'

configure :production do
  DataMapper.setup(:default, ENV['DATABASE_URL'])
  database_upgrade!
end

configure :test, :development do
  DataMapper.setup(:default, 'yaml:///tmp/youdidit')
  database_upgrade!
end

helpers DateRange

helpers do
  def generate_date_url(date)
    %Q(/#{@specified_user ? @specified_user.nickname : 'date'}/#{date})
  end
end

def redirect_to_index(date = nil)
  if date
    redirect "/date/#{date}", 302
  else
    redirect '/', 302
  end
end

get ['/', '/date/:date'] do
  if session[:logged_in]
    @me = User.first(user_id: session[:user_id])
    @user = @me
    if params[:date]
      @date = Date.parse(params[:date])
    else
      @date = Date.today
    end
  end
  slim :index
end

get '/new_menu' do
  @title = 'new menu'
  slim :new_menu
end

post '/add_menu' do
  me = User.first(user_id: session[:user_id])
  menu = Menu.create(
    name: params[:name],
    span_type: params[:span_type],
    user: me,
    created_at: DateTime.now
  )
  redirect '/', 302
end

get '/edit_menu/:id' do
  @menu = Menu.first(id: params[:id])
  slim :edit_menu
end

post '/update_menu/:id' do
  menu = Menu.first(id: params[:id])
  menu.update(
    name: params[:name],
    span_type: params[:span_type]
  )
  redirect '/', 302
end

post '/del_menu/:id' do
  menu = Menu.first(id: params[:id])
  menu.destroy
  redirect '/', 302
end

post '/add_result' do
  menu = Menu.first(id: params[:menu_id])
  worked_at = Date.parse(params[:worked_at])
  result = Result.create(
    menu: menu,
    state: params[:state],
    worked_at: worked_at
  )
  redirect_to_index(worked_at)
end

post '/del_result' do
  result = Result.first(id: params[:result_id])
  result.destroy
  date = Date.parse(params[:date])
  redirect_to_index(date)
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

get ['/:username', '/:username/:date'] do
  @me = User.first(user_id: session[:user_id]) if session[:logged_in]
  @user = User.first(nickname: params[:username])
  if params[:date]
    @date = Date.parse(params[:date])
  else
    @date = Date.today
  end
  slim :index
end

configure do
  set :root, File.dirname(__FILE__)
  set :static, true
  set :public_folder, "#{File.dirname(__FILE__)}/public"
  enable :run
  enable :sessions
  set :session_secret, ENV["SESSION_SECRET"]
  use Rack::Session::Cookie,
    key: 'rack.session',
    path: '/',
    expire_after: 60 * 60 * 24 * 90,
    secret: ENV['SESSION_SECRET']
  use OmniAuth::Builder do
    provider :github, ENV['CLIENT_ID'], ENV['CLIENT_SECRET']
  end
end
