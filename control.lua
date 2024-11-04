-- HandyHands. Factorio mod: Automatically start handcrafting 1 item on your quickbar whenever your crafting queue is empty. Prioritises items in your hand. It's like logistics slots for early game!
-- Copyright (C) 2016  Qon

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>

local SHORTCUT_NAME = 'handyhands-toggle'

local debugging = false

local max_arr = {0, .2, .5, .8, 1, 2, 3, 4}

local CONDITIONAL_NTH_TICK_AMOUNT = 20

local map                = require('lib.functional').map
local filter             = require('lib.functional').filter
local fnn                = require('lib.functional').fnn
local range              = require('lib.functional').range
local list_iter_filt_map = require('lib.functional').list_iter_filt_map
local iterlist_iter      = require('lib.functional').iterlist_iter

-- If we complete an autostarted craft then mark it as done so that the next
-- crafting queue size check knows it wasn't because the player canceled it.
script.on_event(defines.events.on_player_crafted_item, function(event)
    -- How can an item stack that I recieve in an event handler and used immediatly be invalid? Apparently it can...
    -- This fix will pause HandyHands instead of crashing, at least slightly better.
    if not event.item_stack.valid_for_read then return nil end

    local p = game.players[event.player_index]
    local d = global.players_data[event.player_index]
    if d.current_job == event.item_stack.name then
        d.current_job = nil
        d.hh_request_tick = game.tick
        if p.crafting_queue and p.crafting_queue[1].count == 1 and p.mod_settings["autocraft-sound-enabled"].value then
            p.play_sound{path = 'handyhands-core-crafting_finished'--[[, volume_modifier = 1--]]}
        end
    elseif --[[p.crafting_queue_size == 1 and--]] p.crafting_queue and p.crafting_queue[1].count == 1 and d.current_job == nil then
    -- elseif event.item_stack.count == 1 then
        p.play_sound{path = 'handyhands-core-crafting_finished'--[[, volume_modifier = 1--]]}
    end
    global.players_data[event.player_index] = d
    register_player_for_check(event.player_index)
    -- check_player_requests(event.player_index)
end)

function check_registered_players()
    local slot = math.floor(game.tick / CONDITIONAL_NTH_TICK_AMOUNT)
    for player_index, _ in pairs(global.players_to_check) do
        if true or player_index % 5 == slot then
            global.players_to_check[player_index] = nil
            check_player_requests(player_index)
        end
    end
    if table_size(global.players_to_check) == 0 then -- check_player_requests() might have re-registered a player?
        script.on_nth_tick(CONDITIONAL_NTH_TICK_AMOUNT, nil)
    end
end

script.on_load(function()
    if table_size(global.players_to_check or {}) > 0 then
        script.on_nth_tick(CONDITIONAL_NTH_TICK_AMOUNT, check_registered_players)
    end
end)

function register_player_for_check(player_index)
    global.players_to_check[player_index] = true
    script.on_nth_tick(CONDITIONAL_NTH_TICK_AMOUNT, check_registered_players)
end

function on_player_event(event) register_player_for_check(event.player_index) end
function on_force_event(event)  for _, player in ipairs(event.force.players) do register_player_for_check(player.index) end end

script.on_event(defines.events.on_player_cancelled_crafting,     on_player_event)
script.on_event(defines.events.on_player_main_inventory_changed, on_player_event)
script.on_event(defines.events.on_player_set_quick_bar_slot,     on_player_event)
script.on_event(defines.events.on_player_ammo_inventory_changed, on_player_event)
script.on_event(defines.events.on_player_respawned,              on_player_event)
script.on_event(defines.events.on_player_cheat_mode_enabled,     on_player_event)
script.on_event(defines.events.on_research_finished,             function(event) on_force_event(event.research) end) -- research has .force
script.on_event(defines.events.on_technology_effects_reset,      on_force_event)
script.on_event(defines.events.on_forces_merging,                function(event)
    for _, player in ipairs(game.connected_players) do register_player_for_check(player.index) end
end)

-- Init all new joining players.
script.on_event(defines.events.on_player_joined_game, function(event)
    local p = game.players[event.player_index]
    if debugging then p.print('joined!') end
    local d = global.players_data[event.player_index]
    if d == nil then
        d = init_player(event.player_index)
    end
    global.players_data[event.player_index] = d
    on_player_event(event)
end)

function check_player_requests(player_index)
    local p = game.players[player_index]
    if p.connected and p.controller_type == defines.controllers.character then
        local d = global.players_data[player_index]
        local canceled_autocraft = false
        if d.current_job ~= nil and p.crafting_queue_size > 0 then
            if d.current_job ~= p.crafting_queue[#p.crafting_queue].recipe or p.crafting_queue[#p.crafting_queue].count > 1 then
                d.current_job = nil
            elseif p.crafting_queue[d.current_job] ~= nil and p.crafting_queue[d.current_job].recipe == nil then
                canceled_autocraft = true
                enabled(player_index, false) -- d.paused = true
            end
        end
        if p.crafting_queue_size == 0 then
            if d.current_job ~= nil then
                canceled_autocraft = true
                enabled(player_index, false) -- d.paused = true
            end
            if not d.paused then hh_player(player_index) end
        end
        if canceled_autocraft then
            p.print(script.mod_name..' is now paused until you hit increase or decrease key (Options > Controls > Mods).')
            d.current_job = nil
        end
    end
end

-- The mod core logic
-- script.on_event(defines.events.on_tick, function(event)
--     for player_index = game.tick % work_tick + 1, #game.players, work_tick do
--         register_player_for_check(player_index)
--     end
-- end)

local stack_size_cache = {}
function stack_size(item)
    stack_size_cache[item] = stack_size_cache[item] or game.item_prototypes[item].stack_size
    return stack_size_cache[item]
end

-- For better interaction with stack size changing mods: Pretend that the max stack size is only 1/10 as big.
function pretend_stack_size(stack_size)
    if stack_size >= 500 then return stack_size / 10 else return stack_size end
end

function get_request_count(p, d, item)
    local setting = d.settings[item]
    if setting == nil then
        setting = d.settings['Default']
        if setting == nil then
            p.print(script.mod_name..' Error: Uninitialised Default setting.')
        end
    end
    local stsz = pretend_stack_size(stack_size(item))
    local mi = math.ceil(stsz*setting)


    local pl = p.mod_settings['logistics-requests-are-autocraft-requests'].value
    if p.character and
       (pl == 'Always' or pl == 'When personal logistics requests are enabled' and p.character_personal_logistic_requests_enabled) and
       d.personal_logistics_requests[item] then
        if d.settings[item] == nil then
            mi = d.personal_logistics_requests[item].min
        -- else
        --     mi = math.max(mi, d.personal_logistics_requests[item].min)
        end
    end

    -- Don't keep autocrafting this item if it will just end up in logistics trash slots.
    if p.character and d.personal_logistics_requests[item] then
        mi = math.min(mi, d.personal_logistics_requests[item].max)
    end


    return mi
end

function build_request_iterator(p, d)
    -- List is an iterator over all items that are candidates for autocrafting.
    -- qb: The quickbar items. We filter away items which are not "filtered" (blue item lock on quickbar) and pick the "filter_" instead of the item stack.
    local list = {}

    if p.mod_settings['quickbar-slots-are-autocraft-requests'].value then
        local aqb = fnn(map(range(1,4), function(q) return p.get_active_quick_bar_page(q) end))
        local slots = iterlist_iter(map(aqb, function(page)
            return map(range(1,10), function(index)
                return (page-1)*10+index
            end)
        end))
        slots = filter(map(slots, function(q)
            local slot = p.get_quick_bar_slot(q)
            if slot ~= nil then return slot.name end
            return ''
        end), function(q) return q ~= '' end)
        table.insert(list, slots)

        -- All non-empty ammo_bar stacks are autocrafting candidates.
        local ammo_bar = p.get_inventory(defines.inventory.character_ammo)
        if p.character then
            table.insert(list, list_iter_filt_map(ammo_bar, function(q,i,a) return q.valid_for_read end, function(q,i,a) return q.name end))
        end
    end

    -- Manual settings allows autocrafting in inventory.
    local inventory_crafting = {}
    for key, value in pairs(d.settings) do
        table.insert(inventory_crafting, key)
    end
    table.insert(list, list_iter_filt_map(inventory_crafting, function(q) return q ~= 'Default' end))

    -- Personal logistics requests
    local logistics_requests = {}
    local pl = p.mod_settings['logistics-requests-are-autocraft-requests'].value
    if pl == 'Always' or pl == 'When personal logistics requests are enabled' and p.character_personal_logistic_requests_enabled then
        d.personal_logistics_requests = d.personal_logistics_requests or {}
        for i = 1, p.character.request_slot_count do
            local logi_request = p.get_personal_logistic_slot(i)
            if logi_request.min > 0 then
                table.insert(logistics_requests, logi_request.name)
                d.personal_logistics_requests[logi_request.name] = logi_request
            end
        end
    end
    table.insert(list, list_iter_filt_map(logistics_requests))

    return list
end

local a_recipe_memo
function a_recipe(item_name, player)
    local cheat = player == nil or player.cheat_mode

    local recipe = player.force.recipes[item_name]
    if recipe ~= nil then
        if cheat or (recipe.enabled and player.get_craftable_count(recipe) > 0) then return recipe end
    end

    if a_recipe_memo == nil then
        a_recipe_memo = {}
        for recipe_name, recipe_prot in pairs(game.get_filtered_recipe_prototypes({{filter = "has-product-item"}})) do
            for _, product in ipairs(recipe_prot.products) do
                if product.name ~= recipe_name then
                    a_recipe_memo[product.name] = a_recipe_memo[product.name] or {}
                    table.insert(a_recipe_memo[product.name], recipe_prot)
                end
            end
        end
    end
    local multi_product_allowed = player.mod_settings['handyhands-autocraft-multi-product-recipes'].value
    local recipe_prots = a_recipe_memo[item_name]
    if recipe_prots ~= nil then
        for _, recipe_prot in ipairs(recipe_prots) do
            if (cheat or
                (player.force.recipes[recipe_prot.name].enabled and player.get_craftable_count(recipe_prot.name) > 0))
                and (multi_product_allowed or #recipe_prot.products <= 1) then
                return recipe_prot.name
            end
        end
    end
end

function craft(p, d, item, count)
    if p.cheat_mode == false then
        p.begin_crafting{count=1, recipe=a_recipe(item, p), silent=true}
        d.current_job = item
    else
        p.begin_crafting{count=count, recipe=a_recipe(item, p), silent=true}
    end
end

function hh_player(player_index)
    local p = game.players[player_index]
    if p.connected and p.controller_type ~= defines.controllers.character then return nil end
    if p.crafting_queue_size ~= 0 then return nil end
    local d = global.players_data[player_index]
    if d.paused then return nil end
    -- local mi = p.get_main_inventory()

    local selected_item = nil
    local count_selected = nil
    local max_selected = nil
    local cs = p.cursor_stack
    local item

    list = iterlist_iter(build_request_iterator(p, d))
    for item in list do
        if debugging then p.print('debug '..item) end
        -- Check that we can craft this item. If not, skip.
        local ci = p.get_item_count(item)
        local mi = get_request_count(p, d, item)
        local recipe = a_recipe(item, p) -- p.force.recipes[item]
        if ci < mi and recipe ~= nil then
            local prio_selected = 1
            if selected_item ~= nil then
                prio_selected = count_selected/max_selected
            end
            -- prio is a bit backwards. Lower prio number values for prioritized items.
            local prio_current = ci/mi
            local item_held = cs.valid_for_read and cs.name == item
            -- Prioritise items held in cursor above all. Prioritise less fulfilled autocraft requests.
            local prioritised = prio_current < prio_selected or item_held
            -- Check that we can craft the item
            if prio_current < 1 and prioritised then
                selected_item = item
                count_selected = ci
                max_selected = mi
                if cs.valid_for_read and cs.name == item then
                    break
                end
            end
        end
    end
    if selected_item ~= nil then craft(p, d, selected_item, max_selected - count_selected) end
end

-- Handle hotkey presses.
script.on_event('handyhands-increase', function(event) change(event, true) end)
script.on_event('handyhands-decrease', function(event) change(event, false) end)


-- local event_handlers = {

--     on_lua_shortcut = function(event)
--         -- if event.prototype_name ~= SHORTCUT_NAME then return end
--         local p = game.players[event.player_index]
--         printOrFly(p, '1 '..event.prototype_name)
--         remotes.paused(event.player_index, not remotes.paused(event.player_index))
--         p.set_shortcut_toggled(SHORTCUT_NAME, remotes.paused(event.player_index))
--     end,

--     -- ['handyhands-increase'] = function(event) change(event, true) end,
--     -- ['handyhands-decrease'] = function(event) change(event, false) end

--     -- [SHORTCUT_NAME] = function(event)
--     --     local p = game.players[event.player_index]
--     --     printOrFly(p, '2')
--     --     set_enabled(p, not p.is_shortcut_toggled(SHORTCUT_NAME))
--     -- end,
-- }
-- for event_name, handler in pairs (event_handlers) do
--   script.on_event(defines.events[event_name] or event_name, handler)
-- end


function enabled(player_index, set)
    if set ~= nil then
        global.players_data[player_index].paused = not set
        local p = game.players[player_index]
        -- printOrFly(p, set)
        p.set_shortcut_toggled(SHORTCUT_NAME, enabled(player_index))
        if set then register_player_for_check(player_index) end
    end
    return not global.players_data[player_index].paused
end

script.on_event(defines.events.on_lua_shortcut, function(event)
    -- game.print(game.table_to_json(event))
    if event.prototype_name ~= SHORTCUT_NAME then return end
    local p = game.players[event.player_index]
    enabled(event.player_index, not enabled(event.player_index))
end)

function change(event, positive)
    local p = game.players[event.player_index]
    -- init_player(event.player_index, false)
    local d = global.players_data[event.player_index]
    d.hh_request_tick = game.tick
    -- global.players_data[event.player_index] = d
    if d.paused == true then
        enabled(event.player_index, true)
        -- d = global.players_data[event.player_index]
        printOrFly(p, script.mod_name..' is now running again!')
        register_player_for_check(event.player_index)
        return
    end
    local item = 'Default'
    if p.cursor_stack.valid_for_read == true then
        item = p.cursor_stack.name
        if d.settings[item] == nil then
            d.settings[item] = d.settings['Default']
        end
    end
    local changed = false
    if positive then
        for i = 1, #max_arr do
            if max_arr[i] > d.settings[item] then
                d.settings[item] = max_arr[i]
                changed = true
                break
            end
        end
    else
        for i = 1, #max_arr do
            if max_arr[#max_arr-i+1] < d.settings[item] then
                d.settings[item] = max_arr[#max_arr-i+1]
                changed = true
                break
            end
        end
    end
    if changed then
        function settingsmessage(item)
            local trash_warning = ''
            -- TODO make sure d.personal_logistics_requests is actually up to date here
            if p.character and d.personal_logistics_requests[item] ~= nil and d.personal_logistics_requests[item].max < math.ceil(game.item_prototypes[item].stack_size*d.settings[item]) then
                trash_warning = ' [Auto trash: '..d.personal_logistics_requests[item].max..']'
            end
            -- Add the / 10 on bigger stacksize
            return '[item='..item..']: '..d.settings[item]..' stacks ('..math.ceil(pretend_stack_size(game.item_prototypes[item].stack_size)*d.settings[item])..' items)'..trash_warning
        end
        function printall()
            p.print('Changed default autocraft stack size: '..d.settings['Default']..' stacks.')
            for k in pairs(d.settings) do
                if k ~= 'Default' then p.print(settingsmessage(k)) end
            end
        end
        if item == 'Default' then printall()
        else printOrFly(p, settingsmessage(item)) end
    elseif positive == false and d.settings[item] == 0 then
        if item == 'Default' then
            init_player_settings(event.player_index, true)
            d = global.players_data[event.player_index]
            d.settings['Default'] = 0
            p.print('All your '..script.mod_name..' settings were deleted.')
        else
            d.settings[item] = nil
            printOrFly(p, 'Your '..script.mod_name..' setting for [item='..item..'] was deleted [Default is '..d.settings['Default']..' stacks]')
        end
    end
    global.players_data[event.player_index] = d
    register_player_for_check(event.player_index)
end

function printOrFly(p, text)
    if p.character ~= nil then
        p.create_local_flying_text({
            ['text'] = text,
            ['position'] = p.character.position
        })
    else
        p.print(text)
    end
end

function init(event, forceful)
    global.players_to_check = global.players_to_check or {}
    -- Might be called with nil event and forceful
    if global.players_data == nil or forceful then
        global.players_data = {}
    end
    for i = 1, #game.players do
        init_player(i, forceful)
    end
end

function init_player(player_index, forceful)
    local player = game.players[player_index]
    if player.mod_settings['logistics-requests-are-autocraft-requests'].value ~= 'Never' and not player.force.character_logistic_requests then
        player.force.character_logistic_requests = true
    end
    local ps = init_player_settings(player_index, forceful)
    enabled(player_index, enabled(player_index))
    return ps
end

function init_player_settings(player_index, forceful)
    local wasnil = global.players_data[player_index] == nil
    if wasnil or forceful then
        global.players_data[player_index] = {}
        global.players_data[player_index].personal_logistics_requests = {}
        global.players_data[player_index].settings = {}
        global.players_data[player_index].settings['Default'] = 0.2
        -- Only for beginners, so that you don't lose your starting iron to ammo before you have your pick axe ;>
        if wasnil then
            global.players_data[player_index].settings['firearm-magazine'] = 0.05*100/game.item_prototypes['firearm-magazine'].stack_size
            game.players[player_index].print(
                script.mod_name..' autocrafting enabled for quickbar filtered items and ammo. Default amount: '..global.players_data[player_index].settings['Default']..' stacks.'
            )
            game.players[player_index].print('Change '..script.mod_name..' autocrafting limits with hotkeys (Options > Controls > Mods) or personal logistics requests.')
            game.players[player_index].print('Empty cursor: change Default. Forget all '..script.mod_name..' settings by deleting Default setting.')
            game.players[player_index].print('Individual item settings are modified when held in cursor and deleted when decreased below 0.')
        end
    end
    return global.players_data[player_index]
end



script.on_init(init)
script.on_event(defines.events.on_player_joined_game, function(event) init_player(event.player_index, false) end)
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting == 'logistics-requests-are-autocraft-requests' and event.player_index then
        local player = game.players[event.player_index]
        if player.mod_settings['logistics-requests-are-autocraft-requests'].value ~= 'Never' and not player.force.character_logistic_requests then
            player.force.character_logistic_requests = true
        end
    end
    if event.player_index then on_player_event(event) end
end)

-- Data migration
script.on_configuration_changed(function(event)
    for i, p in pairs(game.players) do
        if global.players_data and global.players_data[i] then
            local d = global.players_data[i]
            for item, value in pairs(d.settings) do
                if item ~= 'Default' and not game.item_prototypes[item] then d.settings[item] = nil end
            end
        end
    end
    local cmc = event.mod_changes[script.mod_name]
    if cmc and cmc.old_version ~= cmc.new_version then
        global.players_to_check = global.players_to_check or {}
    end
end)

remote.add_interface('handyhands', {
    -- call change(player_index, positive) to simulate increase/decrease hotkey events. (positive: true for increase, false for decrease)
    change = function(player_index, positive) change({player_index = player_index}, positive) end,
    -- set(player_index, item, limit) sets the autocraft limit for a specific item to the provided limit. limit == nil to remove the setting. Limits are in stacks (float).
    set = function(player_index, item, limit) global.players_data[player_index].settings[item] = limit end,
    -- call settings(player_index) to get the Key/Value pairs to get the stack size limits
    -- call settings(player_index, limits) to set the Key/Value pairs stack size limits (limits is a Key[item_name] --> Value (stacks_to_craft) object)
    settings = function(player_index, limits)
        if limits ~= nil then
            global.players_data[player_index].settings = limits
        end
        return global.players_data[player_index].settings
    end,
    -- call enabled(player_index) to get enabled state for the player
    -- call enabled(player_index, set) to set enabled state for the player (set is a boolean)
    enabled = enabled,
})