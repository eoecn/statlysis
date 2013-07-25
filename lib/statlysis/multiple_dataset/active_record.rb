# encoding: UTF-8

require 'active_record'

module Statlysis
  class ActiveRecordDataset < MultipleDataset
    def set_regexp regexp
      super

      # TODO support multiple

      _resort_source_order

      return self
    end

    def resort_source_order; @sources = @sources.map {|s| s.order("#{cron.time_column} ASC") } end

  end

  def ActiveRecord.[] regexp
  end

end
