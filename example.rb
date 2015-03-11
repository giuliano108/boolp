#!/usr/bin/env ruby

$LOAD_PATH.unshift File.dirname(__FILE__)
require 'boolp'
require 'pp'

Host = Struct.new(:name, :tags)

hosts = [
	's1.dc1', %w{dc1 web redis redismaster},
	's2.dc1', %w{dc1 web},
	's2.dc1', %w{dc1},
	's1.dc2', %w{dc2 web redis},
	's2.dc2', %w{dc2 web},
	's3.dc2', %w{dc2}
].each_slice(2).to_a.map { |name,tags| Host.new(name,tags) }

parser = BoolP::Parser.new '(web || redis) && !redismaster'
parser.parse!
selector = BoolP::TagSelect.new parser.tree
filter = selector.compile

pp hosts.select{ |h| filter.call(h.tags) }.to_a

# [#<struct Host name="s2.dc1", tags=["dc1", "web"]>,
#  #<struct Host name="s1.dc2", tags=["dc2", "web", "redis"]>,
#  #<struct Host name="s2.dc2", tags=["dc2", "web"]>]
