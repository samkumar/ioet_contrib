require "cord"
require "svcd"
sh = require "stormsh"

ACC = require "accel"

-- start a coroutine that provides a REPL
sh.start()

MyDeviceName = "Accelerometer Demo"

cord.new(function()
    cord.await(SVCD.init, MyDeviceName)
    -- The second parameter specifies verbose mode.
	-- BEARCAST.init(MyDeviceName, true)

    --here you can add extra services or extra logic
    --for example, display a mesage after a while:
    --[[storm.os.invokeLater(10*storm.os.SECOND, function()
        cord.new(function()
            BEARCAST.postToClosestDisplay(MyDeviceName.." has started up")
        end)
    end)]]--

    -- or add an echo service that will appear on 15.4 and bluetooth
    -- the service numbers are listed in the manifest:
    -- https://github.com/UCB-IoET/svc/blob/master/manifest.json
    -- Feel free to add new ones by sending pull requests
    local echomsg = "unset"
    SVCD.add_service(0x300c)
    -- Attributes are similarly listed in the manifest
    SVCD.add_attribute(0x300c, 0x4018, function(value)
        -- this function is executed when the attribute is changed
        echomsg = value
        -- notify future readers and currently subscribed clients of the
        -- new value
        SVCD.notify(0x300c, 0x4018, echomsg)
        -- also for fun send it to the nearest monitor
        --[[cord.new(function()
            BEARCAST.postToClosestDisplay("Got echo msg '"..echomsg.."'")
        end)]]--
    end)

    -- DEVICE-SPECIFIC CODE
    SVCD.add_service(0x3005)
    SVCD.add_attribute(0x3005, 0x4009, function (value, srcip, srcport)
        --cord.new(function ()
            print("Attempt to change reading to " .. value)
        --end)]]
    end)
    
    local acc = ACC:new()
    acc:init()
    local arr = storm.array.create(6, storm.array.INT16)
    -- Notify the accelerometer reading every second
    cord.new(function ()
        while true do
            local ax, ay, az, mx, my, mz
            ax, ay, az, mx, my, mz = acc:get()
            arr:set(1, ax)
            arr:set(2, ay)
            arr:set(3, az)
            arr:set(4, mx)
            arr:set(5, my)
            arr:set(6, mz)
            SVCD.notify(0x3005, 0x4009, arr:as_str())
            cord.await(storm.os.invokeLater, storm.os.SECOND)
        end
    end)
end)


-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
