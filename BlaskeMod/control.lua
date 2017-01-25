require("classes.playerspawn")

constants = {
  spawn_colision_search_radius = 5
}


-- Enable remote access into spawn functionality of the mod
remote.add_interface("blaskemod",
  {
    respawn = function(playerIndex) SendPlayerToSpawn(game.players[playerIndex]) end,
    setspawnpoint = function(playerIndex, spawnX, spawnY) SetPlayerSpawn(game.players[playerIndex], spawnX, spawnY) end,
    setspawntocurrentposition = function(playerIndex) SetPlayerSpawn(game.players[playerIndex], game.players[playerIndex].position.x, game.players[playerIndex].position.y) end,
    nuke = function(playerIndex, radius) NukePosition(game.players[playerIndex], radius) end
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

-- Register for player mining
script.on_event(defines.events.on_preplayer_mined_item, function(event)

    local player = game.players[event.player_index]
    local miningTool = player.get_inventory(defines.inventory.player_tools)[1]
    if miningTool.name == "steel-shovel" then
      event.entity.destroy()
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

function BackupInventoryBlueprints(inventory, blueprints, books)
  if inventory ~= nil then
    local blueprintCount = 1
    local bookCount= 1
    for index = 1, #inventory, 1 do
      local item = inventory[index]
      if item ~= nil and item.valid and item.valid_for_read then
        if item.name == "blueprint" then
          local blueprintEntities = DeepCopy(item.get_blueprint_entities())
          blueprints[blueprintCount] = blueprintEntities
          blueprintCount = blueprintCount + 1
        elseif item.name=="blueprint-book" then
          local bookInventory = {main={},active={}}
          local bookPrints = {main={},active={}}
          BackupInventoryBlueprints(item.get_inventory(1),bookPrints.main,nil)
          bookInventory.main = item.get_inventory(1).get_contents()
          BackupInventoryBlueprints(item.get_inventory(2),bookPrints.active,nil)
          bookInventory.active = item.get_inventory(2).get_contents()
          books[bookCount] = {inventory = bookInventory, prints = bookPrints}
          bookCount=bookCount + 1
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
  local player_main_blueprints = { }
  local player_main_blueprint_books = { }
  BackupInventoryEquipment(player_main_inventory, player_main_equipment)
  BackupInventoryBlueprints(player_main_inventory, player_main_blueprints, player_main_blueprint_books)

  local player_quickbar_inventory = player.get_inventory(defines.inventory.player_quickbar)
  local player_quickbar_equipment = { }
  local player_quickbar_blueprints = { }
  local player_quickbar_blueprint_books = { }
  BackupInventoryEquipment(player_quickbar_inventory, player_quickbar_equipment)
  BackupInventoryBlueprints(player_quickbar_inventory, player_quickbar_blueprints, player_quickbar_blueprint_books)

  local player_trash_inventory = player.get_inventory(defines.inventory.player_trash)
  local player_trash_equipment = { }
  local player_trash_blueprints = { }
  local player_trash_blueprint_books = { }
  BackupInventoryEquipment(player_trash_inventory, player_trash_equipment)
  BackupInventoryBlueprints(player_trash_inventory, player_trash_blueprints, player_trash_blueprint_books)

  local playerInventoryBackup = {
    ammo = player.get_inventory(defines.inventory.player_ammo).get_contents(),
    armor = player_armor_inventory.get_contents(),
    armor_equipment = player_armor_equipment,
    guns = player.get_inventory(defines.inventory.player_guns).get_contents(),
    main = player_main_inventory.get_contents(),
    main_equipment = player_main_equipment,
    main_blueprints = player_main_blueprints,
    main_blueprint_books = player_main_blueprint_books,
    quickbar = player_quickbar_inventory.get_contents(),
    quickbar_equipment = player_quickbar_equipment,
    quickbar_blueprints = player_main_blueprints,
    quickbar_blueprint_books = player_quickbar_blueprint_books,
    tools = player.get_inventory(defines.inventory.player_tools).get_contents(),
    trash = player_trash_inventory.get_contents(),
    trash_equipment = player_trash_equipment,
    trash_blueprints = player_main_blueprints,
    trash_blueprint_books = player_trash_blueprint_books
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

function NukePosition(player,radius)
  for k,v in pairs(player.surface.find_entities_filtered({area = {{player.position.x - radius, player.position.y - radius}, {player.position.x + radius, player.position.y + radius}}, force= "enemy"})) do 
    v.destroy() 
  end
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
    RestorePlayerInventory(player.get_inventory(defines.inventory.player_main), playerInventoryBackup.main, playerInventoryBackup.main_blueprints, playerInventoryBackup.main_blueprint_books)
    RestorePlayerInventory(player.get_inventory(defines.inventory.player_quickbar), playerInventoryBackup.quickbar, playerInventoryBackup.quickbar_blueprints, playerInventoryBackup.quickbar_blueprint_books)
    RestorePlayerInventory(player.get_inventory(defines.inventory.player_tools), playerInventoryBackup.tools)
    RestorePlayerInventory(player.get_inventory(defines.inventory.player_trash), playerInventoryBackup.trash,playerInventoryBackup.trash_blueprints,playerInventoryBackup.trash_blueprint_books)

    -- Repopulate any items with equipment grids
    RestoreInventoryEquipment(player.get_inventory(defines.inventory.player_armor), playerInventoryBackup.armor_equipment)
    RestoreInventoryEquipment(player.get_inventory(defines.inventory.player_main), playerInventoryBackup.main_equipment)
    RestoreInventoryEquipment(player.get_inventory(defines.inventory.player_quickbar), playerInventoryBackup.quickbar_equipment)
    RestoreInventoryEquipment(player.get_inventory(defines.inventory.player_trash), playerInventoryBackup.trash_equipment)

    global.player_inventories[player.name] = nil
  end
end

function RestorePlayerInventory(inventory, inventoryBackup, blueprints, books)

  for k, v in pairs(inventoryBackup) do
    inventory.insert( { name = k, count = v })
  end

  local blueprintCount = 1
  local bookCount = 1
  for index = 1, #inventory, 1 do
    local item = inventory[index]
    if item ~= nil and item.valid and item.valid_for_read then
      if item.type == "blueprint" and blueprints ~= nil then
        item.set_blueprint_entities(blueprints[blueprintCount])
        blueprintCount = blueprintCount + 1
      elseif item.type=="blueprint-book" then
        if books[bookCount] ~=nil then
          RestorePlayerInventory(item.get_inventory(1), 
            books[bookCount].inventory.main,
            books[bookCount].prints.main, 
            nil)
          RestorePlayerInventory(item.get_inventory(2), 
            books[bookCount].inventory.active,
            books[bookCount].prints.active, 
            nil)
        end
        bookCount=bookCount + 1
      end
    end
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

function DeepCopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
    end
    setmetatable(copy, DeepCopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end