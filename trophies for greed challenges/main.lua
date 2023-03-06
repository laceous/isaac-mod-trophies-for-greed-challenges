local mod = RegisterMod('Trophies for Greed Challenges', 1)
local game = Game()

mod.exitRoomIndex = 110 -- exit room
mod.allowTrophySpawn = false

function mod:onGameExit()
  mod.allowTrophySpawn = false
end

function mod:onNewRoom()
  if mod:isGreedChallenge() then
    mod.allowTrophySpawn = false
    
    local level = game:GetLevel()
    local room = level:GetCurrentRoom()
    local roomDesc = level:GetCurrentRoomDesc()
    
    if roomDesc.GridIndex == mod.exitRoomIndex and room:GetType() == RoomType.ROOM_GREED_EXIT then
      if not mod:hasTrapdoor() then
        if room:IsClear() then
          mod:spawnTrophy(Isaac.GetFreeNearPosition(room:GetCenterPos(), 3))
        else
          mod.allowTrophySpawn = true
        end
      end
    end
  end
end

function mod:onUpdate()
  if mod:isGreedChallenge() then
    local level = game:GetLevel()
    local room = level:GetCurrentRoom()
    local roomDesc = level:GetCurrentRoomDesc()
    
    if mod.allowTrophySpawn and roomDesc.GridIndex == mod.exitRoomIndex and room:GetType() == RoomType.ROOM_GREED_EXIT and room:IsClear() then
      mod:spawnTrophy(Isaac.GetFreeNearPosition(room:GetCenterPos(), 3))
      mod.allowTrophySpawn = false
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

function mod:hasTrapdoor()
  local room = game:GetRoom()
  
  for _, v in ipairs({ 16, 31, 46, 61, 76, 91, 106 }) do -- 1x1 exit room
    for i = v, v + 12 do
      local gridEntity = room:GetGridEntity(i)
      if gridEntity and gridEntity:GetType() == GridEntityType.GRID_TRAPDOOR then -- variants: 0 = normal, 1 = void portal (not used in greed mode)
        return true
      end
    end
  end
  
  return false
end

function mod:spawnTrophy(position)
  if #Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TROPHY, 0, false, false) == 0 then
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TROPHY, 0, position, Vector.Zero, nil)
  end
end

function mod:isGreedChallenge()
  return game:IsGreedMode() and Isaac.GetChallenge() ~= Challenge.CHALLENGE_NULL
end

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.onGameExit)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.onNewRoom)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.onUpdate)
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.onPickupInit, PickupVariant.PICKUP_BIGCHEST)