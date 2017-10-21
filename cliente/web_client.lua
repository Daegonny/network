local socket = require("socket")

--to receive from shellserver
local receiver = assert(socket.bind("0.0.0.0", 2325))

--to send to shellclient
local sender = assert(socket.tcp())
sender:connect("0.0.0.0", 2319)

local web = assert(socket.bind("0.0.0.0", 2321))


while 1 do
  --getting google chrome request
  local client = web:accept()
  --print('connected: '..client:getpeername())
  local line, err = client:receive()

  if not err then
    --send to shellclient
    sender:send(line)
    sender:close()

    --get response from shellserver
    local requester = receiver:accept()
    local line, err = requester:receive()
    print(line)
    local result = string.gsub(line, "200 OK", "200 OK\n\n", 1)
    --print(result)

    --handle response
    client:send(result)

    client:close()
    requester:close()

  else
    local response = "HTTP/1.1 200 OK\n\n DEU RUIM!"
    client:send(response)
    client:close()
  end
end
