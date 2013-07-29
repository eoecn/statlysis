Statlysis
===============================================
Statistical & Analysis in Ruby DSL

Usage
-----------------------------------------------
### setup

```ruby
Statlysis.setup do
  set_database :statlysis

  # 日常count
  hourly EoeLog, :t
  daily  EoeLog, :t
  daily  EoeLog.where(:ui => 0), :t
  daily  EoeLog.where(:ui => {"$ne" => 0}), :t
  daily  Mongoid[/eoe_logs_[0-9]+$/].where(:ui => {"$ne" => 0}), :t

  # 统计各个模块
  daily  EoeLog.where(:do => {"$in" => [DOMAINS_HASH[:blog], DOMAINS_HASH[:my]]}), :t
  [:www, :code, :skill, :book, :edu, :news, :wiki, :salon, :android].each do |site|
    daily  EoeLog.where(:do => DOMAINS_HASH[site]), :t
  end
end
```

### access

```ruby
Statlysis.daily # => daily configurations
Statlysis.daily.run # => run daily
Statlysis.daily[/name_regexp/] # => return matched daily configurations
```

Features
-----------------------------------------------
* Support time column that stored as integer.

TODO
-----------------------------------------------
1. Admin interface
2. statistical query api in Ruby and HTTP
3. Interacting with Javascript charting library, e.g. Highcharts, D3.
5. More tests
6. support collections which splited by date


Statistical Process
-----------------------------------------------
1. Delete invalid statistical data, e.g. data in tomorrow
2. Count data within the specified time by the dimensions
3. Delete overlapping data, and insert new data


FAQ
-----------------------------------------------
Q: Why use Sequel instead of ActiveRecord?

A: When initialize an ORM object, ActiveRecord is 3 times slower than Sequel, and we just need the basic operations, including read, write, enumerate, etc. See more details in [Quick dive into Ruby ORM object initialization](http://merbist.com/2012/02/23/quick-dive-into-ruby-orm-object-initialization/) .


Q: Why do you recommend using multiple collections to store logs rather than a single collection, or a capped collection?

A: MongoDB can effectively reuse space freed by removing entire collections without leading to data fragmentation, see details at http://docs.mongodb.org/manual/use-cases/storing-log-data/#multiple-collections-single-database


Copyright
-----------------------------------------------
MIT. David Chen at eoe.cn.


Related
-----------------------------------------------
### Projects
* https://github.com/paulasmuth/fnordmetric FnordMetric is a redis/ruby-based realtime Event-Tracking app
* https://github.com/thirtysixthspan/descriptive_statistics adds methods to the Enumerable module to allow easy calculation of basic descriptive statistics for a set of data
* https://github.com/tmcw/simple-statistics simple statistics for javascript in node and the browser
* https://github.com/clbustos/statsample/  A suite for basic and advanced statistics on Ruby. 
* https://github.com/SciRuby/sciruby Tools for scientific computation in Ruby/Rails

### Articles
* http://www.slideshare.net/WombatNation/logging-app-behavior-to-mongo-db

### event collector
* https://github.com/fluent
* https://github.com/logstash/logstash

### admin interface
* http://three.kibana.org/ browser based analytics and search interface to Logstash and other timestamped data sets stored in ElasticSearch.
