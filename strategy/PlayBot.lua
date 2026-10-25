package.path = package.path .. ";./lua_scripts/skill/?.lua"
package.path = package.path .. ";./lua_scripts/play/?.lua"
package.path = package.path .. ";./lua_scripts/worldmodel/?.lua"
package.path = package.path .. ";./lua_scripts/opponent/?.lua"

local allowedOpponents = { Default = true, K1 = true }
if not allowedOpponents[json.OPPONENT_NAME] then
	error("Unsupported opponent profile")
end

local function assertSafeName(value, label)
	if type(value) ~= "string" or value == "" or value:find("..", 1, true)
		or value:find("/", 1, true) or value:find("\\", 1, true) then
		error("Invalid " .. label)
	end
end

local function assertSafePlayPath(value)
	if type(value) ~= "string" or value == "" or value:find("..", 1, true)
		or value:sub(1, 1) == "/" or value:find("\\", 1, true) or value:find(":", 1, true) then
		error("Invalid play path")
	end
end

require(json.OPPONENT_NAME)
require("Skill")
require("Play")
require("task")
math.randomseed(os.time())

for _, value in ipairs(json.gSkill) do
	assertSafeName(value, "skill name")
	local filename = "./lua_scripts/skill/"..value..".lua"
	dofile(filename)
end

for _, value in ipairs(json.gPlayBotSkill) do
	assertSafeName(value, "PlayBot skill name")
	local filename = "./lua_scripts/skill/PlayBotSkill/"..value..".lua"
	--print(filename)
	dofile(filename)
end

for _, value in ipairs(gPlay) do
	assertSafePlayPath(value)
	local filename = "./lua_scripts/play/"..value..".lua"
	dofile(filename)
end
