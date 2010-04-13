
gem_name_stomp = "stomp-1.1.5"
$: << "/usr/lib/ruby/gems/1.8/gems/#{gem_name_stomp}/lib"
$: << ENV['HOME'] + "/.gem/ruby/1.8/gems/#{gem_name_stomp}/lib"

require 'stomp'

client = Stomp::Client.new("stomp://:@localhost:61613?initialReconnectDelay=5000&randomize=false&useExponentialBackOff=false")

instance = ENV['INSTANCE']

ARGF.each_line do |message|
  client.publish("/topic/#{instance}/object-changes", message, :persistent => true)
end
