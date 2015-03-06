// This file is part of the Firestorm Software Distribution.
//
// FSD is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// FSD is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with FSD.  If not, see <http://www.gnu.org/licenses/>.

// Author: Michael Andersen <m.andersen@cs.berkeley.edu>

#include "adcife.h"
#include "analog.h"

#define ADCIFE_SYMBOLS \
    { LSTRKEY( "adcife_init"), LFUNCVAL ( adcife_init ) }, \
    { LSTRKEY( "adcife_new"), LFUNCVAL ( adcife_new ) }, \
    { LSTRKEY( "adcife_sample"), LFUNCVAL (adcife_sample) }, \
    { LSTRKEY( "ADCIFE_GAIN_1"), LNUMVAL ( 0b000 ) }, \
    { LSTRKEY( "ADCIFE_GAIN_2"), LNUMVAL ( 0b001 ) }, \
    { LSTRKEY( "ADCIFE_GAIN_4"), LNUMVAL ( 0b010 ) }, \
    { LSTRKEY( "ADCIFE_GAIN_8"), LNUMVAL ( 0b011 ) }, \
    { LSTRKEY( "ADCIFE_GAIN_16"), LNUMVAL ( 0b100 ) }, \
    { LSTRKEY( "ADCIFE_GAIN_32"), LNUMVAL ( 0b101 ) }, \
    { LSTRKEY( "ADCIFE_GAIN_64"), LNUMVAL ( 0b110 ) }, \
    { LSTRKEY( "ADCIFE_GAIN_HALF"), LNUMVAL ( 0b111 ) }, \
    { LSTRKEY( "PIN_A0"), LNUMVAL ( 0 ) }, \
    { LSTRKEY( "PIN_A1"), LNUMVAL ( 1 ) }, \
    { LSTRKEY( "PIN_A2"), LNUMVAL ( 2 ) }, \
    { LSTRKEY( "PIN_A3"), LNUMVAL ( 3 ) }, \
    { LSTRKEY( "PIN_A4"), LNUMVAL ( 4 ) }, \
    { LSTRKEY( "PIN_A5"), LNUMVAL ( 5 ) },
    

/* The analog pins on the firestorm go through several layers of translation
 * before you get to the channel numbers that are expected for the analog
 * peripheral. This maps the firestorm channel number to the MPU channel
 * number
 */
static const int chanmap [] = {
    6, //A0 maps to AN5 on storm which is AD6 on MPU
    5, //A1 maps to AN4 on storm which is AD5 on MPU
    4, //A2 maps to AN3 on storm which is AD4 on MPU
    3, //A3 maps to AN2 on storm which is AD3 on MPU
    2, //A4 maps to AN1 on storm which is AD2 on MPU
    1  //A5 maps to AN0 on storm which is AD1 on MPU
};

//////////////////////////////////////////////////////////////////////////////
// ADCIFE init implementation
// Initialises the module, but does not create any channels
// Maintainer: Michael Andersen <michael@steelcode.com>
/////////////////////////////////////////////////////////////

//Pure C functions
void c_adcife_init()
{
    //Reset the ADCIFE so that we can apply any configuration changes
    //use APB clock
    ADCIFE->cfg.bits.clksel = 1;
    //The APB clock is at 48Mhz, we need it to be below 1.8 Mhz. /64 gets us closest
    ADCIFE->cfg.bits.prescal = 0b100;
    //Set speed for 300ksps
    ADCIFE->cfg.bits.speed = 0b00;
    //Reset the module
    ADCIFE->cr.bits.swrst = 1;
    //Enable it
    ADCIFE->cr.bits.en = 1;
    //Wait for it to be enabled
    while(!ADCIFE->sr.bits.en);
    //Set the reference to be the external AREF pin
    ADCIFE->cfg.bits.refsel = 0b010;
    //Set the reference to be the internal 1V bandgap
    //ADCIFE->cfg.bits.refsel = 0;
    ADCIFE->cr.bits.refbufen = 1;
    ADCIFE->cr.bits.bgreqen = 1;
}

int c_adcife_sample_channel(uint8_t channel, uint8_t gain_exp)
{
    //TODO: use the channel, maybe add more parameters

    adcife_seqcfg_t seqcfg;
    //Clear conversion flag
    ADCIFE->scr.bits.seoc = 1;
    //Clear out the struct
    seqcfg.flat = 0;
    //Set the positive channel
    seqcfg.bits.muxpos = chanmap[channel];
    //Enable bipolar mode, this seems to drastically reduce noise
    seqcfg.bits.bipolar = 1;
    //Enable the internal voltage source for the negative reference
    seqcfg.bits.internal = 0b10;
    //Set the negative reference to ground
    seqcfg.bits.muxneg = 0b011;
    //Set the gain to 1/2
    seqcfg.bits.gain = gain_exp;
    //Set it
    ADCIFE->seqcfg = seqcfg;
    //Start the conversion
    ADCIFE->cr.bits.strig = 1;
    while(!ADCIFE->sr.bits.seoc);
    return ADCIFE->lcv.bits.lcv;
}

//Lua: storm.n.adcife_init()
int adcife_init(lua_State *L)
{
    c_adcife_init();
    return 0;
}

int adcife_sample_an0(lua_State *L)
{
    //TODO: turn this into a metamethod on a table, look in stormarray.c for examples
int sample = c_adcife_sample_channel(0, 0);
    lua_pushnumber(L, sample);
    return 1;
}

int adcife_sample(lua_State *L)
{
    int channel = lua_tonumber(L, 1);
    int gain = lua_tonumber(L, 2);
    int sample = c_adcife_sample_channel(channel, gain);
    lua_pushnumber(L, sample);
    return 1;
}

//Lua: storm.n.adcife_new(poschan, negchan, gain, resolution)
int adcife_new(lua_State *L)
{
    //TODO: make this construct a table with a rotable metatable and return it
    //see stormarray for examples.
    return 0;
}
