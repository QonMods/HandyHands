-- local techCraftingSlots = table.deepcopy(data.raw.technology['character-logistic-slots-1'])
-- techCraftingSlots.name = 'handyhands-repurposed-logistics-to-crafting-slots'
-- techCraftingSlots.prerequisites = nil
-- techCraftingSlots.unit.count = 1
-- techCraftingSlots.unit.time = 1
-- techCraftingSlots.unit.ingredients = {}
-- techCraftingSlots.effects[1].modifier = 40

data:extend({
  {
    type = "custom-input",
    name = "handyhands-increase",
    key_sequence = "U",
    consuming = "none"
  },{
    type = "custom-input",
    name = "handyhands-decrease",
    key_sequence = "J",
    consuming = "none"
  },{
    type = "sound",
    name = "handyhands-core-crafting_finished",
    filename = "__core__/sound/crafting-finished.ogg",
    volume = 1
  },{
    type = "shortcut",
    name = "handyhands-toggle",
    -- order = "handyhands-toggle-construction",
    action = "lua",
    toggleable = true,
    -- localised_name = {"handyhands-shortcut.toggle"},
    icon =
    {
      filename = "__HandyHands__/graphics/icon/shortcut-toggle.png",
      priority = "extra-high-no-scale",
      size = 144,
      scale = 0.2,
      flags = {"icon"}
    },
    -- small_icon =
    -- {
    --   filename = "__autobuild__/graphics/wrench-x24.png",
    --   priority = "extra-high-no-scale",
    --   size = 24,
    --   scale = 1,
    --   flags = {"icon"}
    -- },
    -- disabled_icon =
    -- {
    --   filename = "__autobuild__/graphics/wrench-x32-white.png",
    --   priority = "extra-high-no-scale",
    --   size = 32,
    --   scale = 1,
    --   flags = {"icon"}
    -- },
    -- disabled_small_icon =
    -- {
    --   filename = "__autobuild__/graphics/wrench-x24-white.png",
    --   priority = "extra-high-no-scale",
    --   size = 24,
    --   scale = 1,
    --   flags = {"icon"}
    -- },
  },
})