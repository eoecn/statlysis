# encoding: UTF-8

# TODO support Activerecord

module Statlysis
  class MultipleDataset
    attr_reader :regexp, :sources, :name
    def set_regexp regexp
      if regexp.is_a?(Regexp)
      elsif regexp.is_a?(String)
        regexp = Regexp.new(string)
      else
        raise "regexp #{regexp} should be a Regexp!" 
      end
      @regexp = regexp

      return self
    end

    def add_source s
      @sources ||= Set.new
      @sources.add s

      @name = s.send(Utils.name(s))
      return self
    end

  end
end

require 'statlysis/multiple_dataset/mongoid'
require 'statlysis/multiple_dataset/active_record'
