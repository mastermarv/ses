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
    @cm.tcl "
      obj root create name 999 objClass document
      obj withPath /999 release
    "

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

  it "should not find deleted objects in the Solr search engine" do
    @cm.tcl "
      obj root create name tobedel objClass document
      obj withPath /tobedel release
    "
    lambda {
      @solr_client.select(:q => 'name:tobedel')['response']['numFound']
    }.should eventually_be(1).within(10.seconds)

    @cm.tcl "obj withPath /tobedel delete"

    lambda {
      @solr_client.select(:q => 'name:tobedel')['response']['numFound']
    }.should eventually_be(0).within(10.seconds)
  end

  it "should only find released objects in the Solr search engine" do
    @cm.tcl "
      obj root create name tobeunreleased objClass document
      obj withPath /tobeunreleased release
    "
    lambda {
      @solr_client.select(:q => 'name:tobeunreleased')['response']['numFound']
    }.should eventually_be(1).within(10.seconds)

    @cm.tcl "obj withPath /tobeunreleased unrelease"

    lambda {
      @solr_client.select(:q => 'name:tobeunreleased')['response']['numFound']
    }.should eventually_be(0).within(10.seconds)
  end

end
