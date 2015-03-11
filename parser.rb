$LOAD_PATH.unshift File.dirname(__FILE__)
require 'waxeye'
module BoolP
end
module BoolP::Waxeye
end
class BoolP::Waxeye::Parser < Waxeye::WaxeyeParser
  @@start = 0
  @@eof_check = true
  @@automata = [Waxeye::FA.new(:input, [Waxeye::State.new([Waxeye::Edge.new(5, 1, false)], false),
      Waxeye::State.new([Waxeye::Edge.new(1, 2, false)], false),
      Waxeye::State.new([Waxeye::Edge.new(5, 3, false)], false),
      Waxeye::State.new([], true)], :prune),
    Waxeye::FA.new(:orexpr, [Waxeye::State.new([Waxeye::Edge.new(2, 1, false)], false),
      Waxeye::State.new([Waxeye::Edge.new("|", 2, true)], true),
      Waxeye::State.new([Waxeye::Edge.new("|", 3, true)], false),
      Waxeye::State.new([Waxeye::Edge.new(5, 4, false)], false),
      Waxeye::State.new([Waxeye::Edge.new(2, 1, false)], false)], :left),
    Waxeye::FA.new(:andexpr, [Waxeye::State.new([Waxeye::Edge.new(3, 1, false)], false),
      Waxeye::State.new([Waxeye::Edge.new("&", 2, true)], true),
      Waxeye::State.new([Waxeye::Edge.new("&", 3, true)], false),
      Waxeye::State.new([Waxeye::Edge.new(5, 4, false)], false),
      Waxeye::State.new([Waxeye::Edge.new(3, 1, false)], false)], :left),
    Waxeye::FA.new(:primary, [Waxeye::State.new([Waxeye::Edge.new("!", 1, false),
        Waxeye::Edge.new("(", 4, true),
        Waxeye::Edge.new(4, 3, false)], false),
      Waxeye::State.new([Waxeye::Edge.new(5, 2, false)], false),
      Waxeye::State.new([Waxeye::Edge.new(3, 3, false)], false),
      Waxeye::State.new([], true),
      Waxeye::State.new([Waxeye::Edge.new(5, 5, false)], false),
      Waxeye::State.new([Waxeye::Edge.new(1, 6, false)], false),
      Waxeye::State.new([Waxeye::Edge.new(")", 7, true)], false),
      Waxeye::State.new([Waxeye::Edge.new(5, 3, false)], false)], :prune),
    Waxeye::FA.new(:term, [Waxeye::State.new([Waxeye::Edge.new([65..90, 97..122], 1, false)], false),
      Waxeye::State.new([Waxeye::Edge.new([48..57, 65..90, "_", 97..122], 1, false),
        Waxeye::Edge.new(5, 2, false)], false),
      Waxeye::State.new([], true)], :left),
    Waxeye::FA.new(:ws, [Waxeye::State.new([Waxeye::Edge.new([9..10, "\r", " "], 0, false)], true)], :void)]

  def initialize()
    super(@@start, @@eof_check, @@automata)
  end
end
