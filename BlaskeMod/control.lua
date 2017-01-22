require("classes.playerspawn")

constants = {
  spawn_colision_search_radius = 5
}


-- Enable remote access into spawn functionality of the mod
remote.add_interface("blaskemod",
  {
    respawn = function(playerIndex) SendPlayerToSpawn(game.players[playerIndex]) end,
    setspawnpoint = function(playerIndex, spawnX, spawnY) SetPlayerSpawn(game.players[playerIndex], spawnX, spawnY) end,
    setspawntocurrentposition = function(playerIndex) SetPlayerSpawn(game.players[playerIndex], game.players[playerIndex].position.x, game.players[playerIndex].position.y) end
    } )

-- Initalize the mod, this only happens one time per world.
script.on_init( function()
    if global.player_spawns == nil then
      global.player_spawns = { }
    end
    if global.player_inventories == nil then
      global.player_inventories = { }
    end
  end )

-- Register for player respawn
script.on_event(defines.events.on_player_respawned, function(event)
    local player = game.players[event.player_index]
    if event.player_port == nil then
      SendPlayerToSpawn(player)
      RestorePlayerInventories(player)
    else
      player.print(event.player_port)
    end
  end )

-- Register for before player death
script.on_event(defines.events.on_pre_player_died, function(event)
    local player = game.players[event.player_index]
    if player ~= nil then
      BackupPlayerInventory(player)
    end
  end )

-- Register for when a player joins the game
script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.players[event.player_index]
    local spawnPoint = global.player_spawns[player.name]

    player.print( { "message-welcome-running-mod", player.name, #game.connected_players })

    if spawnPoint == nil then
      local forceSpawn = player.force.get_spawn_position(player.surface)
      SetPlayerSpawn(player, forceSpawn.X, forceSpawn.Y)
    end
    UpdateSpawnPointButton(player)
  end )

-- Register for ui button clicks
script.on_event(defines.events.on_gui_click, function(event)

    local element = event.element
    local player = game.players[event.player_index]

    local onClickFunction = _G["OnClick_" .. element.name]
    if type(onClickFunction) == "function" then
      onClickFunction(event, player)
    end

  end )

function BackupInventoryEquipment(inventory, equipment)
  if inventory ~= nil then
    for index = 1, #inventory, 1 do
      local equipment_list = { }
      if inventory[index] ~= nil then
        if inventory[index].valid then
          if inventory[index].valid_for_read then
            local equipment_grid = inventory[index].grid
            if equipment_grid ~= nil then
              for ek, ev in pairs(equipment_grid.equipment) do
                equipment_list[ek] = {
                  name = ev.name,
                  x = ev.position.x,
                  y = ev.position.y,
                }
              end
              if equipment_list ~= nil then
                equipment[inventory[index].name] = equipment_list
              end
            end
          end
        end
      end
    end
  end
end

function BackupPlayerInventory(player)

  local player_armor_inventory = player.get_inventory(defines.inventory.player_armor)
  local player_armor_equipment = { }
  BackupInventoryEquipment(player_armor_inventory, player_armor_equipment)

  local player_main_inventory = player.get_inventory(defines.inventory.player_main)
  local player_main_equipment = { }
  BackupInventoryEquipment(player_main_inventory, player_main_equipment)

  local player_quickbar_inventory = player.get_inventory(defines.inventory.player_quickbar)
  local player_quickbar_equipment = { }
  BackupInventoryEquipment(player_quickbar_inventory, player_quickbar_equipment)

  local player_trash_inventory = player.get_inventory(defines.inventory.player_trash)
  local player_trash_equipment = { }
  BackupInventoryEquipment(player_trash_inventory, player_trash_equipment)

  local playerInventoryBackup = {
    ammo = player.get_inventory(defines.inventory.player_ammo).get_contents(),
    armor = player_armor_inventory.get_contents(),
    armor_equipment = player_armor_equipment,
    guns = player.get_inventory(defines.inventory.player_guns).get_contents(),
    main = player_main_inventory.get_contents(),
    main_equipment = player_main_equipment,
    quickbar = player_quickbar_inventory.get_contents(),
    quickbar_equipment = player_quickbar_equipment,
    tools = player.get_inventory(defines.inventory.player_tools).get_contents(),
    trash = player_trash_inventory.get_contents(),
    trash_equipment = player_trash_equipment
  }
  global.player_inventories[player.name] = playerInventoryBackup

end

function GetSpawnPoint(player)
  local spawnPoint = global.player_spawns[player.name]
  local spawnSurface = game.surfaces[spawnPoint.SurfaceIndex]
  local spawnPosition={ X = spawnPoint.X, Y = spawnPoint.Y }
  if spawnSurface.can_place_entity( { name = player.character.name, position = spawnPosition  }) then
    return spawnPosition
  else
    local newSpawnPosition = spawnSurface.find_non_colliding_position(player.character.name,
      { X = spawnPoint.X, Y = spawnPoint.Y },
      constants.spawn_colision_search_radius,
      spawnPoint.SurfaceIndex)
    if newSpawnPosition ~= nil then
      return newSpawnPosition
    end
  end
  return nil
end

function OnClick_SetSpawnPointButton(event, player)
  SetPlayerSpawn(player, player.position.x, player.position.y)
end

function RestoreInventoryEquipment(inventory, equipment)
  if inventory ~= nil and equipment ~= nil then
    for k, v in pairs(inventory.get_contents()) do
      if equipment[k] ~= nil then
        for ek, ev in pairs(equipment[k]) do
          inventory.find_item_stack(k).grid.put( { name = ev.name, position = { x = ev.x, y = ev.y } })
        end
      end
    end
  end
end

function RestorePlayerInventories(player)
  if global.player_inventories[player.name] ~= nil then

    local playerInventoryBackup = global.player_inventories[player.name]

    -- Repopulate the various inventories of the player
    RestorePlayerInventory(player.get_inventory(defines.inventory.player_ammo), playerInventoryBackup.ammo)
    RestorePlayerInventory(player.get_inventory(defines.inventory.player_armor), playerInventoryBackup.armor)
    RestorePlayerInventory(player.get_inventory(defines.inventory.player_guns), playerInventoryBackup.guns)
    RestorePlayerInventory(player.get_inventory(defines.inventory.player_main), playerInventoryBackup.main)
    RestorePlayerInventory(player.get_inventory(defines.inventory.player_quickbar), playerInventoryBackup.quickbar)
    RestorePlayerInventory(player.get_inventory(defines.inventory.player_tools), playerInventoryBackup.tools)
    RestorePlayerInventory(player.get_inventory(defines.inventory.player_trash), playerInventoryBackup.trash)

    -- Repopulate any items with equipment grids
    RestoreInventoryEquipment(player.get_inventory(defines.inventory.player_armor), playerInventoryBackup.armor_equipment)
    RestoreInventoryEquipment(player.get_inventory(defines.inventory.player_main), playerInventoryBackup.main_equipment)
    RestoreInventoryEquipment(player.get_inventory(defines.inventory.player_quickbar), playerInventoryBackup.quickbar_equipment)
    RestoreInventoryEquipment(player.get_inventory(defines.inventory.player_trash), playerInventoryBackup.trash_equipment)

    global.player_inventories[player.name] = nil
  end
end

function RestorePlayerInventory(inventory, inventoryBackup)
  for k, v in pairs(inventoryBackup) do
    inventory.insert( { name = k, count = v })
  end
end

function SpawnPointUpdateToolTip(player)
  local button = player.gui.top.SetSpawnPointButton
  if button ~= nil then
    local playerSpawn = global.player_spawns[player.name]
    button.tooltip = { "tooltip-current-spawn-point", playerSpawn.X, playerSpawn.Y }
  end
end

function SendPlayerToSpawn(player)
  if player ~= nil then
    local spawnPoint = GetSpawnPoint(player)
    if spawnPoint ~= nil then
      player.teleport(spawnPoint, game.surfaces[1])
    end
  end
end

function SetPlayerSpawn(player, spawnX, spawnY)
  if player ~= nil then
    local newSpawn = PlayerSpawn:new( { X = spawnX, Y = spawnY, SurfaceIndex = 1 })
    global.player_spawns[player.name] = newSpawn
    SpawnPointUpdateToolTip(player)
    player.print("Your spawn has been set to X: " .. newSpawn.X .. ", Y: " .. newSpawn.Y)
  end
end

function UpdateSpawnPointButton(player)
  if player ~= nil and player.valid and player.connected then
    if player.gui.top.SetSpawnPointButton ~= nil then
      player.gui.top.SetSpawnPointButton.destroy()
    end
    player.gui.top.add( { type = "button", name = "SetSpawnPointButton", caption = { "caption-button-set-spawn-point" } })
    SpawnPointUpdateToolTip(player)
  else
    game.print("problem showing spawn point button...")
  end
end