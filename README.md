# NetBird for Noctalia

A small Noctalia bar widget for controlling the local NetBird client and reaching peers.

## Features

- Bar icon shows whether this device is connected to NetBird.
- Panel provides Connect and Disconnect controls.
- Peer list includes only peers NetBird currently reports as `Connected` and provides copy buttons for the peer IP and a `netbird ssh` command.
- Optional default SSH username and configurable status refresh interval.

The peer list reflects current CLI connection status. It does not edit NetBird access policies. NetBird CLI and daemon must be installed and configured on the host. SSH availability still depends on NetBird SSH being enabled and allowed for the target peer.

## Install for local development

From this directory, add the folder as a Noctalia plugin source and enable it:

```sh
noctalia msg plugins source add dev path "$PWD"
noctalia msg plugins enable gabriele/netbird
```

Then add `gabriele/netbird:status` to a bar from Noctalia's bar settings. Luau entry edits hot reload; reload Noctalia configuration after changing `plugin.toml`.

## Settings

- **Refresh interval:** status poll frequency in seconds (2–60; default 5).
- **SSH username:** optional username included in copied commands, for example `netbird ssh alice@100.80.0.12`.
- **NetBird CLI path:** executable path (default `/usr/bin/netbird`).

## Notes

Status and peer data come from `netbird status --json`. The plugin invokes the configured CLI path with `status --json`, `up`, and `down` as argument arrays, without shell interpolation. Connecting may require the local NetBird daemon to be available and authenticated.

The bar uses NetBird's monochrome KDE system tray icons, with light and dark artwork for connected and disconnected states. These upstream icons are BSD-3-Clause licensed; see [LICENSES/NetBird-BSD-3-Clause.txt](LICENSES/NetBird-BSD-3-Clause.txt). Source: [NetBird client tray assets](https://github.com/netbirdio/netbird/tree/main/client/ui/assets).

NetBird SSH is documented at [docs.netbird.io/manage/peers/ssh](https://docs.netbird.io/manage/peers/ssh).
