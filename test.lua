require("storm")

storm.n.init_membuffer()

local times = 0
storm.os.invokePeriodically(storm.os.SECOND, function ()
        print(times)
        times = times + 1
    end)
    
while true do
    storm.os.wait_callback()
end
