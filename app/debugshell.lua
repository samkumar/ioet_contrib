
require "cord"
sh = require "stormsh"
LCD = require "LCD"
ACCEL = require "accel"

-- start a coroutine that provides a REPL
sh.start()

test_lcd = function(x)
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


function sleep(n)
    print("we got called")
    cord.await(storm.os.invokeLater, n*storm.os.SECOND)
    print("we are done")
end

t2 = function()
    cord.new(function()
        print "starting t2"
        a,b,c,d = cord.nc(storm.n.helloN, 5)
        print "ending t2"
        print ("retvals: ",a,b,c,d)
    end)
end

t3 = function()
    cord.new(function()
        print "starting t3"
        a,b,c,d = cord.nc(storm.n.helloX, 5, 2*storm.os.SECOND)
        print "ending t3"
        print ("retvals: ",a,b,c,d)
    end)
end

t = function()
    cord.new(function()
            h = ACCEL:new()
            h:init()
            while true do
               print ("acc: ", h:get())
               cord.await(storm.os.invokeLater, 5*storm.os.SECOND)
            end
    end)
end

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
