#define GPIO_BASE 0x400E1000
#define PIN_17TH 0x00002000
#define GPIO_SET_ENABLE 0x004
#define OUTPUT_SET_ENABLE 0x044
#define OUTPUT_TOGGLE_REG 0x05C

/** Toggles D2 as fast as possible. */
int toggleD2(lua_State* L) {
    uint32_t volatile* pin;
    pin = (uint32_t volatile*) (GPIO_BASE + GPIO_SET_ENABLE);
    *pin = PIN_17TH;
    pin = (uint32_t volatile*) (GPIO_BASE + OUTPUT_SET_ENABLE);
    *pin = PIN_17TH;
    pin = (uint32_t volatile*) (GPIO_BASE + OUTPUT_TOGGLE_REG);
    while (1) {
        *pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
	*pin = PIN_17TH;
    }
    return 0;
}
