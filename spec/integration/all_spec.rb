require File.dirname(__FILE__) + '/../spec_helper'
require 'prawn'
require 'base64'

describe "ActiveMQ + Solr integration" do

  def hit_count(q)
    filter_query = [
      "valid_from:[* TO #{Time.now.to_iso}]",
      "NOT valid_until:[* TO #{Time.now.to_iso}]"
    ]
    @solr_client.select(:q => q, :fq => filter_query)['response']['numFound']
  end

  before(:all) do
    RailsConnector::Configuration.instance_name = 'seslucenmy'

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


  it "an object should be found under its name" do
    hit_count('name:999').should == 0
    @cm.tcl "
      obj root create name 999 objClass document
      obj withPath /999 release
    "

    lambda { hit_count('name:999') }.should eventually_be(1)
  end


  it "an object whose path has changed should be found under the new path" do
    hit_count('path:/misc/errors/401').should == 0
    @cm.tcl "obj withPath /global set name misc"

    lambda { hit_count('path:/misc/errors/401') }.should eventually_be(1)
  end


  it "an object which has an HTML body should be found by searching a word of the body" do
    hit_count('body:Boddie').should == 0
    @cm.tcl %!
      obj root edit
      obj root editedContent set blob "Das ist der Boddie des Objekts"
      obj root release
    !

    lambda { hit_count('body:Boddie') }.should eventually_be(1)
  end


  it "an object which has an HTML body should not be found by searching an HTML tag name" do
    @cm.tcl %!
      obj root create name htmlbody objClass document
      obj withPath /htmlbody editedContent set blob "Das ist der <span>Boddie</span> des Objekts"
      obj withPath /htmlbody release
    !
    lambda { hit_count('name:htmlbody') }.should eventually_be(1)

    hit_count('body:span').should == 0
  end


  it "an object which no longer exists should not be found" do
    @cm.tcl "
      obj root create name tobedel objClass document
      obj withPath /tobedel release
    "
    lambda { hit_count('name:tobedel') }.should eventually_be(1)
    @cm.tcl "obj withPath /tobedel delete"

    lambda { hit_count('name:tobedel') }.should eventually_be(0)
  end


  it "an object which is not released should not be found" do
    @cm.tcl "
      obj root create name tobeunreleased objClass document
      obj withPath /tobeunreleased release
    "
    lambda { hit_count('name:tobeunreleased') }.should eventually_be(1)
    @cm.tcl "obj withPath /tobeunreleased unrelease"

    lambda { hit_count('name:tobeunreleased') }.should eventually_be(0)
  end


  it "an object which will be valid in the future should not be found" do
    @cm.tcl "
      obj root create name future objClass document
      obj withPath /future release
    "
    lambda { hit_count('name:future') }.should eventually_be(1)

    @cm.tcl "
      obj withPath /future edit
      obj withPath /future editedContent set validFrom #{3.days.from_now.to_iso}
      obj withPath /future release
    "

    lambda { hit_count('name:future') }.should eventually_be(0)
  end


  it "an object which was valid in the past should not be found" do
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


  it "an object which is valid since the past and will not become invalid should be found" do
    @cm.tcl "
      obj root create name valid_from_past_and_valid_until_open_end objClass document
      obj withPath /valid_from_past_and_valid_until_open_end editedContent set validFrom #{4.days.ago.to_iso}
      obj withPath /valid_from_past_and_valid_until_open_end release
    "

    lambda { hit_count("name:valid_from_past_and_valid_until_open_end") }.should eventually_be(1)
  end


  it "an object which is valid since the past but will become invalid in the future should be found" do
    @cm.tcl "
      obj root create name valid_from_past_and_valid_until objClass document
      obj withPath /valid_from_past_and_valid_until editedContent set validFrom #{4.days.ago.to_iso}
      obj withPath /valid_from_past_and_valid_until editedContent set validUntil #{2.days.from_now.to_iso}
      obj withPath /valid_from_past_and_valid_until release
    "

    lambda { hit_count('name:valid_from_past_and_valid_until') }.should eventually_be(1)
  end


  it "should find text within a PDF document" do
    pdf = Prawn::Document.new
    pdf.text 'This is auniquepdfword in a PDF document'
    blob64 = Base64.encode64(pdf.render)
    @cm.tcl "
      obj root create name pdf objClass generic
      obj withPath /pdf editedContent set blob.base64 {#{blob64}}
      obj withPath /pdf release
    "

    lambda { hit_count('body:auniquepdfword') }.should eventually_be(1)
  end

end
