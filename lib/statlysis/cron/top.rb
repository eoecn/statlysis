# encoding: UTF-8
# TODO support ActiveRecord

module Statlysis
  class Top < Cron
    attr_accessor :result_limit, :logs
    attr_accessor :stat_model
    attr_accessor :pattern_proc, :user_id_proc, :user_info_proc

    def initialize source, opts = {}
      cron.result_limit = opts[:result_limit] || 100
      if not opts[:test]
        [:pattern_proc, :user_id_proc, :user_info_proc].each do |o|
          raise "Please assign :#{o} params!" if opts[o].nil? && !cron.send(o)
          cron.send "#{o}=", opts[o]
        end
        default_assign_attr :stat_table_name, opts
      end
      super
      cron
    end

    def run
      cron.write
    end

    def write; raise DefaultNotImplementWrongMessage end

    def default_assign_attr key_symbol, opts
      if opts[key_symbol]
        cron.send("#{key_symbol}=", opts[key_symbol])
      else
        raise "Please assign opts[:#{key_symbol}]"
      end
    end
  end

  class SingleKv < Top
    attr_accessor :time_ago, :stat_column_name

    def initialize source, opts = {}
      [:time_ago, :stat_column_name].each {|key_symbol| default_assign_attr key_symbol, opts }
      raise "#{cron.class} only is kv store" if cron.stat_table_name # TODO
      super
      cron
    end

  end

end


require 'statlysis/cron/top/lastest_visits.rb'
require 'statlysis/cron/top/hotest_items.rb'
