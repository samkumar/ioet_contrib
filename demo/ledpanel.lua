require "cord"
require "bearcast"
sh = require "stormsh"

-- LED Panel specific globals
-- red is d4, green d5, blue d6
storm.io.set_mode(storm.io.OUTPUT, storm.io.D4, storm.io.D5, storm.io.D6)
storm.io.set(0, storm.io.D4, storm.io.D5, storm.io.D6)


-- start a coroutine that provides a REPL
sh.start()

MyDeviceName = "LedPanel"

cord.new(function()
    cord.await(SVCD.init, MyDeviceName)
    -- The second parameter specifies verbose mode.
	BEARCAST.init(MyDeviceName, true)

    --here you can add extra services or extra logic
    --for example, display a message after a while:
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
	cord.new(function()
		for i=1,flashcount do
			if lednum == 1 then
			    storm.io.set(1, storm.io.D4)
			end
			if lednum == 2 then
			    storm.io.set(1, storm.io.D5)
			end
			if lednum == 3 then
			    storm.io.set(1, storm.io.D4)
			    storm.io.set(1, storm.io.D5)
			end
			if lednum == 4 then
			    storm.io.set(1, storm.io.D6)
			end
			if lednum == 5 then
			    storm.io.set(1, storm.io.D4)
			    storm.io.set(1, storm.io.D6)
			end
			if lednum == 6 then
			    storm.io.set(1, storm.io.D5)
			    storm.io.set(1, storm.io.D6)
			end
			if lednum == 7 then
			    storm.io.set(1, storm.io.D4)
			    storm.io.set(1, storm.io.D5)
			    storm.io.set(1, storm.io.D6)
			end	
			cord.await(storm.os.invokeLater, 700*storm.os.MILLISECOND)
			storm.io.set(0, storm.io.D4)
			storm.io.set(0, storm.io.D5)
			storm.io.set(0, storm.io.D6)
			cord.await(storm.os.invokeLater, 700*storm.os.MILLISECOND)				
		end
	end)
	

        print ("got a request to flash led",lednum, " x ", flashcount)
        
    end)
    -- LED control attribute
    SVCD.add_attribute(0x3003, 0x4006, function(pay, srcip, srcport)
        local ps = storm.array.fromstr(pay)
        local lednum = ps:get(1)
        local duration = ps:get_as(storm.array.INT16, 1)
        print ("got a request to turn on led",lednum, " for ", duration)
        if lednum == 1 then
	    storm.io.set(1, storm.io.D4)
	end
	if lednum == 2 then
	    storm.io.set(1, storm.io.D5)
	end
	if lednum == 3 then
	    storm.io.set(1, storm.io.D4)
	    storm.io.set(1, storm.io.D5)
	end
	if lednum == 4 then
	    storm.io.set(1, storm.io.D6)
	end
	if lednum == 5 then
	    storm.io.set(1, storm.io.D4)
	    storm.io.set(1, storm.io.D6)
	end
	if lednum == 6 then
	    storm.io.set(1, storm.io.D5)
	    storm.io.set(1, storm.io.D6)
	end
	if lednum == 7 then
	    storm.io.set(1, storm.io.D4)
	    storm.io.set(1, storm.io.D5)
	    storm.io.set(1, storm.io.D6)
	end
        if duration > 0 then
            storm.os.invokeLater(duration*storm.os.MILLISECOND, function()
              storm.io.set(0, storm.io.D4)
	      storm.io.set(0, storm.io.D5)
	      storm.io.set(0, storm.io.D6)    
            end)
        end
    end)

end)


-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
