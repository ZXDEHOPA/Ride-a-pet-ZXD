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

local WeightPreference = "None"
local RarityPreference = "None"

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
local WAYPOINT_WAIT = 1
local NEAR_FENCE_WAIT = 10
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


    -- UPDATED:
    -- AFTER_EGG_WAIT = 1

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
-- 5 WAYPOINTS
-- GRADUAL X / Y / Z MOVEMENT
-- =================================

local targetPosition =
    fencePoint

local waypoint1 =
    startPosition:Lerp(
        targetPosition,
        0.1667
    )

local waypoint2 =
    startPosition:Lerp(
        targetPosition,
        0.3333
    )

local waypoint3 =
    startPosition:Lerp(
        targetPosition,
        0.5000
    )

local waypoint4 =
    startPosition:Lerp(
        targetPosition,
        0.6667
    )

local waypoint5 =
    startPosition:Lerp(
        targetPosition,
        0.8333
    )


-- =================================
-- WAYPOINT 1
-- =================================

root = GetRoot()

if not root or not StealingEnabled then
    if root then
        root.Anchored = false
    end

    StealingRunning = false
    return
end

root.CFrame =
    CFrame.new(waypoint1)

root.Anchored = true

if not WaitStealing(
    WAYPOINT_WAIT
) then

    root.Anchored = false
    StealingRunning = false
    return
end

root.Anchored = false


-- =================================
-- WAYPOINT 2
-- =================================

root = GetRoot()

if not root or not StealingEnabled then
    if root then
        root.Anchored = false
    end

    StealingRunning = false
    return
end

root.CFrame =
    CFrame.new(waypoint2)

root.Anchored = true

if not WaitStealing(
    WAYPOINT_WAIT
) then

    root.Anchored = false
    StealingRunning = false
    return
end

root.Anchored = false


-- =================================
-- WAYPOINT 3
-- =================================

root = GetRoot()

if not root or not StealingEnabled then
    if root then
        root.Anchored = false
    end

    StealingRunning = false
    return
end

root.CFrame =
    CFrame.new(waypoint3)

root.Anchored = true

if not WaitStealing(
    WAYPOINT_WAIT
) then

    root.Anchored = false
    StealingRunning = false
    return
end

root.Anchored = false


-- =================================
-- WAYPOINT 4
-- =================================

root = GetRoot()

if not root or not StealingEnabled then
    if root then
        root.Anchored = false
    end

    StealingRunning = false
    return
end

root.CFrame =
    CFrame.new(waypoint4)

root.Anchored = true

if not WaitStealing(
    WAYPOINT_WAIT
) then

    root.Anchored = false
    StealingRunning = false
    return
end

root.Anchored = false


-- =================================
-- WAYPOINT 5
-- =================================

root = GetRoot()

if not root or not StealingEnabled then
    if root then
        root.Anchored = false
    end

    StealingRunning = false
    return
end

root.CFrame =
    CFrame.new(waypoint5)

root.Anchored = true

if not WaitStealing(
    WAYPOINT_WAIT
) then

    root.Anchored = false
    StealingRunning = false
    return
end

root.Anchored = false
    
    -- =================================
    -- RECALCULATE FENCE
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
    -- NEAR FENCE
    -- =================================

    root.CFrame =
        CFrame.new(
            nearFence
        )


    if not WaitStealing(
        NEAR_FENCE_WAIT
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

local RarityOrder = {
    ["Cherub Egg"] = 1,
    ["Solaris Egg"] = 2,
    ["Blackhole Egg"] = 3,
    ["Aurora Egg"] = 4,
    ["Soul Egg"] = 5,
    ["Sinister Egg"] = 6
}


local function GetBackpackEgg()

    local backpack =
        Player:FindFirstChild(
            "Backpack"
        )

    if not backpack then
        return nil
    end


    local availableEggs = {}

    for _, eggName in ipairs(Eggs) do

        if SelectedPlaceEggs[eggName] then

            local egg =
                backpack:FindFirstChild(
                    eggName
                )

            if egg then

                table.insert(
                    availableEggs,
                    egg
                )

            end

        end

    end


    if #availableEggs == 0 then
        return nil
    end


    -- =================================
    -- RARITY PREFERENCE
    -- =================================

    if RarityPreference == "Most Rarest" then

        table.sort(
            availableEggs,
            function(a, b)

                return
                    RarityOrder[a.Name]
                    <
                    RarityOrder[b.Name]

            end
        )

    elseif RarityPreference == "Least Rarest" then

        table.sort(
            availableEggs,
            function(a, b)

                return
                    RarityOrder[a.Name]
                    >
                    RarityOrder[b.Name]

            end
        )

    end


-- =================================
-- WEIGHT PREFERENCE
-- =================================

if WeightPreference == "Lowest Weight" then

    table.sort(
        availableEggs,
        function(a, b)

            local dataA = a:FindFirstChild("Data")
            local dataB = b:FindFirstChild("Data")

            local weightA =
                dataA
                and dataA:FindFirstChild("Weight")

            local weightB =
                dataB
                and dataB:FindFirstChild("Weight")

            if not weightA then
                return false
            end

            if not weightB then
                return true
            end

            return weightA.Value < weightB.Value

        end
    )

elseif WeightPreference == "Highest Weight" then

    table.sort(
        availableEggs,
        function(a, b)

            local dataA = a:FindFirstChild("Data")
            local dataB = b:FindFirstChild("Data")

            local weightA =
                dataA
                and dataA:FindFirstChild("Weight")

            local weightB =
                dataB
                and dataB:FindFirstChild("Weight")

            if not weightA then
                return false
            end

            if not weightB then
                return true
            end

            return weightA.Value > weightB.Value

        end
    )

end


    return availableEggs[1]
end

-- =====================================
-- EGG CAPACITY
-- =====================================

local function GetMyEggsFolder()
    local plot = GetMyPlot()
    if not plot then
        return nil
    end

    return plot:FindFirstChild("Eggs")
end

local function GetEggCount()
    local eggsFolder = GetMyEggsFolder()
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
-- WEIGHT PREFERENCE
-- =====================================

Tab:CreateDropdown({

    Name = "Weight Preference",

    Options = {
        "None",
        "Lowest Weight",
        "Highest Weight"
    },

    CurrentOption = {
        "None"
    },

    MultipleOptions = false,

    Flag = "WeightPreference",

    Callback = function(Option)

        WeightPreference =
            Option[1]

    end
})

-- =====================================
-- RARITY PREFERENCE
-- =====================================

Tab:CreateDropdown({

    Name = "Rarity Preference",

    Options = {
        "None",
        "Least Rarest",
        "Most Rarest"
    },

    CurrentOption = {
        "None"
    },

    MultipleOptions = false,

    Flag = "RarityPreference",

    Callback = function(Option)

        RarityPreference =
            Option[1]

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
