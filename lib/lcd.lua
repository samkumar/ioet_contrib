

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
}

local LCD = {}


LCD.command = function(val)
            local arr = storm.array.create(2, storm.array.UINT8)
            arr:set(1, 0x80)
            arr:set(2, val)
            local rv = cord.await(storm.i2c.write,  storm.i2c.EXT + 0x7c,  storm.i2c.START + storm.i2c.STOP, arr)
            if (rv ~= storm.i2c.OK) then
                print ("ERROR ON I2C WRITE: ",rv)
            end    
end

LCD.init = function(lines, dotsize)
            LCD._df = 0
            if lines == 2 then LCD._df = codes.LCD_2LINE end
            LCD._df = LCD._df + codes.LCD_8BITMODE
            LCD.nl = lines
            LCD._dc = 0
            LCD._dm = codes.LCD_ENTRYLEFT + codes.LCD_ENTRYSHIFTDECREMENT;
            LCD._cl = 0
            if dotsize ~=0 and lines ~= 1 then LCD._df = bit.bor(LCD._df, codes.LCD_5x8DOTS) end
            --this will make sure the CLK and DAT lines are in the correct state
            --because we write to an address we know will NACK 
            --local arr = storm.array.create(1, storm.array.UINT8)
            --cord.await(storm.i2c.write,  storm.i2c.EXT + 0xFE,  storm.i2c.START + storm.i2c.STOP, arr)
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
            cord.await(storm.os.invokeLater, 500*storm.os.MILLISECOND)
            LCD._dc  = codes.LCD_DISPLAYON + codes.LCD_CURSORON + codes.LCD_BLINKON
            LCD.display()
            cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
end
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
LCD.data = function (c)
    local arr = storm.array.create(2, storm.array.UINT8)
    arr:set(1, 0xC0)
    arr:set(2, c)
    local rv = cord.await(storm.i2c.write,  storm.i2c.EXT + 0x7c,  storm.i2c.START + storm.i2c.STOP, arr)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C WRITE: ",rv)
    end    
    cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
end
LCD.clear = function ()
    LCD.command(codes.LCD_CLEARDISPLAY)
    cord.await(storm.os.invokeLater, 2*storm.os.MILLISECOND)
end

return LCD
