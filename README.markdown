statlysis
===============================================
statistical analysis in ruby dsl

Usage
-----------------------------------------------
```ruby
Statlysis.setup do
  set_database :statlysis
  update_time_columns :t
  set_tablename_default_pre :st

  # 初始化键值model
  Statlysis::Top.new('', :test => true).pattern_table_and_model 'st_single_kvs'
  Statlysis::Top.new('', :test => true).pattern_table_and_model 'st_single_kv_histories'

  # 日常count
  EoeLog.class # preload EoeLogTest
  @log_model = IS_DEVELOP ? EoeLogTest : EoeLog
  hourly @log_model, :t
  daily  @log_model, :t
  daily  @log_model.where(:ui => 0), :t
  daily  @log_model.where(:ui => {"$ne" => 0}), :t

  # 统计各个模块
  daily  @log_model.where(:do => {"$in" => [DOMAINS_HASH[:blog], DOMAINS_HASH[:my]]}), :t
  [:www, :code, :skill, :book, :edu, :news, :wiki, :salon, :android].each do |site|
    daily  @log_model.where(:do => DOMAINS_HASH[site]), :t
  end
end
```

TODO
-----------------------------------------------
1. Admin interface
2. statistical query api in Ruby and HTTP
3. Interacting with Javascript charting library, e.g. Highcharts, D3.
4. Add namespace to DSL, like rake
5. More tests
6. support collections which splited by date


Copyright
-----------------------------------------------
MIT. David Chen at eoe.cn.
