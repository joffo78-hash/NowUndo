-- __startup.lua
local ids = {
  "_RS84087f5eddf7bcb9e5eff79b91996cf9693de246",  -- Virtual Launchpad
  "_RS4d2f140eded92aacb6c6f94aeb35589ad9338a23",  -- Twister
  "_RS68ff099cdf91203f77a65008be2c6ebd8c142945",  -- Dashboard
  "_RSbfeee33e0cad7db5843d28be494d11369dda77bb",  -- Auto-Tempo Sync
  "_RS629c296565f29b6e9b06d09a716228ca089fce38",  -- miroir
  "_RS463c27e6e43e1e24f977c239e15c944dfadbc0af",  -- Virtual Launchpad Web
  "_RSec1514e6c5cf32a91fd99731108f960ab9c5713a",  -- Twister Web
}

local start = reaper.time_precise()
local launched = false

local function boot()
  if launched then return end
  if reaper.time_precise() - start < 1.5 then  -- délai pour que l'UI soit prête
    reaper.defer(boot)
    return
  end
  launched = true
  for _, nid in ipairs(ids) do
    local id = reaper.NamedCommandLookup(nid)
    if id ~= 0 then reaper.Main_OnCommand(id, 0) end
  end
end

boot()