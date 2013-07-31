# encoding: UTF-8

module Statlysis
  module TimeSeries
    # range支持如下三种时间范围格式
    #   20121201 20121221
    #   Time.zone.parse('20121221')
    #   Time.zone.parse('20121201')..Time.zone.parse('20121221')
    # opts[:unit]支持:hour, :day, :week, :month等时间单位
    # 返回的结果为时间范围内的序列数组
    def self.parse range, opts = {}
      # removed :utc => true, no effect.
      # and so does :offset => nil
      opts = opts.reverse_merge :unit => :day
      unit = opts[:unit]
      zone = opts[:zone] || Statlysis.default_time_zone || Time.zone

      range = Range.new(*range.split.map {|i| Time.zone.parse(i).in_time_zone(zone) }) if range.is_a?(String)

      begin_unit = "beginning_of_#{unit}".to_sym
      array = if range.respond_to?(:to_datetime)
        [range.in_time_zone(zone).send(begin_unit)]
      elsif range.is_a?(Range)
        ary = [range.first.in_time_zone(zone), range.last.in_time_zone(zone)].map(&begin_unit).uniq

        _ary = []
        _ary.push ary[0]
        tmp = ary[0]
        loop do
          tmp += 1.send(unit)
          break if tmp >= ary[-1]
          _ary << tmp
        end
        _ary.push(ary[1]).compact
        _ary.compact.reject {|i| (i < range.first) && (i >= range.last) }
      end

      # array = array.map {|s| s.to_time } if opts[:utc]
      # array = array.map {|i| i + opts[:offset] } if opts[:offset]
      array.map(&:to_datetime)
    end

  end
end
