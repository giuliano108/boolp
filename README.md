# BoolP

BoolP parses free-form boolean expressions.

An expression is made of _terms_ and _operators_ (`&&`, `||` and `!`) which can be arbitrarily grouped using parentheses.

The parser itself is generated using [Waxeye](https://github.com/orlandohill/waxeye). The Waxeye [runtime](https://raw.githubusercontent.com/orlandohill/waxeye/master/src/ruby/waxeye.rb) (`waxeye.rb`) is included in this repo, so that you don't need anything else to run the tests (`bundle exec rake spec`) and example (`bundle exec ruby example.rb`).

The Waxeye runtime outputs an Abstract Syntax Tree (AST) which is transformed in an easier to handle (and partly optimised) Function Tree (FUNT).

The `TagSelect` class implements a compiler that solves the problem below... `TagSelect#compile` returns a Proc object you can call, passing an array of tags. It, in turn, returns a boolean depending on whether the compiled boolean expression evaluated true or false. 

# Example

You have a list of items, every item can have a set of _tags_ associated to it.

You want to be able to filter the list, including only the items whose tags satisfy the supplied boolean expression (because the given item either does or doesn't have them).

I'm considering using this to "slice and dice" a list of hosts and build firewall rules based on tags (generate Puppet firewall resources).

| hostname | tags                      | 
| ---      | ---                       | 
| s1.dc1   | dc1 web redis redismaster | 
| s2.dc1   | dc1 web                   | 
| s2.dc1   | dc1                       | 
| s1.dc2   | dc2 web redis             | 
| s2.dc2   | dc2 web                   | 
| s3.dc2   | dc2                       | 

Give me a list of all the hosts that have the following tags: `(web || redis) && !redismaster`.

```ruby
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
```
