# encoding: UTF-8

require 'helper'
require 'mongoid_helper'

# setup a single log that combined by multiple collections
(2..12).each do |num|
  collection_class_name = "Log2013#{num.to_s.rjust(2, '0')}"

  # define model dynamically
  Object.const_set(
    collection_class_name,
    (Class.new do
      include Mongoid::Document
      default_collection_name = collection_class_name.sub("Log", "log_")

      field :t, :type => DateTime
      field :url, :type => String
    end)
  )
  
  collection_class = collection_class_name.constantize
  # TODO day to count data mock
end

class TestSingleLogInMultipleCollections < Test::Unit::TestCase
  def setup
    Statlysis.setup do
      daily Mongoid[/log_2013[0-9]{2}$/].where(:ui => {"$ne" => 0}), :t
    end
  end

  def test_m
  end
end
