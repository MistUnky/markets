-- /price - list price of item (initial=initial_price (value subj to change))
-- /sell - sells 1 of item in hand for market price, and decrease market price by 1
-- /buy - buys 1 of item in hand for market price, and increase market price by 1
-- negative price? == 0 or?

market_prices = {}
player_balances = {}
local initial_price = 55555
local lower_limit_price = 0 -- items allowed to be free but cannot become actual "negative price" - can also be used to limit it at 1 value |||||||
local flation_rate = 0.23 -- 23% inflation rate / deflation rate by default

minetest.register_on_dignode(function(pos, oldnode, digger)
	local inv = digger:get_inventory()
	if inv and inv:room_for_item("main", "my_economy:9_0") then
		if player_balances[digger:get_player_name()] == nil then
			player_balances[digger:get_player_name()] = 1
		else
			player_balances[digger:get_player_name()] = player_balances[digger:get_player_name()] + 1
		end
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
		if market_prices[param] == nil then
			market_prices[param] = initial_price
		end
		minetest.chat_send_player(name, "Price of "..param.." is "..market_prices[param])
		return true
	end
})

minetest.register_chatcommand("buy", {
	params = "<itemstr> | <idea/stock>", -- fix idea/stock bug lol by checking if item is real, maybe idk it's funny though, could also allow spamming dbs though so :\ TODO
	description = "Buy one of item",
	func = function(name, param)
		if player_balances[name] == nil then
			player_balances[name] = 0
			minetest.chat_send_player(name, "Get some moneyz first!")
			return true
		end
		if market_prices[param] == nil then
			market_prices[param] = initial_price
		end
		if player_balances[name] >= market_prices[param] then
			player_balances[name] = player_balances[name] - market_prices[param]
			market_prices[param] = market_prices[param] * (1 + flation_rate) --+ 1
			minetest.chat_send_player(name, "Bought! Balance is now "..player_balances[name])
			minetest.get_player_by_name(name):get_inventory():add_item("main", param)
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
			minetest.chat_send_player(name, "Get some moneyz!")
		end
		if market_prices[inhand:get_name()] == nil then
			market_prices[inhand:get_name()] = initial_price
		end
		if market_prices[inhand:get_name()] > lower_limit_price then
			player_balances[name] = player_balances[name] + market_prices[inhand:get_name()]
		end
		market_prices[inhand:get_name()] = market_prices[inhand:get_name()] * (1 - flation_rate) --- 1
		minetest.chat_send_player(name, "Sold! Balance is now "..player_balances[name])
		if inhand:get_count() == 1 then
			minetest.get_player_by_name(name):set_wielded_item(ItemStack(""))
		else
			minetest.get_player_by_name(name):set_wielded_item(ItemStack(inhand:get_name().." "..(inhand:get_count()-1)))
		end
		return true
	end
})

function save_market()
	local dat = {}
	dat.mp = market_prices
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
		market_prices = dat.mp
		player_balances = dat.pb
		io.close(fp)
	end
end

load_market()

minetest.register_on_shutdown(function()
	save_market()
end)
