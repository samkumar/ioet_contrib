
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

function trA(v)
    cord.new(function()
        local remtime
        local stat
        for i=1,15 do
            stat, remtime = cord.await(svcd.invoke,"fe80::212:6d02:0:304E", "getNow", {}, 800)
            if stat == svcd.OK then
                print ("got remote time: "..remtime)
                break
            end
        end
        if stat ~= svcd.OK then
            print "aborting, could not get remote time"
            return
        end
        local trigtime = remtime+(12*storm.os.SECOND_S16)
        local enterabort = true
        for i=1,10 do
            stat = cord.await(svcd.invoke,"fe80::212:6d02:0:304E",
                "trSetup", {187, trigtime, "setRlyA", {v}}, 500)
            if stat == svcd.OK then
                print ("setup transaction")
                enterabort = false
                break
            end
        end

        if enterabort then
            print "trying to abort transaction"
            for i=1,10 do
                stat = cord.await(svcd.invoke,"fe80::212:6d02:0:304E",
                    "trAbort", {187}, 500)
                if stat == svcd.OK then
                    print ("aborted transaction")
                    break
                end
            end
        end
    end)
end

cord.enter_loop()