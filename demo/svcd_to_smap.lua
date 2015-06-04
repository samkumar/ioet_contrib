require "cord"
require "svcd"


--sendto = "2001:470:66:3f9::2"
sendto = "2001:470:66:761::2"
local seen = {}
egress = storm.net.udpsocket(1337, function() end)
function got_data(data, srcip, service, attribute)
    print ("Got data, sending")
    storm.net.sendto(egress, storm.mp.pack({data,string.sub(srcip,-4),attribute}),sendto, 9001)
end

SVCD.init("border", function()
    SVCD.advert_received = function(pay, srcip, srcport)
        local adv = storm.mp.unpack(pay)
        local key = string.sub(srcip,#srcip-4)
        print (string.format("Service advertisment %s", srcip))
        for k,v in pairs(adv) do

            if k == "id" then
                print ("ID="..v)
            else
                print (string.format("  0x%04x:",k))
                for kk,vv in pairs(v) do
                    --k is the service
                    --vv is the attribute here
                    local lkey = key..string.format("%04x",vv)
                    seen[lkey] = {srcip,k,vv}
                    print (string.format("   >%d: 0x%04x", kk, vv))
                end
            end
        end
    end

    storm.os.invokePeriodically(20*storm.os.SECOND, function()
        for k, v in pairs(seen) do
            print ("Subscribing to ",v[3])
            SVCD.subscribe(v[1], v[2], v[3], got_data)
        end
    end)
end)

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
