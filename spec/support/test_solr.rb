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
    mkdir_p @install_dir
    system "rsync -a --exclude=/.git #{vendor_dir}/ #{install_dir}/"
    patch_config
    start
  end

  def patch_config
    config = "#{install_dir}/example/solr/conf/schema.xml"
    contents = File.read(config)
    fields = <<EOS
<fields>
  <field name="id" type="string" indexed="true" stored="true" required="true" />
  <field name="name" type="string" indexed="true" stored="false" required="false" />
  <field name="path" type="string" indexed="true" stored="false" required="false" />
  <field name="valid_from" type="string" indexed="true" stored="false" required="false" />
  <field name="valid_until" type="string" indexed="true" stored="false" required="false" />
  <field name="text" type="text" indexed="true" stored="false" multiValued="true"/>
  <dynamicField name="*" type="html" indexed="true" stored="false" multiValued="true"/>
</fields>
EOS
    contents.gsub!(/<fields>.*?<\/fields>/m, fields)

    field_types = <<EOS
  <fieldType name="html" class="solr.TextField">
    <analyzer>
      <charFilter class="solr.HTMLStripCharFilterFactory"/>
      <tokenizer class="solr.WhitespaceTokenizerFactory"/>
      <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1" catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
    </analyzer>
  </fieldType>
EOS
    contents.gsub!(/<\/types>/, field_types + "</types>")

    open(config, "w") do |f|
      f << contents
    end
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
    puts "Solr is up and running"
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

