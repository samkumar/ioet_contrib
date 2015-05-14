require "cord"
sh = require "stormsh"
sh.start()

storm.io.set_mode(storm.io.OUTPUT, storm.io.GP0)

osock = storm.net.udpsocket(3999, function()  end)

storm.net.udpsocket(4001, function(payload)
    storm.io.set(2, storm.io.GP0)
end)

storm.os.invokePeriodically(500*storm.os.MILLISECOND, function()
    storm.net.sendto(osock, "foo","ff02::1", 4000)
end)

storm.bl.enable("blah", function(x)
    print ("Got conn",x)
end, function()
    local sh = storm.bl.addservice(0x1337)
    storm.bl.addcharacteristic(sh, 0x2448, function(pay)
    print ("Got write:",pay)
    end)
end)

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
