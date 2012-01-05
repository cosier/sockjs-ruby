# encoding: utf-8

require "sockjs/adapter"

module SockJS
  module Transports
    class WelcomeScreen < Transport
      # Settings.
      self.prefix = ""
      self.method = "GET"

      # Handler.
      def handle(request)
        respond(request, 200) do |response|
          response.set_content_type(:plain)
          response.write("Welcome to SockJS!\n")
        end
      end
    end
  end
end