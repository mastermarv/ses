require "resque/tasks"

namespace :index do
  desc "Re-index all objects"
  task :all => :environment do
    i = Infopark::SES::Indexer.new
    i.reindex_all
  end

  namespace :worker do
    desc "Start the worker"
    task :start => :environment do
      queue = Infopark::SES::Indexer.queue
      unless File.exist?("tmp/pids/resque_worker_#{queue}.pid")
        sh "nohup bundle exec rake environment resque:work RAILS_ENV=production QUEUE=#{queue} VERBOSE=1 PIDFILE=tmp/pids/resque_worker_#{queue}.pid >> log/resque_worker_#{queue}.log 2>&1 &"
      end
    end

    desc "Stop the worker"
    task :stop => :environment do
      queue = Infopark::SES::Indexer.queue
      if File.exist?("tmp/pids/resque_worker_#{queue}.pid")
        pid = File.read("tmp/pids/resque_worker_#{queue}.pid")
        sh "kill -9 #{pid} && rm -f tmp/pids/resque_worker_#{queue}.pid; true"
      end
    end

    desc "Restart the worker"
    task :restart do
      Rake::Task["index:worker:stop"].invoke
      Rake::Task["index:worker:start"].invoke
    end
  end
end
