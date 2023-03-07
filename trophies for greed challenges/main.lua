local mod = RegisterMod('Trophies for Greed Challenges', 1)
local game = Game()

mod.exitRoomIndex = 110
mod.trapdoorIndex = nil
mod.trapdoorIndexes = {}

function mod:onGameExit()
  mod.trapdoorIndex = nil
  mod:clearTrapdoorIndexes()
end

function mod:onPreNewRoom(entityType, variant, subType, gridIdx, seed)
  if mod:isGreedChallenge() then
    local trapdoor = 9000
    
    local level = game:GetLevel()
    local room = level:GetCurrentRoom()
    local roomDesc = level:GetCurrentRoomDesc()
    
    if roomDesc.GridIndex == mod.exitRoomIndex and room:GetType() == RoomType.ROOM_GREED_EXIT then
      if entityType == trapdoor then
        table.insert(mod.trapdoorIndexes, gridIdx)
      end
    end
  end
end

function mod:onNewRoom()
  if mod:isGreedChallenge() then
    mod.trapdoorIndex = nil
    
    local level = game:GetLevel()
    local room = level:GetCurrentRoom()
    local roomDesc = level:GetCurrentRoomDesc()
    
    if roomDesc.GridIndex == mod.exitRoomIndex and room:GetType() == RoomType.ROOM_GREED_EXIT then
      for i = #mod.trapdoorIndexes, 1, -1 do -- backwards loop for better removal logic
        local gridEntity = room:GetGridEntity(mod.trapdoorIndexes[i])
        if not (gridEntity and gridEntity:GetType() == GridEntityType.GRID_SPIDERWEB) then -- the game replaces trapdoors with spiderwebs in this case
          table.remove(mod.trapdoorIndexes, i)
        end
      end
      
      if #mod.trapdoorIndexes > 0 then
        if room:IsClear() then
          mod:spawnTrophy(mod.trapdoorIndexes[1])
        else
          mod.trapdoorIndex = mod.trapdoorIndexes[1]
        end
        
        mod:clearTrapdoorIndexes()
      end
    end
  end
end

function mod:onUpdate()
  if mod:isGreedChallenge() then
    local level = game:GetLevel()
    local room = level:GetCurrentRoom()
    local roomDesc = level:GetCurrentRoomDesc()
    
    if mod.trapdoorIndex and roomDesc.GridIndex == mod.exitRoomIndex and room:GetType() == RoomType.ROOM_GREED_EXIT and room:IsClear() then
      mod:spawnTrophy(mod.trapdoorIndex)
      mod.trapdoorIndex = nil
    end
  end
end

-- filtered to PICKUP_BIGCHEST
function mod:onPickupInit(pickup)
  if mod:isGreedChallenge() then
    pickup:Remove()
    mod:spawnTrophy(pickup.Position)
  end
end

function mod:spawnTrophy(idxOrPos)
  local room = game:GetRoom()
  local idx = nil
  local pos = nil
  
  if math.type(idxOrPos) == 'integer' then
    idx = idxOrPos
    pos = room:GetGridPosition(idxOrPos)
  else -- userdata / vector
    pos = idxOrPos
  end
  
  if idx then
    local gridEntity = room:GetGridEntity(idx)
    if gridEntity and gridEntity:GetType() == GridEntityType.GRID_SPIDERWEB then
      room:RemoveGridEntity(idx, 0, false)
    end
  end
  
  if #Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TROPHY, 0, false, false) == 0 then
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TROPHY, 0, pos, Vector.Zero, nil)
  end
end

function mod:clearTrapdoorIndexes()
  for i, _ in ipairs(mod.trapdoorIndexes) do
    mod.trapdoorIndexes[i] = nil
  end
end

function mod:isGreedChallenge()
  return game:IsGreedMode() and Isaac.GetChallenge() ~= Challenge.CHALLENGE_NULL
end

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.onGameExit)
mod:AddCallback(ModCallbacks.MC_PRE_ROOM_ENTITY_SPAWN, mod.onPreNewRoom)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.onNewRoom)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.onUpdate)
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.onPickupInit, PickupVariant.PICKUP_BIGCHEST)