local socket = require("socket")

function readAll(file)
    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()
    return content
end

--to receive from shellserver
local receiver = assert(socket.bind("0.0.0.0", 2321))

--to send to shellclient
local sender = assert(socket.tcp())
sender:connect("0.0.0.0", 2322)


while 1 do
  local requester = receiver:accept()
  print("Connected: "..requester:getpeername())
  local line, err = requester:receive()
  requester:close()

  --check if line payload is a valid HTTP request

  --build response. Change later to a html file
  local response = "HTTP/1.1 200 OK\n\n"..readAll("index.html")
  print("linha: "..line)
  print(response)
  sender:send(response)
  sender:close()
end
