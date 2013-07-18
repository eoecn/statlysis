# encoding: UTF-8

require 'mongoid'
Mongoid.load!(File.expand_path("../config/mongoid.yml", __FILE__), :production)

Dir[File.expand_path("../models/*.rb", __FILE__).to_s].each { |f| require f }
Mongoid.default_session.collections.select {|c| c.name !~ /system/ }.each(&:drop)
