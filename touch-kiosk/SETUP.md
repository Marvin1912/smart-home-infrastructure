# Touch Kiosk – From-Scratch Setup

Raspberry Pi running Chromium in kiosk mode on a DSI touchscreen display,
auto-logging in via LightDM into a labwc Wayland session.

## Requirements

- Raspberry Pi (tested on 64-bit Debian/Raspberry Pi OS Trixie)
- DSI touchscreen with Goodix capacitive controller (mapped to output `DSI-1`)
- `frontend.home-lab.com` must resolve to the frontend host — this is served by
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
| `labwc/rc.xml`                    | `~/.config/labwc/rc.xml`                             |
| `labwc/environment`               | `~/.config/labwc/environment`                        |
| `wayfire.ini`                     | `~/.config/wayfire.ini`                              |
| `lightdm/lightdm.conf`            | `/etc/lightdm/lightdm.conf` (merge into `[Seat:*]`)  |

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

4. Reboot:
   ```bash
   sudo reboot
   ```

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
                                    └── chromium --kiosk http://frontend.home-lab.com/touch
```

- `labwc/rc.xml` maps the Goodix touchscreen to the DSI-1 output.
- `wayfire.ini` disables DPMS and screensaver (screen stays on indefinitely).
- The kiosk service restarts automatically on failure (`Restart=on-failure`).

## Notes

- The Wi-Fi SSID on the current device is `3584298857856414` (hidden SSID).
  Re-configure via `nmtui` or `raspi-config` after a fresh install.
- Hostname is `raspberrypi` — set via `sudo raspi-config` → System → Hostname.
- Static IP (`192.168.178.98`) is assigned by DHCP reservation on the router,
  not configured on the Pi.
