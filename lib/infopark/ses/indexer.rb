module Infopark
  module SES

    class Indexer

      # The callback that decides which fields are to be indexed. See
      # config/initializers/indexer.rb. It may return nil to indicate that the
      # object should not be indexed.
      def self.index_fields(&block)
        @@index_fields_callback = block
      end

      # A hash of keys and Solr URLs to allow indexing into different collections
      def self.collections=(hash)
        @@collections = hash
      end

      # The callback that decides which collections will receive an indexing request.
      # See config/initializers/indexer.rb. It may return a single key or an array of keys.
      def self.collection_selection(&block)
        @@collection_selection_callback = block
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
            log :info, "Received message from MQ: #{msg.body}"
            index(msg.body)
            mq_client.acknowledge(msg)

          rescue ActiveRecord::StatementInvalid => e
            log :error, "[#{e.class}] #{e}"
            unless ActiveRecord::Base.connected? && ActiveRecord::Base.connection.active?
              begin
                log :info, "Detected lost connection. Trying to reconnect..."
                # a simple reconnect! does not work; need to clear all connections
                # and then establish a new connection to make things work
                ActiveRecord::Base.connection_handler.clear_all_connections!
                db_yml = YAML::load(File.read(Rails.root + 'config/database.yml'))
                ActiveRecord::Base.establish_connection(db_yml['cms'])
                mq_client.unreceive(msg, :max_redeliveries => 1.0/0)
              rescue Exception => e
                log :error, "[#{e.class}] ** #{e}"
              end
            end

          rescue StandardError => e
            log :error, "[#{e.class}] #{e}\n  #{(e.backtrace[0,4] + ['...']).join("\n  ")}"
            mq_client.unreceive(msg, :max_redeliveries => 1.0/0)
            sleep 10
          end
        end
      end

      def stop
        mq_client.close
      end

      def reindex_all
        pbar = ProgressBar.new("indexing", Obj.count)
        solr_clients = rsolr_connect
        solr_clients.each_value do |solr_client|
          solr_client.delete_by_query('*:*')
        end
        Obj.find_each do |obj|
          reindex(obj, solr_clients)
          pbar.inc
        end
        solr_clients.each_value do |solr_client|
          solr_client.commit
        end
        pbar.finish
      end

      private

      @@collections = {:default => nil}
      @@collection_selection_callback = lambda {:default}

      def rsolr_connect
        @@collections.merge(@@collections) do |k, url|
          RSolr.connect(:url => url)
        end
      end

      def index(obj_id)
        solr_clients = rsolr_connect
        obj = Obj.find_by_obj_id(obj_id)
        fields = obj && fields_for(obj)
        collections = obj && collections_for(obj)

        solr_clients.each do |collection, solr_client|
          if fields && collections.include?(collection)
            log :info, "Indexing obj #{obj.id} (#{obj.path}) into collection #{collection}"
            # FIXED in rsolr master, gem not yet released:
            #solr_client.add(fields, {:commitWithin => 1.0})
            solr_client.add(fields)
          else
            log :info, "Deleting obj #{obj_id} from collection #{collection}"
            solr_client.delete_by_id(obj_id)
          end
          solr_client.commit
        end
      end

      def reindex(obj, solr_clients)
        if fields = fields_for(obj)
          collections = collections_for(obj)
          solr_clients.each do |collection, solr_client|
            if collections.include?(collection)
              log :info, "Reindexing obj #{obj.id}: #{obj.path} (collection: #{collection})"
              solr_client.add(fields)
            end
          end
        end
      end

      def fields_for(obj)
        @@index_fields_callback.call(obj)
      end

      def collections_for(obj)
        [*@@collection_selection_callback.call(obj)]
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
              'client-id' => 'ses-lucene ' + @@collections.keys.sort_by{|k|k.to_s}.join('/')
            }
          )
        end
      end

      # Log messages appear in log/ses-indexer.log
      def log(severity, msg)
        puts "[#{Time.new.strftime('%Y-%m-%d %H:%M:%S')}] #{severity.to_s.upcase} #{msg}"
      end

    end

  end
end
