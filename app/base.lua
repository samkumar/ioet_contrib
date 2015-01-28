require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library
print ("Base  test ")

sh = require "stormsh"
LED = require("LED")

-- blue LED plugged into LED board attached to shield pin D2

blue = LED:new("D2")

blue:flash(5)

-- start a shell so you can play more

-- start a coroutine that provides a REPL
sh.start()

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
