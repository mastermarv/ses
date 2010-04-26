require File.dirname(__FILE__) + '/../spec_helper'

describe "ActiveMQ + Solr integration" do

  before(:all) do
    @cm = TestCM.new
    @cm.setup

    @mq = TestMQ.new
    @mq.setup

    @solr = TestSolr.new
    @solr.setup
  end

  before do
    @solr_client = RSolr.connect
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

  it "should find the changes made with the CM in the Solr search engine" do
    @solr_client.select(:q => 'name:999')['response']['numFound'].should == 0
    @cm.tcl "obj withPath /global/errors create name 999 objClass document"

    lambda {
      @solr_client.select(:q => 'name:999')['response']['numFound']
    }.should eventually_be(1).within(10.seconds)
  end

  it "should find objects whose paths have changed" do
    @solr_client.select(:q => 'path:/misc/errors/401')['response']['numFound'].should == 0
    @cm.tcl "obj withPath /global set name misc"

    lambda {
      @solr_client.select(:q => 'path:/misc/errors/401')['response']['numFound']
    }.should eventually_be(1).within(10.seconds)
  end

  it "should find an object whose body has changed" do
    @solr_client.select(:q => 'body:Boddie')['response']['numFound'].should == 0
    @cm.tcl %!
      obj root edit
      obj root editedContent set blob "Das ist der Boddie des Objekts"
      obj root release
    !

    lambda {
      @solr_client.select(:q => 'body:Boddie')['response']['numFound']
    }.should eventually_be(1).within(10.seconds)
  end

end
