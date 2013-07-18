# encoding: UTF-8

# TODO support Activerecord

module Statlysis
  class MultipleDataset
    attr_reader :adapter_type, :regexp
    def initialize adapter_type, regexp
      raise "adapter_type #{adapter_type} should be :mongoid or :active_record" if not [:mongoid, :active_record].include?(adapter_type)
      raise "regexp #{regexp} should be a Regexp!" if not regexp.is_a?(Regexp)

      @adapter_type = adapter_type
      @regexp = regexp
    end
  end
end

require 'statlysis/multiple_dataset/mongoid'
require 'statlysis/multiple_dataset/active_record'
