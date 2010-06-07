module Infopark
  module SES

    class Indexer

      # The callback that decides which fields are to be indexed. See
      # config/initializers/indexer.rb. It may return nil to indicate that the
      # object should not be indexed.
      def self.index_fields(&block)
        @@index_fields_callback = block
      end

      def initialize
      end

      def self.serve
        indexer = new
        indexer.start
        at_exit { indexer.stop }
        sleep
      end

      def start
        mq_client.subscribe("/topic/#{RailsConnector::InfoparkBase.instance_name}/object-changes",
            :ack => "client",
            "activemq.prefetchSize" => 1,
            "activemq.subscriptionName" => "ses-lucene") do |msg|
          begin
            index(msg.body)
            mq_client.acknowledge(msg)
          rescue StandardError => e
            $stderr.puts "Unhandled exception in MQ subscriber block: #{e.inspect}"
            infinity = 1.0/0
            mq_client.unreceive(msg, :max_redeliveries => infinity)
          end
        end
      end

      def stop
        mq_client.close
      end

      def reindex_all
        pbar = ProgressBar.new("indexing", Obj.count)
        solr_client = RSolr.connect
        solr_client.delete_by_query('*:*')
        Obj.find_each do |obj|
          if fields = @@index_fields_callback.call(obj)
            ActiveRecord::Base.logger.debug "indexing obj #{obj.id}: #{obj.path}"
            solr_client.add(fields)
          end
          pbar.inc
        end
        solr_client.commit
        pbar.finish
      end

      private

      def index(obj_id)
        solr_client = RSolr.connect

        if fields = fields_for(obj_id)
          # FIXED in rsolr master, gem not yet released:
          #solr_client.add(fields, {:commitWithin => 1.0})
          solr_client.add(fields)
        else
          solr_client.delete_by_id(obj_id)
        end

        solr_client.commit
      end

      def fields_for(obj_id)
        obj = Obj.find(obj_id)
        @@index_fields_callback.call(obj)
      rescue ::ActiveRecord::RecordNotFound
        nil
      end

      def mq_client
        @mq_client ||= begin
            Stomp::Client.new(
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
                'client-id' => 'ses-lucene'
              }
            )
        end
      end

    end

  end
end
