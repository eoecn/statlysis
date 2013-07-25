# encoding: UTF-8

# TODO support Activerecord

module Statlysis
  class MultipleDataset
    def initialize
      @sources ||= Set.new
      return self
    end

    attr_reader :regexp, :sources
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

    def set_time_column time_column; raise DefaultNotImplementWrongMessage; return self; end # support method chain

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

  end
end

require 'statlysis/multiple_dataset/mongoid'
require 'statlysis/multiple_dataset/active_record'
