local socket = require("socket")

--to receive from shellserver
local receiver = assert(socket.bind("0.0.0.0", 2325))

--to receive from chrome
local web = assert(socket.bind("0.0.0.0", 2321))


while 1 do
  --getting google chrome request
  local client = web:accept()
  local line, err = client:receive()

  if not err then
    --to send to shellclient
    local sender = assert(socket.tcp())
    sender:connect("0.0.0.0", 2319)
    sender:send(line)
    sender:close()

    --get response from shellserver
    local requester = receiver:accept()

    local line, err = requester:receive("*a")
    requester:close()
    print(line)
    print("------------------------")

    --handle response
    client:send(line)
  else
    local response = "HTTP/1.1 500 Internal Server Error"
    client:send(response)
  end
  client:close()

end
