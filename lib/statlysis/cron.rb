# encoding: UTF-8

module Statlysis
  class Cron
    attr_reader :multiple_dataset, :time_column, :time_unit
    include Common

    def initialize source, opts = {}
      # setup data type related
      @is_activerecord = Utils.is_activerecord?(source)
      @is_mongoid      = Utils.is_mongoid?(source)

      @time_column      = opts[:time_column]
      @time_unit        = opts[:time_unit]

      # insert source as a dataset
      @multiple_dataset = ActiveRecordDataset.new.add_source(source.order("#{cron.time_column} ASC")) if @is_activerecord
      @multiple_dataset = MongoidDataset.new.add_source(source.asc(cron.time_column)) if @is_mongoid

      @stat_table_name = opts[:stat_table_name] if opts[:stat_table_name]

      cron
    end
    def output; raise DefaultNotImplementWrongMessage end
    def reoutput; @output = nil; output end
    def setup_stat_table; raise DefaultNotImplementWrongMessage end
    def run; raise  DefaultNotImplementWrongMessage end

    def _source
      cron.multiple_dataset.sources.first
    end
    def source_where_array
      # TODO follow index seq
      a = _source.where("").where_values.map do |equality|
        # use full keyvalue index name
        equality.is_a?(String) ? equality.to_sym : "#{equality.operand1.name}#{equality.operand2}"
      end if @is_activerecord
      a = _source.all.selector.reject {|k, v| k == 't' } if @is_mongoid
      a.map {|s1| s1.to_s.split(//).select {|s2| s2.match(/[a-z0-9]/i) }.join }.sort.map(&:to_sym)
    end

    # automode
    # or
    # specify TIME_RANGE and TIME_UNIT in shell to run
    def time_range
      return TimeSeries.parse(ENV['TIME_RANGE'], :unit => (ENV['TIME_UNIT'] || 'day')) if ENV['TIME_RANGE']
      # 选择开始时间。取出统计表的最后时间，和数据表的最先时间对比，哪个最后就选择
      begin_day = DateTime.now.beginning_of_day
      st_timebegin = (a = cron.stat_table.order(:t).where("t >= ?", begin_day.yesterday).first) ? a[:t] : nil
      cron.stat_table.where("t >= ?", begin_day.tomorrow).delete # 明天的数据没出来肯定统计不了
      timebegin = (a = _source.first) ? a.send(cron.time_column) : (DateTime.now - 1.second)
      timebegin = Time.at(timebegin) if is_time_column_integer?
      timebegin = (st_timebegin > timebegin) ? st_timebegin : timebegin if st_timebegin

      timeend = DateTime.now
      logger.info "#{multiple_dataset.name}'s range #{timebegin..timeend}"
      # 把统计表的最后时间点也包含进去重新计算下
      TimeSeries.parse(timebegin..timeend, :unit => cron.time_unit)
    end

    protected

    # 兼容采用整数类型作时间字段
    def is_time_column_integer?
      if @is_activerecord
        _source.columns_hash[cron.time_column.to_s].type == :integer
      else
        false
      end
    end

  end

end


require 'statlysis/cron/count'
require 'statlysis/cron/top'
