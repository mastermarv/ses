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
  end

  after do
  end

  after(:all) do
    @solr.teardown
    @mq.teardown
    @cm.teardown
  end

  it "should find the changes made with the CM in the Solr search engine" do
    @solr_client.select(:q => 'name:401')['response']['numFound'].should == 0
    #@solr_client.select(:q => 'path:/misc/errors/401')['response']['numFound'].should == 0
    # todo: im body suchen

    @cm.tcl "obj withPath /global set name misc"

    # wait

    @solr_client.select(:q => 'name:401')['response']['numFound'].should == 1
    #@solr_client.select(:q => 'path:/misc/errors/401')['response']['numFound'].should == 1
  end

end
