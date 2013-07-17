# encoding: UTF-8

module Statlysis
  module Common
    extend ActiveSupport::Concern

    self.included do
      attr_accessor :stat_table_name, :stat_model, :stat_table
    end

    def pattern_table_and_model tn
      # ensure statlysis table
      tn = tn.pluralize
      unless Statlysis.sequel.table_exists?(tn)
        Statlysis.sequel.create_table tn, DefaultTableOpts.merge(:engine => "InnoDB") do
          primary_key :id
          String :pattern
          index  :pattern
        end
        Statlysis.sequel.add_column tn, :result, String, :text => true
      end

      # generate a statlysis model
      cron.stat_model = Statlysis.setup_stat_table_and_model cron, tn
    end

    def cron; self end
    delegate :logger, :to => $stdout

  end
end
