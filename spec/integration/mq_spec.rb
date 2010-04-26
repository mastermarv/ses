require File.dirname(__FILE__) + '/../spec_helper'

describe "CM Tcl callback objectChangeCallback" do

  before(:all) do
    @cm = TestCM.new
    @cm.setup

    @mq = TestMQ.new
    @mq.setup

  end

  before do
    @client = Stomp::Client.new(
      :hosts => [
        {
          :login => "",
          :passcode => "",
          :host => "localhost",
          :port => 61613,
          :ssl => false
        }
      ],
      :connect_headers => {
        'client-id' => 'test-ses-lucene'
      }
    )
    @received_messages = []
    @client.subscribe("/topic/seslucenmy/object-changes",
        :ack => "client",
        "activemq.prefetchSize" => 1,
        "activemq.subscriptionName" => "test-ses-lucene") do |msg|
      @received_messages << msg
      @client.acknowledge(msg)
    end
  end

  after do
    @client.close
  end

  after(:all) do
    @mq.teardown
    #@cm.teardown
  end

  it "should send an object change message to the message broker" do
    @cm.tcl "obj root edit"
    5.times do
      sleep 1
      break unless @received_messages.empty?
    end
    @received_messages.first.body.should == "2001"
  end

  it "should send multiple object change messages to the message broker" do
    # 2019 == /global, children w/o templates: 2027 2044 2053 2062 2071
    @cm.tcl "obj withPath /global set name misc"
    5.times do
      sleep 1
      break unless @received_messages.size > 5
    end
    @received_messages.map(&:body).should == %w(2019 2027 2044 2053 2062 2071)
  end

end
