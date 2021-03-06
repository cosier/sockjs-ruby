#!/bin/bash

# Open the session.
curl -X POST http://localhost:8081/echo/_/session_1/xhr

# Check valid messages.
curl -X POST http://localhost:8081/echo/_/session_1/xhr_send -d '["msg 1"]'
curl -X POST http://localhost:8081/echo/_/session_1/xhr_send -d '["msg 2"]'
curl -X POST http://localhost:8081/echo/_/session_1/xhr_send -d '["msg 3", "msg 4", "msg 5"]'

# Receive the messages.
curl -X POST http://localhost:8081/echo/_/session_1/xhr

# Check invalid messages.
curl -X POST http://localhost:8081/echo/_/session_1/xhr_send -d '"msg 1"'
curl -X POST http://localhost:8081/echo/_/session_1/xhr_send -d '"msg 2"'
curl -X POST http://localhost:8081/echo/_/session_1/xhr_send -d '"msg 3", "msg 4", "msg 5"'

# Receive the messages.
curl -X POST http://localhost:8081/echo/_/session_1/xhr

# Close app.
curl -X POST http://localhost:8081/close/_/session_1/xhr
curl -X POST http://localhost:8081/close/_/session_1/xhr
curl -X POST http://localhost:8081/close/_/session_1/xhr
