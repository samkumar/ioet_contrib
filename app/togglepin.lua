require "storm"

function togglepin(pin)
    local truepin = storm.io[pin]
    storm.io.set_mode(storm.io.OUTPUT, truepin)
    while true do
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
        storm.io.set(2, truepin)
    end
end

--togglepin("D2")
storm.n.toggleD2()
