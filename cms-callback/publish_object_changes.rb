INSTANCE = ENV['INSTANCE']
INSTANCE_DIR = ENV['INSTANCE_DIR']

gems = []
Dir["#{INSTANCE_DIR}/script/gems/gems/*/"].sort.reverse.each do |gem_dir|
  gem_name = File.basename(gem_dir).gsub(/-[\d.]+$/, '')
  unless gems.include?(gem_name)
    gems << gem_name
    $: << "#{gem_dir}/lib"
  end
end

require 'resque'

module Infopark
  module SES
    class Indexer
      def self.queue
        "index_#{INSTANCE}_#{$mode}"
      end
    end
  end
end

ARGF.each_line do |obj_id|
  $mode="production"
  Resque.enqueue(Infopark::SES::Indexer, obj_id.to_i)
  $mode="preview"
  Resque.enqueue(Infopark::SES::Indexer, obj_id.to_i)
end
