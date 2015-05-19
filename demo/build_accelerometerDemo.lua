#!/usr/bin/env lua

-- RUN THIS FILE FROM THE ROOT DIRECTORY (containing contrib, toolchain etc)

-- This is the build configuration file.

-- this file will be automatically run on startup. If it terminates, the node
-- will drop to a debug shell. If this file is not specified, the node will
-- enter the shell immediately.
autorun = "ioet_contrib/demo/accelerometerDemo.lua"

-- These are files that will be available as libraries. The name sets how they
-- are 'require()'ed.
libs = { --<< EDIT ME
    cord    = "ioet_contrib/lib/cord.lua",
    stormsh = "ioet_contrib/lib/stormsh.lua",
    svcd = "ioet_contrib/lib/svcd/svcd.lua",
    bearcast = "ioet_contrib/lib/bearCast/bearcast.lua",
    reg = "ioet_contrib/lib/i2creg.lua",
    accel = "ioet_contrib/lib/accelerometer.lua"
}


-- If this is true, the toolchains will automatically check for updates when
-- you program
autoupdate = true

-- if true, this will reflash the kernel. This slows down programming, and is
-- not necessary unless you have been told there are kernel updates.
reflash_kernel = true

-- these get passed to the kernel makefile
kernel_opts = {
    quiet = true, -- if set to false, you will see kernel debug messages
    eth_shield = false -- set to true to enable the ethernet shield
}


----
dofile("toolchains/storm_elua/build_support.lua")
go_build()
