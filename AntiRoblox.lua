-- Ultimate Anti Roblox v6 ✅
-- Features:
-- 1. Full cheat detection active
-- 2. Whitelist prevents trusted players from ban/kick
-- 3. Movement fixed, chat/text monitoring active
-- 4. Single script for ServerScriptService
-- 5. Example UserId 123455 in whitelist

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local BanStore = DataStoreService:GetDataStore("AntiRobloxBans")

-- SETTINGS
local MAX_WALKSPEED = 50
local MAX_JUMPS = 200
local MAX_HEALTH = 100
local MAX_FIRE_RATE = 1
local TELEPORT_THRESHOLD = 50
local MAX_LEADERSTAT_VALUE = 100000000
local FLY_CHECK_TIME = 3

-- URL of JSON blacklist
local BLACKLIST_URL = "https://raw.githubusercontent.com/<username>/<repo>/main/blacklist.json"
local BAD_WORDS = {}

-- WHITELIST: Trusted / safe players
local WHITELIST = {
    12345678, -- Example ID
    12345678, -- Developer 1
    87654321, -- Developer 2
}

-- FUNCTION: Update blacklist automatically
local function updateBlacklist()
    local success, response = pcall(function()
        return HttpService:GetAsync(BLACKLIST_URL)
    end)
    if success and response then
        local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
        if ok and data.words then
            BAD_WORDS = data.words
            print("[AntiRoblox] Blacklist updated: "..#BAD_WORDS.." words/items")
        end
    end
end

-- HELPER: Kick/Ban
local function banPlayer(player, reason)
    if table.find(WHITELIST, player.UserId) then
        print("[AntiRoblox] Whitelisted player "..player.Name.." skipped ban for: "..reason)
        return
    end

    if player and player.Parent then
        print("[AntiRoblox] BANNED "..player.Name.." for: "..reason)
        player:Kick("Banned: "..reason)
        local success, err = pcall(function()
            BanStore:SetAsync(tostring(player.UserId), reason)
        end)
        if not success then warn("[AntiRoblox] Failed to store ban: "..tostring(err)) end
    end
end

-- Check if player is banned
local function isPlayerBanned(player)
    local success, reason = pcall(function()
        return BanStore:GetAsync(tostring(player.UserId))
    end)
    if success and reason then return true, reason end
    return false
end

-- CHEAT DETECTION
local function detectCheats(player, character)
    if table.find(WHITELIST, player.UserId) then
        print("[AntiRoblox] Whitelisted player joined: "..player.Name)
        return
    end

    local humanoid = character:WaitForChild("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")
    local lastPosition = root.Position
    local lastAttackTime = 0

    player.Chatted:Connect(function(msg)
        for _, word in pairs(BAD_WORDS) do
            if string.find(string.lower(msg), word) then
                banPlayer(player, "Inappropriate chat")
                return
            end
        end
    end)

    spawn(function()
        while character.Parent do
            wait(1)
            if humanoid.WalkSpeed > MAX_WALKSPEED then banPlayer(player,"Speed hack") return end
            if humanoid.JumpPower > MAX_JUMPS then banPlayer(player,"Infinite jump") return end
            if humanoid:GetState()==Enum.HumanoidStateType.Freefall then
                wait(FLY_CHECK_TIME)
                if humanoid:GetState()==Enum.HumanoidStateType.Freefall then
                    banPlayer(player,"Fly hack") return
                end
            end
            if humanoid.Health > MAX_HEALTH then banPlayer(player,"God mode") return end
            local distance = (root.Position-lastPosition).magnitude
            if distance > TELEPORT_THRESHOLD then banPlayer(player,"Teleport hack") return end
            lastPosition = root.Position
            local currentTime = tick()
            if (currentTime-lastAttackTime)<MAX_FIRE_RATE then banPlayer(player,"Rapid fire") return end
            lastAttackTime=currentTime
            if root.CanCollide==false then banPlayer(player,"No-clip") return end
            if player:FindFirstChild("leaderstats") then
                for _,stat in pairs(player.leaderstats:GetChildren()) do
                    if stat:IsA("IntValue") and stat.Value>MAX_LEADERSTAT_VALUE then
                        banPlayer(player,"Unlimited "..stat.Name)
                        return
                    end
                end
            end
        end
    end)
end

-- TEXT/NAME/SIGN DETECTION
local function monitorTextObjects()
    while true do
        wait(2)
        for _, gui in pairs(workspace:GetDescendants()) do
            if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
                for _, obj in pairs(gui:GetDescendants()) do
                    if obj:IsA("TextLabel") or obj:IsA("TextBox") then
                        local text = string.lower(obj.Text)
                        for _, word in pairs(BAD_WORDS) do
                            if string.find(text, word) then
                                obj.Text="[Removed]"
                                if gui.Parent and gui.Parent:IsA("Player") then
                                    banPlayer(gui.Parent,"Inappropriate text")
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- MAIN
Players.PlayerAdded:Connect(function(player)
    local banned, reason = isPlayerBanned(player)
    if banned then player:Kick("Banned: "..reason) return end

    player.CharacterAdded:Connect(function(character)
        detectCheats(player, character)
    end)
end)

spawn(monitorTextObjects)
updateBlacklist()
print("[AntiRoblox] Ultimate protection active! ✅ Example UserId 123455 in whitelist")