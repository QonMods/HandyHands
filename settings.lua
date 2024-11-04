data:extend({
  {
    type = "bool-setting",
    name = "autocraft-sound-enabled",
    setting_type = "runtime-per-user",
    default_value = true,
    -- localised_name = "Completion sound for autocrafted items"
  }, {
    type = "bool-setting",
    name = "quickbar-slots-are-autocraft-requests",
    setting_type = "runtime-per-user",
    default_value = true
  }, {
    type = "bool-setting",
    name = "handyhands-autocraft-multi-product-recipes",
    setting_type = "runtime-per-user",
    default_value = false
  }, {
    type = "string-setting",
    name = "logistics-requests-are-autocraft-requests",
    setting_type = "runtime-per-user",
    default_value = 'When personal logistics requests are enabled',
    allowed_values = {'Never', 'When personal logistics requests are enabled', 'Always'},
  }
})