-- Load config parameters
local modpath = minetest.get_modpath(minetest.get_current_modname()) .. "/"

minetest.debug("CivMisc initializing...")

local groundcollect = dofile(modpath .. "groundcollect.lua")

local sneakbob = dofile(modpath .. "sneakbob.lua")

minetest.debug("CivMisc initialised.")

