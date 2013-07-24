# encoding: UTF-8

require 'statlysis/cron'

module Statlysis
  class CronSet < Set
    def [] pattern = nil
      # TODO filter
      return self
    end

    def run
      map(&:run)
    end
  end

end
