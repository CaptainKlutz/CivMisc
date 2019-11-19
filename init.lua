-- Load config parameters
local modpath = minetest.get_modpath(minetest.get_current_modname()) .. "/"

minetest.debug("CivMisc initializing...")

local groundcollect = dofile(modpath .. "groundcollect.lua")

local knockback = dofile(modpath .. "knockback.lua")

local sneakbob = dofile(modpath .. "sneakbob.lua")

local minimap = dofile(modpath .. "minimap.lua")

local cleanup = dofile(modpath .. "cleanup.lua")

local spawnutils = dofile(modpath .. "spawnutils.lua")

minetest.debug("CivMisc initialised.")
