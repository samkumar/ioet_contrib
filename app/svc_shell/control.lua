
require "cord"
sh = require "stormsh"
require "svcd"

sh.start()
SHELLSVC = 0x3006
AT_INIT = 0x400d
AT_VERIFY = 0x400b
AT_EXECUTE = 0x400c
AT_SET = 0x400a

SVCD.init("foo", function() end)
function rexec(serial, command)
    cord.new(function()
        local target = "fe80::212:6d02:0:"..serial
        local chunks = {}
        local idx = 1
        while idx <= #command do
            table.insert(chunks, string.sub(command, idx, idx+17))
            idx = idx + 18
        end
        print ("Segmentation complete: "..#chunks.." chunks")
        while not cord.await(SVCD.write, target, SHELLSVC, AT_INIT, string.char(#chunks), 1000) == SVCD.OK do
            print "Init command timeout"
        end
        for i, v in pairs(chunks) do
            local payload = string.char(i)..string.char(#v)..v
            while not cord.await(SVCD.write, target, SHELLSVC, AT_SET, payload, 1000) == SVCD.OK do
                print ("Setchunk("..i..") command timeout")
            end
        end
        while not cord.await(SVCD.write, target, SHELLSVC, AT_EXECUTE, string.char(#chunks), 1000) == SVCD.OK do
            print ("Execute command timeout")
        end
        print "Done"
    end)
end

function t()
    rexec("3122", [[
        storm.io.set_mode(storm.io.OUTPUT, storm.io.GP0)
        storm.io.set(1, storm.io.GP0)
]])
end
function t2()
    rexec("3122", [[
        print("hello world")
]])
end
cord.enter_loop()