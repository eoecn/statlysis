# encoding: UTF-8

require 'active_record'

module Statlysis
  class ActiveRecordDataset < MultipleDataset
    def set_time_column time_column
      @sources = @sources.map {|s| s.order("#{time_column} ASC") }
      return self
    end

  end

  def ActiveRecord.[] regexp
  end

end
