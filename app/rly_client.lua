
svcd = require "svcd"
sh = require "stormsh"
sh.start()

svcd.init()
function setA(v)
    cord.new(function()
        rvA, rvB, rvC = cord.await(svcd.invoke, "fe80::212:6d02:0:304E", "setRlyA", {v}, 2000)
        print ("rvs", rvA, rvB, rvC)
    end)
end

cord.enter_loop()