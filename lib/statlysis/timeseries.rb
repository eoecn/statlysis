# encoding: UTF-8

module Statlysis
  module TimeSeries
    # range支持如下三种时间范围格式
    #   20121201 20121221
    #   DateTime.parse('20121221')
    #   DateTime.parse('20121201')..DateTime.parse('20121221')
    # opts[:unit]支持:hour, :day, :week, :month等时间单位
    # 返回的结果为时间范围内的序列数组
    def self.parse range, opts = {}
      opts = opts.reverse_merge :unit => :day, :utc => true, :offset => nil
      unit = opts[:unit]

      range = Range.new(*range.split.map {|i| DateTime.parse(i).to_time_in_current_zone }) if range.is_a?(String)

      begin_unit = "beginning_of_#{unit}".to_sym
      array = if range.respond_to?(:to_datetime)
        [range.in_time_zone.send(begin_unit)]
      elsif range.is_a?(Range)
        ary = [range.first.in_time_zone, range.last.in_time_zone].map(&begin_unit).uniq

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

      array = array.map {|s| s.to_time } if opts[:utc]
      array = array.map {|i| i + opts[:offset] } if opts[:offset]
      array.map(&:to_datetime)
    end

  end
end
