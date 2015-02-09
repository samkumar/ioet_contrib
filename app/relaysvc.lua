
require "cord"
local svcd = require "svcd"

storm.io.set_mode(storm.io.OUTPUT, storm.io.D4, storm.io.D5, storm.io.D6, storm.io.D7)
storm.io.set(0, storm.io.D4, storm.io.D5, storm.io.D6, storm.io.D7)

cord.new(function()
    svcd.init("ledb")
end)

svcd.register("setR", {s="setBool"}, function(v)
    local value
    if v == 1 or v then value = 1 else value = 0 end
    storm.io.set(value, storm.io.D4)
    return {}
end)

svcd.register("setG", {s="setBool"}, function(v)
    local value
    if v == 1 or v then value = 1 else value = 0 end
    storm.io.set(value, storm.io.D5)
    return {}
end)

svcd.register("setB", {s="setBool"}, function(v)
    local value
    if v == 1 or v then value = 1 else value = 0 end
    storm.io.set(value, storm.io.D6)
    return {}
end)

svcd.register("getNow", {s="getNumber"}, function()
    local now = storm.os.now(storm.os.SHIFT_16)
    print ("returning now",now)
    return {now}
end)

cord.enter_loop()

