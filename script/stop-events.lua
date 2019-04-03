--[[ Copyright (c) 2017 Optera
 * Part of Logistics Train Network
 *
 * See LICENSE.md in the project directory for license information.
--]]

--create stop
function CreateStop(entity, station)
  if global.LogisticTrainStops[entity.unit_number] then
    if message_level >= 1 then printmsg({"ltn-message.error-duplicated-unit_number", entity.unit_number}, entity.force) end
    if debug_log then log("(CreateStop) duplicate stop unit number "..entity.unit_number) end
    return
  end
  local stop_offset = ltn_stop_entity_names[entity.name]
  local posIn, posOut, rotOut, search_area
  --log("Stop created at "..entity.position.x.."/"..entity.position.y..", orientation "..entity.direction)
  if entity.direction == 0 then --SN
    posIn = {entity.position.x + stop_offset, entity.position.y - 1}
    posOut = {entity.position.x - 1 + stop_offset, entity.position.y - 1}
    rotOut = 0
    search_area = {{entity.position.x - 1 + stop_offset, entity.position.y - 1}, {entity.position.x + 1 + stop_offset, entity.position.y}}
  elseif entity.direction == 2 then --WE
    posIn = {entity.position.x, entity.position.y + stop_offset}
    posOut = {entity.position.x, entity.position.y - 1 + stop_offset}
    rotOut = 2
    search_area = {{entity.position.x, entity.position.y - 1 + stop_offset}, {entity.position.x + 1, entity.position.y + 1 + stop_offset}}
  elseif entity.direction == 4 then --NS
    posIn = {entity.position.x - 1 - stop_offset, entity.position.y}
    posOut = {entity.position.x - stop_offset, entity.position.y}
    rotOut = 4
    search_area = {{entity.position.x - 1 - stop_offset, entity.position.y}, {entity.position.x + 1 - stop_offset, entity.position.y + 1}}
  elseif entity.direction == 6 then --EW
    posIn = {entity.position.x - 1, entity.position.y - 1 - stop_offset}
    posOut = {entity.position.x - 1, entity.position.y - stop_offset}
    rotOut = 6
   search_area = {{entity.position.x - 1, entity.position.y - 1 - stop_offset}, {entity.position.x, entity.position.y + 1 - stop_offset}}
  else --invalid orientation
    if message_level >= 1 then printmsg({"ltn-message.error-stop-orientation", tostring(entity.direction)}, entity.force) end
    if debug_log then log("(CreateStop) invalid train stop orientation "..tostring(entity.direction) ) end
    entity.destroy()
    return
  end

  local input, output, lampctrl
  -- handle blueprint ghosts and existing IO entities preserving circuit connections
  local ghosts = entity.surface.find_entities(search_area)
  for _,ghost in pairs (ghosts) do
    if ghost.valid then
      if ghost.name == "entity-ghost" then
        if ghost.ghost_name == ltn_stop_input then
          -- printmsg("reviving ghost input at "..ghost.position.x..", "..ghost.position.y)
          _, input = ghost.revive()
        elseif ghost.ghost_name == ltn_stop_output then
          -- printmsg("reviving ghost output at "..ghost.position.x..", "..ghost.position.y)
          _, output = ghost.revive()
        elseif ghost.ghost_name == ltn_stop_output_controller then
          -- printmsg("reviving ghost lamp-control at "..ghost.position.x..", "..ghost.position.y)
          _, lampctrl = ghost.revive()
        end
      -- something has built I/O already (e.g.) Creative Mode Instant Blueprint
      elseif ghost.name == ltn_stop_input then
        input = ghost
        --printmsg("Found existing input at "..ghost.position.x..", "..ghost.position.y)
      elseif ghost.name == ltn_stop_output then
        output = ghost
        --printmsg("Found existing output at "..ghost.position.x..", "..ghost.position.y)
      elseif ghost.name == ltn_stop_output_controller then
        lampctrl = ghost
        --printmsg("Found existing lamp-control at "..ghost.position.x..", "..ghost.position.y)
      end
    end
  end

  if input == nil then -- create new
    input = entity.surface.create_entity
    {
      name = ltn_stop_input,

      position = posIn,
      force = entity.force
    }
  end
  input.operable = false -- disable gui
  input.minable = false
  input.destructible = false -- don't bother checking if alive

  if lampctrl == nil then
    lampctrl = entity.surface.create_entity
    {
      name = ltn_stop_output_controller,
      position = input.position, -- use the rounded values of actual input position
      force = entity.force
    }
  end
  lampctrl.operable = false -- disable gui
  lampctrl.minable = false
  lampctrl.destructible = false -- don't bother checking if alive

  -- connect lamp and control
  lampctrl.get_control_behavior().parameters = {parameters={{index = 1, signal = {type="virtual",name="signal-white"}, count = 1 }}}
  input.connect_neighbour({target_entity=lampctrl, wire=defines.wire_type.green})
  input.connect_neighbour({target_entity=lampctrl, wire=defines.wire_type.red})
  input.get_or_create_control_behavior().use_colors = true
  input.get_or_create_control_behavior().circuit_condition = {condition = {comparator=">",first_signal={type="virtual",name="signal-anything"}}}

  if output == nil then -- create new
    output = entity.surface.create_entity
    {
      name = ltn_stop_output,
      position = posOut,
      direction = rotOut,
      force = entity.force
    }
  end
  output.operable = false -- disable gui
  output.minable = false
  output.destructible = false -- don't bother checking if alive

  -- enable reading contents and sending signals to trains
  entity.get_or_create_control_behavior().send_to_train = true
  entity.get_or_create_control_behavior().read_from_train = true

  local stop = {
    entity = entity,
    input = input,
    output = output,
    lampControl = lampctrl,
    parkedTrain = nil,
    parkedTrainID = nil,
    station = station,
    errorCode = -1,
    isDepot = false,
    network_id = -1,
    minTraincars = 0,
    maxTraincars = 0,
    trainLimit = 0,
    requestThreshold = min_requested,
    requestStackThreshold = 0,
    requestPriority = 0,
    noWarnings = false,
    provideThreshold = min_provided,
    provideStackThreshold = 0,
    providePriority = 0,
    lockedSlots = 0,
    }
  global.LogisticTrainStops[entity.unit_number] = stop
  StopIDList[#StopIDList+1] = entity.unit_number
  UpdateStopOutput(stop)

  ResetUpdateInterval()
end

function OnEntityCreated(event)
  local entity = event.created_entity
  if entity.type == "train-stop" then
    local station = Station_addStopEntity(entity) -- all stop names are monitored
    if ltn_stop_entity_names[entity.name] then
      CreateStop(entity, station)
      if #StopIDList == 1 then
        --initialize OnTick indexes
        -- stopsPerTick = 1
        global.stopIdStartIndex = 1
        -- register events
        script.on_event(defines.events.on_tick, OnTick)
        script.on_event(defines.events.on_train_changed_state, OnTrainStateChanged)
        script.on_event(defines.events.on_train_created, OnTrainCreated)
        if debug_log then log("(OnEntityCreated) First LTN Stop built: OnTick, OnTrainStateChanged, OnTrainCreated registered") end
      end
    end
  end
end


-- stop removed
function RemoveStop(stopID)
  -- local stopID = entity.unit_number
  local stop = global.LogisticTrainStops[stopID]

  -- clean lookup tables
  for i=#StopIDList, 1, -1 do
    if StopIDList[i] == stopID then
      table.remove(StopIDList, i)
    end
  end
  for k,v in pairs(global.StopDistances) do
    if k:find(stopID) then
      global.StopDistances[k] = nil
    end
  end

  -- remove available train
  if stop and stop.isDepot and stop.parkedTrainID and global.Dispatcher.availableTrains[stop.parkedTrainID] then
    global.Dispatcher.availableTrains_total_capacity = global.Dispatcher.availableTrains_total_capacity - global.Dispatcher.availableTrains[stop.parkedTrainID].capacity
    global.Dispatcher.availableTrains_total_fluid_capacity = global.Dispatcher.availableTrains_total_fluid_capacity - global.Dispatcher.availableTrains[stop.parkedTrainID].fluid_capacity
    global.Dispatcher.availableTrains[stop.parkedTrainID] = nil
  end

  -- destroy IO entities, broken IO entities should be sufficiently handled in initializeTrainStops()
  if stop then
    if stop.input and stop.input.valid then stop.input.destroy() end
    if stop.output and stop.output.valid then stop.output.destroy() end
    if stop.lampControl and stop.lampControl.valid then stop.lampControl.destroy() end
  end

  global.LogisticTrainStops[stopID] = nil

  ResetUpdateInterval()
end

function OnEntityRemoved(event)
-- script.on_event({defines.events.on_pre_player_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, function(event)
  local entity = event.entity
  if entity.train then
    local trainID = entity.train.id
    -- remove from stop if parked
    if global.StoppedTrains[trainID] then
      TrainLeaves(trainID)
    end
    -- removing any carriage fails a delivery
    -- otherwise I'd have to handle splitting and merging a delivery across train parts
    local delivery = global.Dispatcher.Deliveries[trainID]
    if delivery then
      script.raise_event(on_delivery_failed_event, {delivery = delivery, trainID = trainID})
      RemoveDelivery(trainID)
    end

  elseif entity.type == "train-stop" then
    Station_removeStopEntity(entity)
    if ltn_stop_entity_names[entity.name] then
      RemoveStop(entity.unit_number)
      if StopIDList == nil or #StopIDList == 0 then
        -- unregister events
        script.on_event(defines.events.on_tick, nil)
        script.on_event(defines.events.on_train_changed_state, nil)
        script.on_event(defines.events.on_train_created, nil)
        if debug_log then log("(OnEntityRemoved) Removed last LTN Stop: OnTick, OnTrainStateChanged, OnTrainCreated unregistered") end
      end
    end
  end
end


-- remove stop references when deleting surfaces
function OnSurfaceRemoved(event)
  local surfaceID = event.surface_index or "nauvis"
  log("removing LTN stops on surface "..tostring(surfaceID) )
  local surface = game.surfaces[surfaceID]
  if surface then
    local train_stops = surface.find_entities_filtered{type = "train-stop"}
    for _, entity in pairs(train_stops) do
      Station_removeStopEntity(entity)
      if ltn_stop_entity_names[entity.name] then
        RemoveStop(entity.unit_number)
      end
    end
  end
end


script.on_event(defines.events.on_entity_renamed, function(event)
  local uid = event.entity.unit_number
  local oldName = event.old_name
  local newName = event.entity.backer_name

  if event.entity.type == "train-stop" then
    local oldStation = Station_removeStop(oldName, uid)
    local newStation = Station_addStop(newName, uid)
    local stop = global.LogisticTrainStops[uid]
    if stop then
      stop.station = newStation
    end
    if (Station_numStops(oldStation) == 0) then
      -- last station of that name, rename all deliveries
      if debug_log then log("(OnEntityRenamed) last LTN stop "..oldName.." renamed, updating deliveries to "..newName..".") end
      for trainID, delivery in pairs(global.Dispatcher.Deliveries) do
        if delivery.to == oldName then
          delivery.to = newName
        end
        if delivery.from == oldName then
          delivery.from = newName
        end
      end
      Station_mergeStation(new_station, old_station)
    end
  end
end)

