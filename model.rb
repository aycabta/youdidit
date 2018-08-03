require 'bundler'
require 'dm-core'
require 'dm-migrations'
require 'tempfile'
require 'open-uri'

class User
  include DataMapper::Resource
  property :id, Serial
  property :user_id, Decimal, precision: 20, required: true
  property :email, String, length: 256, required: true
  property :name, String, length: 256, required: true
  property :nickname, String, length: 256, required: true
end

DataMapper.finalize

def database_upgrade!
  User.auto_upgrade!
end
