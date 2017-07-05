--[[
original code provided by tenplus1
This mod instigates an effective border for new players joining a server
with persistence of the last state across server restarts
]]

local mod_data = minetest.get_mod_storage()
local border = "false"

-- initialise
if mod_data:get_string("status") == "" then
  mod_data:set_string("status", "true") 
end

--set
border = mod_data:get_string("status")

-- toggle new players
minetest.register_chatcommand("border", {
    params = "",
    description = "Toggles if new players are allowed",
    privs = {server = true},
    func = function (name, param)
      if border == "true" then
        border = "false"
        minetest.chat_send_player(name, "Server allowing new players.")
      else
        border = "true"
        minetest.chat_send_player(name, "Server refusing new players.")
      end
      mod_data:set_string("flag", border) -- save
    end
  })

-- register hook
minetest.register_on_prejoinplayer(function(name, ip)
    -- owner exception
	if minetest.setting_get("name") == name then
	    return
	end
    -- stop NEW players from joining
    if border == "true" and not core.auth_table[name] then
      return ("\nSorry, no new players being admitted at this time!")
    end
  end
)
