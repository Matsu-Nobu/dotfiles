-- NOTE: auto-settionが原因でsytaxが効かなくなることがある
return {
  "rmagatti/auto-session",
  lazy = false,
  config = function()
    require "configs.auto-session"
  end,
}
