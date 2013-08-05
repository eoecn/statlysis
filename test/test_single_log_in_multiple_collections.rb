# encoding: UTF-8

require 'helper'

class TestSingleLogInMultipleCollections < Test::Unit::TestCase
  def setup
    @output = Statlysis.daily['multi'].first.output
  end

  def test_timely
    o = @output.map {|i| i[:timely_c] }[0..30]
    r = (o - [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31]).reject(&:zero?).blank?
    assert_equal r, true
  end

  def test_totally
    o = @output.map {|i| i[:totally_c] }[0..30]
    r = (o - [1,3,6,10,15,21,28,36,45,55,66,78,91,105,120,136,153,171,190,210,231,253,276,300,325,351,378,406,435,465,496]).reject(&:zero?).blank?
    assert_equal r, true
  end

end
