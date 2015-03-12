module BoolP

$LOAD_PATH.unshift File.dirname(__FILE__)
require 'parser'

# A function is defined by its :op (operator type) and
# a list of arguments (which can be identifiers or other functions)
class Function < Array
    attr_accessor :op
    def initialize op, array
        raise "op must be a Symbol" unless op.is_a? Symbol
        raise "array must be an Array" unless array.is_a? Array
        @op = op
        super array
    end
    def inspect
        "#{@op}(#{self.join ','})"
    end
end

class Parser
    attr_reader :funt
    alias :tree :funt

    @@type_to_op = {
        :andexpr => :and,
        :orexpr  => :or,
        :term    => :term
    }

    def initialize input_expression
        raise "input_expression must be a String" unless input_expression.is_a? String
        @parser = Waxeye::Parser.new
        @input_expression = input_expression
        @ast = nil
    end

    def parse!
        ast = @parser.parse @input_expression
        raise ast.to_s if ast.is_a? ::Waxeye::ParseError
        @ast = ast
        @funt = ast_to_funt @ast
        @funt = funt_optimize @funt
    end

    # Traverse the AST depth-first, transforming it into a tree of BoolP::Function s
    def ast_to_funt ast
        raise 'ast cannot be empty' unless ast
        arguments = ast.children.map do |c|
            if c.is_a? ::Waxeye::AST
                case c.type
                when :term
                    c.children.join ''
                when :andexpr
                    ast_to_funt c
                when :orexpr
                    ast_to_funt c
                when :primary
                    if c.children.first == '!' and c.children.length == 2
                        if c.children[1].is_a?(::Waxeye::AST) && c.children[1].type != :term
                            Function.new :not, ast_to_funt(c.children[1])
                        elsif c.children[1].is_a?(::Waxeye::AST) && c.children[1].type == :term
                            Function.new :not, [c.children[1].children.join('')]
                        else
                            Function.new :not, [c.children[1].join('')]
                        end
                    else
                        raise "Negation operator applied to more than one operand"
                    end
                end
            else
                c
            end
        end
        Function.new @@type_to_op[ast.type], arguments 
    end

    # Replace single argument and/or Functions with the argument itself
    def funt_optimize funt
        arguments = funt.map do |node|
            case node 
            when Function
                if node.length == 1 and !node.first.is_a?(Function) and !node.op == :not
                    node.first
                else
                    funt_optimize node
                end
            else
                node
            end
        end
        (arguments.length > 1 or funt.op == :not) ?  Function.new(funt.op, arguments) : arguments.first
    end

    # outputs a string representation of a function tree
    # It replaces every Function f, with the output of f.inspect
    def funt_inspect funt
        return funt unless funt.is_a? Function
        arguments = funt.map do |node|
            case node 
            when Function
                # if any of the children is a Function, then this node is not a leaf node and we need to recurse
                node.any?{|child| child.is_a? Function} ? funt_inspect(node) : node.inspect
            else
                node
            end
        end
        Function.new(funt.op, arguments).inspect
    end
end

# Ruby code in form of a String
class Code < String
end

# "compiles" a function tree, as produced by BoolP::Parser, into a Proc.
# The Proc takes an array of tags as an argument, and outputs true/false depending on the outcome
# of the boolean expression described by the function tree.
# Every function in the tree is supposed to check if some tags exist/don't exist in the array.
# Given:
# - An array `a`.
# - A bunch of terms `t1`, `t2`, ... , `tn`.
# - Functions like `and`, `or`, `not`. Generically: `f`.
# Cases:
# -  t1           ->  a.include?(t1)
# - !t1           -> !a.include?(t1)
# - and(t1,t2,t3) ->  ([t1,t2,t3] - a).empty?    # removing `a` from the terms array should yield an empty array
# -  or(t1,t2,t3) -> !([t1,t2,t3] & a).empty?    # is the set intersection not empty?
class TagSelect
    attr_accessor :compiled_ruby_code

    def initialize funt
        raise 'funt must be a BoolP::Function or a String' unless funt.is_a? Function or funt.is_a? String
        @funt = funt
    end

    def compile
        @compiled_ruby_code = tree_compile @funt
        eval "lambda {|a| #{@compiled_ruby_code}}"
    end

    private
    def tree_compile funt
        return gen_include(funt) unless funt.is_a? Function
        arguments = funt.map do |node|
            case node 
            when Function
                # if any of the children is a Function, then this node is not a leaf node and we need to recurse
                if node.any?{|child| child.is_a? Function}
                    tree_compile node
                else # leaf: can contain only tags/terms or code
                    function_compile node
                end
            else
                node
            end
        end
        function_compile Function.new(funt.op, arguments)
    end

    # Takes a node in a Function tree (which itself is a function)
    # and outputs a Ruby code string...
    def function_compile node
        code       = Code.new ''
        case node.op
        when :and, :or
            tags     = node.select { |c| c.instance_of? String }
            codes    = node.select { |c| c.instance_of? Code }
            opstring = node.op.to_s
            opsep    = " #{opstring} "
            if tags.length > 1
                code << self.send("gen_#{opstring}_multi".to_sym, tags)
            elsif tags.length == 1
                code << gen_include(tags.first)
            end
            code << opsep if !code.empty? and !codes.empty?
            code << codes.join(opsep) unless codes.empty?
        when :not
            case node.first
            when Code
                code << "!(#{node.first})"
            when String
                code << gen_not_include(node.first)
            else
                raise "Unknown argument to :not operator"
            end
        else
            raise "Unknown operator #{op}"
        end
        code
    end

    def gen_include tag
        "a.include?(\"#{tag}\")"
    end

    def gen_not_include tag
        "!a.include?(\"#{tag}\")"
    end

    def gen_and_multi args
        "(#{args.inspect} - a).empty?"
    end

    def gen_or_multi args
        "!(#{args.inspect} & a).empty?"
    end

end

end
