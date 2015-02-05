LCD = require "lcd"

lcd = LCD:new(storm.i2c.EXT, 0x7c, storm.i2c.EXT, 0xc4)
cord.new(function ()
    print("started")
    lcd:init(2, 1)
    print("initialized")
    lcd:writeString("THE INTERNET OF")
    lcd:setCursor(1, 0)
    lcd:writeString("THINGS, Spr '15")
    while true do
        lcd:setBackColor(255, 255, 255)
        cord.await(storm.os.invokeLater, storm.os.SECOND)
        lcd:setBackColor(0, 255, 0)
        cord.await(storm.os.invokeLater, storm.os.SECOND)
        lcd:setBackColor(0, 0, 255)
        cord.await(storm.os.invokeLater, storm.os.SECOND)
    end
end)

cord.enter_loop()
