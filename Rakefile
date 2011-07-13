require 'bundler'
Bundler::GemHelper.install_tasks


task :spec => :test
task :test do
  File.directory?("../fiona") or raise "Expected to find a checked out Fiona source tree at ../fiona"
  File.directory?("../fiona/gen") or raise "Expected to find a built Fiona at ../fiona/gen"
  chdir("test_app") do
    sh "bundle --local --quiet --path .bundle"
    sh "rake db:migrate"
    sh "rake spec RAILS_ENV=test"
  end
end
