INSTANCE = ENV['INSTANCE']
INSTANCE_DIR = ENV['INSTANCE_DIR']
$: << Dir["#{INSTANCE_DIR}/script/gems/gems/resque-*/lib"].last or raise "No resque installed"

require 'resque'

module Infopark
  module SES
    class Indexer
      def self.queue
        "index_#{INSTANCE}"
      end
    end
  end
end

ARGF.each_line do |obj_id|
  Resque.enqueue(Infopark::SES::Indexer, obj_id.to_i)
end
