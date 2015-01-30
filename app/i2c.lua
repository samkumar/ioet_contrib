LCD = require("LCD")

require "cord"
sh = require "stormsh"

ictest = function()
    cord.new(function()
        LCD.init(2, 0)
        LCD.data(0x68)
        LCD.data(0x65)
        LCD.data(0x6c)
        LCD.data(0x6c)
        LCD.data(0x6f)
        LCD.data(0x20)
        LCD.data(0x77)
        LCD.data(0x6f)
        LCD.data(0x72)
        LCD.data(0x6c)
        LCD.data(0x64)
    end)
end


-- start a coroutine that provides a REPL
sh.start()

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
