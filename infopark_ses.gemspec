# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "infopark/ses/version"

Gem::Specification.new do |s|
  s.name        = "infopark_ses"
  s.version     = Infopark::SES::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Infopark AG"]
  s.email       = ["info@infopark.de"]
  s.homepage    = "http://www.infopark.de/"
  s.summary     = %q{Infopark SES Solr integration}
  s.description = %q{Infopark SES provides a daemon which receives object change notifications via Apache Active MQ and sends formatted indexing request to Solr}

  s.files         = `git ls-files`.split("\n").reject {|p| p =~ /^test_app/}
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "activerecord", "~> 3.0.7"
  s.add_dependency "infopark_rails_connector"
  s.add_dependency "stomp"
  s.add_dependency "rsolr", "1.0.0"
  s.add_dependency "daemon-spawn"
  s.add_dependency "ruby-progressbar"
end
