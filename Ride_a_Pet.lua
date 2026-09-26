
local Rayfield = loadstring(game:HttpGet(
    "https://sirius.menu/rayfield"
))()

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
-- DYNAMIC EGG RANKING
-- =====================================

local function GetEggUIData(eggName)

    local playerGui =
        Player:FindFirstChild("PlayerGui")

    if not playerGui then
        return nil
    end

    local main =
        playerGui:FindFirstChild("Main")

    if not main then
        return nil
    end

    local eggTracker =
        main:FindFirstChild("EggTracker")

    if not eggTracker then
        return nil
    end

    local eggsHolder =
        eggTracker:FindFirstChild("EggsHolder")

    if not eggsHolder then
        return nil
    end

    local eggFrame =
        eggsHolder:FindFirstChild(eggName)

    if not eggFrame then
        return nil
    end

    -- Rarity is determined dynamically
    -- from the egg's position/order inside EggsHolder.
    local rarityRank =
        eggFrame.LayoutOrder

    -- Luck
    local luckValue = 0

    local luckDisplay =
        eggFrame:FindFirstChild("LuckDisplay")

    if luckDisplay then

        local luck =
            luckDisplay:FindFirstChild("Luck")

        if luck then

            if luck:IsA("TextLabel")
                or luck:IsA("TextButton")
                or luck:IsA("TextBox")
            then
                local text =
                    luck.Text

                local number =
                    tonumber(
                        string.match(
                            text,
                            "[%d%.]+"
                        )
                    )

                if number then
                    luckValue = number
                end
            end
        end
    end

    return {
        RarityRank = rarityRank,
        Luck = luckValue
    }
end

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

local SelectedStealingEggs = {
    ["Cherub Egg"] = true
}

local SelectedPlaceEggs = {
    ["Cherub Egg"] = true
}

-- =====================================
-- SETTINGS
-- =====================================

local LOAD_WAIT = 1
local AFTER_EGG_WAIT = 0.5

local WAYPOINT_WAIT = 1

local NEAR_BASEPLATE_WAIT = 4
local WALK_DISTANCE = 8

-- =====================================
-- CHARACTER
-- =====================================

local function GetCharacter()
    return Player.Character
end

local function GetRoot()

    local character = GetCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChild(
        "HumanoidRootPart"
    )
end

local function GetHumanoid()

    local character = GetCharacter()

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

local function StopMovement()

    local humanoid = GetHumanoid()
    local root = GetRoot()

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
-- OWNED PLOT
-- =====================================

local function GetMyPlot()

    local plots =
        workspace:FindFirstChild("Plots")

    if not plots then
        return nil
    end

    for _, plot in ipairs(
        plots:GetChildren()
    ) do

        if plot:IsA("Model")
            and plot.Name == "Plot"
        then

            local data =
                plot:FindFirstChild("Data")

            if data then

                local owner =
                    data:FindFirstChild("Owner")

                if owner
                    and owner:IsA("ObjectValue")
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
-- OWNED BASEPLATE
-- =====================================

local function GetMyBaseplate()

    local plot = GetMyPlot()

    if not plot then
        return nil
    end

    local baseplate =
        plot:FindFirstChild("Baseplate")

    if baseplate
        and baseplate:IsA("BasePart")
    then

        return baseplate
    end

    return nil
end

-- =====================================
-- VERIFY OWNERSHIP
-- =====================================

local function VerifyMyPlot(plot)

    if not plot then
        return false
    end

    local data =
        plot:FindFirstChild("Data")

    if not data then
        return false
    end

    local owner =
        data:FindFirstChild("Owner")

    if not owner
        or not owner:IsA("ObjectValue")
    then
        return false
    end

    return owner.Value == Player
end

-- =====================================
-- RANDOM POSITION ON OWN BASEPLATE
-- =====================================

local function GetRandomBaseplatePosition(
    baseplate
)

    if not baseplate then
        return nil
    end

    if not baseplate:IsA("BasePart") then
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

    if not model then
        return nil
    end

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
-- CLOSEST POINT ON BASEPLATE
-- =====================================

local function GetClosestBaseplatePoint(
    baseplate,
    position
)

    if not baseplate
        or not baseplate:IsA("BasePart")
    then
        return nil
    end

    local localPosition =
        baseplate.CFrame:PointToObjectSpace(
            position
        )

    local half =
        baseplate.Size / 2

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

    return baseplate.CFrame:PointToWorldSpace(
        closest
    )
end

-- =====================================
-- BASEPLATE CENTER
-- =====================================

local function GetBaseplateCenter(
    baseplate
)

    if not baseplate then
        return nil
    end

    return baseplate.Position
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

    local eggPosition =
        GetModelPosition(egg)

    if not eggPosition then

        StealingRunning = false

        return
    end

    -- =================================
    -- TP #1
    -- =================================

    root.CFrame =
        CFrame.new(
            eggPosition
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

    eggPosition =
        GetModelPosition(egg)

    if not eggPosition then

        StealingRunning = false

        return
    end

    root.CFrame =
        CFrame.new(
            eggPosition
            + Vector3.new(0, 3, 0)
        )

    if not WaitStealing(
        LOAD_WAIT
    ) then

        StealingRunning = false

        return
    end

    -- =================================
    -- FIRE EGG PROMPT
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
            "RenderedEggs egg prompt not found."
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
    -- OWNER CHECK
    -- BEFORE RETURNING
    -- =================================

    local myPlot =
        GetMyPlot()

    if not myPlot
        or not VerifyMyPlot(myPlot)
    then

        warn(
            "Stealing: Owned Plot not found."
        )

        StealingRunning = false

        return
    end

    -- =================================
    -- OWNED BASEPLATE
    -- =================================

    local baseplate =
        GetMyBaseplate()

    if not baseplate then

        warn(
            "Stealing: Owned Baseplate not found."
        )

        StealingRunning = false

        return
    end

    -- =================================
    -- START POSITION
    -- =================================

    root =
        GetRoot()

    if not root then

        StealingRunning = false

        return
    end

    local startPosition =
        root.Position

    -- =================================
    -- CLOSEST POINT ON OWN BASEPLATE
    -- =================================

    local baseplatePoint =
        GetClosestBaseplatePoint(
            baseplate,
            startPosition
        )

    if not baseplatePoint then

        StealingRunning = false

        return
    end

    -- =================================
    -- DIRECTION
    -- =================================

    local direction =
        baseplatePoint
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

    local totalDistance =
        (
            baseplatePoint
            - startPosition
        ).Magnitude

    -- =================================
    -- WAYPOINT PATTERN
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

    local waypoints = {
        waypoint1,
        waypoint2,
        waypoint3,
        waypoint4,
        waypoint5,
        waypoint6,
        waypoint7,
        waypoint8,
        waypoint9,
        waypoint10
    }

    -- =================================
    -- MOVE THROUGH WAYPOINTS
    -- =================================

    for _, waypoint in ipairs(
        waypoints
    ) do

        if not StealingEnabled then

            StealingRunning = false

            return
        end

        root =
            GetRoot()

        if not root then

            StealingRunning = false

            return
        end

        root.CFrame =
            CFrame.new(
                waypoint
            )

        if not WaitStealing(
            WAYPOINT_WAIT
        ) then

            StealingRunning = false

            return
        end
    end

    -- =================================
    -- RECHECK OWNERSHIP
    -- =================================

    myPlot =
        GetMyPlot()

    if not myPlot
        or not VerifyMyPlot(myPlot)
    then

        StealingRunning = false

        return
    end

    baseplate =
        GetMyBaseplate()

    if not baseplate then

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
    -- RECALCULATE BASEPLATE POINT
    -- =================================

    baseplatePoint =
        GetClosestBaseplatePoint(
            baseplate,
            root.Position
        )

    if not baseplatePoint then

        StealingRunning = false

        return
    end

    local finalDirection =
        baseplatePoint
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
    -- 8 STUDS BEFORE OWN BASEPLATE
    -- =================================

    local nearBaseplate =
        baseplatePoint
        - finalDirection
        * WALK_DISTANCE

    root.CFrame =
        CFrame.new(
            nearBaseplate
        )

    -- =================================
    -- WAIT
    -- =================================

    if not WaitStealing(
        NEAR_BASEPLATE_WAIT
    ) then

        StealingRunning = false

        return
    end

    -- =================================
    -- FINAL OWNER CHECK
    -- =================================

    myPlot =
        GetMyPlot()

    if not myPlot
        or not VerifyMyPlot(myPlot)
    then

        StealingRunning = false

        return
    end

    baseplate =
        GetMyBaseplate()

    if not baseplate then

        StealingRunning = false

        return
    end

    -- =================================
    -- FINAL TP TO OWN BASEPLATE
    -- =================================

    root =
        GetRoot()

    if not root then

        StealingRunning = false

        return
    end

    local center =
        GetBaseplateCenter(
            baseplate
        )

    if center then

        root.CFrame =
            CFrame.new(center)
    end

    StealingRunning = false
end

-- =====================================
-- MY EGGS FOLDER
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

    for _, eggName in ipairs(Eggs) do

        if SelectedPlaceEggs[
            eggName
        ] then

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

    table.sort(
        availableEggs,
        function(a, b)

            -- =========================
            -- RARITY
            -- =========================

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

            -- =========================
            -- WEIGHT
            -- =========================

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

            -- =========================
            -- ORIGINAL ORDER
            -- =========================

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
-- AUTO PLACE EGG
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
    -- OWNER CHECK FIRST
    -- =================================

    local plot =
        GetMyPlot()

    if not plot
        or not VerifyMyPlot(plot)
    then

        warn(
            "Auto Place: Owned Plot not found."
        )

        return false
    end

    -- =================================
    -- OWNED BASEPLATE
    -- =================================

    local baseplate =
        plot:FindFirstChild(
            "Baseplate"
        )

    if not baseplate
        or not baseplate:IsA("BasePart")
    then

        warn(
            "Auto Place: Owned Baseplate not found."
        )

        return false
    end

    -- =================================
    -- GET BACKPACK EGG
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
    -- OLD EGG COUNT
    -- =================================

    local oldEggCount =
        GetEggCount()

    -- =================================
    -- EQUIP
    -- =================================

humanoid:EquipTool(egg)

local equipped = false
for _ = 1, 20 do
    if egg.Parent == Player.Character then
        equipped = true
        break
    end

    task.wait(0.1)
end

if not equipped then
    humanoid:EquipTool(egg)
    task.wait(0.2)

    if egg.Parent ~= Player.Character then
        return false
    end
end

    -- =================================
    -- OWNER CHECK AGAIN
    -- =================================

    plot =
        GetMyPlot()

    if not plot
        or not VerifyMyPlot(plot)
    then

        humanoid:UnequipTools()

        warn(
            "Auto Place: Ownership check failed."
        )

        return false
    end

    -- =================================
    -- BASEPLATE AGAIN
    -- =================================

    baseplate =
        plot:FindFirstChild(
            "Baseplate"
        )

    if not baseplate
        or not baseplate:IsA("BasePart")
    then

        humanoid:UnequipTools()

        return false
    end

    -- =================================
    -- RANDOM OWNED POSITION
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
    -- FINAL OWNER CHECK
    -- IMMEDIATELY BEFORE REMOTE
    -- =================================

    plot =
        GetMyPlot()

    if not plot
        or not VerifyMyPlot(plot)
    then

        humanoid:UnequipTools()

        warn(
            "Auto Place: Final owner check failed."
        )

        return false
    end

    baseplate =
        plot:FindFirstChild(
            "Baseplate"
        )

    if not baseplate
        or not baseplate:IsA("BasePart")
    then

        humanoid:UnequipTools()

        return false
    end

    -- =================================
    -- PLACE
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
    -- CHECK SERVER
    -- =================================

    task.wait(0.8)

    local newEggCount =
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
    -- SECOND CHECK
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

    WaitingForHatch = false

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

    local prompt =
        GetHatchPrompt()

    if not prompt then
        return false
    end

    HatchRunning = true

    print(
        "Auto Hatch: Hatch prompt found."
    )

    fireproximityprompt(
        prompt
    )

    local start =
        os.clock()

    while AutoHatchEnabled
        and not StealingRunning
        and os.clock() - start < 5
    do

        task.wait(0.1)

        if not GetHatchPrompt() then
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

                -- Stealing always has priority.

                if not StealingRunning then

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

        if not Value then

            WaitingForHatch = false

            return
        end

        task.spawn(function()

            while AutoHatchEnabled do

                -- Stealing always has priority.

                if not StealingRunning
                    and not HatchRunning
                then

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
-- LUCK UPGRADE DROPDOWN
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
