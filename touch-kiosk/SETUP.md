# Touch Kiosk – From-Scratch Setup

Raspberry Pi running Chromium in kiosk mode on a DSI touchscreen display,
auto-logging in via LightDM into a labwc Wayland session.

## Requirements

- Raspberry Pi (tested on 64-bit Debian/Raspberry Pi OS Trixie)
- DSI touchscreen with Goodix capacitive controller (mapped to output `DSI-1`)
- `frontend.geitner.cc` must resolve to the frontend host — this is served by
  the local DNS at **192.168.178.29** (not set on the Pi itself)

## Packages

```bash
sudo apt install chromium lightdm labwc
```

The `rpd-labwc` session (`/usr/share/wayland-sessions/rpd-labwc.desktop`) is
provided by the Raspberry Pi OS desktop packages. It launches `/usr/bin/labwc-pi`.

## File Placement

| Config file (this repo)           | Target path on Pi                                    |
|-----------------------------------|------------------------------------------------------|
| `systemd/touch-kiosk.service`     | `~/.config/systemd/user/touch-kiosk.service`         |
| `systemd/touch-kiosk-restart.service` | `~/.config/systemd/user/touch-kiosk-restart.service` |
| `systemd/touch-kiosk-restart.timer`   | `~/.config/systemd/user/touch-kiosk-restart.timer`   |
| `labwc/rc.xml`                    | `~/.config/labwc/rc.xml`                             |
| `labwc/environment`               | `~/.config/labwc/environment`                        |
| `wayfire.ini`                     | `~/.config/wayfire.ini`                              |
| `lightdm/lightdm.conf`            | `/etc/lightdm/lightdm.conf` (merge into `[Seat:*]`)  |
| `chromium-policies/managed/touch-kiosk.json` | `/etc/chromium/policies/managed/touch-kiosk.json` |

## Setup Steps

1. Copy configs to their target paths (see table above).

2. Enable LightDM autologin — the `lightdm.conf` already sets `autologin-user=marvin`.
   Make sure the user is in the `autologin` group:
   ```bash
   sudo usermod -aG autologin marvin
   ```

3. Enable and start the kiosk service:
   ```bash
   systemctl --user daemon-reload
   systemctl --user enable touch-kiosk.service
   # Service starts automatically when the graphical session launches
   ```

4. Enable the periodic restart timer (safety net for a Chromium instance stuck
   on an error page, e.g. after a brief network hiccup):
   ```bash
   systemctl --user enable --now touch-kiosk-restart.timer
   ```

5. Reboot:
   ```bash
   sudo reboot
   ```

Note: `/etc/chromium/policies/managed/touch-kiosk.json` sets one enterprise
policy:
- `TranslateEnabled: false` — needed because the `--disable-translate` /
  `--disable-features=TranslateUI` command-line flags no longer reliably
  suppress the "Translate this page?" bubble on current Chromium versions.

`HttpsOnlyMode: "disallowed"` used to be set here too, to stop Chromium's
HTTPS-First Mode from blocking the then-plain-HTTP `frontend.home-lab.com`
behind an interstitial with no way to click through unattended. Now that
`frontend.geitner.cc` is served over real HTTPS with a valid Let's Encrypt
certificate (smart-home-infrastructure#112), that policy is no longer
needed and has been removed — HTTPS-First Mode doesn't interfere with a
properly-certified HTTPS site.

## How It Works

```
Boot
 └── LightDM (display manager)
      └── auto-login marvin → session: rpd-labwc
           └── labwc-pi (Wayland compositor)
                └── /etc/xdg/autostart/env-display.desktop
                     └── dbus-update-activation-environment --systemd WAYLAND_DISPLAY
                          └── systemd user graphical-session.target
                               └── touch-kiosk.service
                                    └── chromium --kiosk https://frontend.geitner.cc/touch
```

- `labwc/rc.xml` maps the Goodix touchscreen to the DSI-1 output.
- `wayfire.ini` disables DPMS and screensaver (screen stays on indefinitely).
- The kiosk service restarts automatically on failure (`Restart=on-failure`).
- `touch-kiosk-restart.timer` force-restarts the kiosk every 30 minutes as a
  safety net: Chromium doesn't crash (so `Restart=on-failure` never triggers)
  when it merely fails to reach `frontend.geitner.cc` — it just sits on an
  error page. The periodic restart makes it re-navigate to the app URL.
- `touch-kiosk.service` runs Chromium with `--incognito`, so no profile
  persists across restarts (initial boot, on-failure restart, and the
  30-minute timer restart alike). This is required to actually pick up a
  redeployed frontend: restarting the Chromium *process* alone leaves a
  persistent profile — and with it any Service Worker / Cache Storage the
  frontend app registered — intact. A Service Worker intercepts fetches
  before HTTP response headers (like the frontend's Traefik `no-cache`
  middleware, see `k8s/charts/networking`) are even considered, so it can
  keep serving a stale app shell indefinitely regardless of server-side
  cache headers. Incognito mode is the built-in guarantee that the newest
  deploy always gets loaded fresh.

## Notes

- The Wi-Fi SSID on the current device is `3584298857856414` (hidden SSID).
  Re-configure via `nmtui` or `raspi-config` after a fresh install.
- Hostname is `raspberrypi` — set via `sudo raspi-config` → System → Hostname.
- Static IP (`192.168.178.98`) is assigned by DHCP reservation on the router,
  not configured on the Pi.
- **Known issue:** NetworkManager may hold onto other saved Wi-Fi profiles
  (e.g. a neighbor's network picked up during setup) with the same
  `autoconnect-priority` as the Pi's own SSID. If the Pi's Wi-Fi drops, it can
  reconnect to the wrong network, breaking DNS resolution for
  `frontend.geitner.cc`. Check `nmcli connection show` periodically and
  remove/disable-autoconnect on any unintended profiles
  (`sudo nmcli connection delete "<name>"`), or raise the priority of the
  Pi's own SSID (`nmcli connection modify "<ssid>" connection.autoconnect-priority 10`).
  The restart timer above does **not** fix this — it only helps if the Pi is
  already back on the correct network but Chromium is stuck showing an error
  page.
