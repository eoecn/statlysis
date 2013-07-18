# encoding: UTF-8
# TODO support ActiveRecord

module Statlysis
  class Top < Cron
    attr_accessor :result_limit, :logs
    attr_accessor :stat_model
    attr_accessor :pattern_proc, :user_id_proc, :user_info_proc

    def initialize source, opts = {}
      cron.result_limit = opts[:result_limit] || 100
      if not opts[:test]
        [:pattern_proc, :user_id_proc, :user_info_proc].each do |o|
          raise "Please assign :#{o} params!" if opts[o].nil? && !cron.send(o)
          cron.send "#{o}=", opts[o]
        end
        default_assign_attr :stat_table_name, opts
      end
      super
      cron
    end

    def run
      cron.write
    end

    def write; raise DefaultNotImplementWrongMessage end


    def self.ensure_statlysis_table_and_model tn
      Top.new("FakeLogSource", :test => true, :stat_table_name => tn).pattern_table_and_model tn
    end
    def ensure_statlysis_table_and_model tn
      Top.ensure_statlysis_table_and_model tn
    end

    def default_assign_attr key_symbol, opts
      if opts[key_symbol]
        cron.send("#{key_symbol}=", opts[key_symbol])
      else
        raise "Please assign opts[:#{key_symbol}]"
      end
    end
  end

  # 博客最近用户访问计算实现流程讨论
  # 问题分两个，一个是后端，一个是前端。对后端来说，用户每次blog/index|show访问都生成访问记录，后端需要进行排重和去掉未登陆用户。如果在该次访问里进行，特别是某个博客突然火了，必然每次访问都产生IO(磁盘或网络，因为多进程要共享信息），所以必定是异步的。
  # 前端展示考虑到缓存，一般是页面片段缓存，或者ajax载入。
  # 后端异步如何计算每个blog的最近访客，log.js记录了最近访问，一个后台常驻进程循环对日志表按时间记录来读取blog访问信息，把最近访客信息刷新到blog。相对单次请求全部处理，这里处理次数更少，资源更节约，当然瓶颈也在日志表的索引更新和读取。
  class LastestVisits < Top
    attr_accessor :clock
    attr_accessor :reject_proc

    # *pattern_proc* is a proc to extract user_id or url_prefix to compute the
    # top visitors from log
    # *user_id_proc* is a proc to extract user_id from log
    # *user_info_proc* is a proc to extract visitor informations(like id, name, ...)
    # *reject_proc* filter visitors
    def initialize source, opts = {}
      # set variables
      cron.reclock opts[:default_time]
      cron.reject_proc = opts[:reject_proc] || proc {|pattern, user_id| pattern.to_i == user_id.to_i }
      super
      cron.pattern_table_and_model cron.stat_table_name
      cron
    end

    def output
      cron.logs = cron.source.asc(cron.time_column).where(cron.time_column => {"$gte" => cron.clock.current}).limit(1000).to_a
      return {} if cron.logs.blank?
      cron.logs.inject({}) do |h, log|
        pattern = cron.pattern_proc.call(log)
        if pattern
          h[pattern] ||= []
          user_id = cron.user_id_proc.call(log).to_i
          h[pattern] << user_id if not user_id.zero?
        end
        h
      end
    end

    def write
      logger.info "#{Time.now.strftime('%H:%M:%S')} #{cron.stat_model} #{cron.output.inspect}"
      cron.output.each do |pattern, user_ids|
        s = cron.stat_model.find_or_create(:pattern => pattern)
        old_array = (JSON.parse(s.result) rescue []).map {|i| Array(i)[0] }
        new_user_ids = (old_array + user_ids).reverse.uniq.reverse # ensure the right items will overwrite the left [1,4,5,7,4,3,3,2,1,5].uniq => [1, 4, 5, 7, 3, 2]
        s.update :result => new_user_ids.reject {|user_id| cron.reject_proc.call(pattern, user_id) rescue false }.map {|user_id| cron.user_info_proc.call(user_id) }.compact[0..cron.result_limit].to_json
      end
      cron.clock.update cron.logs.last.try(cron.time_column)
    end

    def reclock default_time = nil
      cron.clock = Clock.new cron.stat_table_name, (default_time || cron.clock.current)
    end
  end

  class SingleKv < Top
    attr_accessor :time_ago, :stat_column_name

    def initialize source, opts = {}
      [:time_ago, :stat_column_name].each {|key_symbol| default_assign_attr key_symbol, opts }
      raise "#{cron.class} only is kv store" if cron.stat_table_name # TODO
      super
      cron.ensure_statlysis_table_and_model [Statlysis.tablename_default_pre, 'single_kvs'].compact.join("_").freeze
      cron
    end

  end

  # 一般最近热门列表通常采用简单对一个字段记录访问数的算法，但是这可能会导致刷量等问题。
  #
  # 解决方法为从用户行为中去综合分析，具体流程为：
  # 从URI中抽取item_id, 从访问日志抽取排重IP和user_id，从like,fav,comment表获取更深的用户行为，把前两者通过一定比例相加得到排行。
  # 最后用时间降温来避免马太效应，必可动态提升比例以使最近稍微热门的替换掉之前太热门的。
  #
  # 线性计算速度很快
  #
  class HotestItems < SingleKv
    attr_accessor :key, :id_to_score_and_time_hash_proc
    attr_accessor :limit

    def initialize key, id_to_score_and_time_hash_proc
      cron.key = key
      cron.id_to_score_and_time_hash_proc = id_to_score_and_time_hash_proc
      cron.limit = 20
      super
      cron
    end

    def output
      t = cron.id_to_score_and_time_hash_proc
      while t.is_a?(Proc) do
        t = t.call
      end
      @id_to_score_and_time_hash = t
      @id_to_day_hash = @id_to_score_and_time_hash.inject({}) {|h, ab| h[ab[0]] = (((Time.now - ab[1][1]) / (3600*24)).round + 1); h }

      @id_to_timecooldown_hash = @id_to_score_and_time_hash.inject({}) {|h, kv| h[kv[0]] = (kv[1][0] / Math.sqrt(@id_to_day_hash[kv[0]])); h }
      array = @id_to_timecooldown_hash.sort {|a, b| b[1] <=> a[1] }.map(&:first)
      {cron.key => array}
    end

    def write
      cron.output.each do |key, array|
        json = array[0..140].to_json
        StSingleKv.find_or_create(:pattern => key).update :result => json
        StSingleKvHistory.find_or_create(:pattern => "#{key}_#{Time.now.strftime('%Y%m%d')}").update :result => json
      end
    end

  end

end
