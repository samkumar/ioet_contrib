//This file is included into native.c


#define SVCD_SYMBOLS \
    { LSTRKEY( "svcd_init"), LFUNCVAL ( svcd_init ) }, \
    { LSTRKEY( "svcd_notify"), LFUNCVAL ( notify ) },


//If this file is defining only specific functions, or if it
//is defining the whole thing
#define SVCD_PUREC 0

// This is the metatable for the SVCD table. It will allow use to put some constants
// and symbols into ROM. We could of course put everything into ROM but that would
// prevent consumers from overriding the contents of the table for things like
// advert_received, which you may want to hook into
#define MIN_OPT_LEVEL 2
#include "lrodefs.h"
static const LUA_REG_TYPE svcd_meta_map[] =
{
    { LSTRKEY( "__index" ), LROVAL ( svcd_meta_map ) },
    { LSTRKEY( "OK" ), LNUMVAL ( 1 ) },
    { LSTRKEY( "TIMEOUT" ), LNUMVAL ( 2 ) },

    { LNILKEY, LNILVAL }
};


//////////////////////////////////////////////////////////////////////////////
// SVCD.init() implementation
// Maintainer: Michael Andersen <michael@steelcode.com>
/////////////////////////////////////////////////////////////

// The anonymous func in init that allows for dynamic binding of advert_received
static int svcd_init_adv_received( lua_State *L )
{
    int numargs = lua_gettop(L);
    lua_getglobal(L, "SVCD");
    lua_pushstring(L, "advert_received");
    //Get the advert_received function from the table
    lua_gettable(L, -2);
    //Move it to before the arguments
    lua_insert(L, 1);
    //Pop off the SVCD table
    lua_settop(L, numargs+1);
    //Note that we now call this function from C, so it cannot use any cord await
    //functions. If it needs to do that sort of thing, it can spawn a new cord to do so
    lua_call(L, numargs, 0);
    return 0;
}

// Lua: storm.n.svcd_init ( id, onready )
// Initialises the SVCD module, in global scope
static int svcd_init( lua_State *L )
{
    if (lua_gettop(L) != 2) return luaL_error(L, "Expected (id, onready)");
#if SVCD_PUREC
//If we are going for a pure C implementation, then this would create the global
//SVCD table, otherwise it is created by the Lua code
        //Create the SVCD global table
        lua_createtable(L, 0, 8);
        //Set the metatable
        lua_pushrotable(L, (void*)svcd_meta_map);
        lua_setmetatable(L, 3);
        //Create the empty tables
        lua_pushstring(L, "manifest_map");
        lua_newtable(L);
        lua_settable(L, 3);
        lua_pushstring(L, "blsmap");
        lua_newtable(L);
        lua_settable(L, 3);
        lua_pushstring(L, "blamap");
        lua_newtable(L);
        lua_settable(L, 3);
        lua_pushstring(L, "oursubs");
        lua_newtable(L);
        lua_settable(L, 3);
        lua_pushstring(L, "subscribers");
        lua_newtable(L);
        lua_settable(L, 3);
        lua_pushstring(L, "handlers");
        lua_newtable(L);
        lua_settable(L, 3);
        lua_pushstring(L, "ivkid");
        lua_pushnumber(L, 0);
        lua_settable(L, 3);
        //Duplicate the TOS so the table is still there after
        //setglobal
        lua_pushvalue(L, -1);
        lua_setglobal(L, "SVCD");
#else
    //Load the SVCD table that Lua created
    //This will be index 3
    lua_getglobal(L, "SVCD");
    printf("Put table at %d\n", lua_gettop(L));
#endif
    //Now begins the part that corresponds with the lua init function

    //SVCD.asock
    lua_pushstring(L, "asock");
    lua_pushlightfunction(L, libstorm_net_udpsocket);
    lua_pushnumber(L, 2525);
    lua_pushlightfunction(L, svcd_init_adv_received);
    lua_call(L, 2, 1);
    lua_settable(L, 3); //Store it in the table

    //SVCD.ssock
    lua_pushstring(L, "ssock");
    lua_pushlightfunction(L, libstorm_net_udpsocket);
    lua_pushnumber(L, 2526);
    lua_pushstring(L, "wdispatch");
    lua_gettable(L, 3);
    lua_call(L, 2, 1);
    lua_settable(L, 3); //Store

    //SVCD.nsock
    lua_pushstring(L, "nsock");
    lua_pushlightfunction(L, libstorm_net_udpsocket);
    lua_pushnumber(L, 2527);
    lua_pushstring(L, "ndispatch");
    lua_gettable(L, 3);
    lua_call(L, 2, 1);
    lua_settable(L, 3); //Store

    //SVCD.wcsock
    lua_pushstring(L, "wcsock");
    lua_pushlightfunction(L, libstorm_net_udpsocket);
    lua_pushnumber(L, 2528);
    lua_pushstring(L, "wcdispatch");
    lua_gettable(L, 3);
    lua_call(L, 2, 1);
    lua_settable(L, 3); //Store

    //SVCD.ncsock
    lua_pushstring(L, "ncsock");
    lua_pushlightfunction(L, libstorm_net_udpsocket);
    lua_pushnumber(L, 2529);
    lua_pushstring(L, "ncdispatch");
    lua_gettable(L, 3);
    lua_call(L, 2, 1);
    lua_settable(L, 3); //Store

    //SVCD.subsock
    lua_pushstring(L, "subsock");
    lua_pushlightfunction(L, libstorm_net_udpsocket);
    lua_pushnumber(L, 2530);
    lua_pushstring(L, "subdispatch");
    lua_gettable(L, 3);
    lua_call(L, 2, 1);
    lua_settable(L, 3); //Store

    //manifest table
    lua_pushstring(L, "manifest");
    lua_newtable(L);
    lua_pushstring(L, "id");
    lua_pushvalue(L ,1);
    lua_settable(L, -3);
    lua_settable(L, 3);

     //If id ~= nil
    if (!lua_isnil(L, 1)) {
        lua_pushlightfunction(L, libstorm_os_invoke_periodically);
        lua_pushnumber(L, 3*SECOND_TICKS);
        lua_pushlightfunction(L, libstorm_net_sendto);
        lua_pushstring(L, "asock");
        lua_gettable(L, 3);
        //Pack SVCD.manifest
        lua_pushlightfunction(L, libmsgpack_mp_pack);
        lua_pushstring(L, "manifest");
        lua_gettable(L, 3);
        lua_call(L, 1, 1);
        //Address
        lua_pushstring(L, "ff02::1");
        lua_pushnumber(L, 2525);
        cord_dump_stack(L);
        lua_call(L, 6, 0);

        //Enable the bluetooth
        lua_pushlightfunction(L, libstorm_bl_enable);
        lua_pushvalue(L, 1);
        lua_pushstring(L, "cchanged");
        lua_gettable(L, 3);
        lua_pushvalue(L, 2);
        lua_call(L, 3, 0);
    }

    return 0;
}

//////////////////////////////////////////////////////////////////////////////
// SVCD.notify() implementation
// Maintainers: Sam Kumar <samkumar@berkeley.edu>
//              Leonard Truong <leonardtruong@berkeley.edu>
//              Michael Chen <mc.michaelchen.us@gmail.com>
/////////////////////////////////////////////////////////////
int notify_cord(lua_State* L) {
    int header_index;
    // Push SVCD.subscribers[svc_id][attr_id] (upvalue 1) onto stack
    lua_pushvalue(L, lua_upvalueindex(1));

    // set previous key
    lua_pushvalue(L, lua_upvalueindex(3));

    // get next key
    if (lua_next(L, 1)) {
        // return if we've finished
	return 0;
    }

    // local header = storm.array.create(1, storm.array.UINT16)
    lua_pushlightfunction(L, arr_create);
    lua_pushnumber(L, 1);
    lua_pushnumber(L, ARR_TYPE_UINT16);
    lua_call(L, 2, 1);
    header_index = lua_gettop(L);

    // header:set(1, v)
    lua_pushstring(L, "set");
    lua_gettable(L, -2);
    lua_pushnumber(L, 1);
    lua_pushvalue(L, 3);  // Store current value (3rd element on stack)
    lua_call(L, 2, 0);

    // storm.net.sendto(SVCD.ncsock, header:as_str()..value, k, 2527)
    lua_pushlightfunction(L, libstorm_net_sendto);
    lua_getglobal(L, "SVCD");
    lua_pushstring(L, "ncsock");
    lua_gettable(L, -2);
    lua_pushstring(L, "as_str");
    lua_gettable(L, header_index);
    lua_pushvalue(L, lua_upvalueindex(2));  // value stored as upvalue 2
    lua_concat(L, 2);  // Use lua's concat operator (..)
    lua_pushvalue(L, 2);  // Push current key
    lua_pushnumber(L, 2527);

    lua_pushlightfunction(L, libstorm_os_invoke_later);
    lua_pushnumber(L, 70 * MILLISECOND_TICKS);

    // Push next upvalues
    lua_pushvalue(L, 1);  // Subscribers table
    lua_pushnil(L, lua_upvalueindex(2));  // val
    lua_pushvalue(L, 3);  // Current key
    lua_pushcclosure(L, &notify_cord, 3);  // continuation
    lua_call(L, 3, 0);
    return 0;
}

int notify(lua_State* L) {
    // args: svc_id, attr_id, value

    // SVCD.blamap[svc_id][attr_id]
    lua_getglobal(L, "SVCD");
    int index_SVCD = lua_gettop(L);
    lua_pushstring(L, "blamap");
    lua_gettable(L, index_SVCD);
    lua_pushvalue(L, 1);  // Push on svc_id
    lua_gettable(L, -2);
    lua_pushvalue(L, 2);  // Push on attr_id
    lua_gettable(L, -2);
    int index_arg0 = lua_gettop(L);

    // storm.bl.notify(SVCD.blamap[svc_id][attr_id], value)
    lua_pushlightfunction(L, libstorm_bl_notify);
    lua_pushvalue(L, index_arg0);  // Push on SVCD.blamap[svc_id][attr_id]
    lua_pushvalue(L, 3);  // Push on value
    lua_call(L, 2, 0);
    lua_pop(L, lua_gettop(L) - index_SVCD);  // Clear stack

    // if SVCD.subscribers[svc_id] == nil then
    //  return
    // end
    lua_pushstring(L, "subscribers");
    lua_gettable(L, index_SVCD);
    lua_pushvalue(L, 1);
    lua_gettable(L, -2);
    if (lua_isnil(L, -1)) {
	return 0;
    }

    // if SVCD.subscribers[svc_id][attr_id] == nil then
    //  return
    // end
    lua_pushvalue(L, 2);
    lua_gettable(L, -1);
    if (lua_isnil(L, -1)) {
	return 0;
    }

    int attr_index = lua_gettop(L);  // Index of SVCD.subscribers[svc_id][attr_id]

    // Original lua code:
    // cord.new(function()
    //     for k, v in pairs(SVCD.subscribers[svc_id][attr_id]) do
    //         local header = storm.array.create(1, storm.array.UINT16)
    //         header:set(1, v)
    //         storm.net.sendto(SVCD.ncsock, header:as_str()..value, k, 2527)
    //         cord.await(storm.os.invokeLater, 70*storm.os.MILLISECOND)
    //     end
    // end)

    // We implemented this using a recursive continuation with a closure to keep
    // track of state.  We start by calling the continuation with nil as the
    // current key.  It then uses lua_next to get the next key, then recursively
    // sets itself as the continuation with the new current key.  Once the last
    // key is processed the final continuation will stop, ending the recursion.

    // Push SVCD.subscribers[svc_id][attr_id] as an upvalue for closure
    lua_pushvalue(L, attr_index);
    // Push value as upvalue for closure
    lua_pushvalue(L, 3);
    lua_pushnil(L);
    lua_pushcclosure(L, &notify_cord, 3);  // Anonymous function implemented in notify_cord

    lua_call(L, 1, 0);
    return 0;
}
