require "cord"
require "bearcast"
sh = require "stormsh"

-- start a coroutine that provides a REPL
sh.start()

MyDeviceName = "example"

cord.new(function()
    cord.await(SVCD.init, MyDeviceName)
    -- The second parameter specifies verbose mode.
	BEARCAST.init(MyDeviceName, true)

    --here you can add extra services or extra logic
    --for example, display a mesage after a while:
    storm.os.invokeLater(10*storm.os.SECOND, function()
        cord.new(function()
            BEARCAST.postToClosestDisplay(MyDeviceName.." has started up")
        end)
    end)

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
        cord.new(function()
            BEARCAST.postToClosestDisplay("Got echo msg '"..echomsg.."'")
        end)
    end)


end)


-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
