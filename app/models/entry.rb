require 'date_validator'
require 'time'

class Entry < ActiveRecord::Base
  belongs_to :user

  validates :user_id, presence: true
  validates :date, presence: true, date: true

  def self.entries_by_date_descending(user_id)
    where(user_id: user_id).order('date DESC')
  end

  def self.entry_for_user_and_date(user_id, date)
    entry = where(user_id: user_id, date: date).first

    return entry unless entry.nil?

    if Time.parse(date).strftime("%Y-%m-%d") == Time.now.to_date.strftime("%Y-%m-%d")
      return Entry.create(user_id: user_id, date: date)
    end

    return nil
  end
end
