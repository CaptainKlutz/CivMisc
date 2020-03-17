
local ONE_TIME_TP_PERIOD = 60 * 30 -- 30 mins

minetest.register_on_newplayer(function(player)
      local pname = player:get_player_name()
      local meta = player:get_meta()
      local time = os.time(os.date("!*t"))
      meta:set_int("onetimetp", time)
      minetest.after(3,
         function()
            minetest.chat_send_player(
               pname, "Your one-time teleport is available!\n"
                  .. "   See `/teleport_request` for more information."
            )
         end
      )
      minetest.chat_send_all(
         pname .. " joined the server for the first time!"
      )
end)

local teleport_requests = {}

minetest.register_chatcommand(
   "teleport_request",
   {
      description = "Sends a one-time teleport request to a player.",
      params = "<player>",
      func = function(sender_name, params)
         local sender = minetest.get_player_by_name(sender_name)
         local sender_meta = sender:get_meta()

         local now = os.time(os.date("!*t"))
         if (not sender_meta:contains("onetimetp"))
            or sender_meta:get_int("onetimetp") + ONE_TIME_TP_PERIOD < now
            or (sender_meta:contains("onetimetp_available")
                   and sender_meta:get_int("onetimetp_available") == 0)
         then
            return false, "Your one-time teleport is no longer available."
         end

         if params == ""
            or not sender_meta:contains("onetimetp_available")
         then
            local mins = tostring(math.floor(
               ((sender_meta:get_int("onetimetp") + ONE_TIME_TP_PERIOD) - now)
                  / 60
            ))
            minetest.chat_send_player(
               sender_name,
               "\nBefore using /teleport_request, please note:\n "
                  .. " 1. You can only teleport once using this command.\n "
                  .. " 2. Your ability to teleport expires in "..mins.." minutes.\n "
                  .. " 3. Your inventory will be dropped before you teleport.\n"
            )
            if params ~= "" then
               minetest.chat_send_player(
                  sender_name,
                  "Use `/teleport_request " .. params
                     .. "` again to confirm your teleport."
               )
               sender_meta:set_int("onetimetp_available", 1)
            end
            minetest.chat_send_player(sender_name, " \n")
            -- The player must see the above message before trying to teleport.
            return false
         end

         if params == "" then
            return false, "Please specify the player you wish to teleport to."
         end

         local target_name = params

         if not minetest.get_player_by_name(target_name) then
            return false, target_name .. " is not online."
         end

         minetest.chat_send_player(
            target_name, sender_name .. " has requested a "
               .. "teleport to you. Use '/teleport_accept " .. sender_name
               .. "' to accept the request."
         )
         teleport_requests[target_name] = teleport_requests[target_name] or {}
         teleport_requests[target_name][sender_name] = true

         return true, "One-time teleport request sent to " .. target_name
            .. ". Please wait for them to accept it."
      end
   }
)

local function teleport_player(src_name, dst_name)
   if not teleport_requests[dst_name]
      or not teleport_requests[dst_name][src_name]
   then
      minetest.chat_send_player(
         dst_name, src_name .. " did not request to teleport to you."
      )
      return false
   end

   local src = minetest.get_player_by_name(src_name)
   if not src then
      minetest.chat_send_player(
         dst_name, src_name .. " is not online."
      )
      return false
   end

   local src_meta = src:get_meta()
   local now = os.time(os.date("!*t"))
   if (not src_meta:contains("onetimetp"))
      or src_meta:get_int("onetimetp") + ONE_TIME_TP_PERIOD < now
      or (not src_meta:contains("onetimetp_available"))
      or src_meta:get_int("onetimetp_available") == 0
   then
      minetest.chat_send_player(
         dst_name, src_name .. " can no longer teleport to you."
      )
      return false
   end

   -- The dst is the sender of this command, so this obj will always be valid.
   local dst = minetest.get_player_by_name(dst_name)

   -- XXX: this is a bit of a hack.
   --
   -- We kill the player, then wait a couple of seconds to teleport + revive
   -- them manually -- bypassing `minetest.register_on_respawnplayer`. We then
   -- force-close the death formspec (it's useless once the player is revived.)
   --
   -- However, perhaps I should be handling this more cleanly using
   -- `minetest.register_on_respawnplayer` instead. That change is trickier
   -- because it requires some coherency with spawnutils.lua and overriding
   -- randomspawning. We should have a way to change the text on the death
   -- formspec, too.

   src:set_hp(0)

   -- capture the dst_pos prior to executing the delayed revive. Avoids a
   -- potential crash if the dst player disconnects immediately after accepting.
   local dst_pos = dst:get_pos()
   minetest.after(
      2,
      function()
         -- Sanity check that the src player is still online.
         if not minetest.get_player_by_name(src_name)
            or src_meta:get_int("onetimetp_available") == 0
         then
            minetest.chat_send_player(
               dst_name, src_name .. " could not be teleported at this time."
            )
            return
         end

         src_meta:set_int("onetimetp_available", 0)
         minetest.chat_send_player(
            src_name, "You have been teleported to "..dst_name.."!"
         )
         minetest.chat_send_player(
            dst_name, src_name .. " has been teleported to you!"
         )
         src:set_pos(dst_pos)
         src:set_hp(200)
         minetest.close_formspec(src_name, "")
      end
   )

   return true
end

minetest.register_chatcommand(
   "teleport_accept",
   {
      params = "<player>",
      func = function(sender_name, params)
         -- local sender = minetest.get_player_by_name(sender_name)

         if params == "" then
            return false, "Please specify a player name to teleport to you."
         end

         local target_name = params

         return teleport_player(target_name, sender_name)

      end
   }
)

minetest.debug("[CivMisc] OneTimeTp initialised.")
