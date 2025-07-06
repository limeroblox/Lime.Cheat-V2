-- This is an example script you'd host remotely and load with loadstring
-- It detects the game ID, selects a script URL accordingly,
-- fetches that script, and returns info back to the loader

local HttpService = game:GetService("HttpService")

local gameId = tostring(game.GameId)  -- or use PlaceId if you prefer

-- Map GameId to script URLs (example)
local scripts = {
    ["123456789"] = "https://raw.githubusercontent.com/YourUsername/YourRepo/main/scripts/script1.lua",
    ["987654321"] = "https://raw.githubusercontent.com/YourUsername/YourRepo/main/scripts/script2.lua",
}

local url = scripts[gameId]

if not url then
    error("No script found for this GameId: " .. gameId)
end

-- Fetch the actual script for this game
local success, scriptText = pcall(function()
    return HttpService:GetAsync(url)
end)

if not success then
    error("Failed to fetch script: " .. tostring(scriptText))
end

-- Optionally: Return info back to loader (e.g., script size, url)
print("[Loader] Fetched script for GameId:", gameId)
print("[Loader] Script URL:", url)
print("[Loader] Script length:", #scriptText, "bytes")

-- Execute the fetched script safely
local func, loadErr = loadstring(scriptText)
if not func then
    error("Failed to load fetched script: " .. tostring(loadErr))
end

local ok, runErr = pcall(func)
if not ok then
    error("Error running fetched script: " .. tostring(runErr))
end

-- Return something if needed (optional)
return true
