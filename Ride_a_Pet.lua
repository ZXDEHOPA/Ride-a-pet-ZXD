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

    local playerGui =
        Player:FindFirstChild(
            "PlayerGui"
        )

    if not playerGui then
        return nil
    end

    local main =
        playerGui:FindFirstChild(
            "Main"
        )

    if not main then
        return nil
    end

    local tracker =
        main:FindFirstChild(
            "EggTracker"
        )

    if not tracker then
        return nil
    end

    return tracker:FindFirstChild(
        "EggsHolder"
    )
end

-- =====================================
-- NUMBER PARSER
-- =====================================

local function ParseEggNumber(text)

    if type(text) ~= "string" then
        return nil
    end

    text =
        text:gsub(",", "")

    local number =
        string.match(
            text,
            "%-?%d+%.?%d*"
        )

    if not number then
        return nil
    end

    local value =
        tonumber(number)

    if not value then
        return nil
    end

    local suffix =
        string.match(
            text,
            "[KkMmBbTt]"
        )

    if suffix then

        local multipliers = {

            K = 1e3,
            k = 1e3,

            M = 1e6,
            m = 1e6,

            B = 1e9,
            b = 1e9,

            T = 1e12,
            t = 1e12
        }

        value *=
            multipliers[suffix]
    end

    return value
end

-- =====================================
-- RARITY VALUES
-- =====================================

local RarityValues = {

    ["Common"] = 1,

    ["Uncommon"] = 2,

    ["Rare"] = 3,

    ["Epic"] = 4,

    ["Legendary"] = 5,

    ["Mythic"] = 6,

    ["Secret"] = 7,

    ["Exclusive"] = 8
}

-- =====================================
-- GET TEXT FROM OBJECT
-- =====================================

local function GetObjectText(object)

    if not object then
        return nil
    end

    if object:IsA("TextLabel")
        or object:IsA("TextButton")
        or object:IsA("TextBox")
    then

        return object.Text
    end

    if object:IsA("StringValue") then
        return object.Value
    end

    return nil
end

-- =====================================
-- GET EGG RARITY
-- =====================================

local function GetEggRarity(
    eggFrame
)

    if not eggFrame then
        return 0, "Unknown"
    end

    local eggName =
        string.lower(
            eggFrame.Name
        )

    -- =================================
    -- SPECIAL ROBUX / EXCLUSIVE EGGS
    -- =================================

    if eggName == "dragon"
        or eggName == "giant"
    then

        return 8, "Exclusive"
    end

    -- =================================
    -- ATTRIBUTE
    -- =================================

    local rarity =
        eggFrame:GetAttribute(
            "Rarity"
        )

    if typeof(rarity) == "number" then

        return rarity,
            tostring(rarity)
    end

    if typeof(rarity) == "string" then

        local rarityName =
            rarity

        local rarityNumber =
            RarityValues[
                rarityName
            ]

        if rarityNumber then

            return rarityNumber,
                rarityName
        end

        local lowerRarity =
            string.lower(
                rarity
            )

        for name, value in pairs(
            RarityValues
        ) do

            if string.lower(name)
                == lowerRarity
            then

                return value,
                    name
            end
        end
    end

    -- =================================
    -- SEARCH RARITY OBJECTS
    -- =================================

    local rarityObjectNames = {

        "Rarity",

        "RarityDisplay",

        "RarityLabel",

        "EggRarity"
    }

    for _, objectName in ipairs(
        rarityObjectNames
    ) do

        local object =
            eggFrame:FindFirstChild(
                objectName,
                true
            )

        if object then

            if object:IsA(
                "NumberValue"
            )
            or object:IsA(
                "IntValue"
            )
            then

                return object.Value,
                    tostring(
                        object.Value
                    )
            end

            local text =
                GetObjectText(
                    object
                )

            if text then

                local lowerText =
                    string.lower(
                        text
                    )

                for rarityName,
                    rarityNumber
                    in pairs(
                        RarityValues
                    )
                do

                    if string.find(
                        lowerText,
                        string.lower(
                            rarityName
                        ),
                        1,
                        true
                    )
                    then

                        return rarityNumber,
                            rarityName
                    end
                end
            end
        end
    end

    -- =================================
    -- UNKNOWN
    -- =================================

    return 0, "Unknown"
end

-- =====================================
-- GET LUCK
-- =====================================

local function GetLuckFromEggFrame(
    eggFrame
)

    if not eggFrame then
        return 0
    end

    -- =================================
    -- LUCK ATTRIBUTE
    -- =================================

    local luckAttribute =
        eggFrame:GetAttribute(
            "Luck"
        )

    if typeof(luckAttribute)
        == "number"
    then

        return luckAttribute
    end

    if typeof(luckAttribute)
        == "string"
    then

        local value =
            ParseEggNumber(
                luckAttribute
            )

        if value then
            return value
        end
    end

    -- =================================
    -- LUCK DISPLAY
    --
    -- EggFrame
    -- > LuckDisplay
    -- > Luck
    -- =================================

    local luckDisplay =
        eggFrame:FindFirstChild(
            "LuckDisplay"
        )

    if not luckDisplay then
        return 0
    end

    local luck =
        luckDisplay:FindFirstChild(
            "Luck",
            true
        )

    if not luck then
        return 0
    end

    if luck:IsA("NumberValue")
        or luck:IsA("IntValue")
    then

        return luck.Value
    end

    local text =
        GetObjectText(
            luck
        )

    if text then

        return
            ParseEggNumber(
                text
            ) or 0
    end

    local textObject =
        luck:FindFirstChildWhichIsA(
            "TextLabel",
            true
        )

    if textObject then

        return
            ParseEggNumber(
                textObject.Text
            ) or 0
    end

    return 0
end

-- =====================================
-- GET DYNAMIC EGG DATA
-- =====================================

local function GetDynamicEggData()

    local holder =
        GetEggsHolder()

    if not holder then
        return {}
    end

    local result = {}

    for _, child in ipairs(
        holder:GetChildren()
    ) do

        if child:IsA("Frame") then

            local rarityRank,
                rarityName =
                GetEggRarity(
                    child
                )

            local luck =
                GetLuckFromEggFrame(
                    child
                )

            result[
                child.Name
            ] = {

                Name =
                    child.Name,

                RarityRank =
                    rarityRank,

                RarityName =
                    rarityName,

                Luck =
                    luck,

                Frame =
                    child
            }
        end
    end

    return result
end

-- =====================================
-- GET SORTED EGG NAMES
-- =====================================

local function GetDynamicEggNames()

    local data =
        GetDynamicEggData()

    local names = {}

    for eggName in pairs(
        data
    ) do

        table.insert(
            names,
            eggName
        )
    end

    -- =================================
    -- SORT:
    --
    -- 1. HIGHEST RARITY
    -- 2. HIGHEST LUCK
    -- 3. NAME
    -- =================================

    table.sort(
        names,
        function(a, b)

            local eggA =
                data[a]

            local eggB =
                data[b]

            if eggA.RarityRank
                ~= eggB.RarityRank
            then

                return
                    eggA.RarityRank
                    > eggB.RarityRank
            end

            if eggA.Luck
                ~= eggB.Luck
            then

                return
                    eggA.Luck
                    > eggB.Luck
            end

            return
                string.lower(a)
                <
                string.lower(b)
        end
    )

    return names
end

-- =====================================
-- OWNED PLOT
-- =====================================

local function GetMyPlot()

    local plots =
        workspace:FindFirstChild(
            "Plots"
        )

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
                    and owner.Value
                        == Player
                then

                    return plot
                end
            end
        end
    end

    return nil
end

local function VerifyMyPlot(
    plot
)

    if not plot then
        return false
    end

    local data =
        plot:FindFirstChild(
            "Data"
        )

    if not data then
        return false
    end

    local owner =
        data:FindFirstChild(
            "Owner"
        )

    return owner
        and owner:IsA(
            "ObjectValue"
        )
        and owner.Value
            == Player
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

    if not baseplate
        or not baseplate:IsA(
            "BasePart"
        )
    then

        return nil
    end

    local size =
        baseplate.Size

    local margin = 1

    local usableX =
        math.max(
            size.X
                - margin * 2,
            0
        )

    local usableZ =
        math.max(
            size.Z
                - margin * 2,
            0
        )

    local x =
        (
            math.random()
            - 0.5
        )
        * usableX

    local z =
        (
            math.random()
            - 0.5
        )
        * usableZ

    return
        baseplate.CFrame:
            PointToWorldSpace(
                Vector3.new(
                    x,
                    size.Y / 2
                        + 0.1,
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

    for _, eggName in ipairs(
        names
    ) do

        if SelectedStealingEggs[
            eggName
        ] then

            for _, egg in ipairs(
                renderedEggs:GetChildren()
            ) do

                if egg.Name
                    == eggName
                    and egg:IsA(
                        "Model"
                    )
                then

                    return egg
                end
            end
        end
    end

    return nil
end

local function GetModelPosition(
    model
)

    if not model then
        return nil
    end

    local cf =
        model:GetBoundingBox()

    return cf.Position
end

local function GetEggPrompt(
    egg
)

    if not egg then
        return nil
    end

    return
        egg:FindFirstChildWhichIsA(
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
        or not baseplate:IsA(
            "BasePart"
        )
    then

        return nil
    end

    local localPosition =
        baseplate.CFrame:
            PointToObjectSpace(
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

    return
        baseplate.CFrame:
            PointToWorldSpace(
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
        and os.clock()
            - start
            < duration
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
        GetModelPosition(
            egg
        )

    if not eggPosition then

        StealingRunning = false

        return
    end

    root.CFrame =
        CFrame.new(
            eggPosition
                + Vector3.new(
                    0,
                    3,
                    0
                )
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

    if not root
        or not egg
    then

        StealingRunning = false

        return
    end

    eggPosition =
        GetModelPosition(
            egg
        )

    if not eggPosition then

        StealingRunning = false

        return
    end

    root.CFrame =
        CFrame.new(
            eggPosition
                + Vector3.new(
                    0,
                    3,
                    0
                )
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
        GetEggPrompt(
            egg
        )

    if not prompt then

        warn(
            "Stealing: Egg prompt not found."
        )

        StealingRunning = false

        return
    end

    fireproximityprompt(
        prompt
    )

    if not WaitStealing(
        AFTER_EGG_WAIT
    ) then

        StealingRunning = false

        return
    end

    local myPlot =
        GetMyPlot()

    if not myPlot
        or not VerifyMyPlot(
            myPlot
        )
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

    if direction.Magnitude
        < 0.1
    then

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

    -- 10 WAYPOINTS

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

    myPlot =
        GetMyPlot()

    if not myPlot
        or not VerifyMyPlot(
            myPlot
        )
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

    if finalDirection.Magnitude
        < 0.1
    then

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
        or not VerifyMyPlot(
            myPlot
        )
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

    return
        plot:FindFirstChild(
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

    for eggName,
        eggData in pairs(
            dynamicData
        )
    do

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

    if #availableEggs
        == 0
    then

        return nil
    end

    -- =================================
    -- SORT:
    --
    -- RARITY DESCENDING
    -- LUCK DESCENDING
    -- WEIGHT TIE BREAK
    -- NAME TIE BREAK
    -- =================================

    table.sort(
        availableEggs,
        function(a, b)

            local dataA =
                a.Data

            local dataB =
                b.Data

            -- HIGHER RARITY FIRST

            if dataA.RarityRank
                ~= dataB.RarityRank
            then

                return
                    dataA.RarityRank
                    > dataB.RarityRank
            end

            -- HIGHER LUCK FIRST

            if dataA.Luck
                ~= dataB.Luck
            then

                return
                    dataA.Luck
                    > dataB.Luck
            end

            -- WEIGHT TIE BREAK

            if WeightPreference
                ~= "None"
            then

                local toolDataA =
                    a.Tool:FindFirstChild(
                        "Data"
                    )

                local toolDataB =
                    b.Tool:FindFirstChild(
                        "Data"
                    )

                local weightA =
                    toolDataA
                    and
                    toolDataA:
                        FindFirstChild(
                            "Weight"
                        )

                local weightB =
                    toolDataB
                    and
                    toolDataB:
                        FindFirstChild(
                            "Weight"
                        )

                local valueA =
                    weightA
                    and
                    tonumber(
                        weightA.Value
                    )

                local valueB =
                    weightB
                    and
                    tonumber(
                        weightB.Value
                    )

                if valueA
                    and valueB
                    and valueA
                        ~= valueB
                then

                    if WeightPreference
                        == "Highest Weight"
                    then

                        return
                            valueA
                            > valueB
                    end

                    if WeightPreference
                        == "Lowest Weight"
                    then

                        return
                            valueA
                            < valueB
                    end
                end
            end

            -- FINAL ALPHABETICAL TIE BREAK

            return
                string.lower(
                    a.Tool.Name
                )
                <
                string.lower(
                    b.Tool.Name
                )
        end
    )

    return
        availableEggs[1].Tool
end

-- =====================================
-- EQUIP EGG
-- =====================================

local function EquipEgg(
    egg
)

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

    if egg.Parent
        ~= backpack
    then

        egg =
            backpack:FindFirstChild(
                egg.Name
            )
    end

    if not egg then
        return false
    end

    if not egg:IsA(
        "Tool"
    )
    then

        warn(
            "Auto Place: "
            .. egg.Name
            .. " is not a Tool. ClassName = "
            .. egg.ClassName
        )

        return false
    end

    humanoid:EquipTool(
        egg
    )

    local start =
        os.clock()

    while os.clock()
        - start
        < 2
    do

        if egg.Parent
            == character
        then

            return true
        end

        task.wait(0.1)

        if egg.Parent
            == backpack
        then

            humanoid:EquipTool(
                egg
            )
        end
    end

    return egg.Parent
        == character
end

-- =====================================
-- HATCH PROMPT
-- =====================================

local function GetHatchPrompt()

    local plot =
        GetMyPlot()

    if not plot
        or not VerifyMyPlot(
            plot
        )
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

    return
        egg:FindFirstChildWhichIsA(
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
        or not VerifyMyPlot(
            plot
        )
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

    if not EquipEgg(
        egg
    )
    then

        warn(
            "Auto Place: Could not equip "
            .. egg.Name
        )

        return false
    end

    plot =
        GetMyPlot()

    if not plot
        or not VerifyMyPlot(
            plot
        )
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

    plot =
        GetMyPlot()

    if not plot
        or not VerifyMyPlot(
            plot
        )
    then

        humanoid:UnequipTools()

        return false
    end

    local fired =
        pcall(function()

            EggPlaced:FireServer({
                PlantPosition =
                    position
            })

        end)

    if not fired then

        humanoid:UnequipTools()

        return false
    end

    task.wait(0.8)

    local newEggCount =
        GetEggCount()

    if newEggCount
        > oldEggCount
    then

        if AutoHatchEnabled then
            WaitingForHatch =
                true
        end

        print(
            "Auto Place: Egg placed."
        )

        return true
    end

    task.wait(0.5)

    newEggCount =
        GetEggCount()

    if newEggCount
        > oldEggCount
    then

        if AutoHatchEnabled then
            WaitingForHatch =
                true
        end

        print(
            "Auto Place: Egg placed."
        )

        return true
    end

    humanoid:UnequipTools()

    WaitingForHatch =
        false

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
        and os.clock()
            - start
            < 5
    do

        task.wait(0.1)

        if not GetHatchPrompt() then
            break
        end
    end

    HatchRunning = false

    WaitingForHatch =
        false

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

if #EggOptions
    == 0
then

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

        Name =
            "Stealing Egg",

        Options =
            EggOptions,

        CurrentOption = {

            EggOptions[1]
                or "Cherub Egg"
        },

        MultipleOptions =
            true,

        Flag =
            "StealingEggs",

        Callback =
            function(
                Options
            )

                SelectedStealingEggs =
                    {}

                if type(
                    Options
                )
                == "table"
                then

                    for _, eggName
                        in ipairs(
                            Options
                        )
                    do

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

    Name =
        "Auto Egg",

    CurrentValue =
        false,

    Flag =
        "EggAuto",

    Callback =
        function(
            Value
        )

            StealingEnabled =
                Value

            if not Value then

                StealingRunning =
                    false

                StopMovement()

                return
            end

            task.spawn(
                function()

                    while StealingEnabled do

                        RunStealingEgg()

                        if not StealingEnabled then
                            break
                        end

                        task.wait(0.5)
                    end
                end
            )
        end
})

-- =====================================
-- PLACE EGG DROPDOWN
-- =====================================

local PlaceDropdown =
    Tab:CreateDropdown({

        Name =
            "Egg",

        Options =
            EggOptions,

        CurrentOption = {

            EggOptions[1]
                or "Cherub Egg"
        },

        MultipleOptions =
            true,

        Flag =
            "PlaceEggs",

        Callback =
            function(
                Options
            )

                SelectedPlaceEggs =
                    {}

                if type(
                    Options
                )
                == "table"
                then

                    for _, eggName
                        in ipairs(
                            Options
                        )
                    do

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

task.spawn(
    function()

        for _ = 1, 20 do

            task.wait(0.5)

            local names =
                GetDynamicEggNames()

            if #names > 0 then

                pcall(
                    function()

                        StealingDropdown:
                            Refresh(
                                names
                            )

                        PlaceDropdown:
                            Refresh(
                                names
                            )
                    end
                )

                break
            end
        end
    end
)

-- =====================================
-- WEIGHT PREFERENCE
-- =====================================

Tab:CreateDropdown({

    Name =
        "Weight Preference",

    Options = {

        "None",

        "Lowest Weight",

        "Highest Weight"
    },

    CurrentOption = {

        "None"
    },

    MultipleOptions =
        false,

    Flag =
        "WeightPreference",

    Callback =
        function(
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

    Name =
        "Auto Place Egg",

    CurrentValue =
        false,

    Flag =
        "AutoPlaceEgg",

    Callback =
        function(
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

            task.spawn(
                function()

                    while AutoPlaceEnabled do

                        if not StealingRunning
                            and not WaitingForHatch
                        then

                            pcall(
                                function()
                                    PlaceSelectedEgg()
                                end
                            )
                        end

                        task.wait(0.5)
                    end
                end
            )
        end
})

-- =====================================
-- AUTO HATCH EGG
-- =====================================

Tab:CreateToggle({

    Name =
        "Auto Hatch Egg",

    CurrentValue =
        false,

    Flag =
        "AutoHatchEgg",

    Callback =
        function(
            Value
        )

            AutoHatchEnabled =
                Value

            if not Value then

                WaitingForHatch =
                    false

                return
            end

            task.spawn(
                function()

                    while AutoHatchEnabled do

                        if not StealingRunning
                            and not HatchRunning
                        then

                            local prompt =
                                GetHatchPrompt()

                            if prompt then

                                WaitingForHatch =
                                    true

                                pcall(
                                    function()
                                        HatchEgg()
                                    end
                                )
                            end
                        end

                        task.wait(0.25)
                    end
                end
            )
        end
})

-- =====================================
-- LUCK UPGRADE
-- =====================================

Tab:CreateDropdown({

    Name =
        "Luck Upgrade",

    Options = {

        "One Time",

        "Max"
    },

    CurrentOption = {

        "One Time"
    },

    MultipleOptions =
        false,

    Flag =
        "LuckUpgradeMode",

    Callback =
        function(
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

    Name =
        "Auto Luck Upgrade",

    CurrentValue =
        false,

    Flag =
        "AutoLuckUpgrade",

    Callback =
        function(
            Value
        )

            LuckEnabled =
                Value

            if not Value then
                return
            end

            task.spawn(
                function()

                    while LuckEnabled do

                        pcall(
                            function()

                                if LuckMode
                                    == "Max"
                                then

                                    Upgrades:
                                        FireServer(
                                            "Max"
                                        )

                                else

                                    Upgrades:
                                        FireServer()
                                end
                            end
                        )

                        task.wait(1)
                    end
                end
            )
        end
})
