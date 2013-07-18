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

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.dirname(__FILE__)

require 'mongoid'
Mongoid.load!(File.expand_path("../config/mongoid.yml", __FILE__), :production)
require 'statlysis'

def Rails.root; Pathname.new(File.expand_path('../.', __FILE__)) end
require 'sqlite3'

Statlysis.set_database :statlysis
ActiveRecord::Base.establish_connection(Statlysis.config.database_opts.merge("adapter" => "sqlite3"))
Dir[File.expand_path("../migrate/*.rb", __FILE__).to_s].each { |f| require f }


Dir[File.expand_path("../models/*.rb", __FILE__).to_s].each { |f| require f }
Mongoid.default_session.collections.select {|c| c.name !~ /system/ }.each(&:drop) # delete lastest data
