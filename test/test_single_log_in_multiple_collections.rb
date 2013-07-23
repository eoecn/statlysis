# encoding: UTF-8

require 'helper'

class TestSingleLogInMultipleCollections < Test::Unit::TestCase
  def setup
    Statlysis.setup do
      # daily Mongoid[/log_2013[0-9]{2}$/], :t
    end
  end

  def test_m
  end
end
