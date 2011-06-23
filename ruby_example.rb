# ruby_example.end
#
# Andrew Lunny <alunny@gmail.com>
#
# Sends statistics to stats.js daemon over UDP
# Heavily based on Steve Ivy's Python example
#
# Usage
#   require 'ruby_example' # or rename to statsd_ruby or whatever
#   StatsD.host = "localhost"
#   StatsD.port = "8125"
#
#   then call module methods
#   StatsD.timing "some.long.operation", 123456879
#   etc

require 'socket'

module StatsD
  class << self
    # host and port for the stats.js process
    attr_accessor :host, :port

    # log timing information
    #
    # stat - The string label for the metric
    # time - The length of the operation, in ms
    # sample_rate - how often to sample
    #
    def timing(stat, time, sample_rate=1)
      stats = { stat => "#{ time }|ms" }
      send stats, sample_rate
    end

    # increment one or more stats counters
    #
    # stats - an Array of stat names, or a String (one stat)
    # sample_rate - how often to sample
    #
    def increment(stats, sample_rate=1)
      update_counters stats, 1, sample_rate
    end

    # decrement one or more stats counters
    #
    # stats - an Array of stat names, or a String (one stat)
    # sample_rate - how often to sample
    #
    def decrement(stats, sample_rate=1)
      update_counters stats, -1, sample_rate
    end

    # update one or more stats counters by arbitrary amounts
    #
    # stats - an Array of stat names, or a String (one stat)
    # delta - The quantity to change each counter by
    # sample_rate - how often to sample
    #
    def update_counters(stats, delta=1, sample_rate=1)
      stats = [stats] if stats.class == String

      data = stats.inject({}) do |hash, val|
        hash[val] = "#{ delta }|c"
        hash
      end

      send data, sample_rate
    end

    # send the sample data to the stats.js process over UDP
    # requires StatsD.host and StatsD.port to be set
    #
    # data - a hash of stats and values
    # sample_rate - how often to sample
    #
    def send(data, sample_rate=1)
      fail "set StatsD.host and StatsD.port" unless host and port

      sample_data = {}

      # take care of the sampling
      if sample_rate < 1
        if rand <= sample_rate
          data.each_pair do |stat, val|
            sample_data[stat] = "#{ val }|@#{ sample_rate }"
          end
        end
      else
        sample_data = data
      end

      # open the socket and send the message
      begin
        sock = UDPSocket.open
        sock.connect host, port

        sample_data.each_pair do |stat, val|
          sock.send "#{ stat }:#{ val }", 0
        end
      rescue Exception => e
        $stderr.puts "something failed: #{ e.inspect }"
      end
    end
  end
end
