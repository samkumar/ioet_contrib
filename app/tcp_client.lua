require "storm"
require "string"
require "cord"

server_ip = "fe80::0212:6d02:0000:4021"
server_port = 32067

-- Create active socket
csock = storm.net.tcpactivesocket()

-- Bind socket to port 1024
storm.net.tcpbind(csock, 1024)

prevcord = nil
function connection_lost(how, socket)
    if prevcord ~= nil then
        cord.cancel(prevcord) -- connect failed, so stop this cord
    end
    if how ~= 0 then -- connection broken
        cord.await(storm.os.invokeLater, storm.os.SECOND)
        prevcord = cord.new(function () tryconnect(socket) end)
    else
        storm.net.tcpclose(socket)
        -- End of program
    end
end

function tryconnect(clsock)
    cord.await(storm.net.tcpconnect, clsock, server_ip, 32067)
    data, err = cord.await(storm.net.tcprecvfull, clsock, 751)
    storm.net.tcpshutdown(clsock, storm.net.SHUT_RDWR)
    
    print("Length of data received: " .. string.len(data))
    print(string.sub(data, 0, 99))
    print(string.sub(data, 100, 199))
    print(string.sub(data, 200, 299))
    print(string.sub(data, 300, 399))
    print(string.sub(data, 400, 499))
    print(string.sub(data, 500, 599))
    print(string.sub(data, 600, 699))
    print(string.sub(data, 700))
end

cord.new(function ()
    connection_lost(1, csock)
end)

cord.enter_loop()
