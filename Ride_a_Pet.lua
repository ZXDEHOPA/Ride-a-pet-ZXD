local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Ride a Pet",
    LoadingTitle = "Ride a Pet",
    LoadingSubtitle = "By ZXD",
    ConfigurationSaving = {
        Enabled = false
    }
})

local Tab = Window:CreateTab("Egg Selection")

local Enabled = false

local SelectedEggs = {
    ["Cherub Egg"] = true
}

local Eggs = {
    "Cherub Egg",
    "Solaris Egg",
    "Blackhole Egg"
}

-- =====================================
-- FIXED SETTINGS
-- =====================================

local LOAD_WAIT = 1.5
local AFTER_EGG_WAIT = 0.5

local WAYPOINT_WAIT = 0.75
local NEAR_FENCE_WAIT = 10

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
-- EGG FUNCTIONS
-- =====================================

local function GetEgg(name)

    local egg =
        workspace:FindFirstChild(
            name,
            true
        )

    if egg and egg:IsA("Model") then
        return egg
    end

    return nil
end


local function GetSelectedEgg()

    for _, eggName in ipairs(Eggs) do

        if SelectedEggs[eggName] then

            local egg =
                GetEgg(eggName)

            if egg then
                return egg
            end
        end
    end

    return nil
end


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
-- FENCE FUNCTIONS
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
-- WAIT
-- =====================================

local function WaitWithCheck(
    duration
)

    local start =
        os.clock()

    while Enabled
        and os.clock() - start < duration
    do
        task.wait(0.05)
    end

    return Enabled
end


-- =====================================
-- MAIN EGG RUN
-- =====================================

local function RunEgg()

    -- =================================
    -- FIND SELECTED EGG
    -- =================================

    local egg =
        GetSelectedEgg()

    if not egg then

        task.wait(0.25)

        return
    end

    local root =
        GetRoot()

    if not root then
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

    print("TP #1")


    if not WaitWithCheck(
        LOAD_WAIT
    ) then
        return
    end


    -- =================================
    -- TP #2
    -- =================================

    root =
        GetRoot()

    egg =
        GetSelectedEgg()

    if not root or not egg then
        return
    end

    root.CFrame =
        CFrame.new(
            GetModelPosition(egg)
            + Vector3.new(0, 3, 0)
        )

    print("TP #2")


    if not WaitWithCheck(
        LOAD_WAIT
    ) then
        return
    end


    -- =================================
    -- FIRE EGG
    -- =================================

    egg =
        GetSelectedEgg()

    if not egg then

        warn(
            "Selected egg disappeared"
        )

        return
    end

    local prompt =
        GetEggPrompt(egg)

    if not prompt then

        warn(
            "Egg ProximityPrompt not found"
        )

        return
    end

    fireproximityprompt(
        prompt
    )

    print("Egg fired")


    if not WaitWithCheck(
        AFTER_EGG_WAIT
    ) then
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

        return
    end

    root =
        GetRoot()

    if not root then
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

    if not root or not Enabled then
        return
    end

    root.CFrame =
        CFrame.new(
            waypoint1
        )

    print("Waypoint 1")

    if not WaitWithCheck(
        WAYPOINT_WAIT
    ) then
        return
    end


    -- =================================
    -- WAYPOINT 2
    -- =================================

    root =
        GetRoot()

    if not root or not Enabled then
        return
    end

    root.CFrame =
        CFrame.new(
            waypoint2
        )

    print("Waypoint 2")

    if not WaitWithCheck(
        WAYPOINT_WAIT
    ) then
        return
    end


    -- =================================
    -- WAYPOINT 3
    -- =================================

    root =
        GetRoot()

    if not root or not Enabled then
        return
    end

    root.CFrame =
        CFrame.new(
            waypoint3
        )

    print("Waypoint 3")

    if not WaitWithCheck(
        WAYPOINT_WAIT
    ) then
        return
    end


    -- =================================
    -- WAYPOINT 4
    -- =================================

    root =
        GetRoot()

    if not root or not Enabled then
        return
    end

    root.CFrame =
        CFrame.new(
            waypoint4
        )

    print("Waypoint 4")

    if not WaitWithCheck(
        WAYPOINT_WAIT
    ) then
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
        "Teleported near Full Fence"
    )


    -- =================================
    -- WAIT 10 SECONDS
    -- =================================

    print(
        "Waiting 10 seconds near fence..."
    )

    if not WaitWithCheck(
        NEAR_FENCE_WAIT
    ) then
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
        "Teleported to Full Fence center"
    )
end


-- =====================================
-- MULTI-SELECT EGG DROPDOWN
-- =====================================

Tab:CreateDropdown({

    Name = "Egg",

    Options = Eggs,

    CurrentOption = {
        "Cherub Egg"
    },

    MultipleOptions = true,

    Flag = "SelectedEggs",

    Callback = function(Options)

        SelectedEggs = {}

        if type(Options) == "table" then

            for _, eggName in ipairs(Options) do
                SelectedEggs[eggName] = true
            end

        else

            SelectedEggs[Options] = true

        end

    end
})


-- =====================================
-- EGG AUTO
-- =====================================

Tab:CreateToggle({

    Name = "Auto Egg",

    CurrentValue = false,

    Flag = "EggAuto",

    Callback = function(Value)

        Enabled = Value

        if not Value then

            StopMovement()

            return
        end

        task.spawn(function()

            while Enabled do

                RunEgg()

                if not Enabled then
                    break
                end

                task.wait(0.5)

            end

        end)

    end
})