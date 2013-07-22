# encoding: UTF-8

require 'active_record'

module Statlysis
  class ActiveRecordDataset < MultipleDataset
  end

  def ActiveRecord.[] regexp
  end

end
