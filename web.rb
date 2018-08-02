require 'bundler'
require 'sinatra'
require 'slim'
require 'omniauth'
require 'omniauth-github'
require 'uri'

configure :production do
  DataMapper.setup(:default, ENV['DATABASE_URL'])
  database_upgrade!
end

configure :test, :development do
  DataMapper.setup(:default, 'yaml:///tmp/wisha')
  database_upgrade!
end
