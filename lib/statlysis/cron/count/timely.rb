# encoding: UTF-8

module Statlysis
  class Timely < Count
    def setup_stat_model
      cron.stat_table_name = [cron.class.name.split("::")[-1], cron.multiple_dataset.name, cron.source_where_array.join, cron.time_unit[0]].map {|s| s.to_s.gsub('_','') }.reject {|s| s.blank? }.join('_').downcase
      raise "mysql only support table_name in 64 characters, the size of '#{cron.stat_table_name}' is #{cron.stat_table_name.to_s.size}. please set cron.stat_table_name when you create a Cron instance" if cron.stat_table_name.to_s.size > 64

      if not Statlysis.sequel.table_exists?(cron.stat_table_name)
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

          # Fix there should be uniq index name between tables
          # `SQLite3::SQLException: index t_timely_c_totally_c already exists (Sequel::DatabaseError)`
          if not Statlysis.config.is_skip_database_index
            Statlysis.sequel.add_index cron.stat_table_name, index_column_names, :name => index_column_names_name
          end
        end
      end

      n = cron.stat_table_name.to_s.singularize.camelize
      cron.stat_model = class_eval <<-MODEL, __FILE__, __LINE__+1
        class ::#{n} < Sequel::Model;
          self.set_dataset :#{cron.stat_table_name}
        end
        #{n}
      MODEL
    end

    def output
      @output ||= (cron.time_range.map do |time|
        timely_c = 0
        totally_c = 0
        # support multiple data sources
        _first_source = nil
        cron.multiple_dataset.sources.each do |s|
          timely_c  += s.where(unit_range_query(time)).count
          _t = DateTime1970
          _t = is_time_column_integer? ? _t.to_i : _t
          totally_c += s.where(unit_range_query(time, _t)).count
          _first_source ||= s.where(unit_range_query(time))
        end
        logger.info "#{time.in_time_zone(cron.time_zone)} multiple_dataset:#{cron.multiple_dataset.name} _first_source:#{_first_source.inspect} timely_c:#{timely_c} totally_c:#{totally_c}" if ENV['DEBUG']

        if timely_c.zero? && totally_c.zero?
          nil
        else
          {:t => time, :timely_c => timely_c, :totally_c => totally_c}
        end
      end.compact)
    end
  end

end
