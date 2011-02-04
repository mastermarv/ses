require 'bundler'
Bundler::GemHelper.install_tasks


task :spec => :test
task :test do
  File.directory?("../nps") or raise "Expected to find a checked out Fiona source tree at ../nps"
  File.directory?("../nps/gen") or raise "Expected to find a built Fiona at ../nps/gen"
  chdir("test_app") do
    sh "bundle --local --quiet --path .bundle"
    sh "rake db:migrate"
    sh "rake spec"
  end
end
