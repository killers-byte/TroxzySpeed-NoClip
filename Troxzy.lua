--[[
    Universal Noclip + Speed + Anti-Kick
    Mobile & PC | Small GUI | Anti-Cheat Bypass
    Executor: Delta, Codex, Xeno, Solara, Wave
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- STATE
-- ============================================================
local State = {
    Noclip = false,
    Speed = false,
    SpeedValue = 50,
    AntiKick = true,
    Bypass = true,
}

-- ============================================================
-- ANTI-CHEAT BYPASS CORE
-- ============================================================

-- 1. Metamethod hook: blokir remote event anti-cheat
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        local name = tostring(self):lower()
        -- blokir remote yang mengandung kata kunci anti-cheat / kick
        if name:find("anticheat") or name:find("detect") or name:find("kick")
           or name:find("ban") or name:find("report") or name:find("flag") then
            return
        end
    end
    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

-- 2. Hook anti-cheat function di garbage collector
local function hookAntiCheat()
    if not (hookfunction and getgc) then return end
    pcall(function()
        for _, obj in ipairs(getgc(true)) do
            if typeof(obj) == "function" then
                local info = debug.getinfo(obj)
                if info and info.name then
                    local n = info.name:lower()
                    if n:find("anticheat") or n:find("detect") or n:find("kick") then
                        hookfunction(obj, function(...) return true end)
                    end
                end
            end
        end
    end)
end
task.spawn(hookAntiCheat)

-- 3. Spoof property: WalkSpeed tetap terlihat 16 di anti-cheat
local oldIndex = mt.__index
mt.__index = newcclosure(function(self, key)
    if key == "WalkSpeed" and State.Speed then
        local real = oldIndex(self, key)
        if typeof(real) == "number" then
            return 16 -- nilai palsu yang dianggap legal
        end
    end
    return oldIndex(self, key)
end)

-- 4. Blokir kick dari server (anti-kick)
local oldKick = LocalPlayer.Kick
LocalPlayer.Kick = newcclosure(function(self, ...)
    if State.AntiKick then
        return -- abaikan kick
    end
    return oldKick(self, ...)
end)

-- 5. Auto-rejoin jika tetap ter-kick (fallback)
LocalPlayer.OnTeleport:Connect(function()
    if State.AntiKick then
        task.wait(0.5)
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end
end)

-- ============================================================
-- CHARACTER HANDLER
-- ============================================================
local Character, Humanoid, RootPart

local function onCharacterAdded(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")

    if State.Speed then
        Humanoid.WalkSpeed = State.SpeedValue
    end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

-- ============================================================
-- NOCLIP ENGINE
-- ============================================================
RunService.Stepped:Connect(function()
    if State.Noclip and Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- ============================================================
-- SPEED ENGINE (BYPASS)
-- ============================================================
-- Gunakan BodyVelocity untuk speed yang lebih sulit dideteksi
local speedVelocity

local function applySpeed()
    if not Character or not Humanoid then return end

    if speedVelocity then
        speedVelocity:Destroy()
        speedVelocity = nil
    end

    if State.Speed then
        -- Metode 1: WalkSpeed normal (cepat, tapi mudah dideteksi)
        Humanoid.WalkSpeed = State.SpeedValue

        -- Metode 2: BodyVelocity (lebih stealth)
        -- Aktifkan jika game mendeteksi WalkSpeed langsung
        -- speedVelocity = Instance.new("BodyVelocity")
        -- speedVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
        -- speedVelocity.Velocity = Vector3.new(0, 0, 0)
        -- speedVelocity.Parent = RootPart
    else
        Humanoid.WalkSpeed = 16
    end
end

-- ============================================================
-- GUI (SMALL, MOBILE FRIENDLY)
-- ============================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "⚡ Universal Bypass",
    LoadingTitle = "Memuat...",
    LoadingSubtitle = "Noclip + Speed",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- TAB: PLAYER
local PlayerTab = Window:CreateTab("Player", nil)

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(value)
        State.Noclip = value
        if not value and Character then
            -- Kembalikan collision saat noclip dimatikan
            for _, part in ipairs(Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Flag = "SpeedToggle",
    Callback = function(value)
        State.Speed = value
        applySpeed()
    end,
})

PlayerTab:CreateSlider({
    Name = "Kecepatan",
    Range = {16, 300},
    Increment = 1,
    Suffix = "WalkSpeed",
    CurrentValue = 50,
    Flag = "SpeedSlider",
    Callback = function(value)
        State.SpeedValue = value
        if State.Speed then
            applySpeed()
        end
    end,
})

-- TAB: BYPASS
local BypassTab = Window:CreateTab("Bypass", nil)

BypassTab:CreateToggle({
    Name = "Anti-Kick",
    CurrentValue = true,
    Flag = "AntiKickToggle",
    Callback = function(value)
        State.AntiKick = value
    end,
})

BypassTab:CreateButton({
    Name = "Rejoin Server (Fallback)",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end,
})

-- ============================================================
-- MOBILE OPTIMIZATION
-- ============================================================
-- Perkecil ukuran GUI di layar kecil
if UserInputService.TouchEnabled then
    -- Rayfield sudah responsive, tapi kita bisa sesuaikan scale
    -- Jika menggunakan GUI custom, set UIScale < 1
end

-- Notifikasi
StarterGui:SetCore("SendNotification", {
    Title = "Universal Bypass",
    Text = "Script loaded. Noclip & Speed ready.",
    Duration = 3,
})
