require 'rspec/core/rake_task'
require 'fileutils'
require 'tempfile'

RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = ['--color','--format documentation']
end

file 'parser.rb' => 'bool.waxeye' do
    sh 'waxeye -g ruby . bool.waxeye' do |ok, res|
        state = :scanning
        if ! ok
            puts "waxeye returned an error (#{res.exitstatus})"
        else
            header = <<-EOH.gsub(/^\s+/,'')
                $LOAD_PATH.unshift File.dirname(__FILE__)
                require 'waxeye'
                module BoolP
                end
                module BoolP::Waxeye
                end

                class BoolP::Waxeye::Parser < Waxeye::WaxeyeParser
            EOH
            outfile = Tempfile.new('parser.rb.temp')
            File.foreach('parser.rb') do |line|
                case state
                when :scanning
                    if line.match /^begin/
                        state = :in_header
                        outfile.puts header
                    end
                when :in_header
                    state = :done if line.match /^class/
                else
                    outfile.puts line
                end
            end
            outfile.close
            FileUtils.mv outfile.path, 'parser.rb'
        end
    end
end
