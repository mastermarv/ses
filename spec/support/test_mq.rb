require "fileutils"
include FileUtils

class TestMQ
  def initialize
    @vendor_dir = "vendor/apache-activemq"
    @install_dir = "tmp/apache-activemq"
  end

  attr_reader :vendor_dir, :install_dir

  def setup
    rm_rf install_dir
    system "rsync -a --exclude=/.git #{vendor_dir}/ #{install_dir}/"
    patch_config
    start
  end

  def patch_config
    config = "#{install_dir}/conf/activemq.xml"
    contents = File.read(config)
    contents.gsub!(%!<transportConnector name="openwire" uri="tcp://0.0.0.0:61616"/>!,
                   %!<transportConnector name="openwire" uri="tcp://0.0.0.0:61616"/>
                     <transportConnector name="stomp" uri="stomp://0.0.0.0:61613"/>!)
    open(config, "w") do |f|
      f << contents
    end
  end

  def start
    system "#{install_dir}/bin/activemq-admin start >/dev/null 2>&1 &"
    until %x(#{install_dir}/bin/activemq-admin query) =~ /StompURL = \w+/
      puts "Waiting for MQ to start up"
      sleep 1
    end
  end

  def teardown
    system "#{install_dir}/bin/activemq-admin stop >/dev/null 2>&1"
  end
end

