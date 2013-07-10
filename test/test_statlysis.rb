# encoding: UTF-8

require 'helper'

def Rails.root; Pathname.new(ENV['RAILS_ROOT'] || "#{Dir.pwd}/../..") end
raise "Please setup RAILS_ROOT shell env first!" if not File.exists?(Rails.root.join("config/database.yml"))

class TestStatlysis < Test::Unit::TestCase
  include Statlysis

  def setup
    super
    @dt = DateTime.parse "20121221 +0800"
    @dt1 = DateTime.parse "20111221 +0800"
    @dt2 = DateTime.parse "20121221 +0800"
    Statlysis.set_database :statlysis
    @old_datetime = DateTime.parse("20130105")
  end

  def test_parse_datetime
    assert_equal [@dt], TimeSeries.parse(@dt), "抽取单个时间没通过"
  end

  def test_parse_special_datetime
    assert_equal 1, TimeSeries.parse(DateTime.parse('2012122110')).length, "抽取单个时间没通过"
  end

  def test_parse_range_in_hour
    # (@dt2 - @dt1).to_i  == 366
    assert_equal 24, TimeSeries.parse(@dt1..(@dt1+1.day-1.second), :unit => :hour).length, "抽取小时的时间范围没通过"
  end

  def test_parse_range_in_day
    # (@dt2 - @dt1).to_i  == 366
    assert_equal 366, TimeSeries.parse(@dt1..(@dt2-1.second)).length, "抽取天的时间范围没通过"
  end

  def test_parse_range_in_week
    # (@dt2 - @dt1).to_i / 7.0 == 52.285714285714285
    assert_equal 53, TimeSeries.parse(@dt1..(@dt2-1.second), :unit => :week).length, "抽取周的时间范围没通过"
  end

  def test_parse_range_in_201212_week
    w1 = DateTime.parse "20121201 +0800"
    w2 = DateTime.parse "20121231 +0800"
    assert_equal 6, TimeSeries.parse(w1..w2, :unit => :week).length, "2012十二月应该有六周"
  end

  def test_setup_count_stat_table
    eval("class CodeGist < ActiveRecord::Base; end")
    t = Statlysis::Timely.new CodeGist.where(:user_id => 470700), :time_column => :created_at, :time_unit => :day
    t.setup_stat_table
    is_created = Statlysis.sequel.table_exists?(t.stat_table_name)
    Statlysis.sequel.drop_table t.stat_table_name

    assert(is_created, "统计表#{t.stat_table_name}没有成功创建")
  end

  def test_setup_lastest_visits_stat_table
    tn = 'st_blog_lastest_visits_tests'
    lv = Statlysis::LastestVisits.new "FakeLogCollection", :stat_table_name => tn, :test => true, :default_time => @old_datetime
    lv.pattern_table_and_model tn
    is_sequel_model = lv.stat_model.respond_to?(:count)
    Statlysis.sequel.drop_table tn

    assert(is_sequel_model, "统计表#{lv.stat_table_name}没有成功创建")
  end

  def test_clock_set_time
    clock = Statlysis::Clock.new "mvj3", Time.now
    clock.update @old_datetime
    update_old_time = (@old_datetime != clock.current)
    assert(update_old_time, "Can't update old time")
  end

end
