# encoding: UTF-8

require 'statlysis/cron'

module Statlysis
  class CronSet < Set
    # filter cron_sets by pattern
    def [] pattern = nil
      case pattern
      when Fixnum, Integer # support array idx access
        self.to_a[pattern]
      else
        CronSet.new(select do |cron_set|
          cron_set.multiple_dataset.name.to_s.match Regexp.new(pattern.to_s)
        end)
      end
    end

    def run
      map(&:run)
    end
  end

end
