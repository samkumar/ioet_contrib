/**
 * This file defines the contrib native C functions. You can access these as
 * storm.n.<function>
 * for example storm.n.hello()
 */

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "lrotable.h"
#include "auxmods.h"
#include <platform_generic.h>
#include <string.h>
#include <stdint.h>
#include <interface.h>
#include <stdlib.h>
#include <libstorm.h>

/**
 * This is required for the LTR patch that puts module tables
 * in ROM
 */
#define MIN_OPT_LEVEL 2
#include "lrodefs.h"

////////////////// BEGIN FUNCTIONS /////////////////////////////
#define USERLAND_BUFFER_SIZE 7210
#define BUFFER_PATTERN 0xbed0f3ed

int32_t __attribute__((naked)) k_syscall_ex_ri32_u32ptr_u32_u32(uint32_t id, uint32_t* arg0, uint32_t arg1, uint32_t arg2)
{
    __syscall_body(ABI_ID_SYSCALL_EX);
}

uint32_t userland_membuffer[USERLAND_BUFFER_SIZE];

int init_membuffer(lua_State* L) {
    int32_t result = k_syscall_ex_ri32_u32ptr_u32_u32(0x5a00, userland_membuffer, USERLAND_BUFFER_SIZE, BUFFER_PATTERN);
    if (result != 0) {
        printf("COULD NOT REGISTER USERLAND MEMORY BUFFER: %ld\n", result);
    }
    return 0;
}

////////////////// BEGIN MODULE MAP /////////////////////////////
const LUA_REG_TYPE contrib_native_map[] =
{
    /*{ LSTRKEY( "hello" ), LFUNCVAL ( contrib_hello ) },
    { LSTRKEY( "helloX" ), LFUNCVAL ( contrib_helloX_entry ) },
    { LSTRKEY( "fourth_root"), LFUNCVAL ( contrib_fourth_root_m1000 ) },
    { LSTRKEY( "run_foobar"), LFUNCVAL ( contrib_run_foobar ) },
    { LSTRKEY( "makecounter"), LFUNCVAL ( contrib_makecounter ) },

    SVCD_SYMBOLS
    CHAIRCONTROL_SYMBOLS
    I2CCHAIR_SYMBOLS
    BLCHAIR_SYMBOLS
    FLASH_SYMBOLS
    RECEIVER_SYMBOLS
    ADCIFE_SYMBOLS
    RNQ_SYMBOLS
    NEOPIXEL_SYMBOLS

    // -- Register address --
    { LSTRKEY( "TMP006_VOLTAGE" ), LNUMVAL(0x00)},
    { LSTRKEY( "TMP006_LOCAL_TEMP" ), LNUMVAL(0x01)},
    { LSTRKEY( "TMP006_CONFIG" ), LNUMVAL(0x02)},
    { LSTRKEY( "TMP006_MFG_ID" ), LNUMVAL(0xFE)},
    { LSTRKEY( "TMP006_DEVICE_ID" ), LNUMVAL(0xFF)},

    // -- Config register values
    { LSTRKEY( "TMP006_CFG_RESET" ), LNUMVAL(0x80)},
    { LSTRKEY( "TMP006_CFG_MODEON" ), LNUMVAL(0x70)},
    { LSTRKEY( "TMP006_CFG_1SAMPLE" ), LNUMVAL(0x00)},
    { LSTRKEY( "TMP006_CFG_2SAMPLE" ), LNUMVAL(0x02)},
    { LSTRKEY( "TMP006_CFG_4SAMPLE" ), LNUMVAL(0x04)},
    { LSTRKEY( "TMP006_CFG_8SAMPLE" ), LNUMVAL(0x06)},
    { LSTRKEY( "TMP006_CFG_16SAMPLE" ), LNUMVAL(0x08)},
    { LSTRKEY( "TMP006_CFG_DRDYEN" ), LNUMVAL(0x01)},
    { LSTRKEY( "TMP006_CFG_DRDY" ), LNUMVAL(0x80)},*/
    
    { LSTRKEY( "init_membuffer" ), LFUNCVAL( init_membuffer ) },

    //The list must end with this
    { LNILKEY, LNILVAL }
};
