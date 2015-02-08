
require "cord"
local svcd = require "svcd"

storm.io.set_mode(storm.io.OUTPUT, storm.io.D4, storm.io.D5, storm.io.D6, storm.io.D7)
storm.io.set(0, storm.io.D4, storm.io.D5)
storm.io.set(1, storm.io.D6, storm.io.D7)

cord.new(function()
    svcd.init()
end)

svcd.register("setRlyA", {s="setBool"}, function(v)
    print ("got setRlyA", v)
    storm.io.set(v, storm.io.D4)
    return {5,6}
end)

svcd.register("setRlyB", {s="setBool"}, function(v)
    print "got setRlyB"
    storm.io.set(v, storm.io.D5)
    return {}
end)

svcd.register("setRlyC", {s="setBool"}, function(v)
    print "got setRlyC"
    storm.io.set(v, storm.io.D6)
    return {}
end)

svcd.register("setRlyD", {s="setBool"}, function(v)
    print "got setRlyD"
    storm.io.set(v, storm.io.D7)
    return {}
end)

transactions = {}

function scanlowest()
end

svcd.register("trSetup", {s="-"}, function(ikvid, time, fn, args)
    if
    transactions[ivkid] = {t=time,f=fn,a=args}
end)
cord.enter_loop()

