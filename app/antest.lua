
require "cord"

storm.n.adcife_init()

storm.io.set_mode(storm.io.ANALOG, storm.io.A0)

storm.os.invokePeriodically(storm.os.MILLISECOND * 300, function()
    local v = storm.n.adcife_sample_an0();
    print ("RES: ", v)
end)

cord.enter_loop()
