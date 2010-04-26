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
          obj = Obj.find(msg.body)
          solr_client = RSolr.connect

          # FIXED in rsolr master, gem not yet released:
          #solr_client.add({:id => 1, :name => obj.name}, {:commitWithin => 1.0})
          solr_client.add(:id => obj.id, :name => obj.name, :path => obj.path)
          solr_client.commit

          mq_client.acknowledge(msg)
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
