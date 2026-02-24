pcall(coroutine.yield, true, 1, game)
pcall(coroutine.yield, true, 2, workspace)
pcall(coroutine.yield, true, 3, script)

local scriptUrl = "https://raw.githubusercontent.com/buhayhayahay332-lang/Compx/main/Operation%20One/main.lua"
loadstring(game:HttpGet(scriptUrl, true))()
