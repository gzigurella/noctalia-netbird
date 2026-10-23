--!nonstrict

local snapshot = noctalia.state.get("snapshot") or {
  installed = false,
  connected = false,
  peers = {},
  error = "",
}
local busy = false
local sshUsername = noctalia.getConfig("ssh_username") or ""
local netbirdPath = noctalia.getConfig("netbird_path") or "/usr/bin/netbird"

local function requestRefresh()
  local rev = noctalia.state.get("refreshRequested") or 0
  noctalia.state.set("refreshRequested", rev + 1)
end

local function sshCommand(peer)
  local target = peer.ip
  if sshUsername ~= "" then
    target = sshUsername .. "@" .. target
  end
  return "netbird ssh " .. target
end

local function copy(text)
  noctalia.copyToClipboard(text, "text/plain")
  noctalia.notify(noctalia.tr("panel.copied"), text)
end

local function render()
  local peers = snapshot.peers or {}
  local peerRows = {}
  for _, peer in ipairs(peers) do
    table.insert(peerRows, ui.row({ key = peer.ip, gap = 8, align = "center" }, {
      ui.column({ gap = 2, flexGrow = 1 }, {
        ui.label({ text = peer.name, fontWeight = "medium", maxWidth = 260 }),
        ui.label({ text = peer.ip, color = "on_surface_variant", fontFamily = "monospace" }),
      }),
      ui.button({
        glyph = "copy",
        variant = "ghost",
        tooltip = noctalia.tr("panel.copy_ip"),
        onClick = function() copy(peer.ip) end,
      }),
      ui.button({
        glyph = "terminal",
        variant = "secondary",
        tooltip = noctalia.tr("panel.copy_ssh"),
        onClick = function() copy(sshCommand(peer)) end,
      }),
    }))
  end

  if #peerRows == 0 then
    local message
    if not snapshot.installed then
      message = noctalia.tr("panel.netbird_missing")
    elseif not snapshot.connected then
      message = noctalia.tr("panel.connect_to_see_peers")
    else
      message = noctalia.tr("panel.no_reachable_peers")
    end
    table.insert(peerRows, ui.label({ text = message, color = "on_surface_variant", maxLines = 2 }))
  end

  local peerLabel = noctalia.trp("panel.reachable_peers", #peers)
  local errorText = snapshot.error or ""
  local children = {
    ui.row({ gap = 8, align = "center", justify = "space_between" }, {
      ui.column({ gap = 2, flexGrow = 1 }, {
        ui.label({ text = noctalia.tr("panel.title"), fontSize = 16, fontWeight = "bold" }),
        ui.label({
          text = snapshot.connected and peerLabel or (snapshot.installed and noctalia.tr("panel.disconnected") or noctalia.tr("panel.status_unavailable")),
          color = snapshot.connected and "primary" or "on_surface_variant",
        }),
      }),
      ui.button({ glyph = "refresh", variant = "ghost", tooltip = noctalia.tr("panel.refresh"), onClick = requestRefresh }),
    }),
  }

  if errorText ~= "" then
    table.insert(children, ui.label({ text = errorText, color = "error", maxLines = 2 }))
  end

  table.insert(children, ui.scroll({ flexGrow = 1, gap = 10, align = "stretch" }, peerRows))
  table.insert(children, ui.button({
    text = busy and noctalia.tr("panel.working") or (snapshot.connected and noctalia.tr("panel.disconnect") or noctalia.tr("panel.connect")),
    glyph = snapshot.connected and "plug-zap" or "plug",
    variant = snapshot.connected and "destructive" or "primary",
    enabled = snapshot.installed and not busy,
    onClick = "toggleConnection",
  }))
  panel.render(ui.column({ flexGrow = 1, gap = 14, align = "stretch" }, children))
end

function toggleConnection()
  if busy or not snapshot.installed then
    return
  end
  busy = true
  render()
  local action = snapshot.connected and "down" or "up"
  local accepted = noctalia.runAsync({ netbirdPath, action }, function(result)
    busy = false
    if result.exitCode ~= 0 then
      local detail = noctalia.string.trim(result.stderr or "")
      noctalia.notifyError(noctalia.tr("panel.command_failed"), detail ~= "" and detail or noctalia.tr("panel.try_again"))
    end
    requestRefresh()
    render()
  end)
  if not accepted then
    busy = false
    render()
    noctalia.notifyError(noctalia.tr("panel.command_failed"), noctalia.tr("panel.try_again"))
  end
end

noctalia.state.watch("snapshot", function(value)
  if type(value) == "table" then
    snapshot = value
    render()
  end
end)

function onOpen()
  render()
  requestRefresh()
end

function update()
  render()
end
