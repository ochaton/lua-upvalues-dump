-- Save previous env for good
local M = {}
local env = getfenv(2)

local names = {}
local AUTOGEN = {
	__index = function(self, key)
		if debug.getinfo(2).func ~= M.envmap then return nil end
--		print("Autocreate for ", names[self], " ",  key)
		rawset(self, key, {})
		return self[key]
	end
}
local symbols = setmetatable({}, AUTOGEN)

local procceed = {}
local map = setmetatable({}, {
	__index = function(self, key)
		rawset(self, key, {
			info = {
				names = {},
			},
			next = {},
		})
		return self[key]
	end
})

names[symbols] = 'symbols'
names[map] = 'map'

local log = setmetatable({}, {
	__index = function (self, key)
		return function(...)
			print(string.format(...))
		end
	end
})

local function envmap(smth, smthname)
	symbols[smth][1] = symbols[smth][1] or smthname
	log.info("Start processing '%s' (%s) known as '%s'", smth, type(smth), symbols[smth][1])
	if procceed[smth] then return map[smth] end
	procceed[smth] = true

	map[smth] = map[smth] or {}

	local need_to_procceed = {}
	local values = {}

	if type(smth) == 'function' then
		local i = 1
		while true do
			local name, item = debug.getupvalue(smth, i)
			i = i + 1
			if not (name and item) then break end
			values[name] = item
			map[item].info.names[smth] = name
			table.insert(symbols[item], symbols[smth][1] .. "." .. name)
		end
	elseif type(smth) == 'table' then
		-- If we link to table
		-- we can execute only functions
		for name, item in pairs(smth) do
			if type(item) == 'function' then
				values[name] = item
			end
			map[item].info.names[smth] = name
			table.insert(symbols[item], symbols[smth][1] .. "." .. name)
		end
	elseif type(smth) == 'string' then
	end

	if type(smth) ~= 'number' and smthname then
		log.info("Register %s as %s", smth, smthname)
		table.insert(symbols[smth], 1, smthname)
	end

	for name, item in pairs(values) do
		log.info("Caught %s (%s)", symbols[item][1], item)
		if type(item) ~= 'number' then
			table.insert(symbols[item], name)
		end

		table.insert(need_to_procceed, { item, name })

		map[smth].next[item] = map[item]
	end

	for _, v in ipairs(need_to_procceed) do
		log.info("Need_to_proceed: %s: %s", v[2], v[1])
		envmap(v[1])
	end

	return map[smth]
end

local function draw(smth, name)
	envmap(smth, name)

	local name = name or symbols[smth][1]

	local drawen = {}

	local function draw_node(me, name)
		if drawen[me] then return end
		drawen[me] = true

		log.info("%s (%s %s)", name, type(me), me)

		for object, node in pairs(map[me].next) do
			draw_node(object, ("%s->%s"):format(name, map[object].info.names[me]))
		end

	end

	draw_node(smth, name)
end

M.envmap = envmap
M.map = map
M.symbols = symbols
M.draw = draw
return M

-- END
