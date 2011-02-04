instance = ENV['INSTANCE']
instance_dir = ENV['INSTANCE_DIR']
$: << Dir["#{instance_dir}/script/gems/gems/stomp-*/lib"].last or raise "No stomp installed"

require 'stomp'

client = Stomp::Client.new("stomp://:@localhost:61613?initialReconnectDelay=5000&randomize=false&useExponentialBackOff=false")

ARGF.each_line do |message|
  client.publish("/topic/#{instance}/object-changes", message.chomp, :persistent => true)
end
