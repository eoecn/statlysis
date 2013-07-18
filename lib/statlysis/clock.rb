# encoding: UTF-8

module Statlysis
  class Clock
    attr_accessor :clock
    include Common

    def initialize feature, default_time
      raise "Please assign default_time params" if not default_time
      cron.stat_table_name = [Statlysis.tablename_default_pre, 'clocks'].compact.join("_")
      unless Statlysis.sequel.table_exists?(cron.stat_table_name)
        Statlysis.sequel.create_table cron.stat_table_name, DefaultTableOpts.merge(:engine => "InnoDB") do
          primary_key :id
          String      :feature
          DateTime    :t
          index       :feature, :unique => true
        end
      end
      Statlysis.setup_stat_table_and_model cron
      cron.clock = cron.stat_model.find_or_create(:feature => feature)
      cron.clock.update :t => default_time if cron.current.nil?
      cron
    end

    def update time
      time = DateTime.now if time == DateTime1970
      return false if time && (time < cron.current)
      cron.clock.update :t => time
    end

    def current; cron.clock.t end
  end

end
