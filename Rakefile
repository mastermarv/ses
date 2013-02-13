require 'bundler'
Bundler::GemHelper.install_tasks


task :spec => :test
task :test do
  chdir("test_app") do
    Bundler.with_clean_env do
      sh "bundle --local --quiet --path .bundle"
      mkdir_p "tmp/pids"
      sh "bundle exec rake spec RAILS_ENV=test"
      end
  end
end
