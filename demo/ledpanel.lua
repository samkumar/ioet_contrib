require "cord"
require "bearcast"
sh = require "stormsh"

-- LED Panel specific globals
-- We don't NEED to use the LED class, this is just showing how we
-- would use code from third parties to marginally improve our lives
local LED = require "led"
lr = LED:new("D4")
lg = LED:new("D5")
lb = LED:new("D6")

-- start a coroutine that provides a REPL
sh.start()

MyDeviceName = "LedPanel"

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

    -- DEVICE SPECIFIC CODE
    -- This is what makes us an LED Panel
    SVCD.add_service(0x3003)
    -- LED flash attribute
    SVCD.add_attribute(0x3003, 0x4005, function(pay, srcip, srcport)
        local ps = storm.array.fromstr(pay)
        local lednum = ps:get(1)
        local flashcount = ps:get(2)
        print ("got a request to flash led",lednum, " x ", flashcount)
        if lednum == 0 then
            lr:flash(flashcount,300)
        end
        if lednum == 1 then
            lg:flash(flashcount,300)
        end
        if lednum == 2 then
            lb:flash(flashcount,300)
        end
    end)
    -- LED control attribute
    SVCD.add_attribute(0x3003, 0x4006, function(pay, srcip, srcport)
        local ps = storm.array.fromstr(pay)
        local lednum = ps:get(1)
        local duration = ps:get_as(storm.array.INT16, 1)
        print ("got a request to turn on led",lednum, " for ", duration)
        local target
        if lednum == 0 then
            target=lr
        end
        if lednum == 1 then
            target=lg
        end
        if lednum == 2 then
            target=lb
        end
        if duration > 0 then
            target:on()
            storm.os.invokeLater(duration*storm.os.MILLISECOND, function()
                target:off()
            end)
        elseif duration == 0 then
            target:off()
        else
            target:on()
        end
    end)

end)


-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
