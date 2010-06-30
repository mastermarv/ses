require File.dirname(__FILE__) + '/../spec_helper'
require 'prawn'
require 'base64'

describe "ActiveMQ + Solr multicore integration" do

  def hit_count(q, core)
    @solr_client[core].select(:q => q)['response']['numFound']
  end

  before(:all) do
    RailsConnector::Configuration.instance_name = 'seslucenmy'

    @cm = TestCM.new
    @cm.setup

    @mq = TestMQ.new
    @mq.setup

    @solr = TestSolrMulticore.new
    @solr.setup
  end

  before do
    @solr_client = [RSolr.connect(:url => 'http://127.0.0.1:8983/solr/core0'),
        RSolr.connect(:url => 'http://127.0.0.1:8983/solr/core1')]
    Infopark::SES::Indexer.collections = {
      :c0 => 'http://127.0.0.1:8983/solr/core0',
      :c1 => 'http://127.0.0.1:8983/solr/core1'
    }

    Infopark::SES::Indexer.collection_selection do |obj|
      case obj.name
        when 'core_0' then :c0
        when 'core_1' then :c1
        when 'no_core' then []
        else [:c0, :c1]
      end
    end

    @ses_indexer = Infopark::SES::Indexer.new
    @ses_indexer.start
  end

  after do
    @ses_indexer.stop
  end

  after(:all) do
    @solr.teardown
    @mq.teardown
    @cm.teardown
  end


  it "should find a document in the selected collection(s)" do
    @cm.tcl "
      obj root create name core_x objClass document
      obj withPath /core_x editedContent set blob multicoretest
      obj withPath /core_x release
    "

    lambda { hit_count('body:multicoretest', 0) }.should eventually_be(1)
    lambda { hit_count('body:multicoretest', 1) }.should eventually_be(1)

    @cm.tcl "
      obj withPath /core_x set name core_0
    "

    lambda { hit_count('body:multicoretest', 1) }.should eventually_be(0)

    @cm.tcl "
      obj withPath /core_0 set name core_1
    "

    lambda { hit_count('body:multicoretest', 0) }.should eventually_be(0)
  end


  it "should be able to index into no collection" do
    @cm.tcl "
      obj root create name nocoretest objClass document
      obj withPath /nocoretest editedContent set blob nocoretest
      obj withPath /nocoretest release
    "

    lambda { hit_count('body:nocoretest', 0) }.should eventually_be(1)
    lambda { hit_count('body:nocoretest', 1) }.should eventually_be(1)

    @cm.tcl "
      obj withPath /nocoretest set name no_core
    "

    lambda { hit_count('body:nocoretest', 0) }.should eventually_be(0)
    lambda { hit_count('body:nocoretest', 1) }.should eventually_be(0)
  end

end