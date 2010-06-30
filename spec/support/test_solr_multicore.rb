require "fileutils"
include FileUtils

require 'net/http'

class TestSolrMulticore < TestSolr

  def start
    Dir.chdir("#{install_dir}/example") do
      mkdir_p "logs"
      system "java -DSTOP.PORT=8079 -DSTOP.KEY=stop -Dsolr.solr.home=multicore -jar start.jar >> logs/server.log 2>&1 &"
    end
    until ping
      puts "Waiting for Solr to start up"
      sleep 1
    end
    puts "Solr is up and running"
  end

  def patch_config
    super
    cp_r("#{install_dir}/example/solr/conf", "#{install_dir}/example/multicore/core0")
    cp_r("#{install_dir}/example/solr/conf", "#{install_dir}/example/multicore/core1")
  end

end
