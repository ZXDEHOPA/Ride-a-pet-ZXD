local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Ride a Pet",
    LoadingTitle = "Ride a Pet",
    LoadingSubtitle = "By ZXD",
    ConfigurationSaving = {
        Enabled = false
    }
})

local Tab = Window:CreateTab("Main Menu")


-- =====================================
-- REMOTES
-- =====================================

local Upgrades =
    ReplicatedStorage.Remotes.Game.Plot.Upgrades

local EggPlaced =
    ReplicatedStorage.Remotes.Game.EggPlaced


-- =====================================
-- EGG LIST
-- =====================================

local Eggs = {
    "Cherub Egg",
    "Solaris Egg",
    "Blackhole Egg",
    "Aurora Egg",
    "Soul Egg",
    "Sinister Egg"
}


-- =====================================
-- STATES
-- =====================================

local StealingEnabled = false
local StealingRunning = false

local AutoPlaceEnabled = false
local AutoHatchEnabled = false

local LuckEnabled = false
local LuckMode = "One Time"

local WaitingForHatch = false
local HatchRunning = false
local LearnedEggCapacity = nil


-- =====================================
-- SELECTED EGGS
-- =====================================

local SelectedStealingEggs = {
    ["Cherub Egg"] = true
}

local SelectedPlaceEggs = {
    ["Cherub Egg"] = true
}


-- =====================================
-- STEALING SETTINGS
-- =====================================

local LOAD_WAIT = 3
local AFTER_EGG_WAIT = 1
local WAYPOINT_WAIT = 0.75
local NEAR_FENCE_WAIT = 7
local WALK_DISTANCE = 8


-- =====================================
-- CHARACTER
-- =====================================

local function GetRoot()

    local character = Player.Character

    if not character then
        return nil
    end

    return character:FindFirstChild(
        "HumanoidRootPart"
    )
end


local function GetHumanoid()

    local character = Player.Character

    if not character then
        return nil
    end

    return character:FindFirstChildOfClass(
        "Humanoid"
    )
end


local function UnequipCurrentTool()

    local humanoid = GetHumanoid()

    if humanoid then
        humanoid:UnequipTools()
    end
end


-- =====================================
-- RENDERED EGG
--
-- STEALING ONLY
-- =====================================

local function GetSelectedStealingEgg()

    local renderedEggs =
        workspace:FindFirstChild(
            "RenderedEggs"
        )

    if not renderedEggs then
        return nil
    end


    for _, eggName in ipairs(Eggs) do

        if SelectedStealingEggs[eggName] then

            for _, egg in ipairs(
                renderedEggs:GetChildren()
            ) do

                if egg.Name == eggName
                    and egg:IsA("Model")
                then

                    return egg

                end

            end

        end

    end


    return nil
end


-- =====================================
-- MODEL POSITION
-- =====================================

local function GetModelPosition(model)

    local cf =
        model:GetBoundingBox()

    return cf.Position
end


-- =====================================
-- EGG PROMPT
-- =====================================

local function GetEggPrompt(egg)

    return egg:FindFirstChildWhichIsA(
        "ProximityPrompt",
        true
    )
end


-- =====================================
-- FENCE
-- =====================================

local function GetFence()

    local fence =
        workspace:FindFirstChild(
            "Full Fence",
            true
        )

    if fence and fence:IsA("Model") then
        return fence
    end

    return nil
end


local function GetClosestFencePoint(
    fence,
    position
)

    local cf, size =
        fence:GetBoundingBox()

    local localPosition =
        cf:PointToObjectSpace(
            position
        )

    local half =
        size / 2

    local closest =
        Vector3.new(

            math.clamp(
                localPosition.X,
                -half.X,
                half.X
            ),

            math.clamp(
                localPosition.Y,
                -half.Y,
                half.Y
            ),

            math.clamp(
                localPosition.Z,
                -half.Z,
                half.Z
            )
        )

    return cf:PointToWorldSpace(
        closest
    )
end


local function GetFenceCenter(fence)

    local cf =
        fence:GetBoundingBox()

    return cf.Position
end


-- =====================================
-- STEALING WAIT
-- =====================================

local function WaitStealing(duration)

    local start =
        os.clock()

    while StealingEnabled
        and os.clock() - start < duration
    do

        task.wait(0.05)

    end

    return StealingEnabled
end


-- =====================================
-- STOP MOVEMENT
-- =====================================

local function StopMovement()

    local humanoid =
        GetHumanoid()

    local root =
        GetRoot()

    if humanoid and root then

        -- Make sure the player is never
        -- left anchored after stopping.
        root.Anchored = false

        humanoid:Move(
            Vector3.zero,
            false
        )

        humanoid:MoveTo(
            root.Position
        )

    end
end


-- =====================================
-- STEALING
-- =====================================

local function RunStealingEgg()

    if not StealingEnabled then
        return
    end

    StealingRunning = true


    -- =================================
    -- FIND RENDERED EGG
    -- =================================

    local egg =
        GetSelectedStealingEgg()

    if not egg then

        StealingRunning = false

        task.wait(0.25)

        return
    end


    local root =
        GetRoot()

    if not root then

        StealingRunning = false

        return
    end


    -- =================================
    -- TP #1
    -- =================================

    root.CFrame =
        CFrame.new(
            GetModelPosition(egg)
            + Vector3.new(0, 3, 0)
        )


    if not WaitStealing(
        LOAD_WAIT
    ) then

        StealingRunning = false

        return
    end


    -- =================================
    -- TP #2
    -- RECHECK RENDERED EGGS
    -- =================================

    root =
        GetRoot()

    egg =
        GetSelectedStealingEgg()

    if not root or not egg then

        StealingRunning = false

        return
    end


    root.CFrame =
        CFrame.new(
            GetModelPosition(egg)
            + Vector3.new(0, 3, 0)
        )


    if not WaitStealing(
        LOAD_WAIT
    ) then

        StealingRunning = false

        return
    end


    -- =================================
    -- FIRE PROMPT
    -- =================================

    egg =
        GetSelectedStealingEgg()

    if not egg then

        StealingRunning = false

        return
    end


    local prompt =
        GetEggPrompt(egg)

    if not prompt then

        warn(
            "RenderedEggs egg prompt not found"
        )

        StealingRunning = false

        return
    end


    fireproximityprompt(prompt)


    if not WaitStealing(
        AFTER_EGG_WAIT
    ) then

        StealingRunning = false

        return
    end


    -- =================================
    -- FIND FENCE
    -- =================================

    local fence =
        GetFence()

    if not fence then

        warn(
            "Full Fence not found"
        )

        StealingRunning = false

        return
    end


    root =
        GetRoot()

    if not root then

        StealingRunning = false

        return
    end


    local startPosition =
        root.Position

    local fencePoint =
        GetClosestFencePoint(
            fence,
            startPosition
        )


-- =================================
-- WAYPOINT POSITIONS
-- =================================

local waypoint1 =
    startPosition:Lerp(
        fencePoint,
        0.0909
    )

local waypoint2 =
    startPosition:Lerp(
        fencePoint,
        0.1818
    )

local waypoint3 =
    startPosition:Lerp(
        fencePoint,
        0.2727
    )

local waypoint4 =
    startPosition:Lerp(
        fencePoint,
        0.3636
    )

local waypoint5 =
    startPosition:Lerp(
        fencePoint,
        0.4545
    )

local waypoint6 =
    startPosition:Lerp(
        fencePoint,
        0.5455
    )

local waypoint7 =
    startPosition:Lerp(
        fencePoint,
        0.6364
    )

local waypoint8 =
    startPosition:Lerp(
        fencePoint,
        0.7273
    )

local waypoint9 =
    startPosition:Lerp(
        fencePoint,
        0.8182
    )

local waypoint10 =
    startPosition:Lerp(
        fencePoint,
        0.9091
    )


-- =================================
-- WAYPOINT TELEPORT FUNCTION
-- =================================

local function TeleportToWaypoint(position)

    if not StealingEnabled then
        return false
    end

    local character =
        Player.Character

    if not character then
        return false
    end

    local root =
        GetRoot()

    if not root then
        return false
    end


    -- Create temporary platform
    local platform =
        Instance.new("Part")

    platform.Name =
        "StealingWaypointPlatform"

    platform.Size =
        Vector3.new(
            8,
            1,
            8
        )

    platform.Transparency =
        1

    platform.CanCollide =
        true

    platform.CanTouch =
        false

    platform.CanQuery =
        false

    platform.Anchored =
        true

    platform.CFrame =
        CFrame.new(
            position
            - Vector3.new(
                0,
                3,
                0
            )
        )

    platform.Parent =
        workspace


    -- Refresh character/root
    character =
        Player.Character

    root =
        GetRoot()

    if not character or not root then

        platform:Destroy()

        return false
    end


    -- Force teleport
    character:PivotTo(
        CFrame.new(
            position
        )
    )


    -- Wait while standing on platform
    local success =
        WaitStealing(
            WAYPOINT_WAIT
        )


    -- Remove platform
    if platform then
        platform:Destroy()
    end


    return success
end


-- =================================
-- WAYPOINT 1
-- =================================

if not TeleportToWaypoint(
    waypoint1
) then

    StealingRunning = false

    return
end


-- =================================
-- WAYPOINT 2
-- =================================

if not TeleportToWaypoint(
    waypoint2
) then

    StealingRunning = false

    return
end


-- =================================
-- WAYPOINT 3
-- =================================

if not TeleportToWaypoint(
    waypoint3
) then

    StealingRunning = false

    return
end


-- =================================
-- WAYPOINT 4
-- =================================

if not TeleportToWaypoint(
    waypoint4
) then

    StealingRunning = false

    return
end


-- =================================
-- WAYPOINT 5
-- =================================

if not TeleportToWaypoint(
    waypoint5
) then

    StealingRunning = false

    return
end


-- =================================
-- WAYPOINT 6
-- =================================

if not TeleportToWaypoint(
    waypoint6
) then

    StealingRunning = false

    return
end


-- =================================
-- WAYPOINT 7
-- =================================

if not TeleportToWaypoint(
    waypoint7
) then

    StealingRunning = false

    return
end


-- =================================
-- WAYPOINT 8
-- =================================

if not TeleportToWaypoint(
    waypoint8
) then

    StealingRunning = false

    return
end


-- =================================
-- WAYPOINT 9
-- =================================

if not TeleportToWaypoint(
    waypoint9
) then

    StealingRunning = false

    return
end


-- =================================
-- WAYPOINT 10
-- =================================

if not TeleportToWaypoint(
    waypoint10
) then

    StealingRunning = false

    return
end
    
    -- =================================
    -- FINAL FENCE TP
    -- =================================

    root =
        GetRoot()

    fence =
        GetFence()

    if not root or not fence then

        StealingRunning = false

        return
    end


    root.CFrame =
        CFrame.new(
            GetFenceCenter(fence)
        )


    StealingRunning = false
end


-- =====================================
-- MY PLOT
-- =====================================

local function GetMyPlot()

    local plotsFolder =
        workspace:FindFirstChild(
            "Plots"
        )

    if not plotsFolder then
        return nil
    end


    for _, plot in ipairs(
        plotsFolder:GetChildren()
    ) do

        if plot:IsA("Model")
            and plot.Name == "Plot"
        then

            local data =
                plot:FindFirstChild(
                    "Data"
                )

            if data then

                local owner =
                    data:FindFirstChild(
                        "Owner"
                    )

                if owner
                    and owner:IsA(
                        "ObjectValue"
                    )
                    and owner.Value == Player
                then

                    return plot

                end
            end
        end
    end


    return nil
end


-- =====================================
-- BASEPLATE
-- =====================================

local function GetMyBaseplate()

    local plot =
        GetMyPlot()

    if not plot then
        return nil
    end


    local baseplate =
        plot:FindFirstChild(
            "Baseplate"
        )


    if baseplate
        and baseplate:IsA("BasePart")
    then

        return baseplate

    end


    return nil
end


-- =====================================
-- RANDOM BASEPLATE POSITION
-- =====================================

local function GetRandomBaseplatePosition(
    baseplate
)

    if not baseplate then
        return nil
    end


    local size =
        baseplate.Size

    local cf =
        baseplate.CFrame


    local x =
        (math.random() - 0.5)
        * size.X

    local z =
        (math.random() - 0.5)
        * size.Z


    local localPosition =
        Vector3.new(
            x,
            size.Y / 2 + 0.1,
            z
        )


    return cf:PointToWorldSpace(
        localPosition
    )
end


-- =====================================
-- BACKPACK EGG
-- =====================================

local function GetBackpackEgg()

    local backpack =
        Player:FindFirstChild(
            "Backpack"
        )

    if not backpack then
        return nil
    end


    for _, eggName in ipairs(Eggs) do

        if SelectedPlaceEggs[eggName] then

            local egg =
                backpack:FindFirstChild(
                    eggName
                )

            if egg then
                return egg
            end

        end

    end


    return nil
end


-- =====================================
-- EGG CAPACITY
-- =====================================

local function GetMyEggsFolder()

    local plot =
        GetMyPlot()

    if not plot then
        return nil
    end

    return plot:FindFirstChild("Eggs")
end


local function GetEggCount()

    local eggsFolder =
        GetMyEggsFolder()

    if not eggsFolder then
        return 0
    end

    return #eggsFolder:GetChildren()
end


-- =====================================
-- HATCH PROMPT
-- =====================================

local function GetHatchPrompt()

    local plot =
        GetMyPlot()

    if not plot then
        return nil
    end


    local egg =
        plot:FindFirstChild(
            "Egg",
            true
        )

    if not egg then
        return nil
    end


    local hatch =
        egg:FindFirstChild(
            "Hatch",
            true
        )


    if hatch
        and hatch:IsA(
            "ProximityPrompt"
        )
    then

        return hatch

    end


    return egg:FindFirstChildWhichIsA(
        "ProximityPrompt",
        true
    )
end


-- =====================================
-- AUTO PLACE
-- =====================================

local function PlaceSelectedEgg()

    if not AutoPlaceEnabled then
        return false
    end

    if StealingRunning then
        return false
    end

    if WaitingForHatch then
        return false
    end

    local egg =
        GetBackpackEgg()

    if not egg then
        return false
    end

    local humanoid =
        GetHumanoid()

    if not humanoid then
        return false
    end


    -- =================================
    -- EQUIP
    -- =================================

    humanoid:EquipTool(egg)

    task.wait(0.2)


    -- =================================
    -- BASEPLATE
    -- =================================

    local baseplate =
        GetMyBaseplate()

    if not baseplate then
        humanoid:UnequipTools()
        return false
    end


    -- =================================
    -- RANDOM POSITION
    -- =================================

    local position =
        GetRandomBaseplatePosition(
            baseplate
        )

    if not position then
        humanoid:UnequipTools()
        return false
    end


    -- =================================
    -- PLACE
    -- =================================

    local success =
        pcall(function()

            EggPlaced:FireServer({
                PlantPosition = position
            })

        end)


    if not success then
        humanoid:UnequipTools()
        return false
    end


    task.wait(0.3)


    -- =================================
    -- CHECK PLACEMENT RESULT
    -- =================================

    if egg.Parent == Player.Character then

        local currentEggCount =
            GetEggCount()

        humanoid:UnequipTools()

        LearnedEggCapacity =
            currentEggCount

        WaitingForHatch = true

        print(
            "Placement failed. Eggs inside Plot > Eggs:",
            currentEggCount
        )

        return false
    end


    -- =================================
    -- SUCCESS
    -- =================================

    WaitingForHatch = false

    print(
        "Egg placed successfully. Continuing placement."
    )

    return true
end


-- =====================================
-- AUTO HATCH
-- =====================================

local function HatchEgg()

    if not AutoHatchEnabled then
        return false
    end


    if StealingRunning then
        return false
    end


    if HatchRunning then
        return false
    end


    local prompt =
        GetHatchPrompt()

    if not prompt then
        return false
    end


    HatchRunning = true


    fireproximityprompt(
        prompt
    )


    print(
        "Auto Hatch: Hatch prompt fired"
    )


    task.wait(0.5)


    HatchRunning = false

    WaitingForHatch = false


    print(
        "Auto Hatch finished. Auto Place resumed."
    )


    return true
end


-- =====================================
-- STEALING DROPDOWN
-- =====================================

Tab:CreateDropdown({

    Name = "Stealing Egg",

    Options = Eggs,

    CurrentOption = {
        "Cherub Egg"
    },

    MultipleOptions = true,

    Flag = "StealingEggs",

    Callback = function(Options)

        SelectedStealingEggs = {}

        if type(Options) == "table" then

            for _, eggName in ipairs(
                Options
            ) do

                SelectedStealingEggs[
                    eggName
                ] = true

            end

        else

            SelectedStealingEggs[
                Options
            ] = true

        end
    end
})


-- =====================================
-- AUTO EGG
-- =====================================

Tab:CreateToggle({

    Name = "Auto Egg",

    CurrentValue = false,

    Flag = "EggAuto",

    Callback = function(Value)

        StealingEnabled = Value


        if not Value then

            StealingRunning = false

            StopMovement()

            return
        end


        task.spawn(function()

            while StealingEnabled do

                RunStealingEgg()

                if not StealingEnabled then
                    break
                end

                task.wait(0.5)

            end

        end)

    end
})


-- =====================================
-- PLACE EGG DROPDOWN
-- =====================================

Tab:CreateDropdown({

    Name = "Egg",

    Options = Eggs,

    CurrentOption = {
        "Cherub Egg"
    },

    MultipleOptions = true,

    Flag = "PlaceEggs",

    Callback = function(Options)

        SelectedPlaceEggs = {}

        if type(Options) == "table" then

            for _, eggName in ipairs(
                Options
            ) do

                SelectedPlaceEggs[
                    eggName
                ] = true

            end

        else

            SelectedPlaceEggs[
                Options
            ] = true

        end
    end
})


-- =====================================
-- AUTO PLACE
-- =====================================

Tab:CreateToggle({

    Name = "Auto Place Egg",

    CurrentValue = false,

    Flag = "AutoPlaceEgg",

    Callback = function(Value)

        AutoPlaceEnabled = Value


        if not Value then

            UnequipCurrentTool()

            WaitingForHatch = false

            return
        end


        task.spawn(function()

            while AutoPlaceEnabled do

                if not StealingRunning
                    and not WaitingForHatch
                then

                    pcall(function()

                        PlaceSelectedEgg()

                    end)

                end


                task.wait(0.5)

            end

        end)

    end
})


-- =====================================
-- AUTO HATCH
-- =====================================

Tab:CreateToggle({

    Name = "Auto Hatch Egg",

    CurrentValue = false,

    Flag = "AutoHatchEgg",

    Callback = function(Value)

        AutoHatchEnabled = Value


        if not Value then
            return
        end


        task.spawn(function()

            while AutoHatchEnabled do

                -- Stealing has priority
                if not StealingRunning then

                    if WaitingForHatch
                        and not HatchRunning
                    then

                        pcall(function()

                            HatchEgg()

                        end)

                    end

                end


                task.wait(0.5)

            end

        end)

    end
})


-- =====================================
-- LUCK UPGRADE
-- =====================================

Tab:CreateDropdown({

    Name = "Luck Upgrade",

    Options = {
        "One Time",
        "Max"
    },

    CurrentOption = {
        "One Time"
    },

    MultipleOptions = false,

    Flag = "LuckUpgradeMode",

    Callback = function(Option)

        LuckMode =
            Option[1]

    end
})


-- =====================================
-- AUTO LUCK UPGRADE
-- =====================================

Tab:CreateToggle({

    Name = "Auto Luck Upgrade",

    CurrentValue = false,

    Flag = "AutoLuckUpgrade",

    Callback = function(Value)

        LuckEnabled = Value


        if not Value then
            return
        end


        task.spawn(function()

            while LuckEnabled do

                if LuckMode == "Max" then

                    Upgrades:FireServer(
                        "Max"
                    )

                else

                    Upgrades:FireServer()

                end


                task.wait(1)

            end

        end)

    end
})
