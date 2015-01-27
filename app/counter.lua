require "cord"
require "storm"

function blinkpin(pin, duration)
    storm.io.set_mode(storm.io.OUTPUT, pin)
    storm.io.set(0, pin)
    local led_state = 0
    return storm.os.invokePeriodically(duration, function()
        if led_state == 0 then
            storm.io.set(1, pin)
            led_state = 1
        else
            storm.io.set(0, pin)
            led_state = 0
        end
    end)
end

blinkpin(2, 1 * storm.os.SECOND)
blinkpin(3, 2 * storm.os.SECOND)
blinkpin(4, 4 * storm.os.SECOND)
blinkpin(5, 8 * storm.os.SECOND)

cord.enter_loop()
