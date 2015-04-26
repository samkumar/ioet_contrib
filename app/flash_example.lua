require "cord"
sh = require "stormsh"
sh.start()

-- So if you type go() from the terminal, it runs this.
function go ()

    local rx = storm.array.create(16, storm.array.UINT8)
    local tx = storm.array.fromstr("this is on flash")

    storm.flash.read(0, rx, function()
        print("The flash contained: '"..rx:as_str().."'")

        storm.flash.write(0, tx, function() end)

        print("Try rebooting your device!")
    end)

end

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
