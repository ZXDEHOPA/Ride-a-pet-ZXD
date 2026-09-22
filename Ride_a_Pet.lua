local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

-- =====================================
-- WINDOW
-- =====================================

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
-- EGGS
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
-- RARITY ORDER
-- =====================================

local RarityOrder = {
    ["Cherub Egg"] = 1,
    ["Solaris Egg"] = 2,
    ["Blackhole Egg"] = 3,
    ["Aurora Egg"] = 4,
    ["Soul Egg"] = 5,
    ["Sinister Egg"] = 6
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

local HatchRunning = false
local WaitingForHatch = false

local WeightPreference = "None"
local RarityPreference = "None"

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

local function GetCharacter()

    return Player.Character

end

local function GetRoot()

    local character =
        GetCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChild(
        "HumanoidRootPart"
    )
end

local function GetHumanoid()

    local character =
        GetCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChildOfClass(
        "Humanoid"
    )
end

local function UnequipCurrentTool()

    local humanoid =
        GetHumanoid()

    if humanoid then
        humanoid:UnequipTools()
    end

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
-- SELECTED STEALING EGG
-- ONLY RenderedEggs
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

    if not egg then
        return nil
    end

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

    if fence
        and fence:IsA("Model")
    then

        return fence

    end

    return nil
end

-- =====================================
-- CLOSEST FENCE POINT
-- =====================================

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

-- =====================================
-- FENCE CENTER
-- =====================================

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
-- STEALING
-- =====================================

local function RunStealingEgg()

    if not StealingEnabled then
        return
    end

    StealingRunning = true

    -- =================================
    -- FIND EGG
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

    -- =================================
    -- AFTER EGG WAIT
    -- =================================

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

    -- =================================
    -- FENCE POINT
    -- =================================

    local fencePoint =
        GetClosestFencePoint(
            fence,
            startPosition
        )

    -- =================================
    -- DIRECTION
    -- =================================

    local direction =
        fencePoint
        - startPosition

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

    -- =================================
    -- DISTANCE
    -- =================================

    local totalDistance =
        (
            fencePoint
            - startPosition
        ).Magnitude

    -- =================================
    -- 10 WAYPOINTS
    -- =================================

    local waypoint1 =
        startPosition
        + direction
        * (totalDistance * 0.0909)

    local waypoint2 =
        startPosition
        + direction
        * (totalDistance * 0.1818)

    local waypoint3 =
        startPosition
        + direction
        * (totalDistance * 0.2727)

    local waypoint4 =
        startPosition
        + direction
        * (totalDistance * 0.3636)

    local waypoint5 =
        startPosition
        + direction
        * (totalDistance * 0.4545)

    local waypoint6 =
        startPosition
        + direction
        * (totalDistance * 0.5455)

    local waypoint7 =
        startPosition
        + direction
        * (totalDistance * 0.6364)

    local waypoint8 =
        startPosition
        + direction
        * (totalDistance * 0.7273)

    local waypoint9 =
        startPosition
        + direction
        * (totalDistance * 0.8182)

    local waypoint10 =
        startPosition
        + direction
        * (totalDistance * 0.9091)

    -- =================================
    -- WAYPOINT 1
    -- =================================

    root = GetRoot()

    if not root or not StealingEnabled then
        StealingRunning = false
        return
    end

    root.CFrame =
        CFrame.new(waypoint1)

    if not WaitStealing(
        WAYPOINT_WAIT
    ) then
        StealingRunning = false
        return
    end

    -- =================================
    -- WAYPOINT 2
    -- =================================

    root = GetRoot()

    if not root or not StealingEnabled then
        StealingRunning = false
        return
    end

    root.CFrame =
        CFrame.new(waypoint2)

    if not WaitStealing(
        WAYPOINT_WAIT
    ) then
        StealingRunning = false
        return
    end

    -- =================================
    -- WAYPOINT 3
    -- =================================

    root = GetRoot()

    if not root or not StealingEnabled then
        StealingRunning = false
        return
    end

    root.CFrame =
        CFrame.new(waypoint3)

    if not WaitStealing(
        WAYPOINT_WAIT
    ) then
        StealingRunning = false
        return
    end

    -- =================================
    -- WAYPOINT 4
    -- =================================

    root = GetRoot()

    if not root or not StealingEnabled then
        StealingRunning = false
        return
    end

    root.CFrame =
        CFrame.new(waypoint4)

    if not WaitStealing(
        WAYPOINT_WAIT
    ) then
        StealingRunning = false
        return
    end

    -- =================================
    -- WAYPOINT 5
    -- =================================

    root = GetRoot()

    if not root or not StealingEnabled then
        StealingRunning = false
        return
    end

    root.CFrame =
        CFrame.new(waypoint5)

    if not WaitStealing(
        WAYPOINT_WAIT
    ) then
        StealingRunning = false
        return
    end

    -- =================================
    -- WAYPOINT 6
    -- =================================

    root = GetRoot()

    if not root or not StealingEnabled then
        StealingRunning = false
        return
    end

    root.CFrame =
        CFrame.new(waypoint6)

    if not WaitStealing(
        WAYPOINT_WAIT
    ) then
        StealingRunning = false
        return
    end

    -- =================================
    -- WAYPOINT 7
    -- =================================

    root = GetRoot()

    if not root or not StealingEnabled then
        StealingRunning = false
        return
    end

    root.CFrame =
        CFrame.new(waypoint7)

    if not WaitStealing(
        WAYPOINT_WAIT
    ) then
        StealingRunning = false
        return
    end

    -- =================================
    -- WAYPOINT 8
    -- =================================

    root = GetRoot()

    if not root or not StealingEnabled then
        StealingRunning = false
        return
    end

    root.CFrame =
        CFrame.new(waypoint8)

    if not WaitStealing(
        WAYPOINT_WAIT
    ) then
        StealingRunning = false
        return
    end

    -- =================================
    -- WAYPOINT 9
    -- =================================

    root = GetRoot()

    if not root or not StealingEnabled then
        StealingRunning = false
        return
    end

    root.CFrame =
        CFrame.new(waypoint9)

    if not WaitStealing(
        WAYPOINT_WAIT
    ) then
        StealingRunning = false
        return
    end

    -- =================================
    -- WAYPOINT 10
    -- =================================

    root = GetRoot()

    if not root or not StealingEnabled then
        StealingRunning = false
        return
    end

    root.CFrame =
        CFrame.new(waypoint10)

    if not WaitStealing(
        WAYPOINT_WAIT
    ) then
        StealingRunning = false
        return
    end

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
        fencePoint
        - root.Position

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

    -- =================================
    -- 8 STUDS BEFORE FENCE
    -- =================================

    local nearFence =
        fencePoint
        - finalDirection
        * WALK_DISTANCE

    root.CFrame =
        CFrame.new(
            nearFence
        )

    -- =================================
    -- WAIT 10 SECONDS
    -- =================================

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

    local margin = 1

    local usableX =
        math.max(
            size.X - margin * 2,
            0
        )

    local usableZ =
        math.max(
            size.Z - margin * 2,
            0
        )

    local x =
        (math.random() - 0.5)
        * usableX

    local z =
        (math.random() - 0.5)
        * usableZ

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
-- MY EGG FOLDER
-- =====================================

local function GetMyEggsFolder()

    local plot =
        GetMyPlot()

    if not plot then
        return nil
    end

    return plot:FindFirstChild(
        "Eggs"
    )
end

-- =====================================
-- EGG COUNT
-- =====================================

local function GetEggCount()

    local eggsFolder =
        GetMyEggsFolder()

    if not eggsFolder then
        return 0
    end

    return #eggsFolder:GetChildren()
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

    local availableEggs = {}

    -- =================================
    -- FIND AVAILABLE EGGS
    -- =================================

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
    -- SORT
    -- =================================

    table.sort(
        availableEggs,
        function(a, b)

            -- -------------------------
            -- RARITY
            -- -------------------------

            if RarityPreference ~= "None" then

                local rarityA =
                    RarityOrder[a.Name]
                    or math.huge

                local rarityB =
                    RarityOrder[b.Name]
                    or math.huge

                if rarityA ~= rarityB then

                    if RarityPreference ==
                        "Most Rarest"
                    then

                        return rarityA < rarityB

                    elseif RarityPreference ==
                        "Least Rarest"
                    then

                        return rarityA > rarityB

                    end

                end
            end

            -- -------------------------
            -- WEIGHT
            -- -------------------------

            if WeightPreference ~= "None" then

                local dataA =
                    a:FindFirstChild(
                        "Data"
                    )

                local dataB =
                    b:FindFirstChild(
                        "Data"
                    )

                local weightA =
                    dataA
                    and dataA:FindFirstChild(
                        "Weight"
                    )

                local weightB =
                    dataB
                    and dataB:FindFirstChild(
                        "Weight"
                    )

                local valueA =
                    weightA
                    and tonumber(
                        weightA.Value
                    )

                local valueB =
                    weightB
                    and tonumber(
                        weightB.Value
                    )

                if valueA
                    and valueB
                then

                    if valueA ~= valueB then

                        if WeightPreference ==
                            "Highest Weight"
                        then

                            return valueA > valueB

                        elseif WeightPreference ==
                            "Lowest Weight"
                        then

                            return valueA < valueB

                        end

                    end

                elseif valueA then

                    return true

                elseif valueB then

                    return false

                end
            end

            -- -------------------------
            -- ORIGINAL ORDER
            -- -------------------------

            local orderA =
                table.find(
                    Eggs,
                    a.Name
                )
                or math.huge

            local orderB =
                table.find(
                    Eggs,
                    b.Name
                )
                or math.huge

            return orderA < orderB

        end
    )

    return availableEggs[1]
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

    -- Search for the Egg belonging
    -- to our plot.

    local egg =
        plot:FindFirstChild(
            "Egg",
            true
        )

    if not egg then
        return nil
    end

    -- Prefer a prompt specifically
    -- named Hatch.

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

    -- Fallback to any prompt
    -- inside the Egg.

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

    -- =================================
    -- GET EGG
    -- =================================

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
    -- OLD COUNT
    -- =================================

    local oldEggCount =
        GetEggCount()

    -- =================================
    -- EQUIP
    -- =================================

    humanoid:EquipTool(egg)

    task.wait(0.25)

    if egg.Parent ~= Player.Character then

        return false
    end

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
    -- FIRE SERVER
    -- =================================

    local fired =
        pcall(function()

            EggPlaced:FireServer({
                PlantPosition = position
            })

        end)

    if not fired then

        humanoid:UnequipTools()

        return false
    end

    -- =================================
    -- WAIT SERVER
    -- =================================

    task.wait(0.8)

    -- =================================
    -- NEW COUNT
    -- =================================

    local newEggCount =
        GetEggCount()

    -- =================================
    -- SUCCESS
    -- =================================

    if newEggCount > oldEggCount then

        print(
            "Auto Place: Egg placed."
        )

        -- Only wait for hatch when
        -- Auto Hatch is actually enabled.

        if AutoHatchEnabled then

            WaitingForHatch = true

        else

            WaitingForHatch = false

        end

        return true
    end

    -- =================================
    -- SECOND SERVER CHECK
    -- =================================

    task.wait(0.5)

    newEggCount =
        GetEggCount()

    if newEggCount > oldEggCount then

        print(
            "Auto Place: Egg placed."
        )

        if AutoHatchEnabled then
            WaitingForHatch = true
        else
            WaitingForHatch = false
        end

        return true
    end

    -- =================================
    -- FAILED
    -- =================================

    humanoid:UnequipTools()

    print(
        "Auto Place: Placement failed."
    )

    if AutoHatchEnabled then
        WaitingForHatch = true
    else
        WaitingForHatch = false
    end

    return false
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

    -- =================================
    -- FIND REAL HATCH PROMPT
    -- =================================

    local prompt =
        GetHatchPrompt()

    if not prompt then
        return false
    end

    -- =================================
    -- HATCH
    -- =================================

    HatchRunning = true

    print(
        "Auto Hatch: Hatch prompt found."
    )

    fireproximityprompt(
        prompt
    )

    -- =================================
    -- WAIT FOR HATCH TO PROCESS
    -- =================================

    local start =
        os.clock()

    while AutoHatchEnabled
        and not StealingRunning
        and os.clock() - start < 5
    do

        task.wait(0.1)

        local currentPrompt =
            GetHatchPrompt()

        if not currentPrompt then
            break
        end

    end

    HatchRunning = false
    WaitingForHatch = false

    print(
        "Auto Hatch: Finished."
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

        elseif Options then

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

        StealingEnabled =
            Value

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

        elseif Options then

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
-- AUTO PLACE TOGGLE
-- =====================================

Tab:CreateToggle({

    Name = "Auto Place Egg",

    CurrentValue = false,

    Flag = "AutoPlaceEgg",

    Callback = function(Value)

        AutoPlaceEnabled =
            Value

        if not Value then

            UnequipCurrentTool()

            WaitingForHatch = false

            return
        end

        task.spawn(function()

            while AutoPlaceEnabled do

                -- Stealing has priority.

                if not StealingRunning then

                    -- If an egg needs to hatch,
                    -- wait for Auto Hatch.

                    if not WaitingForHatch then

                        pcall(function()

                            PlaceSelectedEgg()

                        end)

                    end

                end

                task.wait(0.5)

            end

        end)

    end
})

-- =====================================
-- AUTO HATCH TOGGLE
-- =====================================

Tab:CreateToggle({

    Name = "Auto Hatch Egg",

    CurrentValue = false,

    Flag = "AutoHatchEgg",

    Callback = function(Value)

        AutoHatchEnabled =
            Value

        -- Turning Auto Hatch off
        -- allows Auto Place to continue.

        if not Value then

            WaitingForHatch = false

            return
        end

        -- =================================
        -- HATCH LOOP
        -- =================================

        task.spawn(function()

            while AutoHatchEnabled do

                -- Stealing has priority.

                if not StealingRunning
                    and not HatchRunning
                then

                    -- IMPORTANT:
                    -- Search the actual Hatch prompt
                    -- every loop.

                    local prompt =
                        GetHatchPrompt()

                    if prompt then

                        WaitingForHatch = true

                        pcall(function()

                            HatchEgg()

                        end)

                    end

                end

                task.wait(0.25)

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

        LuckEnabled =
            Value

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
