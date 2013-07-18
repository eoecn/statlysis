# encoding: UTF-8

# TODO support Activerecord

module Statlysis
  class MultipleDataset
    attr_reader :regexp
    def set_regexp regexp
      raise "regexp #{regexp} should be a Regexp!" if not regexp.is_a?(Regexp)
      @regexp = regexp
      return self
    end
  end
end

require 'statlysis/multiple_dataset/mongoid'
require 'statlysis/multiple_dataset/active_record'
