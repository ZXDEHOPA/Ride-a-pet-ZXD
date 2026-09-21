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
-- STEALING EGG
-- =====================================

local StealingEnabled = false
local StealingRunning = false

local SelectedStealingEggs = {
    ["Cherub Egg"] = true
}


-- =====================================
-- AUTO PLACE
-- =====================================

local AutoPlaceEnabled = false

local SelectedPlaceEggs = {
    ["Cherub Egg"] = true
}


-- =====================================
-- AUTO HATCH
-- =====================================

local AutoHatchEnabled = false


-- =====================================
-- AUTO LUCK
-- =====================================

local LuckEnabled = false
local LuckMode = "One Time"


-- =====================================
-- FIXED SETTINGS
-- =====================================

local LOAD_WAIT = 1.5
local AFTER_EGG_WAIT = 0.5

local WAYPOINT_WAIT = 0.5
local NEAR_FENCE_WAIT = 8

local WALK_DISTANCE = 8


-- =====================================
-- CHARACTER FUNCTIONS
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


-- =====================================
-- UNEQUIP
-- =====================================

local function UnequipCurrentTool()

    local humanoid =
        GetHumanoid()

    if humanoid then
        humanoid:UnequipTools()
    end
end


-- =====================================
-- RENDERED EGGS
--
-- STEALING EGGS ONLY
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
-- EGG PROMPT
-- =====================================

local function GetEggPrompt(egg)

    return egg:FindFirstChildWhichIsA(
        "ProximityPrompt",
        true
    )
end


local function GetModelPosition(model)

    local cf =
        model:GetBoundingBox()

    return cf.Position
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
-- STOP MOVEMENT
-- =====================================

local function StopMovement()

    local humanoid =
        GetHumanoid()

    local root =
        GetRoot()

    if humanoid and root then

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
-- STEALING EGG
-- =====================================

local function RunStealingEgg()

    if not StealingEnabled then
        return
    end

    StealingRunning = true


    -- =================================
    -- FIND EGG IN RENDERED EGGS
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

    print(
        "Stealing Egg: TP #1"
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

    print(
        "Stealing Egg: TP #2"
    )


    if not WaitStealing(
        LOAD_WAIT
    ) then

        StealingRunning = false

        return
    end


    -- =================================
    -- FIRE EGG
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
            "Rendered egg ProximityPrompt not found"
        )

        StealingRunning = false

        return
    end


    fireproximityprompt(
        prompt
    )

    print(
        "Stealing Egg: Egg fired"
    )


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


    -- =================================
    -- START POSITION
    -- =================================

    local startPosition =
        root.Position

    local fencePoint =
        GetClosestFencePoint(
            fence,
            startPosition
        )


    local direction =
        fencePoint - startPosition

    direction =
        Vector3.new(
            direction.X,
            0,
            direction.Z
        )


    if direction.Magnitude < 0.1 then

        StealingRunning = false

        return
    end


    direction =
        direction.Unit


    local totalDistance =
        (
            fencePoint
            - startPosition
        ).Magnitude


    -- =================================
    -- 4 DYNAMIC WAYPOINTS
    -- =================================

    local waypoint1 =
        startPosition
        + direction
        * (totalDistance * 0.20)

    local waypoint2 =
        startPosition
        + direction
        * (totalDistance * 0.40)

    local waypoint3 =
        startPosition
        + direction
        * (totalDistance * 0.60)

    local waypoint4 =
        startPosition
        + direction
        * (totalDistance * 0.80)


    -- =================================
    -- WAYPOINT 1
    -- =================================

    root =
        GetRoot()

    if not root or not StealingEnabled then

        StealingRunning = false

        return
    end


    root.CFrame =
        CFrame.new(
            waypoint1
        )

    print(
        "Stealing Egg: Waypoint 1"
    )


    if not WaitStealing(
        WAYPOINT_WAIT
    ) then

        StealingRunning = false

        return
    end


    -- =================================
    -- WAYPOINT 2
    -- =================================

    root =
        GetRoot()

    if not root or not StealingEnabled then

        StealingRunning = false

        return
    end


    root.CFrame =
        CFrame.new(
            waypoint2
        )

    print(
        "Stealing Egg: Waypoint 2"
    )


    if not WaitStealing(
        WAYPOINT_WAIT
    ) then

        StealingRunning = false

        return
    end


    -- =================================
    -- WAYPOINT 3
    -- =================================

    root =
        GetRoot()

    if not root or not StealingEnabled then

        StealingRunning = false

        return
    end


    root.CFrame =
        CFrame.new(
            waypoint3
        )

    print(
        "Stealing Egg: Waypoint 3"
    )


    if not WaitStealing(
        WAYPOINT_WAIT
    ) then

        StealingRunning = false

        return
    end


    -- =================================
    -- WAYPOINT 4
    -- =================================

    root =
        GetRoot()

    if not root or not StealingEnabled then

        StealingRunning = false

        return
    end


    root.CFrame =
        CFrame.new(
            waypoint4
        )

    print(
        "Stealing Egg: Waypoint 4"
    )


    if not WaitStealing(
        WAYPOINT_WAIT
    ) then

        StealingRunning = false

        return
    end


    -- =================================
    -- RECALCULATE NEAR FENCE
    -- =================================

    root =
        GetRoot()

    fence =
        GetFence()

    if not root or not fence then

        StealingRunning = false

        return
    end


    fencePoint =
        GetClosestFencePoint(
            fence,
            root.Position
        )


    local finalDirection =
        fencePoint - root.Position

    finalDirection =
        Vector3.new(
            finalDirection.X,
            0,
            finalDirection.Z
        )


    if finalDirection.Magnitude < 0.1 then

        StealingRunning = false

        return
    end


    finalDirection =
        finalDirection.Unit


    local nearFence =
        fencePoint
        - finalDirection
        * WALK_DISTANCE


    -- =================================
    -- TP NEAR FENCE
    -- =================================

    root.CFrame =
        CFrame.new(
            nearFence
        )

    print(
        "Stealing Egg: Near fence"
    )


    -- =================================
    -- WAIT NEAR FENCE
    -- =================================

    print(
        "Stealing Egg: Waiting..."
    )


    if not WaitStealing(
        NEAR_FENCE_WAIT
    ) then

        StealingRunning = false

        return
    end


    -- =================================
    -- TELEPORT TO FENCE CENTER
    -- =================================

    root =
        GetRoot()

    fence =
        GetFence()

    if not root or not fence then

        StealingRunning = false

        return
    end


    local fenceCenter =
        GetFenceCenter(
            fence
        )


    root.CFrame =
        CFrame.new(
            fenceCenter
        )


    print(
        "Stealing Egg: Finished"
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
-- MY BASEPLATE
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
        and baseplate:IsA(
            "BasePart"
        )
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


    for _, eggName in ipairs(
        Eggs
    ) do

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
        return
    end


    local egg =
        GetBackpackEgg()

    if not egg then
        return
    end


    local character =
        Player.Character

    local humanoid =
        character
        and character:FindFirstChildOfClass(
            "Humanoid"
        )


    if not humanoid then
        return
    end


    -- =================================
    -- EQUIP
    -- =================================

    humanoid:EquipTool(
        egg
    )

    task.wait(0.2)


    -- =================================
    -- FIND BASEPLATE
    -- =================================

    local baseplate =
        GetMyBaseplate()

    if not baseplate then

        UnequipCurrentTool()

        return
    end


    -- =================================
    -- RANDOM POSITION
    -- =================================

    local position =
        GetRandomBaseplatePosition(
            baseplate
        )


    if not position then

        UnequipCurrentTool()

        return
    end


    -- =================================
    -- PLACE
    -- =================================

    local equippedEgg =
        egg

    EggPlaced:FireServer({
        PlantPosition = position
    })


    task.wait(0.3)


    -- =================================
    -- PLACE FAILED / PLOT FULL
    -- =================================

    if equippedEgg.Parent
        == Player.Character
    then

        UnequipCurrentTool()

        print(
            "Egg could not be placed. Tool unequipped."
        )

        return
    end


    print(
        equippedEgg.Name .. " placed!"
    )
end


-- =====================================
-- AUTO HATCH
--
-- STEALING HAS PRIORITY
-- =====================================

local function HatchEgg()

    if not AutoHatchEnabled then
        return
    end


    if StealingRunning then
        return
    end


    local prompt =
        GetHatchPrompt()

    if not prompt then
        return
    end


    fireproximityprompt(
        prompt
    )


    print(
        "Auto Hatch: Hatch prompt fired"
    )
end


-- =====================================
-- STEALING EGG DROPDOWN
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
-- AUTO PLACE EGG DROPDOWN
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
-- AUTO PLACE EGG
-- =====================================

Tab:CreateToggle({

    Name = "Auto Place Egg",

    CurrentValue = false,

    Flag = "AutoPlaceEgg",

    Callback = function(Value)

        AutoPlaceEnabled = Value


        if not Value then

            UnequipCurrentTool()

            return
        end


        task.spawn(function()

            while AutoPlaceEnabled do

                if not StealingRunning then

                    PlaceSelectedEgg()

                end

                task.wait(0.5)

            end

        end)

    end
})


-- =====================================
-- AUTO HATCH EGG
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

                -- Stealing always gets priority.
                if not StealingRunning then

                    HatchEgg()

                end

                task.wait(0.5)

            end

        end)

    end
})


-- =====================================
-- LUCK UPGRADE MODE
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
