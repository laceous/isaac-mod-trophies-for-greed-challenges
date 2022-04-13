local mod = RegisterMod('Trophies for Greed Challenges', 1)
local game = Game()

mod.exitRoomIndex = 110 -- exit room
mod.spiderWebIndex = 67 -- center of 1x1 room
mod.allowTrophySpawn = false

function mod:onGameExit()
  mod.allowTrophySpawn = false
end

function mod:onNewRoom()
  if mod:isGreedChallenge() then
    mod.allowTrophySpawn = false
    
    local level = game:GetLevel()
    local room = level:GetCurrentRoom()
    
    if level:GetCurrentRoomIndex() == mod.exitRoomIndex then
      local gridEntity = room:GetGridEntity(mod.spiderWebIndex)
      if gridEntity and gridEntity:GetType() == GridEntityType.GRID_SPIDERWEB then -- there will be a spiderweb here instead of a trapdoor
        room:RemoveGridEntity(mod.spiderWebIndex, 0, false)
        
        if room:IsClear() then
          mod:spawnTrophy(room:GetGridPosition(mod.spiderWebIndex))
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
    
    if level:GetCurrentRoomIndex() == mod.exitRoomIndex and mod.allowTrophySpawn and room:IsClear() then
      mod:spawnTrophy(room:GetGridPosition(mod.spiderWebIndex))
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

function mod:spawnTrophy(position)
  if #Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TROPHY, 0, false, false) == 0 then
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TROPHY, 0, position, Vector(0,0), nil)
  end
end

function mod:isGreedChallenge()
  return game:IsGreedMode() and Isaac.GetChallenge() ~= Challenge.CHALLENGE_NULL
end

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.onGameExit)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.onNewRoom)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.onUpdate)
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.onPickupInit, PickupVariant.PICKUP_BIGCHEST)