require "fileutils"
include FileUtils

require 'net/http'

class TestSolr
  def initialize
    @vendor_dir = "vendor/apache-solr"
    @install_dir = "tmp/apache-solr"
  end

  attr_reader :vendor_dir, :install_dir

  def setup
    teardown if File.directory?(install_dir)
    rm_rf install_dir
    system "rsync -a --exclude=/.git #{vendor_dir}/ #{install_dir}/"
    patch_config
    start
  end

  def patch_config
    # welche felder werden indiziert? (siehe schema.xml)
  end

  def start
    Dir.chdir("#{install_dir}/example") do
      mkdir_p "logs"
      system "java -DSTOP.PORT=8079 -DSTOP.KEY=stop -jar start.jar >> logs/server.log 2>&1 &"
    end
    until ping
      puts "Waiting for Solr to start up"
      sleep 1
    end
  end

  def teardown
    Dir.chdir("#{install_dir}/example") do
      system "java -DSTOP.PORT=8079 -DSTOP.KEY=stop -jar start.jar --stop >> logs/server.log 2>&1"
    end
  end

  private

  def ping
    Net::HTTP.new("localhost", 8983).start do |http|
      http.read_timeout = 5
      response = http.get("/solr")
    end
    true
  rescue Exception => e
    false
  end

end

