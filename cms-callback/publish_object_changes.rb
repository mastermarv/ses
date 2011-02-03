base_dir = ENV['NPS_BASE']
instance = ENV['INSTANCE']
$: << Dir["#{base_dir}/3rdparty/gems/gems/stomp-*/lib"].last or raise "No stomp installed"

require 'stomp'

client = Stomp::Client.new("stomp://:@localhost:61613?initialReconnectDelay=5000&randomize=false&useExponentialBackOff=false")

ARGF.each_line do |message|
  client.publish("/topic/#{instance}/object-changes", message.chomp, :persistent => true)
end
