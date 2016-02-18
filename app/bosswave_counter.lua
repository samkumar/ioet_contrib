require "cord"
sh = require "stormsh"
require "string"
Display = require "sseg"

localrouter_ip = "2607:f140:400:a008:1c3d:9858:896d:79a"
localrouter_port = 28589

uri = "castle.bw2.io/hamilton/1003/accel"--"castle.bw2.io/sam/led"

fsentity = string.char(0x8c, 0xa9, 0x82, 0xcd, 0xed, 0x42, 0x76, 0xb8, 0x19, 0xc1, 0x6d, 0xfe, 0x29, 0xba, 0x62, 0xae, 0xac, 0x98, 0xec, 0xce, 0x22, 0x87, 0x9d, 0x75, 0x1e, 0x71, 0xdb, 0xbd, 0x2b, 0xdf, 0x2d, 0x2f, 0x8f, 0x4a, 0x9b, 0xed, 0xe, 0x22, 0x3b, 0x62, 0x36, 0x83, 0x59, 0x3f, 0x14, 0x9a, 0x2d, 0x77, 0x0, 0xe0, 0xe, 0xb6, 0xd, 0x3b, 0xa5, 0x3e, 0x37, 0x1a, 0x51, 0xd6, 0x40, 0xfb, 0x73, 0xc0, 0x2, 0x8, 0xbb, 0xa1, 0xe4, 0x91, 0xc, 0xcf, 0x31, 0x14, 0x3, 0x8, 0xd5, 0x9a, 0x15, 0xe3, 0x3a, 0x99, 0x3e, 0x14, 0x5, 0x20, 0x53, 0x61, 0x6d, 0x20, 0x4b, 0x75, 0x6d, 0x61, 0x72, 0x20, 0x3c, 0x73, 0x61, 0x6d, 0x6b, 0x75, 0x6d, 0x61, 0x72, 0x39, 0x39, 0x40, 0x67, 0x6d, 0x61, 0x69, 0x6c, 0x2e, 0x63, 0x6f, 0x6d, 0x3e, 0x6, 0x15, 0x46, 0x69, 0x72, 0x65, 0x73, 0x74, 0x6f, 0x72, 0x6d, 0x20, 0x31, 0x20, 0x66, 0x6f, 0x72, 0x20, 0x42, 0x45, 0x41, 0x52, 0x53, 0x0, 0x73, 0xf0, 0xb0, 0x27, 0x28, 0xc4, 0x16, 0xac, 0x58, 0x7f, 0x87, 0x65, 0x48, 0x65, 0xcc, 0xfe, 0x6e, 0x38, 0x82, 0x80, 0x7c, 0x2b, 0x93, 0xa8, 0xdd, 0x80, 0xc6, 0x35, 0x49, 0x72, 0x27, 0x3, 0xc, 0x24, 0x96, 0xe2, 0xca, 0x5a, 0x9e, 0x32, 0x65, 0xe9, 0x32, 0xda, 0xf9, 0xac, 0x95, 0x8a, 0x41, 0xf4, 0xd, 0x9a, 0x17, 0xdc, 0xb8, 0xa, 0xf2, 0x1f, 0x47, 0xd6, 0x83, 0xc1, 0x21, 0xe)

-- Create active socket
csock = storm.net.tcpactivesocket()

-- Bind socket to port 1025
storm.net.tcpbind(csock, 1025)

seqno = 0
function getseqno()
    seqno = seqno + 1
    return seqno
end

prevsend = nil
function connection_lost(how, socket)
    if how ~= 0 then -- connection broken
        if prevsend ~= nil then
            cord.cancel(prevsend) -- connect failed, so stop this cord
            prevsend = nil
        end
        print("Attempting to connect")
        storm.os.invokeLater(storm.os.SECOND, function ()
            prevsend = cord.new(function ()
                handleconnection(socket)
            end)
        end)
    else
        storm.net.tcpclose(socket)
        print("Closed socket")
        -- End of program
    end
end

function readbw2(clsock)
    local msgtype, seqno, framelen = cord.await(storm.bw.recvhdr, clsock)
    print("Received " .. msgtype .. " (seqno = " .. seqno .. ")")
    if msgtype == nil then
        resetconn(clsock)
    end
    local table = {}
    while true do
        ftype, key, val = cord.await(storm.bw.recvfield, clsock)
        if ftype == nil or ftype == "end" then
            break
        end
        table[key] = val
        print(ftype .. ": key = " .. key .. ", value = " .. val)
    end
    print()
    return msgtype, seqno, table
end
--[[
function readbw2messages(clsock)
    local introframe = true
    while true do
        local msgtype, seqno, framelen = cord.await(storm.bw.recvhdr, clsock)
        print("Received " .. msgtype .. " (seqno = " .. seqno .. ")")
        while true do
            ftype, key, val = cord.await(storm.bw.recvfield, clsock)
            if ftype == nil or ftype == "end" then
                break
            end
            print(ftype .. ": key = " .. key .. ", value = " .. val)
        end
        print()
        introframe = false
    end
end
]]
Display:init()
opencount = 0
Display:num(opencount)

function resetconn(clsock)
    print("FAILED: restarting")
    storm.net.tcpabort(clsock)
    cord.await(function () end) -- block until the cord is terminated by connectionlost handler
end

function handleconnection(clsock)
    local msgtype, seqno, dict, chain, subshandle, payload, state
    
    cord.await(storm.net.tcpconnect, clsock, localrouter_ip, localrouter_port, 2000)
    
    -- Deal with useless connection frame
    _, _, _ = readbw2(clsock)
    
    local msgseqno = getseqno()
    --print("Sending " .. msgseqno)
    storm.bw.sendmsg(clsock, msgseqno, "sete", {}, {["1.0.1.2:"] = fsentity}, {})
    
    msgtype, seqno, dict = readbw2(clsock)
    local vk = dict["vk"]
    
    --print("VK is " .. vk)
    
    msgseqno = getseqno()
    print("Sending " .. msgseqno)
    storm.bw.sendmsg(clsock, msgseqno, "bldc", {["uri"] = uri, ["to"] = vk, ["accesspermissions"] = "C*"}, {}, {})
    msgtype, seqno, dict = readbw2(clsock)
    if msgtype == "resp" and dict["status"] == "okay" then
        while dict["finished"] ~= "true" do
            msgtype, seqno, dict = readbw2(clsock)
            if msgtype == "rslt" and dict["hash"] ~= nil then
                chain = chain or dict["hash"]
            elseif dict["status"] == "error" then
                resetconn(clsock)
            end
        end
    end
    
    msgseqno = getseqno()
    --print("Sending " .. msgseqno)
    storm.bw.sendmsg(clsock, msgseqno, "subs", {["uri"] = uri, ["primary_access_chain"] = chain, ["elaborate_pac"] = "full", ["unpack"] = "true"}, {}, {})
    msgtype, seqno, dict = readbw2(clsock)
    if dict["status"] ~= "okay" or dict["handle"] == nil then
        resetconn(clsock)
    else
        subshandle = dict["handle"]
    end
    
    print("Ready")
    
    while true do
        msgtype, seqno, dict = readbw2(clsock)
        payload = dict["2.0.4.64:33555520"]
        if payload ~= nil then
            payload = storm.mp.unpack(payload)
            if payload["AT"] then
                print("OPEN")
                opencount = (opencount + 1) % 10000
                Display:num(opencount)
            end
            collectgarbage("collect")
        end
        cord.yield()
    end
end

cord.new(function ()
    storm.net.tcpaddconnectionlost(csock, connection_lost)
    connection_lost(1, csock)
end)

-- start a coroutine that provides a REPL
sh.start()

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
