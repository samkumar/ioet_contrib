

-- singleton
local SVCD = {
    OK=1,
    TIMEOUT=2,
    manifest = {},
    dmanifest = {},
    transactions = {},
    nxt_time=nil,
    th = nil
}

--[[ TODO
SVCD.scan_transactions = function()
    local now = storm.os.now(storm.os.SHIFT_0)
    for k,v in pairs(SVCD.transactions) do
        if v[1] <= now then
    end
end
SVCD.trSetup = function(src_ip, src_port, ikvid, time, fn, args)
    if manifest[fn] ~= nil then
        SVCD.transactions[ivkid] = {time, fn, args }
        if SVCD.nxt_time and time < SVCD.nxt_time then
            storm.os.cancel(SVCD.th)
            local now = storm.os.now(storm.os.SHIFT_0)
            if now >= time then
                print "MISSED TR DEADLINE"
                return
            end

            SVCD.th = storm.os.invokeLater(time-now, SVCD.scan_transactions)
        end
    end
end
SVCD.trAbort = function(ikvid)
end
]]--
SVCD.dispatch = function(payload, src_ip, src_port)
    print "dispatch"
    local t = storm.mp.unpack(payload)
    -- a well formed payload should be a list of two elements
    -- the first being a function name, and the second being a table of
    -- arguments
    local fn = t[1]
    local args = t[2]
    if fn == nil or args == nil then
        print "[SVCD] Ignoring bad fn ivk"
    end
    if SVCD.manifest[fn] == nil then
       print "[SVCD] Attempt to invoke unoffered service"
    else
        -- spawn a new cord so that async function handlers can
        -- be written
        print ("[SVCD] Invoking",fn)

        -- I have implemented transaction setup and cancel as
        -- layer-breaking services so that they can broadcast
        -- their replies and hook into the services manifest
        if (fn == "trSetup") then
            SVCD.trSetup(src_ip, src_port, unpack(args))
        elseif (fn == "trAbort") then
            SVCD.trAbort(unpack(args))
        else
            cord.new(function()
                local rv = SVCD.manifest[fn](unpack(args))
                storm.net.sendto(SVCD.ssock, storm.mp.pack(rv), src_ip, src_port)
            end)
        end
    end
end

SVCD.advertise = function()
    storm.net.sendto(SVCD.asock, storm.mp.pack(SVCD.dmanifest), "ff02::1", 1527)
end

SVCD.cdispatch = function(pay, srcip, srcport)
    if SVCD._cdispatch ~= nil then
        SVCD._cdispatch(pay, srcip, srcport)
        SVCD._cdispatch = nil
    end
end
SVCD.adispatch = function(pay, srcip, srcport)
    -- I am not implementing a real service discovery table
    -- management thingy here, just making sure it is possible
    local adv = storm.mp.unpack(pay)
    print (string.format("Service advertisment %s", srcip))
    for k,v in pairs(adv) do
        print ("  " .. k .. ":")
        for kk,vv in pairs(v) do
            print ("    >"..kk..":"..vv)
        end
    end
end
SVCD.init = function(id)
   SVCD.id = id
   SVCD.ssock = storm.net.udpsocket(1525, SVCD.dispatch)
   SVCD.csock = storm.net.udpsocket(1526, SVCD.cdispatch)
   SVCD.asock = storm.net.udpsocket(1527, SVCD.adispatch)
   SVCD.eph = 32768 --start of ephemeral range
   storm.os.invokePeriodically(3*storm.os.SECOND, SVCD.advertise)
end

SVCD.invoke = function (targetip, fn, args, timeout_ms, onreply)
    local eph = SVCD.eph
    SVCD.eph = SVCD.eph + 1
    if SVCD.eph > 65535 then
        SVCD.eph = 32768
    end
    local has_been_invoked = false
    local tmr = storm.os.invokeLater(timeout_ms*storm.os.MILLISECOND, function()
        print "timeout tmr"
        if not has_been_invoked then
            has_been_invoked = true
            onreply(SVCD.TIMEOUT)
            SVCD._cdispatch = nil
        end
    end)
    SVCD._cdispatch = function(pay, srcip, srcport)
        print "got response"
        if has_been_invoked then return end
        storm.os.cancel(tmr)
        has_been_invoked = true
        local upay = storm.mp.unpack(pay)

        print ("upay:",upay)
        print ("uplen:",#upay)
        print ("2, ",upay[2])
        print ("3, ",upay[3])
        onreply(SVCD.OK, unpack(upay))
    end
    storm.net.sendto(SVCD.csock, storm.mp.pack({fn, args}), targetip, 1525)
end

SVCD.register = function(svcname, descriptor, fn)
    SVCD.manifest[svcname] = fn
    SVCD.dmanifest[svcname] = descriptor
end


return SVCD