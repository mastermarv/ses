gem_name_stomp = "stomp-?.?.?"
Dir["/usr/lib/ruby/gems/1.8/gems/#{gem_name_stomp}/lib"].each { |d| $: << d }
Dir["/var/lib/ruby/gems/1.8/gems/#{gem_name_stomp}/lib"].each { |d| $: << d }
Dir[ENV['HOME'] + "/.gem/ruby/1.8/gems/#{gem_name_stomp}/lib"].each { |d| $: << d }

require 'stomp'

client = Stomp::Client.new("stomp://:@localhost:61613?initialReconnectDelay=5000&randomize=false&useExponentialBackOff=false")

instance = ENV['INSTANCE']

ARGF.each_line do |message|
  client.publish("/topic/#{instance}/object-changes", message.chomp, :persistent => true)
end
