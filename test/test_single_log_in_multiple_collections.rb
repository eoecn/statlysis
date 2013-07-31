# encoding: UTF-8

require 'helper'

class TestSingleLogInMultipleCollections < Test::Unit::TestCase
  def setup
    @output = Statlysis.daily['multi'].first.output
  end

  def test_timely
  end

  def test_totally
  end

end
