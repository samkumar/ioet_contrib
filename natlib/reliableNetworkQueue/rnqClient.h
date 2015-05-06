int rnqclient_new(lua_State* L);
int rnqclient_sendMessage(lua_State* L);
int rnqclient_close(lua_State* L);

#define RNQC_SYMBOLS \
    { LSTRKEY( "NQClient_new" ), LFUNCVAL( rnqclient_new ) }, \
    { LSTRKEY( "NQClient_sendMessage" ), LFUNCVAL( rnqclient_sendMessage ) }, \
    { LSTRKEY( "NQClienet_close" ), LFUNCVAL( rnqclient_close ) },
