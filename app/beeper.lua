require "cord"
sh = require "stormsh"
sh.start()

storm.io.set_mode(storm.io.OUTPUT, storm.io.D4)

function beep()
    cord.new(function()
        for i = 1,3 do
            storm.io.set(1, storm.io.D4)
            cord.await(storm.os.invokeLater, 1*storm.os.MILLISECOND)
            storm.io.set(0, storm.io.D4)
            cord.await(storm.os.invokeLater, 1*storm.os.MILLISECOND)
        end
    end)
end

osock = storm.net.udpsocket(3999, function()  end)
ivkid = 0
storm.net.udpsocket(4000, function(payload)
    beep()
    storm.net.sendto(osock, "foo", "ff02::1", 4001)
end)

cord.new(function()
    beep()
    cord.await(storm.os.invokeLater, 2*storm.os.SECOND)
    beep()
    cord.await(storm.os.invokeLater, 2*storm.os.SECOND)
    beep()
    cord.await(storm.os.invokeLater, 2*storm.os.SECOND)
    beep()
end)

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
