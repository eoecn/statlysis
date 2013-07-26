# encoding: UTF-8

module Statlysis
  TimeUnits = %w[hour day week month year]
  DateTime1970 = DateTime.parse("19700101").in_time_zone

  DefaultTableOpts = {:charset => "utf8", :collate => "utf8_general_ci", :engine => "MyISAM"}

  DefaultNotImplementWrongMessage = "Not implement yet, please config it by subclass".freeze
end
