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
  has n, :menus
end

class Menu
  include DataMapper::Resource
  module Span
    Daily = 0
    Weekly = 1
    Monthly = 2
    def self.list
      [Daily, Weekly, Monthly]
    end
    Name = {
      Daily => 'Daily',
      Weekly => 'Weekly',
      Monthly => 'Monthly'
    }
  end
  property :id, Serial
  property :name, String, length: 256, required: true
  property :span_type, Decimal, required: true
  property :created_at, DateTime, required: true
  belongs_to :user, required: true
end

DataMapper.finalize

def database_upgrade!
  User.auto_upgrade!
  Menu.auto_upgrade!
end
