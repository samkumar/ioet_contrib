REG = require "reg"
string = require "string"

--[[ References: The best documentation I could find about how to
LCD was actually a C++ library for it, at
Seeed-Studio/Grove_LCD_RGB_Backlight. I used the existing code
to figure out what messages I needed to send via I2C to actuate the
LCD. ]]--


local codes = {
    LCD_CLEARDISPLAY = 0x01,
    LCD_RETURNHOME = 0x02,
    LCD_ENTRYMODESET = 0x04,
    LCD_DISPLAYCONTROL = 0x08,
    LCD_CURSORSHIFT = 0x10,
    LCD_FUNCTIONSET = 0x20,
    LCD_SETCGRAMADDR = 0x40,
    LCD_SETDDRAMADDR = 0x80,

    --lags for display entry mode
    LCD_ENTRYRIGHT = 0x00,
    LCD_ENTRYLEFT = 0x02,
    LCD_ENTRYSHIFTINCREMENT = 0x01,
    LCD_ENTRYSHIFTDECREMENT = 0x00,

    --lags for display on/off control
    LCD_DISPLAYON = 0x04,
    LCD_DISPLAYOFF = 0x00,
    LCD_CURSORON = 0x02,
    LCD_CURSOROFF = 0x00,
    LCD_BLINKON = 0x01,
    LCD_BLINKOFF = 0x00,

    --flags for display/cursor shift
    LCD_DISPLAYMOVE = 0x08,
    LCD_CURSORMOVE = 0x00,
    LCD_MOVERIGHT = 0x04,
    LCD_MOVELEFT = 0x00,

    --flags for function set
    LCD_8BITMODE = 0x10,
    LCD_4BITMODE = 0x00,
    LCD_2LINE = 0x08,
    LCD_1LINE = 0x00,
    LCD_5x10DOTS = 0x04,
    LCD_5x8DOTS = 0x00,
    
    -- flags for communication
    LCD_COMMAND = 0x80,
    LCD_WRITE = 0x40,
    
    LCD_ADDR = 0x7c,
    LCD_PORT = storm.i2c.EXT,
    
    RGB_ADDR = 0xc4,
    RGB_PORT = storm.i2c.EXT,
    RED_ADDR = 0x04,
    GREEN_ADDR = 0x03,
    BLUE_ADDR = 0x02,
    
    LED_OUTPUT = 0x08,
}

local LCD = {}


LCD.command = function(val)
    LCD.lcdreg:w(codes.LCD_COMMAND, val)
end

-- Writes a character to the cursor's current position. --
LCD.write = function (char)
    LCD.lcdreg:w(codes.LCD_WRITE, char)
end

LCD.init = function(lines, dotsize)
            LCD.lcdreg = REG:new(codes.LCD_PORT, codes.LCD_ADDR)
            LCD.rgbreg = REG:new(codes.RGB_PORT, codes.RGB_ADDR)
            LCD.red = -1
            LCD.green = -1
            LCD.blue = -1
            
            LCD._df = 0
            if lines == 2 then LCD._df = codes.LCD_2LINE end
            LCD._df = LCD._df + codes.LCD_8BITMODE
            LCD.nl = lines
            LCD._dc = 0
            LCD._dm = codes.LCD_ENTRYLEFT + codes.LCD_ENTRYSHIFTDECREMENT;
            LCD._cl = 0
            if dotsize ~=0 and lines ~= 1 then LCD._df = bit.bor(LCD._df, codes.LCD_5x8DOTS) end
            -- seriously, the chip requires this...
            cord.await(storm.os.invokeLater, 200*storm.os.MILLISECOND)
            LCD.command(codes.LCD_FUNCTIONSET + LCD._df)
            cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
            LCD.command(codes.LCD_FUNCTIONSET + LCD._df)
            cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
            LCD.command(codes.LCD_FUNCTIONSET + LCD._df)
            cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
            LCD.command(codes.LCD_FUNCTIONSET + LCD._df)
            cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
            LCD.command(0x08)
            cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
            LCD.command(0x01)
            cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
            LCD.command(0x6)
            cord.await(storm.os.invokeLater, 200*storm.os.MILLISECOND)
            LCD._dc  = codes.LCD_DISPLAYON + codes.LCD_CURSORON + codes.LCD_BLINKON
            LCD.display()
            cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
            
            -- Initialization work for the backlight LED. --
            LCD.rgbreg:w(codes.LED_OUTPUT, 0xAA)
end

-- Sets the position of the cursor. ROW and COL are 0-indexes --
LCD.setCursor = function(row, col)
    if row == 0 then
        col = bit.bor(col, 0x80)
    else
        col = bit.bor(col, 0xc0)
    end
    LCD.command(col)
end
LCD.display = function ()
    LCD._dc = bit.bor(LCD._dc, codes.LCD_DISPLAYON)
    LCD.command(codes.LCD_DISPLAYCONTROL + LCD._dc)
end
LCD.nodisplay = function ()
    LCD._dc = bit.bor(LCD._dc, bit.bnor(codes.LCD_DISPLAYON))
    LCD.command(codes.LCD_DISPLAYCONTROL + LCD._dc)
end
-- Erases the screen. --
LCD.clear = function ()
    LCD.command(codes.LCD_CLEARDISPLAY)
    cord.await(storm.os.invokeLater, 2*storm.os.MILLISECOND)
end

-- Writes a string to the LCD display at the cursor. --
LCD.writeString = function (str)
    local i
    for i = 1, #str do
        LCD.write(string.byte(str:sub(i, i)))
    end
end

--[[ Sets the color of the RGB backlight. RED, GREEN, and BLUE
should be integers from 0 to 255. ]]--
LCD.setBackColor = function (red, green, blue)
    local result
    if red ~= LCD.red then
        result = LCD.rgbreg:w(codes.RED_ADDR, red)
        if result ~= nil then
            LCD.red = red
        end
    end
    if green ~= LCD.green then
        result = LCD.rgbreg:w(codes.GREEN_ADDR, green)
        if result ~= nil then
            LCD.green = green
        end
    end
    if blue ~= LCD.blue then
        result = LCD.rgbreg:w(codes.BLUE_ADDR, blue)
        if result ~= nil then
            LCD.blue = blue
        end
    end
end

return LCD
