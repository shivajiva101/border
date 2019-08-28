--[[
original code provided by tenplus1
This mod instigates an effective border for new players joining a server
with persistence of the last state and visa records across server restarts
]]

local mod_data = minetest.get_mod_storage()
local border = mod_data:get_string("status")
local visa = mod_data:get_string("visa")
local duration = minetest.settings:get("border.visa_duration") or 86400 -- 1 day
local msg = minetest.settings:get("border.msg") or "\nSorry, no new players being admitted at this time!"

local function update_visa_cache(name)
	-- If name exists in cache remove it
	if visa[name] then
		visa[name] = nil
		collectgarbage()
	else
		-- cache visa
		visa[name] = os.time() + duration 
	end
	mod_data:set_string("visa", minetest.serialize(visa))
end

if border == "" then
	-- Initialise
	mod_data:set_string("status", "OPEN")
	border = "OPEN"
end

if visa == "" then
	-- initialise
	visa = {}
else
	-- load visa table
	visa = minetest.deserialize(visa)
	-- iterate
	for name,expires in pairs(visa) do
		local t_remains = expires - os.time()
		if t_remains > 0 then
			--set
			minetest.after(t_remains, update_visa_cache, name)
		else
			-- remove
			update_visa_cache(name)
		end
	end
end

-- announce status
minetest.after(5, function()
	minetest.chat_send_all("[border:info] border is "..border)
end)

-- chat command to toggle the border status
minetest.register_chatcommand("border", {
    params = "",
    description = "Toggles if new players are allowed",
    privs = {server = true},
    func = function (name, param)
      if border == "CLOSED" then
        border = "OPEN"
        minetest.chat_send_player(name, "[border:info] allowing new players.")
      else
        border = "CLOSED"
        minetest.chat_send_player(name, "[border:info] refusing new players.")
      end
      mod_data:set_string("status", border) -- save current state
    end
})

-- add visa
minetest.register_chatcommand("visa", {
	params = "player",
	description = "Adds a temporary visa allowing a new player to create an account",
	privs = {server = true},
	func = function (name, param)
		if not param then
			minetest.chat_send_player(name, "Use: /visa <name>")
		end
		update_visa_cache(param)
		minetest.after(duration, update_visa_cache, param)
		minetest.chat_send_player(name, "A visa was issued to "..param)
    end
  })

-- register callback
minetest.register_on_prejoinplayer(function(name, ip)
	-- owner exception
	if minetest.setting_get("name") == name then
			return
	end
	-- stop NEW players from joining unless they have a visa
	local player_exists = minetest.get_auth_handler().get_auth(name)
	if border == "CLOSED" and not player_exists and not visa[name] then
			return msg
	end
	if visa[name] then update_visa_cache(name) end -- remove visa
end
)
