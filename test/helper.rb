require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'statlysis'

def Rails.root; Pathname.new(ENV['RAILS_ROOT'] || "#{Dir.pwd}/../..") end
raise "Please setup RAILS_ROOT shell env first!" if not File.exists?(Rails.root.join("config/database.yml"))

Statlysis.set_database :statlysis

class Test::Unit::TestCase
end
