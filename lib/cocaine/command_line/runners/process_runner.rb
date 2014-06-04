# coding: UTF-8

module Cocaine
  class CommandLine
    class ProcessRunner
      def self.available?
        Process.respond_to?(:spawn)
      end

      def self.supported?
        available? && !Cocaine::CommandLine.java?
      end

      def supported?
        self.class.supported?
      end

      def call(command, env = {}, options = {})
        stdoutin, stdoutout = IO.pipe
        stderrin, stderrout = IO.pipe
        options[:out] = stdoutout
        options[:err] = stderrout
        with_modified_environment(env) do
          pid = spawn(env, command, options)
          stdoutout.close
          stderrout.close
          stdout = read_stream(stdoutin)
          stderr = read_stream(stderrin)
          waitpid(pid)
          stdoutin.close
          stderrin.close
          Output.new(stdout, stderr)
        end
      end

      private

      def read_stream(io)
        result = ""
        while partial_result = io.read(8192)
          result << partial_result
        end
        result
      end

      def spawn(*args)
        Process.spawn(*args)
      end

      def waitpid(pid)
        Process.waitpid(pid)
      rescue Errno::ECHILD
        # In JRuby, waiting on a finished pid raises.
      end

      def with_modified_environment(env, &block)
        ClimateControl.modify(env, &block)
      end

    end
  end
end
