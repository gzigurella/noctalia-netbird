--!nonstrict
-- Poll the local NetBird CLI and publish the reachable peer list to the UI.

local refreshSeconds = noctalia.getConfig("refresh_seconds") or 5
local netbirdPath = noctalia.getConfig("netbird_path") or "/usr/bin/netbird"
local busy = false

local function publish(snapshot)
  noctalia.state.set("snapshot", snapshot)
end

local function pollStatus()
  if busy then
    return
  end
  busy = true
  local accepted = noctalia.runAsync({ netbirdPath, "status", "--json" }, function(result)
    busy = false
    if result.exitCode ~= 0 then
      local detail = noctalia.string.trim(result.stderr or "")
      local missing = string.find(string.lower(detail), "no such file", 1, true) ~= nil
      publish({
        installed = not missing,
        connected = false,
        peers = {},
        error = detail ~= "" and detail or noctalia.tr("status.unavailable"),
      })
      return
    end

    local data, decodeError = noctalia.json.decode(result.stdout or "")
    if type(data) ~= "table" then
      publish({
        installed = true,
        connected = false,
        peers = {},
        error = tostring(decodeError or noctalia.tr("status.invalid_response")),
      })
      return
    end

    local managementConnected = data.management ~= nil and data.management.connected == true
    local connectedPeers = {}
    local details = data.peers ~= nil and data.peers.details or {}
    if managementConnected and type(details) == "table" then
      for _, peer in ipairs(details) do
        if string.lower(tostring(peer.status or "")) == "connected" then
          local ip = tostring(peer.netbirdIp or ""):match("^[^/]+") or ""
          if ip ~= "" then
            table.insert(connectedPeers, {
              name = tostring(peer.fqdn or ip),
              ip = ip,
              connectionType = tostring(peer.connectionType or ""),
            })
          end
        end
      end
    end

    table.sort(connectedPeers, function(a, b)
      return string.lower(a.name) < string.lower(b.name)
    end)

    publish({
      installed = true,
      connected = managementConnected,
      ip = tostring(data.netbirdIp or ""):match("^[^/]+") or "",
      peers = connectedPeers,
      error = "",
    })
  end)

  if not accepted then
    busy = false
  end
end

function update()
  noctalia.setUpdateInterval(math.max(2, refreshSeconds) * 1000)
  pollStatus()
end

function onConfigChanged()
  refreshSeconds = noctalia.getConfig("refresh_seconds") or 5
  netbirdPath = noctalia.getConfig("netbird_path") or "/usr/bin/netbird"
  noctalia.setUpdateInterval(math.max(2, refreshSeconds) * 1000)
end

noctalia.state.watch("refreshRequested", function()
  pollStatus()
end)
