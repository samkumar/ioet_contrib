//This file is included into native.c
#include "libstormarray.h"
extern const uint8_t arr_sizemap[]; //from libstormarray.c
extern const uint8_t arr_shiftmap[]; //from libstormarray.c

// This is copied from libstorm.c
#define MAXPINSPEC 14
static const uint16_t pinspec_map [] =
{
    0x0109, //D0 = PB09
    0x010A, //D1 = PB10
    0x0010, //D2 = PA16
    0x000C, //D3 = PA12
    0x0209, //D4 = PC09
    0x000A, //D5 = PA10
    0x000B, //D6 = PA11
    0x0013, //D7 = PA19
    0x000D, //D8 = PA13
    0x010B, //D9 = PB11
    0x010C, //D10 = PB12
    0x010F, //D11 = PB15
    0x010E, //D12 = PB14
    0x010D, //D13 = PB13
};

#define NEOPIXEL_SYMBOLS \
    { LSTRKEY( "neopixel"), LFUNCVAL ( neopixel ) },

void ws2812_sendarray(uint8_t *data, int datlen, uint32_t maskhi, uint32_t masklo, volatile uint32_t *set, volatile uint32_t *clr);

static int neopixel( lua_State *L )
{
    uint16_t count;
    int pinspec;
    storm_array_t *arr = lua_touserdata(L, 1);
    if (!arr)
    {
        return luaL_error(L, "invalid array");
    }
    if (arr->type != ARR_TYPE_UINT8)
    {
        return luaL_error(L, "wrong array type: not uint8");
    }

    count = arr->len >> arr_shiftmap[arr->type];

    pinspec = luaL_checkint( L, 2 );
    if (pinspec < 0 || pinspec > MAXPINSPEC)
    {
      return luaL_error( L, "invalid IO pin");
    }

    uint32_t port_offset = pinspec_map[pinspec] & 0xff00;
    uint32_t pin_offset = pinspec_map[pinspec] & 0x00ff;

    uint32_t volatile *port_gpio_enable = (uint32_t *)(0x400E1000 + port_offset + 0x004);
    uint32_t volatile *port_output_enable = (uint32_t *)(0x400E1000 + port_offset + 0x044);
    uint32_t volatile *port_set = (uint32_t *)(0x400E1000 + port_offset + 0x054);
    uint32_t volatile *port_clr = (uint32_t *)(0x400E1000 + port_offset + 0x058);

    *port_gpio_enable = (1 << pin_offset); // enable the pin
    *port_output_enable = (1 << pin_offset); // set the pin as on output

    ws2812_sendarray((uint8_t*)ARR_START(arr),
                     count,
                     (1 << pin_offset),
                     (1 << pin_offset),
                     port_set,
                     port_clr
        );

    return 0;
}

/*****************************
  Based on code from:
  https://github.com/cpldcpu/light_ws2812/blob/master/light_ws2812_ARM/light_ws2812_cortex.c

  Modified because the original code uses a different version of ARM
  (among other issues, it creates an infinite loop)
******************************/

#define ws2812_cpuclk 48000000

///////////////////////////////////////////////////////////////////////
// End user defined area
///////////////////////////////////////////////////////////////////////

#if (ws2812_cpuclk<8000000)
    #error "Minimum clockspeed for ARM ws2812 library is 8 Mhz!"
#endif

#if (ws2812_cpuclk>60000000)
    #error "Maximum clockspeed for ARM ws2812 library is 60 Mhz!"
#endif




#define ws2812_ctot (((ws2812_cpuclk/1000)*1250)/1000000)
#define ws2812_t1   (((ws2812_cpuclk/1000)*375 )/1000000)       // floor
#define ws2812_t2   (((ws2812_cpuclk/1000)*625+500000)/1000000) // ceil

#define w1 (ws2812_t1-2)
#define w2 (ws2812_t2-ws2812_t1-2+1)
#define w3 (ws2812_ctot-ws2812_t2-5)

#define ws2812_DEL1 "   nop     \n\t"
#define ws2812_DEL2 "   b   .+2 \n\t"
#define ws2812_DEL4 ws2812_DEL2 ws2812_DEL2
#define ws2812_DEL8 ws2812_DEL4 ws2812_DEL4
#define ws2812_DEL16 ws2812_DEL8 ws2812_DEL8


void ws2812_sendarray(uint8_t *data,int datlen, uint32_t maskhi, uint32_t masklo, volatile uint32_t *set, volatile uint32_t *clr)
{
    uint32_t i = 0; // set value to avoid warning
    uint32_t curbyte;

    while (datlen--) {
        curbyte=*data++;

    asm volatile(
            "       cpsid i                     \n\t" // disable interrupts
            "       lsl %[dat],#24              \n\t"
            "       mov %[ctr],#8               \n\t"
            "ilop%=:                            \n\t"
            "       lsls %[dat], #1             \n\t"
            "       str %[maskhi], [%[set]]     \n\t"
#if (w1&1)
            ws2812_DEL1
#endif
#if (w1&2)
            ws2812_DEL2
#endif
#if (w1&4)
            ws2812_DEL4
#endif
#if (w1&8)
            ws2812_DEL8
#endif
#if (w1&16)
            ws2812_DEL16
#endif
            "       bcs one%=                   \n\t"
            "       str %[masklo], [%[clr]]     \n\t"
            "one%=:                             \n\t"
#if (w2&1)
            ws2812_DEL1
#endif
#if (w2&2)
            ws2812_DEL2
#endif
#if (w2&4)
            ws2812_DEL4
#endif
#if (w2&8)
            ws2812_DEL8
#endif
#if (w2&16)
            ws2812_DEL16
#endif
            "       subs %[ctr], #1             \n\t"
            "       str %[masklo], [%[clr]]     \n\t"
            "       beq end%=                   \n\t"
#if (w3&1)
            ws2812_DEL1
#endif
#if (w3&2)
            ws2812_DEL2
#endif
#if (w3&4)
            ws2812_DEL4
#endif
#if (w3&8)
            ws2812_DEL8
#endif
#if (w3&16)
            ws2812_DEL16
#endif

            "       b   ilop%=                  \n\t"
            "end%=:                             \n\t"
            "       cpsie i                     \n\t" // re-enable interrupts
            :   [ctr] "+r" (i)
            :   [dat] "r" (curbyte), [set] "r" (set), [clr] "r" (clr), [masklo] "r" (masklo), [maskhi] "r" (maskhi)
            );
    }
}

