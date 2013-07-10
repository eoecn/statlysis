# encoding: UTF-8

module Statlysis
  class Count < Cron
    def initialize source, opts = {}
      super
      Statlysis.check_set_database
      cron.setup_stat_table
      Statlysis.setup_stat_table_and_model cron
      cron
    end

    # 设置数据源，并保存结果入数据库
    def run
      cron.source          = cron.source.order("#{cron.time_column} ASC") if is_mysql?
      cron.source          = cron.source.asc(cron.time_column) if is_mongodb?

      (puts("#{cron.source_name} have no result!"); return false) if cron.output.blank?
      # delete first in range
      @output = cron.output
      unless @output.any?
        puts "没有数据"; return
      end
      @num_i = 0; @num_add = 999
      Statlysis.sequel.transaction do
        cron.stat_table.where("t >= ? AND t <= ?", cron.output[0][:t], cron.output[-1][:t]).delete
        while !(_a = @output[@num_i..(@num_i+@num_add)]).blank? do
          # batch insert all
          cron.stat_table.insert_multiple _a
          @num_i += (@num_add + 1)
        end
      end
    end


    def reoutput; @output = nil; output end
    protected
    def unit_range_query time, time_begin = nil
      # time begin and end
      tb = time # TODO 差八个小时 [.in_time_zone, .localtime, .utc] 对于Rails，计算结果还是一样的。
      te = (time+1.send(cron.time_unit)-1.second)
      tb, te = tb.to_i, te.to_i if is_time_column_integer?
      tb = time_begin || tb
      return ["#{cron.time_column} >= ? AND #{cron.time_column} < ?", tb, te] if is_mysql?
      return {cron.time_column => {"$gte" => tb.utc, "$lt" => te.utc}} if is_mongodb? # .utc  [fix undefined method `__bson_dump__' for Sun, 16 Dec 2012 16:00:00 +0000:DateTime]
    end

  end

  class Timely < Count
    def setup_stat_table
      # TODO migration proc, merge into setup_stat_table_and_model
      cron.stat_table_name = [cron.class.name.split("::")[-1], cron.source_name, cron.source_where_array.join, cron.time_unit[0]].map {|s| s.to_s.gsub('_','') }.reject {|s| s.blank? }.join('_').downcase
      raise "mysql only support table_name in 64 characters, the size of '#{cron.stat_table_name}' is #{cron.stat_table_name.to_s.size}. please set cron.stat_table_name when you create a Cron instance" if cron.stat_table_name.to_s.size > 64
      unless Statlysis.sequel.table_exists?(cron.stat_table_name)
        Statlysis.sequel.transaction do
          Statlysis.sequel.create_table cron.stat_table_name, DefaultTableOpts do
            DateTime :t # alias for :time
          end

          # TODO Add cron.source_where_array before count_columns
          count_columns = [:timely_c, :totally_c] # alias for :count
          count_columns.each {|w| Statlysis.sequel.add_column cron.stat_table_name, w, Integer }
          index_column_names = [:t] + count_columns
          index_column_names_name = index_column_names.join("_")
          index_column_names_name = index_column_names_name[-63..-1] if index_column_names_name.size > 64

          Statlysis.sequel.add_index cron.stat_table_name, index_column_names, :name => index_column_names_name
        end
      end
    end

    def output
      @output ||= (cron.time_range.map do |time|
        timely_c  = cron.source.where(unit_range_query(time)).count
        _t = DateTime.parse("19700101")
        _t = is_time_column_integer? ? _t.to_i : _t
        totally_c = cron.source.where(unit_range_query(time, _t)).count

        puts "#{time.in_time_zone} #{cron.source_name} timely_c:#{timely_c} totally_c:#{totally_c}"
        if timely_c.zero? && totally_c.zero?
          nil
        else
          {:t => time, :timely_c => timely_c, :totally_c => totally_c}
        end
      end.compact)
    end
  end

  class Dimensions < Count
  end

end
