require "cord"
sh = require "stormsh"
sh.start()

-- So if you type go() from the terminal, it runs this.
function go ()
    print("doing init")
    -- spi mode 0 == (0, 0). read the wiki page for SPI if you don't know what that is
    -- the baud rate is 1M
    storm.spi.init(0,1000000)
    -- CS is done manually, because sometimes you need to chain multiple transfers with
    -- CS still down
    storm.spi.setcs(1)
    storm.os.invokePeriodically(100*storm.os.MILLISECOND, function()
        -- SPI takes a TX array and an (empty) RX array. The length of the transfer
        -- is determined by the TX array, the RX array can be longer than TX if required
        local tx = storm.array.create(16, storm.array.UINT8)
        local rx = storm.array.create(16, storm.array.UINT8)
        tx:set(1, 0xAA)
        tx:set(2, 0xAB)
        tx:set(3, 0xAC)
        tx:set(4, 0xAD)
        storm.spi.setcs(0)
        -- Write out the TX bytes, and store the received bytes in RX
        storm.spi.xfer(tx, rx, function()
            -- When the transfer is complete, this function is invoked.
            -- you can access the RX array in this closure. Even if the
            -- RX and TX arrays go out of scope, libstorm will pin them
            -- so they won't be GC'd.
            storm.spi.setcs(1)
        end)
    end)
end

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
