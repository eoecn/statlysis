# encoding: UTF-8

module Statlysis
  module Common
    extend ActiveSupport::Concern

    self.included do
      attr_accessor :stat_table_name, :stat_model, :stat_table
    end

    def cron; self end
    delegate :logger, :to => Statlysis

  end
end
