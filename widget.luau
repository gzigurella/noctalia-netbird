--!nonstrict

local snapshot = noctalia.state.get("snapshot") or {
  installed = false,
  connected = false,
  peers = {},
  error = "",
}

local function render()
  local state = snapshot.connected and "connected" or "disconnected"
  local theme = noctalia.isDarkMode() and "dark" or "light"
  barWidget.setImage(`icons/netbird-{state}-{theme}.png`, false, 18, 18)
  if snapshot.connected then
    barWidget.setTooltip(noctalia.tr("widget.connected", { count = #snapshot.peers }))
  elseif snapshot.installed then
    barWidget.setTooltip(noctalia.tr("widget.disconnected"))
  else
    barWidget.setTooltip(noctalia.tr("widget.unavailable"))
  end
end

noctalia.state.watch("snapshot", function(value)
  if type(value) == "table" then
    snapshot = value
    render()
  end
end)

function update()
  render()
end

