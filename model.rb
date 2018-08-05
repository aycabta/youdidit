require 'bundler'
require 'dm-core'
require 'dm-migrations'
require 'tempfile'
require 'open-uri'
require 'date'

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
  property :span_type, Integer, required: true
  property :created_at, DateTime, required: true
  belongs_to :user, required: true
  has n, :results

  def result_by_date(date)
    if @result_by_date
      @result_by_date
    else
      @result_by_date = Result.first(menu: self, worked_at: date)
    end
  end
end

class Result
  include DataMapper::Resource
  module State
    Nothing = 0
    Did = 1
    Completed = 2
    def self.list
      [Nothing, Did, Completed]
    end
    Name = {
      Nothing => 'Nothing',
      Did => 'Did',
      Completed => 'Completed'
    }
  end
  property :id, Serial
  property :state, Integer, required: true
  property :worked_at, Date, required: true
  belongs_to :menu, required: true

  def state_name
    State::Name[state]
  end
end

DataMapper.finalize

def database_upgrade!
  User.auto_upgrade!
  Menu.auto_upgrade!
  Result.auto_upgrade!
end
