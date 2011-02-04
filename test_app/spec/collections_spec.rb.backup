require File.dirname(__FILE__) + '/spec_helper'

describe "Indexer collection support" do

  before do
    Infopark::SES::Indexer.send(:public, :index)
    Infopark::SES::Indexer.collections = {}
    @indexer = Infopark::SES::Indexer.new

    @rsolr_client = mock("rsolr", :commit => nil, :delete_by_id => nil)
    RSolr.stub!(:connect).and_return(@rsolr_client)

    Obj.stub!(:find_each)
    Obj.stub!(:count).and_return(0)
  end

  it "should apply a configured Solr URL when indexing" do
    Infopark::SES::Indexer.collections = {:default => 'http://mysolr/path'}
    @indexer.stub!(:obj_for)
    RSolr.should_receive(:connect).with(hash_including(:url => 'http://mysolr/path'))

    @indexer.index(2001)
  end

  it "should apply a configured Solr URL when re-indexing all" do
    Infopark::SES::Indexer.collections = {:default => 'http://solr/x'}
    RSolr.should_receive(:connect).with(hash_including(:url => 'http://solr/x'))
    @rsolr_client.should_receive(:delete_by_query)

    @indexer.reindex_all
  end

  it "should create a unique durable consumer for a unique set of collections" do
    mock = mock_model(Stomp::Client, :subscribe => nil)
    Stomp::Client.should_receive(:new).with(
        hash_including(:connect_headers => {'client-id' => 'ses-lucene a'})).and_return mock
    Stomp::Client.should_receive(:new).with(
        hash_including(:connect_headers => {'client-id' => 'ses-lucene de/en/fr'})).and_return mock

    Infopark::SES::Indexer.collections = {:a => 'http://solr/a'}
    Infopark::SES::Indexer.new.start
    Infopark::SES::Indexer.collections = {:en => 'x', :de => 'y', :fr => 'z'}
    Infopark::SES::Indexer.new.start
  end

  describe "with more than one collection" do

    it "should de-index from every collection" do
      Infopark::SES::Indexer.collections = {:en => 'http://en/solr', :de => 'http://de/solr'}
      @indexer.stub!(:obj_for)
      RSolr.should_receive(:connect).with(hash_including(:url => 'http://en/solr'))
      RSolr.should_receive(:connect).with(hash_including(:url => 'http://de/solr'))
      @rsolr_client.should_receive(:delete_by_id).twice.with(2001)

      @indexer.index(2001)
    end

    it "should index into selected collections only" do
      Infopark::SES::Indexer.collections = {:en => 'en', :de => 'de', :fr => 'fr'}
      Infopark::SES::Indexer.collection_selection do |obj|
        [:de, :en]
      end
      @indexer.stub!(:fields_for).and_return({})
      Obj.stub!(:find).and_return(mock_model(Obj))
      @rsolr_client.should_receive(:add).twice

      @indexer.index(2001)
    end

  end

  describe "when re-indexing all collections" do

    it "should de-index from every collection" do
      Infopark::SES::Indexer.collections = {:en => 'http://en', :de => 'http://de'}
      @rsolr_client.should_receive(:delete_by_query).twice

      @indexer.reindex_all
    end

    it "should index into selected collections only" do
      Infopark::SES::Indexer.collections = {:en => 'en', :de => 'de', :fr => 'fr'}
      Infopark::SES::Indexer.collection_selection do |obj|
        [:de, :en]
      end
      Obj.should_receive(:find_each).and_yield(mock_model(Obj, :path => nil))
      @indexer.stub!(:fields_for).and_return({})
      @rsolr_client.stub!(:delete_by_query)
      @rsolr_client.should_receive(:add).twice

      @indexer.reindex_all
    end

  end

end
