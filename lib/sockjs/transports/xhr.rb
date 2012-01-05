# encoding: utf-8

require "sockjs/adapter"

module SockJS
  module Transports
    class XHRPost < Transport
      # Settings.
      self.prefix  = /[^.]+\/([^.]+)\/xhr$/
      self.method  = "POST"

      # Handler.
      def handle(request)
        respond(request, 200) do |response, session|
          if session
            body = session.process_buffer

            unless body.respond_to?(:bytesize)
              raise TypeError, "Block has to return a string or a string-like object responding to #bytesize, but instead an object of #{body.class} class has been returned (object: #{body.inspect})."
            end

            response.set_content_type(:plain)
            response.write(body)
          else
            # TODO: refactor this.
            match = request.path_info.match(self.class.prefix)
            session = self.connection.create_session(match[1], self)

            response.set_content_type(:javascript)
            response.set_access_control(request.origin)
            response.set_session_id(request.session_id)

            session.open!
          end
        end
      end
    end

    class XHROptions < Transport
      # Settings.
      self.prefix  = /[^.]+\/([^.]+)\/xhr$/
      self.method  = "OPTIONS"

      # Handler.
      def handle(request)
        respond(request, 204) do |response, session|
          response.set_allow_options_post
          response.set_cache_control
          response.set_access_control(request.origin)
        end
      end
    end

    class XHRSendPost < Transport
      # Settings.
      self.prefix  = /[^.]+\/([^.]+)\/xhr_send$/
      self.method  = "POST"

      # Handler.
      def handle(request)
        respond(request, 204) do |response, session|
          if session
            session.receive_message(request.data.read)

            # When we use HTTP 204 with Content-Type, Rack::Lint
            # will be bitching about it. That's understandable,
            # as Lint is suppose to make sure that given response
            # is valid according to the HTTP standard. However
            # what's totally sick is that Lint is included by default
            # in the development mode. It'd be really dishonest
            # to change this behaviour, regardless how jelly brain
            # minded it is. Funnily enough users can't deactivate
            # Lint either in development, so we'll have to tell them
            # to hack it. Bloody hell, that just can't be happening!
            response.set_content_type(:plain)
            response.set_access_control(request.origin)
            response.set_session_id(request.session_id)
          else
            self.error(404, :plain, "Session is not open!")
          end
        end

      rescue SockJS::HttpError => error
        error.to_response(self, request)
      end
    end

    class XHRSendOptions < XHROptions
      # Settings.
      self.prefix  = /[^.]+\/([^.]+)\/xhr_send$/
      self.method  = "OPTIONS"
    end

    class XHRStreamingPost < Transport
      # Settings.
      self.prefix = /[^.]+\/([^.]+)\/xhr_streaming$/
      self.method = "POST"

      def session_class
        SockJS::Session
      end

      # Handler.
      def handle(request)
        response(request, 200) do |response, session|
          response.set_content_type(:javascript)
          response.set_access_control(request.origin)
          response.set_session_id(request.session_id)
          response.write_head

          # IE requires 2KB prefix:
          # http://blogs.msdn.com/b/ieinternals/archive/2010/04/06/comet-streaming-in-internet-explorer-with-xmlhttprequest-and-xdomainrequest.aspx
          preamble = "h" * 2048 + "\n"
          self.try_timer_if_valid(request, response, preamble)
        end
      end

      def send(*messages)
        messages.each do |message|
          @response.write(message)
        end
      end
    end

    class XHRStreamingOptions < XHROptions
      # Settings.
      self.prefix  = /[^.]+\/([^.]+)\/xhr_streaming$/
      self.method  = "OPTIONS"
    end
  end
end