require File.dirname(__FILE__) + '/../spec_helper'

describe "ActiveMQ + Solr integration" do

  def hit_count(q)
    filter_query = [
      "valid_from:[* TO #{Time.now.to_iso}]",
      "valid_until:[#{Time.now.to_iso} TO *]"
    ]
    @solr_client.select(:q => q, :fq => filter_query)['response']['numFound']
  end

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
    hit_count('name:999').should == 0
    @cm.tcl "
      obj root create name 999 objClass document
      obj withPath /999 release
    "

    lambda { hit_count('name:999') }.should eventually_be(1)
  end

  it "should find objects whose paths have changed" do
    hit_count('path:/misc/errors/401').should == 0
    @cm.tcl "obj withPath /global set name misc"

    lambda { hit_count('path:/misc/errors/401') }.should eventually_be(1)
  end

  it "should find an object whose body has changed" do
    hit_count('body:Boddie').should == 0
    @cm.tcl %!
      obj root edit
      obj root editedContent set blob "Das ist der Boddie des Objekts"
      obj root release
    !

    lambda { hit_count('body:Boddie') }.should eventually_be(1)
  end

  it "should not find deleted objects in the Solr search engine" do
    @cm.tcl "
      obj root create name tobedel objClass document
      obj withPath /tobedel release
    "
    lambda { hit_count('name:tobedel') }.should eventually_be(1)

    @cm.tcl "obj withPath /tobedel delete"

    lambda { hit_count('name:tobedel') }.should eventually_be(0)
  end

  it "should only find released objects in the Solr search engine" do
    @cm.tcl "
      obj root create name tobeunreleased objClass document
      obj withPath /tobeunreleased release
    "
    lambda { hit_count('name:tobeunreleased') }.should eventually_be(1)

    @cm.tcl "obj withPath /tobeunreleased unrelease"

    lambda { hit_count('name:tobeunreleased') }.should eventually_be(0)
  end

  it "should not find objects which are valid in the future" do
    @cm.tcl "
      obj root create name future objClass document
      obj withPath /future release
    "
    lambda { hit_count('name:future') }.should eventually_be(1)

    @cm.tcl "
      obj withPath /future edit
      obj withPath /future editedContent set validFrom #{(Time.now + 3).to_iso}
      obj withPath /future release
    "
    lambda { hit_count('name:future') }.should eventually_be(0)
  end

  it "should not find objects which are valid in the past" do
    @cm.tcl "
      obj root create name past objClass document
      obj withPath /past release
    "
    lambda { hit_count('name:past') }.should eventually_be(1)

    @cm.tcl "
      obj withPath /past edit
      obj withPath /past editedContent set validFrom #{4.days.ago.to_iso}
      obj withPath /past editedContent set validUntil #{3.days.ago.to_iso}
      obj withPath /past release
    "
    lambda { hit_count('name:past') }.should eventually_be(0)
  end

  it "should find objects which are valid since the past" do
    @cm.tcl "
      obj root create name valid_from_past_and_valid_until_open_end objClass document
      obj withPath /valid_from_past_and_valid_until_open_end editedContent set validFrom #{4.days.ago.to_iso}
      obj withPath /valid_from_past_and_valid_until_open_end release
    "
    lambda { hit_count("name:valid_from_past_and_valid_until_open_end") }.should eventually_be(1)
  end

  it "should find objects which are valid since the past but invalid in the future" do
    @cm.tcl "
      obj root create name valid_from_past_and_valid_until objClass document
      obj withPath /valid_from_past_and_valid_until editedContent set validFrom #{4.days.ago.to_iso}
      obj withPath /valid_from_past_and_valid_until editedContent set validUntil #{(Time.now + 2).to_iso}
      obj withPath /valid_from_past_and_valid_until release
    "
    lambda { hit_count('name:valid_from_past_and_valid_until') }.should eventually_be(1)
  end

end
