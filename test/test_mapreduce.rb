# encoding: UTF-8

require 'helper'

require 'mongoid'
Mongoid.load!(File.expand_path("../config/mongoid.yml", __FILE__), :production)

Dir[File.expand_path("../models/*.rb", __FILE__).to_s].each { |f| require f }
Mongoid.default_session.collections.select {|c| c.name !~ /system/ }.each(&:drop)

class TestMapReduce < Test::Unit::TestCase
  include Statlysis

  def setup
    # copied from git://github.com/joe1chen/mongoid-mapreduce.git
    @aapl = Company.create :name => 'Apple', :market => 'Technology', :quote => 401.82, :shares => 972_090_000
    @msft = Company.create :name => 'Microsoft', :market => 'Technology', :quote => 25.06, :shares => 8_380_000_000
    @sbux = Company.create :name => 'Starbucks', :market => 'Food', :quote => 38.60, :shares => 746_010_000
    Employee.create :name => 'Alan', :division => 'Software', :age => 30, :awards => 5, :rooms => [1,2], :active => true, :company => @aapl
    Employee.create :name => 'Bob', :division => 'Software', :age => 30, :awards => 4, :rooms => [3,4,5], :active => true, :company => @aapl
    Employee.create :name => 'Chris', :division => 'Hardware', :age => 30, :awards => 3, :rooms => [1,2,3,4], :active => false, :company => @aapl
  end

  def test_hotest_items_mapreduce
  end


end
