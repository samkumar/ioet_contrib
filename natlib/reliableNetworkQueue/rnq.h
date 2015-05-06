int rnqclient_new(lua_State* L);
int rnqclient_sendMessage(lua_State* L);
int rnqclient_close(lua_State* L);

int rnqserver_new(lua_State* L);
int rnqserver_close(lua_State* L);

#define RNQC_SYMBOLS \
    { LSTRKEY( "NQClient_new" ), LFUNCVAL( rnqclient_new ) }, \
    { LSTRKEY( "NQClient_sendMessage" ), LFUNCVAL( rnqclient_sendMessage ) }, \
    { LSTRKEY( "NQClient_close" ), LFUNCVAL( rnqclient_close ) }, \
    { LSTRKEY( "NQServer_new" ), LFUNCVAL( rnqserver_new ) }, \
    { LSTRKEY( "NQServer_close" ), LFUNCVAL( rnqserver_close ) },
