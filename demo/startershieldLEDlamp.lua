require "cord"
require "svcd"
sh = require("stormsh")
shield = require("starter")
shield.LED.start()

green = 0

function buzz()
    cord.new(function()
        shield.Buzz.go()
        cord.await(storm.os.invokeLater, 100*storm.os.MILLISECOND)
        shield.Buzz.stop()
    end)
end

actFan = function(state)
    if state == 1 then
        green = 1
        shield.LED.on("green")
    else
        green = 0
        shield.LED.off("green")
    end
    buzz()
end

sock = storm.net.udpsocket(1234, function(payload, from, port)
    print (string.format("from %s port %d: %s",from,port,payload))
    actFan(storm.mp.unpack(payload))
end)

-- cord.new(function()
--     storm.os.invokePeriodically(1 * storm.os.SECOND, function()
--         cord.new( function()
--             storm.net.sendto(sock, storm.mp.pack(green), "2001:470:66:3f9::2", 1234)
--         end)
--     end)
-- end)

SVCD.init("firestormSensor", function()
    print "starting SVCD"
    SVCD.add_service(0x300e)
    SVCD.add_attribute(0x300e, 0x401a, function(pay, ip, port)
        print (pay)
        actFan(pay)
    end)
    cord.new(function()
        while true do
            SVCD.notify(0x300e, 0x401a, green)
            cord.await(storm.os.invokeLater, storm.os.SECOND)
        end
    end)
end)



sh.start()
cord.enter_loop()
