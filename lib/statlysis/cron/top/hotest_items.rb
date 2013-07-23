# encoding: UTF-8

module Statlysis
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
