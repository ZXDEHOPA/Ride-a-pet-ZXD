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

local SelectedStealingEggs = {}
local SelectedPlaceEggs = {}

-- =====================================
-- SETTINGS
-- =====================================

local LOAD_WAIT = 1
local AFTER_EGG_WAIT = 0.5
local WAYPOINT_WAIT = 1
local NEAR_BASEPLATE_WAIT = 10
local WALK_DISTANCE = 8

local FallbackEggs = {
    "Cherub Egg",
    "Solaris Egg",
    "Blackhole Egg",
    "Aurora Egg",
    "Soul Egg",
    "Sinister Egg"
}

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

    return character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local character = GetCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
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
        humanoid:Move(Vector3.zero, false)
        humanoid:MoveTo(root.Position)
    end
end

-- =====================================
-- DYNAMIC EGG TRACKER
--
-- PlayerGui
-- > Main
-- > EggTracker
-- > EggsHolder
-- > Egg Frame
-- =====================================

local function GetEggsHolder()
    local playerGui = Player:FindFirstChild("PlayerGui")

    if not playerGui then
        return nil
    end

    local main = playerGui:FindFirstChild("Main")

    if not main then
        return nil
    end

    local tracker = main:FindFirstChild("EggTracker")

    if not tracker then
        return nil
    end

    return tracker:FindFirstChild("EggsHolder")
end

local function ParseLuckText(text)
    if type(text) ~= "string" then
        return 0
    end

    text = text:gsub(",", ".")

    local number = string.match(
        text,
        "%-?%d+%.?%d*"
    )

    if not number then
        return 0
    end

    return tonumber(number) or 0
end

local function GetLuckFromEggFrame(eggFrame)
    local luckDisplay =
        eggFrame:FindFirstChild("LuckDisplay")

    if not luckDisplay then
        return 0
    end

    local luck =
        luckDisplay:FindFirstChild("Luck")

    if not luck then
        return 0
    end

    if luck:IsA("TextLabel")
        or luck:IsA("TextButton")
        or luck:IsA("TextBox")
    then
        return ParseLuckText(luck.Text)
    end

    local textObject =
        luck:FindFirstChildWhichIsA(
            "TextLabel",
            true
        )

        or luck:FindFirstChildWhichIsA(
            "TextButton",
            true
        )

        or luck:FindFirstChildWhichIsA(
            "TextBox",
            true
        )

    if textObject then
        return ParseLuckText(textObject.Text)
    end

    return 0
end

-- =====================================
-- GET DYNAMIC EGG DATA
-- =====================================

local function GetDynamicEggData()
    local holder = GetEggsHolder()

    if not holder then
        return {}
    end

    local frames = {}

    for index, child in ipairs(
        holder:GetChildren()
    ) do
        if child:IsA("Frame") then
            table.insert(frames, {
                Frame = child,
                OriginalIndex = index
            })
        end
    end

    -- The EggTracker's visual order
    -- is used as the rarity order.
    --
    -- Top egg = rarest.
    -- Lower egg = less rare.

    table.sort(frames, function(a, b)
        local orderA =
            a.Frame.LayoutOrder

        local orderB =
            b.Frame.LayoutOrder

        if orderA ~= orderB then
            return orderA < orderB
        end

        local yA =
            a.Frame.AbsolutePosition.Y

        local yB =
            b.Frame.AbsolutePosition.Y

        if yA ~= yB then
            return yA < yB
        end

        return a.OriginalIndex <
            b.OriginalIndex
    end)

    local result = {}

    for rarityRank, entry in ipairs(frames) do
        local frame = entry.Frame

        result[frame.Name] = {
            Name = frame.Name,
            RarityRank = rarityRank,
            Luck = GetLuckFromEggFrame(frame),
            Frame = frame
        }
    end

    return result
end

-- =====================================
-- GET EGG NAMES
-- =====================================

local function GetDynamicEggNames()
    local data =
        GetDynamicEggData()

    local names = {}

    for _, eggData in pairs(data) do
        table.insert(
            names,
            eggData.Name
        )
    end

    table.sort(names, function(a, b)
        return data[a].RarityRank <
            data[b].RarityRank
    end)

    return names
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

    return owner
        and owner:IsA("ObjectValue")
        and owner.Value == Player
end

-- =====================================
-- OWNED BASEPLATE
-- =====================================

local function GetMyBaseplate()
    local plot =
        GetMyPlot()

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
-- RANDOM BASEPLATE POSITION
-- =====================================

local function GetRandomBaseplatePosition(
    baseplate
)
    if not baseplate
        or not baseplate:IsA("BasePart")
    then
        return nil
    end

    local size =
        baseplate.Size

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

    return baseplate.CFrame:PointToWorldSpace(
        Vector3.new(
            x,
            size.Y / 2 + 0.1,
            z
        )
    )
end

-- =====================================
-- RENDERED EGG
-- =====================================

local function GetSelectedStealingEgg()
    local renderedEggs =
        workspace:FindFirstChild(
            "RenderedEggs"
        )

    if not renderedEggs then
        return nil
    end

    local names =
        GetDynamicEggNames()

    for _, eggName in ipairs(names) do
        if SelectedStealingEggs[
            eggName
        ] then

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

local function GetModelPosition(model)
    if not model then
        return nil
    end

    local cf =
        model:GetBoundingBox()

    return cf.Position
end

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
-- BASEPLATE POINT
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
-- STEALING WAIT
-- =====================================

local function WaitStealing(
    duration
)
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
            "Stealing: Egg prompt not found."
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

    local baseplate =
        GetMyBaseplate()

    if not baseplate then
        warn(
            "Stealing: Owned Baseplate not found."
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

    local baseplatePoint =
        GetClosestBaseplatePoint(
            baseplate,
            startPosition
        )

    if not baseplatePoint then
        StealingRunning = false
        return
    end

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

    -- 10 waypoints.
    local waypoints = {}

    for i = 1, 10 do
        local fraction =
            i / 11

        table.insert(
            waypoints,
            startPosition
            + direction
            * (
                totalDistance
                * fraction
            )
        )
    end

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
            CFrame.new(waypoint)

        if not WaitStealing(
            WAYPOINT_WAIT
        ) then
            StealingRunning = false
            return
        end
    end

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

    local nearBaseplate =
        baseplatePoint
        - finalDirection
        * WALK_DISTANCE

    root.CFrame =
        CFrame.new(
            nearBaseplate
        )

    if not WaitStealing(
        NEAR_BASEPLATE_WAIT
    ) then
        StealingRunning = false
        return
    end

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

    root.CFrame =
        CFrame.new(
            baseplate.Position
        )

    StealingRunning = false
end

-- =====================================
-- MY EGGS
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

    local dynamicData =
        GetDynamicEggData()

    local availableEggs = {}

    for eggName, eggData in pairs(
        dynamicData
    ) do
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
                    {
                        Tool = egg,
                        Data = eggData
                    }
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

            -- RAREST FIRST
            if a.Data.RarityRank
                ~= b.Data.RarityRank
            then
                return
                    a.Data.RarityRank
                    < b.Data.RarityRank
            end

            -- HIGHEST LUCK FIRST
            if a.Data.Luck
                ~= b.Data.Luck
            then
                return
                    a.Data.Luck
                    > b.Data.Luck
            end

            -- WEIGHT ONLY BREAKS A TIE
            if WeightPreference
                ~= "None"
            then
                local dataA =
                    a.Tool:FindFirstChild(
                        "Data"
                    )

                local dataB =
                    b.Tool:FindFirstChild(
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
                    and valueA ~= valueB
                then
                    if WeightPreference
                        == "Highest Weight"
                    then
                        return valueA > valueB
                    else
                        return valueA < valueB
                    end
                end
            end

            return a.Tool.Name <
                b.Tool.Name
        end
    )

    return availableEggs[1].Tool
end

-- =====================================
-- EQUIP EGG
-- =====================================

local function EquipEgg(egg)
    local humanoid =
        GetHumanoid()

    local character =
        GetCharacter()

    local backpack =
        Player:FindFirstChild(
            "Backpack"
        )

    if not humanoid
        or not character
        or not backpack
        or not egg
    then
        return false
    end

    if egg.Parent ~= backpack then
        egg =
            backpack:FindFirstChild(
                egg.Name
            )
    end

    if not egg then
        return false
    end

    if not egg:IsA("Tool") then
        warn(
            "Auto Place: "
            .. egg.Name
            .. " is not a Tool. ClassName = "
            .. egg.ClassName
        )

        return false
    end

    humanoid:EquipTool(egg)

    local start =
        os.clock()

    while os.clock() - start < 2 do
        if egg.Parent == character then
            return true
        end

        task.wait(0.1)

        if egg.Parent == backpack then
            humanoid:EquipTool(egg)
        end
    end

    return egg.Parent == character
end

-- =====================================
-- HATCH PROMPT
-- =====================================

local function GetHatchPrompt()
    local plot =
        GetMyPlot()

    if not plot
        or not VerifyMyPlot(plot)
    then
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
    if not AutoPlaceEnabled
        or StealingRunning
        or WaitingForHatch
    then
        return false
    end

    local plot =
        GetMyPlot()

    if not plot
        or not VerifyMyPlot(plot)
    then
        return false
    end

    local baseplate =
        plot:FindFirstChild(
            "Baseplate"
        )

    if not baseplate
        or not baseplate:IsA(
            "BasePart"
        )
    then
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

    local oldEggCount =
        GetEggCount()

    if not EquipEgg(egg) then
        warn(
            "Auto Place: Could not equip "
            .. egg.Name
        )

        return false
    end

    plot =
        GetMyPlot()

    if not plot
        or not VerifyMyPlot(plot)
    then
        humanoid:UnequipTools()
        return false
    end

    baseplate =
        plot:FindFirstChild(
            "Baseplate"
        )

    if not baseplate
        or not baseplate:IsA(
            "BasePart"
        )
    then
        humanoid:UnequipTools()
        return false
    end

    local position =
        GetRandomBaseplatePosition(
            baseplate
        )

    if not position then
        humanoid:UnequipTools()
        return false
    end

    -- Final owner check.
    plot =
        GetMyPlot()

    if not plot
        or not VerifyMyPlot(plot)
    then
        humanoid:UnequipTools()
        return false
    end

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

    task.wait(0.8)

    local newEggCount =
        GetEggCount()

    if newEggCount > oldEggCount then
        if AutoHatchEnabled then
            WaitingForHatch = true
        end

        print(
            "Auto Place: Egg placed."
        )

        return true
    end

    task.wait(0.5)

    newEggCount =
        GetEggCount()

    if newEggCount > oldEggCount then
        if AutoHatchEnabled then
            WaitingForHatch = true
        end

        print(
            "Auto Place: Egg placed."
        )

        return true
    end

    humanoid:UnequipTools()

    WaitingForHatch = false

    print(
        "Auto Place: Placement failed."
    )

    return false
end

-- =====================================
-- AUTO HATCH
-- =====================================

local function HatchEgg()
    if not AutoHatchEnabled
        or StealingRunning
        or HatchRunning
    then
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
-- INITIAL EGG OPTIONS
-- =====================================

local EggOptions =
    GetDynamicEggNames()

if #EggOptions == 0 then
    EggOptions =
        table.clone(
            FallbackEggs
        )
end

if EggOptions[1] then
    SelectedStealingEggs[
        EggOptions[1]
    ] = true

    SelectedPlaceEggs[
        EggOptions[1]
    ] = true
end

-- =====================================
-- STEALING EGG DROPDOWN
-- =====================================

local StealingDropdown =
    Tab:CreateDropdown({

        Name = "Stealing Egg",

        Options = EggOptions,

        CurrentOption = {
            EggOptions[1]
                or "Cherub Egg"
        },

        MultipleOptions = true,

        Flag = "StealingEggs",

        Callback = function(
            Options
        )
            SelectedStealingEggs = {}

            if type(Options)
                == "table"
            then
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

    Callback = function(
        Value
    )
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

local PlaceDropdown =
    Tab:CreateDropdown({

        Name = "Egg",

        Options = EggOptions,

        CurrentOption = {
            EggOptions[1]
                or "Cherub Egg"
        },

        MultipleOptions = true,

        Flag = "PlaceEggs",

        Callback = function(
            Options
        )
            SelectedPlaceEggs = {}

            if type(Options)
                == "table"
            then
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
-- REFRESH DYNAMIC EGG LIST
-- =====================================

task.spawn(function()

    for _ = 1, 20 do

        task.wait(0.5)

        local names =
            GetDynamicEggNames()

        if #names > 0 then

            pcall(function()

                StealingDropdown:Refresh(
                    names
                )

                PlaceDropdown:Refresh(
                    names
                )

            end)

            break
        end
    end
end)

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

    Callback = function(
        Option
    )
        WeightPreference =
            Option[1]
    end
})

-- =====================================
-- AUTO PLACE EGG
-- =====================================

Tab:CreateToggle({

    Name = "Auto Place Egg",

    CurrentValue = false,

    Flag = "AutoPlaceEgg",

    Callback = function(
        Value
    )
        AutoPlaceEnabled =
            Value

        if not Value then

            UnequipCurrentTool()

            WaitingForHatch =
                false

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
-- AUTO HATCH EGG
-- =====================================

Tab:CreateToggle({

    Name = "Auto Hatch Egg",

    CurrentValue = false,

    Flag = "AutoHatchEgg",

    Callback = function(
        Value
    )
        AutoHatchEnabled =
            Value

        if not Value then
            WaitingForHatch =
                false

            return
        end

        task.spawn(function()

            while AutoHatchEnabled do

                if not StealingRunning
                    and not HatchRunning
                then

                    local prompt =
                        GetHatchPrompt()

                    if prompt then

                        WaitingForHatch =
                            true

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

    Callback = function(
        Option
    )
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

    Callback = function(
        Value
    )
        LuckEnabled =
            Value

        if not Value then
            return
        end

        task.spawn(function()

            while LuckEnabled do

                pcall(function()

                    if LuckMode
                        == "Max"
                    then

                        Upgrades:FireServer(
                            "Max"
                        )

                    else

                        Upgrades:FireServer()

                    end

                end)

                task.wait(1)
            end

        end)
    end
})
