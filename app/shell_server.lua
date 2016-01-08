require "storm"
require "string"
require "cord"

-- SENDFUNCS maps a socket's FD to a function to send data on that socket
sendfuncs = {}

-- For each socket, we create a cord, which needs to be cancelled if the connection is broken
-- CORDS maps a socket's FD to the cord that is running its interactive session
cords = {}

function do_nothing() end

-- Create server socket
lstnsock = storm.net.tcppassivesocket()

-- Bind socket to port 74
storm.net.tcpbind(lstnsock, 74)

function broadcast(str)
    for k, v in pairs(queues) do
        if v ~= nil then
            v:enqueue(str)
        end
    end
end

function connection_lost(how, sock)
    local fd = storm.net.tcpfd(sock)
    local c = cords[fd]
    cords[fd] = nil
    sendfuncs[fd] = nil
    
    cord.cancel(c)
    
    conn_lost_signal() -- signal waiting thread, if any, to start
end

local conn_lost_signal = do_nothing

-- Accept incoming connection requests
cord.new(function ()
    local clntsock
    local cfd
    while true do
        while true do
            storm.os.setoutputhook(broadcast)
            clntsock, a, port, b = cord.await(storm.net.tcplistenaccept, lstnsock)
            storm.os.setoutputhook(broadcast)
            if clntsock == nil then
                -- Wait until a connection is lost
                cord.await(function (cb) conn_lost_signal = cb end)
                conn_lost_signal = do_nothing
            else
                break
            end
        end
        -- At this point, clntsock is the client socket
        storm.net.tcpaddconnectionlost(clntsock, connection_lost)
        cfd = storm.net.tcpfd(clntsock)
        cords[cfd] = cord.new(function () remote_shell(clntsock) end)
    end
end)

local readchunksize = 100
local SENDBUF_MAX = 250 -- Maximum number of queued bytes to send on any single socket
-- Accept commands from and send output to the remote user
function remote_shell(csock)
    local fd = storm.net.tcpfd(csock)
    if not storm.net.tcpisestablished(csock) then
        cord.await(storm.net.tcpaddconnectdone, csock)
    end
    local maxedbuffer = false
    local outputhook = function (str)
        local outstanding = storm.net.tcpoutstanding(csock)
        if storm.net.tcpoutstanding(csock) < SENDBUF_MAX then
            if maxedbuffer then
                storm.net.tcpsend(csock, "{ Shell Server: Can send data again. }\n")
            end
            maxedbuffer = false
            storm.net.tcpsend(csock, str)
        else
            if not maxedbuffer then
                storm.net.tcpsend(csock, "{ Shell Server: Send buffer full. Dropping characters... }\n")
            end
            maxedbuffer = true
        end
    end
    sendfuncs[fd] = outputhook
    
    local buf
    local chunk
    
    storm.net.tcpsend(csock, "\27[34;1mstormsh> \27[0m")
    
    while true do
        storm.os.setoutputhook(broadcast) -- before yielding
        
        -- Wait until something is in the receive buffer
        buf = cord.await(storm.net.tcprecvfull, csock, 1)
        
        -- We may have yielded to another cord while waiting, so restore output redirection
        storm.os.setoutputhook(outputhook)
        
        -- Then empty the receive buffer completely
        repeat
            _, chunk = storm.net.tcprecv(csock, readchunksize)
            buf = buf .. chunk
        until string.len(chunk) ~= readchunksize
        
        -- Now, buf contains a line of input, so execute it
        storm.os.stormshell(buf)
    end
end

cord.enter_loop()
