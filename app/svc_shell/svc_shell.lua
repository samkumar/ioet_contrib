
require "cord"
sh = require "stormsh"
require "svcd"
--LCD = require "LCD"

sh.start()

local verify_char

local shell_expected
local chunks = {}
-- This is the onwrite func
function setchunk(val)
    print "gsc"
    local idx = string.byte(val)
    local len = string.byte(val, 2)
    print ("len:",len)
    chunks[idx] = string.sub(val, 3, 3+len-1)
    print ("got setchunk "..idx.." content: "..chunks[idx])
    do_verify()
end
function execute(val)
    print ("got execute")
    for i, s in pairs(chunks) do
        print ("chunk: '"..s.."'")
        storm.os.stormshell(s)
    end
    chunks = {}
    shell_expected = {}
end
function verify(val)
    -- we do nothing on verify write
end
function do_verify()
    local cnt = 0
    for i=1,shell_expected do
        if chunks[i] == nil then cnt = cnt + 1 end
    end
    local missing = storm.array.create(cnt+2, storm.array.UINT8);
    missing:set(1, shell_expected)
    missing:set(2, cnt)
    cnt = 0
    for i=1,shell_expected do
        if cnt < 10 then
            if chunks[i] == nil then
                missing:set(2+cnt, i)
                cnt = cnt + 1
            end
        end
    end
    print "Sending verify:"
    for i=1,(cnt+2) do
        print (i.." > "..missing:get(i))
    end
    SVCD.notify(0x3006, 0x400b, missing:as_str())
end
function init(val)

    shell_expected = string.byte(val)
    print ("Got init: ",shell_expected)
    chunks = {}
    do_verify()
end

function onready()
    cord.new(function()
        SVCD.add_service(0x3006)
        cord.await(storm.os.invokeLater,500*storm.os.MILLISECOND)
        SVCD.add_attribute(0x3006, 0x400a, setchunk)
        cord.await(storm.os.invokeLater,500*storm.os.MILLISECOND)
        SVCD.add_attribute(0x3006, 0x400b, verify)
        cord.await(storm.os.invokeLater,500*storm.os.MILLISECOND)
        SVCD.add_attribute(0x3006, 0x400c, execute)
        cord.await(storm.os.invokeLater,500*storm.os.MILLISECOND)
        SVCD.add_attribute(0x3006, 0x400d, init)
        cord.await(storm.os.invokeLater,500*storm.os.MILLISECOND)
        SVCD.add_service(0x3007)
        cord.await(storm.os.invokeLater,500*storm.os.MILLISECOND)
        SVCD.add_attribute(0x3007, 0x400e, function() end)
        storm.os.invokePeriodically(4*storm.os.SECOND, function()
            print ("Notifying")
            local payload = storm.net.stats()
            SVCD.notify(0x3007, 0x400e, payload)
        end)
    end)

end

brsock = storm.net.udpsocket(9001, function()
end)

rstsock = storm.net.udpsocket(666, function()
    storm.os.reset()
end)

function l(msg)
    storm.net.sendto(brsock, msg, "ff02::1",9000)
end

function l2(dest, msg)
    storm.net.sendto(brsock, msg, dest, 9000)
end
SVCD.init("unused", onready)





-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()