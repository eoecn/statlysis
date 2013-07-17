# encoding: UTF-8

require 'rake'
require 'only_one_rake'

namespace :statlysis do
  Statlysis::Units.each do |unit|
    desc "statistical in #{unit}"
    only_one_task "#{unit}_count" => :environment do
      Statlysis.send("#{unit}_crons").map(&:run)
    end
  end

  desc "realtime process"
  only_one_task :realtime_process => :environment do
    loop { Statlysis.realtime_crons.map(&:run); sleep 1 }
  end

  desc "similar process"
  only_one_task :similar_process => :environment do
    Statlysis.similar_crons.map(&:run)
  end

  desc "hotest process"
  only_one_task :hotest_process => :environment do
    Statlysis.hotest_crons.map(&:run)
  end

end
