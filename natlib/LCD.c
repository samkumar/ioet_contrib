
//These taken from https://github.com/Seeed-Studio/Grove_LCD_RGB_Backlight/blob/master/rgb_lcd.h

#define LCD_ADDRESS     (0x7c>>1)
#define RGB_ADDRESS     (0xc4>>1)

// commands
#define LCD_CLEARDISPLAY 0x01
#define LCD_RETURNHOME 0x02
#define LCD_ENTRYMODESET 0x04
#define LCD_DISPLAYCONTROL 0x08
#define LCD_CURSORSHIFT 0x10
#define LCD_FUNCTIONSET 0x20
#define LCD_SETCGRAMADDR 0x40
#define LCD_SETDDRAMADDR 0x80

// flags for display entry mode
#define LCD_ENTRYRIGHT 0x00
#define LCD_ENTRYLEFT 0x02
#define LCD_ENTRYSHIFTINCREMENT 0x01
#define LCD_ENTRYSHIFTDECREMENT 0x00

// flags for display on/off control
#define LCD_DISPLAYON 0x04
#define LCD_DISPLAYOFF 0x00
#define LCD_CURSORON 0x02
#define LCD_CURSOROFF 0x00
#define LCD_BLINKON 0x01
#define LCD_BLINKOFF 0x00

// flags for display/cursor shift
#define LCD_DISPLAYMOVE 0x08
#define LCD_CURSORMOVE 0x00
#define LCD_MOVERIGHT 0x04
#define LCD_MOVELEFT 0x00

// flags for function set
#define LCD_8BITMODE 0x10
#define LCD_4BITMODE 0x00
#define LCD_2LINE 0x08
#define LCD_1LINE 0x00
#define LCD_5x10DOTS 0x04
#define LCD_5x8DOTS 0x00


static int contrib_lcd_hellox_tail(lua_State *L);
static int contrib_lcd_hellox_entry(lua_State *L);

static int contrib_lcd_init_entry(lua_State *L);
static int contrib_lcd_init_tail(lua_State *L);
static int contrib_lcd_stage1(lua_State *L);

static int contrib_lcd_command(lua_State *L)
{
    lua_getglobal(L, "cord");
    lua_pushstring(L, "await");
    lua_rawget(L, -2);
    lua_remove(L, -2);
    lua_pushlightfunction(L, libstorm_i2c_invokeLater);
    lua_pushnumber(L, ticks);
    return cord_invoke_custom(L, 2);
}
}
/**
 * Load's the LCD module and stores it in the global scope as LCD
 */
static int contrib_lcd_load(lua_State *L)
{
    lua_createtable(L, 0, 5);

    lua_pushstring(L, "hellox");
    lua_pushlightfunction(L, contrib_lcd_hellox_entry);
    cord_wrap_nc(L);
    lua_rawset(L, 1);

    //Set the LCD table as a global
    lua_setglobal(L, "LCD");
    return 0;
}

static int contrib_lcd_init(lua_State *L)
{
    int lines = lua_tonumber(L, 1);
    int dotsize = lua_tonumber(L, 2);
    int df, dc, dm; //displayfunc, displaycontrol, displaymode
    if (lua_gettop(L) != 2) return luaL_error("Expected 2 params");
    df = lines == 2 ? LCD_2LINE : LCD_1LINE;
    df |= LCD_8BITMODE;
    dm = LCD_ENTRYLEFT | LCD_ENTRYSHIFTDECREMENT;
    dc = LCD_DISPLAYON | LCD_CURSOROFF | LCD_BLINKOFF;

    lua_getglobal(L, "LCD"); //This in 3 now
    lua_pushstring(L, "dc");
    lua_pushnumber(L, dc);
    lua_settable(L, -3);

    lua_pushstring(L, "dm");
    lua_pushnumber(L, dm);
    lua_settable(L, -3);

    //We have to wait 50 ms
    //We have to write the display function 4 times with 5ms between
    lua_pushnumber(L, 4);
    cord_set_continuation(L, contrib_lcd_stage1, 1);
    return nc_invoke_sleep(L, 50*MILLISECOND_TICKS);
}
static int contrib_lcd_stage1(lua_State *L)
{
    int timesleft = lua_tonumber(L, lua_upvalueindex(1));
    int df;
    if (timesleft > 0)
    {
        lua_getglobal(L, "LCD"); //position 1
        lua_pushstring(L, "df");
        lua_gettable(L, 1); //position 2
        df = lua_tonumber(L, -1);
        lua_pushnumber(L, timesleft-1);
        //We have to write the display function 4 times with 5ms between
        cord_set_continuation(L, contrib_lcd_stage1_delay, 1);
        //Invoke our command function
        lua_pushstring(L, "command");
        lua_gettable(L, 1);
        lua_pushnumber(L, LCD_FUNCTIONSET | df);
        printf("invoking command\n");
        cord_dump_stack(L);
        return cord_invoke_custom(L, 1);
    }
    else
    {
        lua_getglobal(L, "LCD"); //position 1
        //Done with the four function sets, lets do display
        cord.set_continuation(L, contrib_lcd_stage2, 0);
        lua_pushstring(L, "display");
        lua_gettable(L, 1); //now display is TOS
        return cord_invoke_custom(L, 0);
    }
}
static int contrib_lcd_stage1_delay(lua_State *L)
{
    //Our job is just to sleep for 5ms then go to stage 1
    //forward the number of times left
    lua_pushvalue(L, lua_upvalueindex(1));
    cord_set_continuation(L, contrib_lcd_stage1, 1);
    return nc_invoke_sleep(L, 5*MILLISECOND_TICKS);
}
static int contrib_lcd_stage2(lua_State *L)
{
    //clear
    lua_getglobal(L, "LCD"); //position 1
    cord.set_continuation(L, contrib_lcd_stage3, 0);
    lua_pushstring(L, "clear");
    lua_gettable(L, 1);
    return cord_invoke_custom(L, 0);
}
static int contrib_lcd_stage3(lua_State *L)
{
    int df;
    //clear
    lua_getglobal(L, "LCD"); //position 1
    cord.set_continuation(L, contrib_lcd_stage4, 0);
    lua_pushstring(L, "command");
    lua_gettable(L, 1);
    lua_pushnumber(LCD_ENTRYMODESET |  LCD_ENTRYLEFT | LCD_ENTRYSHIFTDECREMENT );
    return cord_invoke_custom(L, 1);
}
/**
 * Creates a new LCD control object
 *
 * Lua signature: new() -> LCD table
 * Maintainer: Michael Andersen <m.andersen@cs.berkeley.edu>
 */
static int contrib_lcd_new(lua_State *L);

static int contrib_lcd_hellox_entry(lua_State *L)
{
    //First run of the loop, lets configure N and X
    int N = luaL_checknumber(L, 1);
    int X = luaL_checknumber(L, 2);
    int loopcounter = 0;

    //Do our job
    printf ("Hello world\n");

    //We already have these on the top of the stack, but this is
    //how you would push variables you want access to in the continuation
    //Also counting down would be more efficient, but this is an example
    lua_pushnumber(L, loopcounter + 1);
    lua_pushnumber(L, N);
    lua_pushnumber(L, X);
    //Now we want to sleep, and when we are done, invoke helloX_tail with
    //the top 3 values of the stack available as upvalues
    cord_set_continuation(L, contrib_lcd_hellox_tail, 3);
    return nc_invoke_sleep(L, X);

    //We can't do anything after a cord_invoke_* call, ever!
}
static int contrib_lcd_hellox_tail(lua_State *L)
{
    //Grab our upvalues (state passed to us from the previous func)
    int loopcounter = lua_tonumber(L, lua_upvalueindex(1));
    int N = lua_tonumber(L, lua_upvalueindex(2));
    int X = lua_tonumber(L, lua_upvalueindex(3));

    //Do our job with them
    if (loopcounter < N)
    {
        printf ("Hello world\n");
        //Again, an example, these are already at the top of
        //the stack
        lua_pushnumber(L, loopcounter + 1);
        lua_pushnumber(L, N);
        lua_pushnumber(L, X);
        cord_set_continuation(L, contrib_lcd_hellox_tail, 3);
        return nc_invoke_sleep(L, X);
    }
    else
    {
        //Base case, now we do our return
        //We promised to return the number 42
        lua_pushnumber(L, 42);
        lua_pushnumber(L, 43);
        return cord_return(L, 2);
    }
}
