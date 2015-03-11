require_relative '../boolp'

describe BoolP::Parser do
    subject(:parser_class) { BoolP::Parser }
    describe 'constructor' do
        it 'validates input' do
            expect{ parser_class.new :foo }.to raise_error
        end
        it 'returns a Parser object' do
            expect( parser_class.new '' ).to be_an_instance_of BoolP::Parser
        end
    end

    describe 'properties' do
        subject(:parser_object) { parser_class.new '' }
        it 'contains a private BoolP::Waxeye::Parser' do
            expect( parser_object.instance_variable_get('@parser') ).to be_an_instance_of BoolP::Waxeye::Parser
        end
    end

    describe '.parse!' do
        it 'returns an error on unparseable input' do
            p = parser_class.new '(a && ( b )'
            expect{ p.parse! }.to raise_error
        end
        it 'generates a Waxeye::AST' do
            p = parser_class.new '(a && ( b ))'
            p.parse!
            expect( p.instance_variable_get('@ast') ).to be_an_instance_of Waxeye::AST
        end
        [
            # input                                         output
            'a '                                          , 'a',
            '!a'                                          , 'not(a)',
            '(a || b && (c || x && !y))'                  , 'or(a,and(b,or(c,and(x,not(y)))))',
            'ct && test || !( blah && (smth || other) )'  , 'or(and(ct,test),not(and(blah,or(smth,other))))',
            'a || b && c'                                 , 'or(a,and(b,c))',
            'a || b && !c'                                , 'or(a,and(b,not(c)))',
            '(a || b) && c'                               , 'and(or(a,b),c)',
            'a && !b || c'                                , 'or(and(a,not(b)),c)',
            'a || b || c || !d'                           , 'or(a,b,c,not(d))',
            '  (x && ( y && ( z ) ) )'                    , 'and(x,and(y,z))',
            'x && !test'                                  , 'and(x,not(test))',
        ].each_slice(2) do |i|
            it "parses <#{i[0]}> to <#{i[1]}>" do
                p = parser_class.new i[0]
                p.parse!
                expect( p.funt_inspect p.funt ).to eq(i[1])
            end
        end
    end
end

describe BoolP::Function do
    subject(:function_class) { BoolP::Function }
    describe 'constructor' do
        it 'validates input' do
            expect{ function_class.new               }.to     raise_error
            expect{ function_class.new 'foo' , 'foo' }.to     raise_error
            expect{ function_class.new :op   , 'foo' }.to     raise_error
            expect{ function_class.new :op   , []    }.to_not raise_error
        end
        it 'returns a Function object' do
            expect( function_class.new(:op, []) ).to be_an_instance_of BoolP::Function
        end
        it 'returns an object which is also an Array' do
            expect( function_class.new(:op, []) ).to be_kind_of Array
        end
    end

    describe 'properties' do
        subject(:function_object) { function_class.new :opname, [:arg1, :arg2] }
        it 'has an "op" getter that returns a Symbol' do
            expect( function_object.op ).to eq(:opname)
        end
        it 'can be indexed like an Array' do
            expect( function_object[1] ).to eq(:arg2)
        end
    end

    describe 'inspect' do
        it 'stringifies neatly' do
            f = function_class.new :opname, [:arg1, :arg2]
            expect( f.inspect ).to eq('opname(arg1,arg2)')
        end
    end
end

describe BoolP::TagSelect do
    subject(:tagselect_class) { BoolP::TagSelect }
    describe 'constructor' do
        it 'validates input' do
            expect{ tagselect_class.new                               }.to     raise_error
            expect{ tagselect_class.new []                            }.to     raise_error
            expect{ tagselect_class.new 'foo'                         }.to_not raise_error
            expect{ tagselect_class.new BoolP::Function.new :test, [] }.to_not raise_error
        end
    end
	describe '.compile' do
        [
            # input                                         output
            'a'                                           , 'a.include?("a")',
            '!a'                                          , '!a.include?("a")',
            '!(a && b)'                                   , '!((["a", "b"] - a).empty?)',
            't1 && t2 && t3'                              , '(["t1", "t2", "t3"] - a).empty?',
            't1 || t2 || t3'                              , '!(["t1", "t2", "t3"] & a).empty?',
            '(web || redis) && !redismaster'              , '!(["web", "redis"] & a).empty? and !a.include?("redismaster")',
			'ct && test || !(blah && (smth || other))'    , '(["ct", "test"] - a).empty? or !(a.include?("blah") and !(["smth", "other"] & a).empty?)',
        ].each_slice(2) do |i|
            it "compiles <#{i[0]}> to <#{i[1]}>" do
				p = BoolP::Parser.new i[0]
				p.parse!
				selector = BoolP::TagSelect.new p.tree
				filter = selector.compile
                expect( selector.compiled_ruby_code ).to eq(i[1])
            end
        end
	end
end
