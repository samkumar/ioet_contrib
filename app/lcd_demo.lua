LCD = require "lcd"

cord.new(function ()
    LCD.init(2, 1)
    LCD.writeString("THE INTERNET OF")
    LCD.setCursor(1, 0)
    LCD.writeString("THINGS, Spr '15")
    while true do
        LCD.setBackColor(255, 255, 255)
        cord.await(storm.os.invokeLater, storm.os.SECOND)
        LCD.setBackColor(0, 255, 0)
        cord.await(storm.os.invokeLater, storm.os.SECOND)
        LCD.setBackColor(0, 0, 255)
        cord.await(storm.os.invokeLater, storm.os.SECOND)
    end
end)

cord.enter_loop()
