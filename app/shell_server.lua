require "storm"
require "string"
require "cord"
AsyncQueue = require "aqueue"

-- For each socket, we need a queue of messages to send
-- QUEUES maps a socket's FD to an AsyncQueue of messages
queues = {}

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
    local queue = queues[fd]
    queues[fd] = nil
    
    queue:reset()
    
    conn_lost_signal() -- signal waiting threads to start
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
        queues[cfd] = nil
        storm.net.tcpaddconnectdone(clntsock, function () queues[cfd] = "done" end)
        cord.new(function () remote_shell(clntsock) end)
    end
end)

local readchunksize = 100
-- Accept commands from and send output to the remote user
function remote_shell(csock)
    local fd = storm.net.tcpfd(csock)
    if queues[fd] == nil then
        cord.await(storm.net.tcpaddconnectdone, csock)
    end
    local queue = AsyncQueue:new(function (str, cb)
        storm.net.tcpsendfull(csock, str, cb)
    end)
    queues[fd] = queue
    local outputhook = function (str)
        queue:enqueue(str)
    end
    local buf
    local chunk
    
    queue:enqueue("\27[34;1mstormsh> \27[0m")
    
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
