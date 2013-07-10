# encoding: UTF-8
# Sequel的操作均需通过Symbol
#
# 删除匹配的统计表
# Statlysis.sequel.tables.select {|i| i.to_s.match(//i) }.each {|i| Statlysis.sequel.drop_table i }

require "active_support/all"
require 'active_support/core_ext/module/attribute_accessors.rb'
require 'active_record'
require 'rails'
%w[yaml sequel only_one_rake mongoid].map(&method(:require))

module Statlysis
  Units = %w[hour day week month year]
  DefaultTableOpts = {:charset => "utf8", :collate => "utf8_general_ci", :engine => "MyISAM"}

  def self.setup_stat_table_and_model cron, tablename = nil
    tablename = cron.stat_table_name if tablename.nil?
    tablename ||= cron.stat_table.first_source_table
    cron.stat_table = Statlysis.sequel[tablename.to_sym]

    str = tablename.to_s.singularize.camelize
    eval("class ::#{str} < Sequel::Model;
      self.set_dataset :#{tablename}
      def self.[] item_id
        JSON.parse(find_or_create(:pattern => item_id).result) rescue []
      end
    end; ")
    cron.stat_model = str.constantize
  end

end

require 'statlysis/common'
require 'statlysis/timeseries'
require 'statlysis/clock'
require 'statlysis/rake'
require 'statlysis/cron'
require 'statlysis/similar'

module Statlysis
  mattr_accessor :sequel, :default_time_columns, :database_opts, :tablename_default_pre
  Units.each {|unit| module_eval "mattr_accessor :#{unit}_crons; self.#{unit}_crons = []" }
  [:realtime, :similar, :hotest].each do |sym|
    sym = "#{sym}_crons".to_sym
    mattr_accessor sym; self.send "#{sym}=", []
  end
  # TODO _crons uniq, no readd
  extend self

  # 会在自动拼接统计数据库表名时去除这些时间字段
  def update_time_columns *columns
    self.default_time_columns ||= [:created_at, :updated_at]
    columns.each {|column| self.default_time_columns.push column }
    self.default_time_columns = self.default_time_columns.uniq
  end

  def set_database sym_or_hash
    self.database_opts = if sym_or_hash.is_a? Symbol
      YAML.load_file(Rails.root.join("config/database.yml"))[sym_or_hash.to_s]
    elsif Hash
      sym_or_hash
    else
      raise "Statlysis#set_database only support symbol or hash params"
    end
    self.sequel = Sequel.connect self.database_opts.except('database')
    self.sequel.execute("CREATE DATABASE IF NOT EXISTS #{self.database_opts['database']} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;")
    self.sequel.use self.database_opts['database']
    # Statlysis.sequel.tables.map {|t| eval "class ::#{t.to_s.camelize} < ActiveRecord::Base; self.establish_connection Statlysis.database_opts; self.table_name = :#{t}; end; #{t.to_s.camelize}" }
  end

  def set_tablename_default_pre str
    self.tablename_default_pre = str.to_s
  end

  def daily source, time_column = :created_at; timely source, :time_unit => :day, :time_column => time_column end
  def hourly source, time_column = :created_at; timely source, :time_unit => :hour, :time_column => time_column end

  def check_set_database; raise "Please setup database first" if sequel.nil?  end

  def timely source, opts
    self.check_set_database
    opts.reverse_merge! :time_column => :created_at, :time_unit => :day
    t = Timely.new source, opts
    module_eval("self.#{opts[:time_unit]}_crons").push t
  end

  # the real requirement is to compute lastest items group by special pattens, like user_id, url prefix, ...
  def lastest_visits source, opts
    self.check_set_database
    opts.reverse_merge! :time_column => :created_at
    self.realtime_crons.push LastestVisits.new(source, opts)
  end

  # TODO 为什么一层proc的话会直接执行的
  def hotest_items key, id_to_score_and_time_hash = {}
    _p = proc { if block_given?
      (proc do
        id_to_score_and_time_hash = Hash.new
        yield id_to_score_and_time_hash
        id_to_score_and_time_hash
      end)
    else
      (proc { id_to_score_and_time_hash })
    end}

    self.hotest_crons.push HotestItems.new(key, _p)
  end

  # TODO support mongoid
  def similar_items model_name, id_to_text_hash = {}
    _p = if block_given?
      (proc do
        id_to_text_hash = Hash.new {|hash, key| hash[key] = "" }
        yield id_to_text_hash
        id_to_text_hash
      end)
    else
      (proc { id_to_text_hash })
    end

    self.similar_crons.push Similar.new(model_name, _p)
  end

end


module Statlysis
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path('../statlysis/rake.rb', __FILE__)
    end
  end if defined? Rails
end
