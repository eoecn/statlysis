# encoding: UTF-8

require 'active_record'

module Statlysis
  class ActiveRecordDataset < MultipleDataset
    def set_regexp regexp
      super

      # TODO test it
      activerecord_models = _select_orm(ActiveRecord::Store)
      activerecord_models.select do |_model|
        @sources.add _model if _model.table_name.to_s.match(@regexp)
      end

      _resort_source_order

      return self
    end

    def resort_source_order; @sources = @sources.map {|s| s.order("#{cron.time_column} ASC") } end

  end

  def ActiveRecord.[] regexp
  end

end
