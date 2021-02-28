require 'minitest/autorun'
require 'minitest/unit'
require 'sinatra/activerecord'

ActiveRecord::Base.establish_connection("mysql2://#{ENV['TEST_DB_USER']}:#{ENV['TEST_DB_PASS']}@#{ENV['TEST_DB_HOST']}/#{ENV['TEST_DB_DB']}")

if __FILE__ == $PROGRAM_NAME
  Dir.glob('./app/models/*_tests.rb').each do |f|
    require f
  end
end
