require "storm"
require "string"
require "cord"
tcpstr = require "tcpstr"

server_ip = "fe80::0212:6d02:0000:401c"
-- server_ip = "2001:470:83ae:2:0212:6d02:0000:4021"
-- server_ip = "2001:470:1f04:5f2::2"
server_port = 32067

-- Create active socket
csock = storm.net.tcpactivesocket()

-- Bind socket to port 1024
storm.net.tcpbind(csock, 1024)

prevcord = nil
function connection_lost(how, socket)
    if how ~= 0 then -- connection broken
        if prevcord ~= nil then
            cord.cancel(prevcord) -- connect failed, so stop this cord
        end
        print("Attempting to connect")
        prevcord = cord.new(function ()
            cord.await(storm.os.invokeLater, storm.os.SECOND)
            tryconnect(socket)
        end)
    else
        storm.net.tcpclose(socket)
        print("Closed socket")
        -- End of program
    end
end

function tryconnect(clsock)
    cord.await(storm.net.tcpconnect, clsock, server_ip, server_port, 300)
    local data = nil
    while data ~= "" do
        data = tcpstr:recv_string(clsock)
        print_string(data)
    end
    resp = tcpstr:send_string(clsock, long_response)
    print("Got response: " .. resp)
    resp = tcpstr:send_string(clsock, "")
    print("Got response: " .. resp)
    
    storm.net.tcpshutdown(clsock, storm.net.SHUT_RDWR)
end

cord.new(function ()
    storm.net.tcpaddconnectionlost(csock, connection_lost)
    connection_lost(1, csock)
end)

local stepsize = 80
function print_string(str)
    local length = string.len(str)
    for i = 1, length, stepsize do
        print(string.sub(str, i, i + stepsize - 1))
    end
end
    
-- Taken from the abstract of the sMAP paper
long_response = "As more and more physical information becomes available, a critical problem is enabling the simple and efficient exchange of this data. We present our design for a simple RESTful web service called the Simple Measuring and Actuation Profile (sMAP) which allows instruments and other producers of physical information to directly publish their data. In our design study, we consider what information should be represented, and how it fits into the RESTful paradigm. To evaluate sMAP, we implement a large number of data sources using this profile, and consider how easy it is to use to build new applications. We also design and evaluate a set of adaptations made at each layer of the protocol stack which allow sMAP to run on constrained devices."

cord.enter_loop()
