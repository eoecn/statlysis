# encoding: UTF-8

module Statlysis
  module Utils
    class << self
      def is_activerecord?(data); data.is_a?(ActiveRecordDataset) || !!((data.try(:included_modules) || []).index(ActiveRecord::Store)) end
      def is_mongoid?(data); data.is_a?(MongoidDataset) || !!((data.try(:included_modules) || []).index(Mongoid::Document)) end
      def name(data)
        return :collection_name if Utils.is_mongoid?(data)
        return :table_name      if Utils.is_activerecord?(data)
      end
    end
  end
end
