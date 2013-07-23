# encoding: UTF-8

module Statlysis
  # See tech details at http://mvj3.github.io/2013/01/30/recent-visitors-implement/
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
      Utils.setup_pattern_table_and_model cron.stat_table_name
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

end
