require 'paint'
require 'fileutils'
require 'rspec/core/formatters/base_formatter'

module RoxClient::RSpec

  class Formatter < RSpec::Core::Formatters::BaseFormatter

    def initialize *args
      super *args

      config = RoxClient::RSpec.config
      @client = Client.new config.server, config.client_options
      @test_run = TestRun.new config.project

      @groups = []
    end

    def start example_count
      # TODO: measure milliseconds
      @start_time = Time.now
    end

    def example_group_started group
      @groups << group
    end

    def example_group_finished group
      @groups.pop
    end

    def example_started example
      @current_time = Time.now
    end

    def example_passed example
      add_result example, true
    end

    def example_failed example
      add_result example, false
    end

    def stop
      end_time = Time.now
      @test_run.end_time = end_time.to_i * 1000
      @test_run.duration = ((end_time - @start_time) * 1000).round
    end

    def dump_summary duration, example_count, failure_count, pending_count
      @client.process @test_run
    end

    private

    def add_result example, successful

      options = {
        passed: successful,
        duration: ((Time.now - @current_time) * 1000).round
      }
      options[:message] = failure_message(example) unless successful

      @test_run.add_result example, @groups, options
    end
    
    def failure_message example
      exception = example.execution_result[:exception]
      Array.new.tap do |a|
        a << full_example_name(example)
        a << "Failure/Error: #{read_failed_line(exception, example).strip}"
        a << "  #{exception.class.name}:" unless exception.class.name =~ /RSpec/
        exception.message.to_s.split("\n").each do |line|
          a << "    #{line}"
        end
        format_backtrace(example.execution_result[:exception].backtrace, example).each do |backtrace_info|
          a << "# #{backtrace_info}"
        end
      end.join "\n"
    end

    def full_example_name example
      (@groups.collect{ |g| g.description.strip } << example.description.strip).join ' '
    end
  end
end
