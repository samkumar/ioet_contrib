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

static void cord_dump_stack (lua_State *L)
{ //Stolen from the book
      int i;
      int top = lua_gettop(L);
      for (i = 1; i <= top; i++) {  /* repeat for each level */
        int t = lua_type(L, i);
        switch (t) {

          case LUA_TSTRING:  /* strings */
            printf("`%s'", lua_tostring(L, i));
            break;

          case LUA_TBOOLEAN:  /* booleans */
            printf(lua_toboolean(L, i) ? "true" : "false");
            break;

          case LUA_TNUMBER:  /* numbers */
            printf("%d", (int) lua_tonumber(L, i));
            break;

          default:  /* other values */
            printf("%s", lua_typename(L, t));
            break;

        }
        printf("  ");  /* put a separator */
      }
      printf("\n");  /* end the listing */
    }

//Not a lua function
//First push the upvalues
//then call this
static inline void cord_set_continuation(lua_State *L, lua_CFunction continuation, int num_upvalues)
{
    lua_pushcclosure(L, continuation, num_upvalues);
}

//First call set_continuation
//Then push fn
//Then push arguments
static int cord_invoke_custom(lua_State *L, int num_arguments)
{
    int argidx = lua_gettop(L) - num_arguments + 1;
    int i;
    lua_createtable(L, num_arguments, 0);
    lua_insert(L, argidx);
    for (i=num_arguments;i>=1;i--)
        lua_rawseti(L, argidx, i);
    return lua_yield(L, 3); //continuation, targetfn, table of args
}

static int cord_invoke_sleep(lua_State *L, int ticks)
{
    lua_getglobal(L, "cord");
    lua_pushstring(L, "await");
    lua_rawget(L, -2);
    lua_remove(L, -2);
    lua_pushlightfunction(L, libstorm_os_invokeLater);
    lua_pushnumber(L, ticks);
    return cord_invoke_custom(L, 2);
}

//Push your return values
//then call this
static int cord_return(lua_State *L, int num_vals)
{
    int i;
    int rvidx = lua_gettop(L) - num_vals + 1;
    lua_createtable(L, num_vals, 0);
    lua_insert(L, rvidx);
    for (i=num_vals;i>=1;i--)
        lua_rawseti(L, rvidx, i);
    lua_pushnumber(L, -1);
    lua_insert(L, -2);
    return lua_yield(L, 2);
}
/**
 * Prints out hello world
 *
 * Lua signature: hello() -> nil
 * Maintainer: Michael Andersen <m.andersen@cs.berkeley.edu>
 */
static int contrib_hello(lua_State *L)
{
    printf("Hello world\n");
    // The number of return values
    return 0;
}

/**
 * Prints out hello world N times, X ticks apart
 *
 * N >= 1
 * Lua signature: helloX(N,X) -> 42
 * Maintainer: Michael Andersen <m.andersen@cs.berkeley.edu>
 */
static int contrib_helloX_tail(lua_State *L);
static int contrib_helloX_entry(lua_State *L)
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
    cord_set_continuation(L, contrib_helloX_tail, 3);
    return cord_invoke_sleep(L, X);

    //We can't do anything after a cord_invoke_* call, ever!
}
static int contrib_helloX_tail(lua_State *L)
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
        cord_set_continuation(L, contrib_helloX_tail, 3);
        return cord_invoke_sleep(L, X);
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


/**
 * Prints out hello world N times, 1 second apart. requires nc
 *
 * Lua signature: helloN() -> nil
 * Maintainer: Michael Andersen <m.andersen@cs.berkeley.edu>
 */
static int contrib_helloN_tail(lua_State *L);
static int contrib_helloN(lua_State *L)
{
    printf("Hello world\n");
    lua_pushnumber(L, 1);
    lua_pushcclosure(L, contrib_helloN_tail, 1);
    lua_pushnil(L);
    lua_createtable(L, 0, 0);
    return lua_yield(L, 3);
}
static int contrib_helloN_tail(lua_State *L)
{
    //First argument is state
    printf("tail called\n");
    int state = lua_tonumber(L, lua_upvalueindex(1));
    printf("state is %d\n", state);
    switch(state)
    {
        case 1:
            printf("hello world 1\n");
            //tail call
            lua_pushnumber(L, state + 1);
            lua_pushcclosure(L, contrib_helloN_tail, 1);
            lua_getglobal(L, "sleep");
            lua_createtable(L, 1, 0);
            //For each argument
            lua_pushnumber(L, 1);
            lua_rawseti(L, -2, 1);
            printf("yielding");
            return lua_yield(L, 3); //tailfn + target + table of args
        case 2:
            printf("hello world 2\n");
            //tail call
            lua_pushnumber(L, state + 1);
            lua_pushcclosure(L, contrib_helloN_tail, 1);
            lua_getglobal(L, "sleep");
            lua_createtable(L, 3, 0);
            //For each argument
            lua_pushnumber(L, 1);
            lua_rawseti(L, -2, 1);
            return lua_yield(L, 3); //tailfn + target + table of args
        case 3:
            printf("hello world 3\n");
            //tail call
            lua_pushnumber(L, state + 1);
            lua_pushcclosure(L, contrib_helloN_tail, 1);
            lua_getglobal(L, "sleep");
            lua_createtable(L, 3, 0);
            //For each argument
            lua_pushnumber(L, 1);
            lua_rawseti(L, -2, 1);
            return lua_yield(L, 3); //tailfn + target + table of args
        default:
            lua_pushnumber(L, -1);
            lua_createtable(L, 3, 0);
            //For each argument
            lua_pushnumber(L, 40);
            lua_rawseti(L, -2, 1);
            //For each argument
            lua_pushnumber(L, 50);
            lua_rawseti(L, -2, 2);
            //For each argument
            lua_pushnumber(L, 60);
            lua_rawseti(L, -2, 3);
            return lua_yield(L, 2); //-1 and return value
    }

}
////////////////// BEGIN MODULE MAP /////////////////////////////
const LUA_REG_TYPE contrib_native_map[] =
{
    { LSTRKEY( "hello" ), LFUNCVAL ( contrib_hello ) },
    { LSTRKEY( "helloN" ), LFUNCVAL ( contrib_helloN ) },
    { LSTRKEY( "helloX" ), LFUNCVAL ( contrib_helloX_entry ) },

    //The list must end with this
    { LNILKEY, LNILVAL }
};