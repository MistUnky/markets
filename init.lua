-- /price - list price of item (initial=initial_price (value subj to change))
-- /sell - sells 1 of item in hand for market price, and decrease market price by 1
-- /buy - buys 1 of item in hand for market price, and increase market price by 1
-- negative price? == 0 or?
-- price = demand - supply

player_balances = {}
item_supply = {}
item_demand = {}

minetest.register_on_dignode(function(pos, oldnode, digger)
	local inv = digger:get_inventory()
	if player_balances[digger:get_player_name()] == nil then
		player_balances[digger:get_player_name()] = 1
	else
		player_balances[digger:get_player_name()] = player_balances[digger:get_player_name()] + 1
	end
end)

minetest.register_chatcommand("bal", {
	params = "",
	description = "Print Balance",
	func = function(name, param)
		if player_balances[name] == nil then
			player_balances[name] = 0
		end
		minetest.chat_send_player(name, "Balance is currently "..player_balances[name])
		return true
	end
})

minetest.register_chatcommand("price", {
	params = "<itemstr>",
	description = "List price of item",
	func = function(name, param)
		if param == "" or param == nil then
			minetest.chat_send_player(name, "You can't price nil!")
			return false
		end
		if item_supply[param] == nil then
			minetest.chat_send_player(name, "Not yet on market!")
			return true
		end
		minetest.chat_send_player(name, "Price of "..param.." is "..(item_demand[param] - item_supply[param]))
		return true
	end
})

minetest.register_chatcommand("buy", {
	params = "<itemstr>",
	description = "Buy one of item",
	func = function(name, param)
		if param == "" or param == nil then
			minetest.chat_send_player(name, "You can't buy nil!")
			return false
		end
		if player_balances[name] == nil then
			player_balances[name] = 0
		end
		if item_supply[param] == nil then
			minetest.chat_send_player(name, "Not yet on market!")
			return true
		end
		if item_demand[param] == nil then
			item_demand[param] = 0
		end
		local price = item_demand[param] - item_supply[param]
		if player_balances[name] >= price then
			player_balances[name] = player_balances[name] - price
			minetest.chat_send_player(name, "Bought! Balance is now "..player_balances[name])
			minetest.get_player_by_name(name):get_inventory():add_item("main", param)
			item_demand[param] = item_demand[param] + 1
			item_supply[param] = item_supply[param] - 1
			return true
		else
			minetest.chat_send_player(name, "You're too poor!")
			return true
		end
	end
})

minetest.register_chatcommand("sell", {
	params = "",
	description = "Sell one of item",
	func = function(name, param)
		local inhand = minetest.get_player_by_name(name):get_wielded_item()
		if inhand:get_name() == "" then
			minetest.chat_send_player(name, "You can't sell nil!")
			return false
		end
		if player_balances[name] == nil then
			player_balances[name] = 0
		end
		if item_supply[inhand:get_name()] == nil then
			item_supply[inhand:get_name()] = 0
		end
		if item_demand[inhand:get_name()] == nil then
			item_demand[inhand:get_name()] = 0
		end
		local price = item_demand[inhand:get_name()] - item_supply[inhand:get_name()]
		if price < 0 then
			if player_balances[name] > 0 - price then
				player_balances[name] = player_balances[name] + price
			else
				minetest.chat_send_player(name, "You don't have enough funds!")
				return true
			end
		else
			player_balances[name] = player_balances[name] + price
		end
		item_supply[inhand:get_name()] = item_supply[inhand:get_name()] + 1
		item_demand[inhand:get_name()] = item_demand[inhand:get_name()] - 1
		minetest.chat_send_player(name, "Sold "..inhand:get_name().."! Balance is now "..player_balances[name])
		if inhand:get_count() == 1 then
			minetest.get_player_by_name(name):set_wielded_item(ItemStack(""))
		else
			minetest.get_player_by_name(name):set_wielded_item(ItemStack(inhand:get_name().." "..(inhand:get_count()-1)))
		end
		return true
	end
})

minetest.register_chatcommand("wtf", {
	params = "",
	description = "Detect Item in Hand's Name",
	func = function(name, param)
		minetest.chat_send_player(name, "You have item \""..minetest.get_player_by_name(name):get_wielded_item():get_name().."\"")
		return true
	end
})

minetest.register_chatcommand("gdp", {
	params = "",
	description = "List total money in circulation", -- money.circ is MV/P=Y
	func = function(name, param)
		local gdp = 0
		for key, val in pairs(player_balances) do
			gdp = gdp + val
		end
		minetest.chat_send_player(name, "GDP: "..gdp)
		return true
	end
})

function save_market()
	local dat = {}
	dat.is = item_supply
	dat.id = item_demand
	dat.pb = player_balances
	local fp = io.open(minetest.get_worldpath() .. "/markets.dat", "w")
	fp:write(minetest.serialize(dat))
	io.close(fp)
end
	
function load_market()
	local dat = {}
	local fp = io.open(minetest.get_worldpath() .. "/markets.dat", "r")
	if fp then
		dat = minetest.deserialize(fp:read("*all"))
		item_supply = dat.is
		item_demand = dat.id
		player_balances = dat.pb
		io.close(fp)
	end
end

load_market()

minetest.register_on_shutdown(function()
	save_market()
end)
