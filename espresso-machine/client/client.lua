local QBCore = exports['qb-core']:GetCoreObject()

--- ============================
---          Constants
--- ============================

--- @class Espresso
local EspressoMachine = {
    id = nil,            -- The id of the espresso machine
    lattesAvailable = 0, -- The number of lattes available
    lattesId = {},       -- The ids of the latte objects placed on the espresso machine
    lattesOffsets =      -- The vector3 offset values of the latte objects placed on the espresso machine
    {
        { x = 0.24,  y = 0.20,  z = 0.18 },
        { x = 0.24,  y = 0.08,  z = 0.18 },
        { x = 0.24,  y = -0.04, z = 0.18 },
        { x = 0.12,  y = 0.20,  z = 0.18 },
        { x = 0.12,  y = 0.08,  z = 0.18 },
        { x = 0.12,  y = -0.04, z = 0.18 },
        { x = 0.00,  y = -0.04, z = 0.18 },
        { x = -0.12, y = -0.04, z = 0.18 },
        { x = -0.24, y = -0.04, z = 0.18 },
    },
    location = nil, -- The location of the espresso machine
    inUse = false,  -- Determines whether the machine is currently being used or not
}

local EspressoMachineModel = 'prop_coffee_mac_01' -- The espresso machine model
local LatteCupModel = 'p_amb_coffeecup_01'        -- The latte cup prop model
-- local LatteCupModel = 'v_res_mcofcup'             -- The latte cup prop model

local RightHandBone = 28422

local SmokeParticle = { asset = 'scr_mp_cig', name = 'ent_anim_cig_smoke' }

--- ============================
---           Animator
--- ============================

--- Espresso animations
local Animations = {
    espresso =
    {
        buttonPress = { name = 'button_press', dictionary = 'anim@mp_radio@garage@medium', flag = 0, },
    },
}

--- Load the animation then play
--- @param entity number
--- @param animation table
--- @return number animDuration
function executeAnimation(entity, animation)
    RequestAnimDict(animation.dictionary)
    repeat
        Wait(1)
    until HasAnimDictLoaded(animation.dictionary)

    TaskPlayAnim(entity, animation.dictionary, animation.name,
        8.0, 8.0, -1, animation.flag,
        0.0, false, false, false)

    RemoveAnimDict(animation.dictionary)

    return GetAnimDuration(animation.dictionary, animation.name)
end

--- ============================
---           Helpers
--- ============================

--- Load model and wait until finished
--- @param modelHash number
function loadModel(modelHash)
    -- Request the model and wait for it to load
    RequestModel(modelHash)
    repeat
        Wait(1)
    until HasModelLoaded(modelHash)
end

--- Load ped model, create the ped, then release the model
--- @param model string
--- @param coords vector3
--- @param heading number
--- @param isNetwork boolean
--- @return number obj
function createEntity(model, coords, heading, isNetwork)
    coords = coords or vec3(0, 0, 0)
    heading = heading or 0.0
    isNetwork = isNetwork or true

    -- Get the model hash
    local modelHash = GetHashKey(model)

    -- Load the model
    loadModel(modelHash)

    -- Create the entity
    local entity = CreateObject(modelHash, coords.x, coords.y, coords.z,
        isNetwork, false, false)

    -- Release the model
    SetModelAsNoLongerNeeded(modelHash)

    return entity
end

--- Triggers the event to delete the entity on the server-side
--- @param entity number
function deleteEntity(entity)
    TriggerServerEvent('espresso:server:deleteEntity', NetworkGetNetworkIdFromEntity(entity))
end

--- The target options for the espresso machine
--- @return table
function espressoTargetOptions()
    return
    {
        options = {
            {
                icon = 'fas fa-coffee',
                label = "Make a latte",
                num = 1,
                canInteract = function()
                    return not EspressoMachine.inUse
                end,
                action = function()
                    -- Create latte item
                    EspressoMachine:createLatte()
                end
            },
            {
                icon = 'fas fa-coffee',
                label = "Grab a latte",
                num = 2,
                canInteract = function()
                    return EspressoMachine.lattesAvailable > 0
                end,
                action = function()
                    -- Add a latte to player's inventory
                    EspressoMachine:grabLatte()
                end
            },
        },
        distance = 1.5,
    }
end

--- Create the espresso machine object
function initializeEspressoMachine()
    local playerPed = PlayerPedId()
    local forwardCoords = GetEntityCoords(playerPed) + GetEntityForwardVector(playerPed) * 0.75

    -- Create the espresso machine prop
    EspressoMachine.id = createEntity(EspressoMachineModel, forwardCoords, 0, true)
    SetEntityHeading(EspressoMachine.id, GetEntityHeading(playerPed))
    PlaceObjectOnGroundProperly(EspressoMachine.id)

    -- Set the location property
    EspressoMachine.location = GetEntityCoords(EspressoMachine.id)

    -- Add the target options to the espresso machine
    exports['qb-target']:AddTargetEntity(EspressoMachine.id, espressoTargetOptions())
end

--- ============================
---       Espresso Class
--- ============================

--- Create the espresso machine and add the target options
function EspressoMachine:start()
    -- Remove espresso machine if already exists
    if EspressoMachine.id then
        deleteEntity(EspressoMachine.id)

        for index = 1, #EspressoMachine.lattesId do
            deleteEntity(EspressoMachine.lattesId[index])
        end
    end

    -- Create a new espresso machine
    initializeEspressoMachine()
end

--- Create particle to turn on the espresso machine lights
--- @return number particleHandle
function EspressoMachine:turnOn()
    -- Load the asset
    RequestNamedPtfxAsset(SmokeParticle.asset)
    repeat
        Wait(0)
    until HasNamedPtfxAssetLoaded(SmokeParticle.asset)

    -- Specify the asset before starting the particle
    UseParticleFxAsset(SmokeParticle.asset)

    -- Start the particle looped animation on the cigarette
    return StartNetworkedParticleFxLoopedOnEntity(SmokeParticle.name, EspressoMachine.id,
        -0.118, -0.1725, 0.117, 0.0, 0.0, 0.0, 3.0,
        true, true, true)
end

--- Start the process to make a latte
function EspressoMachine:createLatte()
    -- Do the press button animation
    Wait(executeAnimation(PlayerPedId(), Animations.espresso.buttonPress) * 1000)

    -- Set the in use property to true preventing others to use the machine
    EspressoMachine.inUse = true

    -- Turn on the machine
    local particleHandle = EspressoMachine:turnOn()

    -- Progress bar to track the latte being made
    QBCore.Functions.Progressbar('makeLatte', 'Making a latte', 15000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = false,
    }, {}, {}, {}, function()
        -- Stop the particle animation
        StopParticleFxLooped(particleHandle, false)

        -- Notify player the latte is done
        TriggerEvent('QBCore:Notify', 'Latte is done', 'success', 5000)

        -- Increase the count of the lattes available
        EspressoMachine.lattesAvailable = EspressoMachine.lattesAvailable + 1

        -- Add a latte cup on top of the espresso machine
        if EspressoMachine.lattesAvailable <= #EspressoMachine.lattesOffsets then
            table.insert(EspressoMachine.lattesId, createEntity(LatteCupModel,
                GetOffsetFromEntityInWorldCoords(EspressoMachine.id,
                    EspressoMachine.lattesOffsets[EspressoMachine.lattesAvailable].x,
                    EspressoMachine.lattesOffsets[EspressoMachine.lattesAvailable].y,
                    EspressoMachine.lattesOffsets[EspressoMachine.lattesAvailable].z),
                0, true))
        end

        -- Set the in use property to false again
        EspressoMachine.inUse = false
    end)
end

--- Take a latte from the machine
function EspressoMachine:grabLatte()
    -- Remove a latte cup from the espresso machine
    if EspressoMachine.lattesAvailable <= #EspressoMachine.lattesOffsets then
        deleteEntity(EspressoMachine.lattesId[EspressoMachine.lattesAvailable])
        table.remove(EspressoMachine.lattesId, EspressoMachine.lattesAvailable)
    end

    -- Progress bar to grab an available latte
    QBCore.Functions.Progressbar('grabLatte', 'Grabbing latte', 1000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'amb@world_human_drinking@coffee@male@enter',
        anim = 'enter',
        flags = 49
    }, {
        model = LatteCupModel,
        bone = RightHandBone,
        coords = vec3(0.0, 0.0, 0.02),
        rotation = vec3(0.0, 0.0, 0.0),
    }, {}, function()
        -- Item notification that a latte has been addeed
        TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items['latte'], 'add')

        -- Add a latte to the player's inventory
        TriggerServerEvent('espresso:server:createLatte')

        -- Decrement the available latte count
        EspressoMachine.lattesAvailable = EspressoMachine.lattesAvailable - 1
    end)
end

--- Drink a latte
function EspressoMachine:drinkLatte()
    -- Progress bar to drink a latte
    QBCore.Functions.Progressbar('drinkLatte', 'Drinking latte', 10000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'amb@world_human_drinking@coffee@male@idle_a',
        anim = 'idle_a',
        flags = 49
    }, {
        model = LatteCupModel,
        bone = RightHandBone,
        coords = vec3(0.0, 0.0, 0.02),
        rotation = vec3(0.0, 0.0, 0.0),
    }, {}, function()
        -- Item notification that a latte has been removed
        TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items['latte'], 'remove')

        -- Increase the thirst for the player
        TriggerServerEvent('consumables:server:addThirst',
            QBCore.Functions.GetPlayerData().metadata.thirst + math.random(40, 50))

        -- Relieve stress for the player
        TriggerServerEvent('hud:server:RelieveStress', math.random(12, 24))
    end)
end

--- ============================
---          NetEvents
--- ============================

--- Create the espresso machine
RegisterNetEvent('espresso:client:start', function()
    EspressoMachine:start()
end)

--- Remove the closest espresso machine
RegisterNetEvent('espresso:client:removeespresso', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    -- Get the closest espresso object
    local espressoObj = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z,
        3.0, GetHashKey(EspressoMachineModel), false, false, false)

    deleteEntity(espressoObj)

    for index = 1, #EspressoMachine.lattesId do
        deleteEntity(EspressoMachine.lattesId[index])
    end
end)

--- Drink a latte
RegisterNetEvent('espresso:client:drinkLatte', function()
    EspressoMachine:drinkLatte()
end)

--- ============================
---          Commands
--- ============================

RegisterCommand('drinkCoffee', function()
    local playerPed = PlayerPedId()
    local coffeeScenario = 'WORLD_HUMAN_AA_COFFEE'

    if IsPedUsingScenario(playerPed, coffeeScenario) then
        ClearPedTasks(playerPed)
        return
    end

    TaskStartScenarioInPlace(playerPed, coffeeScenario, 0, true)
end, false)
