local socket = require("socket")

function readAll(file)
    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()
    return content
end

--to receive from shellserver
local receiver = assert(socket.bind("0.0.0.0", 2321))


while 1 do
  local requester = receiver:accept()
  local line, err = requester:receive()
  requester:close()

  --check if line payload is a valid HTTP request
  if line == "GET / HTTP/1.1" then
    --build response
    response = "HTTP/1.1 200 OK\n\n"..readAll("index.html")
  else
    response = "HTTP/1.1 400 Bad Request \n\nInvalid Request!"
  end

  print(line)
  print("---------")
  print(response)
  --to send to shellclient
  local sender = assert(socket.tcp())
  sender:connect("0.0.0.0", 2322)
  sender:send(response)
  sender:close()
  print("---------")
end
