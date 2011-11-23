# encoding: utf-8

require "forwardable"

require_relative "./rack"

module SockJS
  module Thin
    class Request < Rack::Request
    end


    # This is just to make Rack happy.
    DUMMY_RESPONSE ||= [-1, Hash.new, Array.new]


    class Response < Response
      def async?
        @body.is_a?(DelayedResponseBody)
      end
    end


    class AsyncResponse < Response
      extend Forwardable

      def initialize(request, status = nil, headers = Hash.new, &block)
        @request, @body   = request, DelayedResponseBody.new
        @status, @headers = status, headers

        block.call(self) if block
      end

      def write_head(status = nil, headers = nil)
        super(status, headers) do
          callback = @request.env["async.callback"]
          callback.call(@status, @headers, @body)
        end
      end

      def_delegator :body, :write
      def_delegator :body, :finish
    end


    # Wouldn't it be better to make everything
    # simply async? The API we have is async anyway.
    # We would get rid of these stupid hacks AND
    # there's a significant chance that Rack::Lint
    # wouldn't screw with us anymore!
    class SyncResponse < Response
      def write_head(status = nil, headers = nil)
        super(status, headers) do
          # Do nothing. Frankly, what the hell are we suppose to do when Rack doesn't support it?
        end
      end

      def write(data)
        super() do
          @body << data
        end
      end

      def finish(data = nil)
        super(data) do
          @body = [@body] if @body.respond_to?(:bytesize)
          [@status, @headers, @body]
        end
      end
    end


    class DelayedResponseBody
      include EventMachine::Deferrable

      def call(body)
        body.each do |chunk|
          self.write(chunk)
        end
      end

      def write(chunk)
        @body_callback.call(chunk)
      end

      def each(&block)
        @body_callback = block
      end

      alias_method :finish, :succeed
    end
  end
end
