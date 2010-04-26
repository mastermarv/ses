module Infopark
  module SES

    class Indexer

      def initialize
      end

      def start
        mq_client.subscribe("/topic/#{RailsConnector::InfoparkBase.instance_name}/object-changes",
            :ack => "client",
            "activemq.prefetchSize" => 1,
            "activemq.subscriptionName" => "ses-lucene") do |msg|
          begin
            solr_client = RSolr.connect

            obj_id = msg.body
            begin
              obj = Obj.find(obj_id)
              # FIXED in rsolr master, gem not yet released:
              #solr_client.add({:id => obj.id, ...}, {:commitWithin => 1.0})
              solr_client.add(:id => obj.id, :name => obj.name, :path => obj.path, :body => obj.body)
            rescue ::ActiveRecord::RecordNotFound
              solr_client.delete_by_id(obj_id)
            end

            solr_client.commit
            mq_client.acknowledge(msg)
          rescue StandardError => e
            $stderr.puts "Unhandled exception in MQ subscriber block: #{e.inspect}"
          end
        end
      end

      def stop
        mq_client.close
      end

      private

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
