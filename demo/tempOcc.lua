require "cord"
require "svcd"
TEMP = require("temp")
sh = require("stormsh")

temp = TEMP:new()
occ = 0

SVCD.init("tempOccSensor", function()
    print "starting SVCD"
    SVCD.add_service(0x300f)
    SVCD.add_attribute(0x300f, 0x401b, function(pay, ip, port)
    end)
    SVCD.add_attribute(0x300f, 0x401c, function(pay, ip, port)
    end)
    cord.new(function()
        while true do
            SVCD.notify(0x300f, 0x401b, temp:getTemp())
            cord.await(storm.os.invokeLater, 500*storm.os.MILLISECOND)
            SVCD.notify(0x300f, 0x401c, occ)
            cord.await(storm.os.invokeLater, storm.os.SECOND)
        end
    end)
end)

sock = storm.net.udpsocket(1237, function(payload, from, port)
    print (string.format("from %s port %d: %s",from,port,payload))
end)

cord.new(function()
    pin = storm.io.A0
    storm.io.set_mode(storm.io.INPUT, pin)
    cord.await(storm.os.invokeLater, storm.os.SECOND)
    cord.new(function()
        while (1) do
            occ = storm.io.get(pin)
            cord.await(storm.os.invokeLater, storm.os.SECOND)
        end
    end)
end)

-- cord.new(function()
--     temp:init()
-- 
--     storm.os.invokePeriodically(1 * storm.os.SECOND, function()
--         cord.new( function()
--             local now = temp:getTemp()
--             print(string.format("temp %d occ %d", now, occ))
--             storm.net.sendto(sock, storm.mp.pack({now, occ}), "2001:470:66:3f9::2", 1237)
--         end)
--     end)
-- end)


sh.start()
cord.enter_loop()
