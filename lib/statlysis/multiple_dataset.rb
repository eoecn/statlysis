# encoding: UTF-8

module Statlysis
  class MultipleDataset
    def initialize cron = nil
      @cron = cron
      @sources ||= Set.new
      return self
    end

    attr_reader :cron, :regexp, :sources
    def set_regexp regexp
      case regexp
      when Regexp
      when String
        regexp = Regexp.new(string)
      else
        raise "regexp #{regexp} should be a Regexp!" 
      end
      @regexp = regexp

      return self
    end

    def add_source s
      @sources.add s

      return self
    end

    def name
      if @sources.size.zero?
        Statlysis.logger.warn "Add source to #{self} first!"
        return nil
      elsif @sources.size == 1
        @sources.first.send(Utils.name(@sources.first))
      else
        # /multiple_log_2013[0-9]{4}/ => 'multiple_log'
        regexp.inspect[1..-2].gsub(/\-|\[|\]|\{|\}|[0-9]/, '').sub(/\_+$/, '')
      end
    end
    # Access dataset name, compact with many ORM
    alias collection_name name # mongoid
    alias table_name name # activerecord


    def first_time
      _resort_source_order.map(&:first).compact.map {|i| i.send(cron.time_column) }.compact.min || DateTime1970
    end
    def _resort_source_order; resort_source_order if cron; end # lazy load if cron is unassigned
    def resort_source_order; raise DefaultNotImplementWrongMessage; end

  end
end

require 'statlysis/multiple_dataset/mongoid'
require 'statlysis/multiple_dataset/active_record'
