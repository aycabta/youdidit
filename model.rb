require 'bundler'
require 'dm-core'
require 'dm-migrations'
require 'tempfile'
require 'open-uri'
require 'date'
require_relative 'date_range'

class User
  include DataMapper::Resource
  property :id, Serial
  property :user_id, Integer, precision: 20, required: true
  property :email, String, length: 256, required: true
  property :name, String, length: 256, required: true
  property :nickname, String, length: 256, required: true
  has n, :menus

  def daily_menus
    @daily ||= Menu.all(
      user: self,
      span_type: Menu::Span::Daily
    )
  end

  def weekly_menus
    @weekly ||= Menu.all(
      user: self,
      span_type: Menu::Span::Weekly
    )
  end

  def monthly_menus
    @monthly ||= Menu.all(
      user: self,
      span_type: Menu::Span::Monthly
    )
  end

  def abyss
    @abyss ||= menus.size
  end

  def darkness_depth(d)
    c = menus.map { |m|
      r = m.result_by_span(d)
      if r
        case r.state
        when Result::State::Completed
          2
        when Result::State::Did
          1
        when Result::State::Nothing
          0
        end
      else
        0
      end
    }.sum
    abyss.zero? ? 0 : c / abyss.to_f
  end

  def each_week_of_darkness(date)
    start_date = date.prev_year + 1
    start_date -= (start_date.cwday - 1)
    days = (date - start_date).to_i
    weeks = (days / 7) + (days % 7 == 0 ? 0 : 1)
    weeks.times do |index|
      yield start_date + (7 * index), index
    end
  end
end

class Menu
  include DataMapper::Resource
  include DateRange
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

  def result_by_span(date)
    case span_type
    when Span::Daily
      Result.first(menu: self, worked_at: date)
    when Span::Weekly
      Result.first(menu: self, worked_at: week_range(date))
    when Span::Monthly
      Result.first(menu: self, worked_at: month_range(date))
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
