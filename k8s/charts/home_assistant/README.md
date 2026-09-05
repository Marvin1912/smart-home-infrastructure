# Home Assistant

This chart does not run Home Assistant itself — HA runs as a Docker container
directly on `home-server` (see `docker-compose.yml` at the repo root, service
`homeassistant`, bind-mounting `/opt/home_assistant/config:/config`). This
chart covers the pieces that live in the cluster:

- Prometheus scrape wiring (`service.yaml`, `endpoints.yaml`,
  `servicemonitor.yaml`) pointing at the HA instance's `/api/prometheus`
  endpoint.
- Alerting rules (`rules.yaml`), e.g. low battery.
- The **config git-sync CronJob** described below.

## Config git-sync

`automations.yaml`, `scripts.yaml`, `scenes.yaml` and the `themes/` directory
are `!include`d from `home_assistant/configuration.yaml` (see that file's
`automation:`/`script:`/`scene:`/`frontend.themes:` keys), but Home Assistant
writes to them live whenever automations/scripts/scenes/themes are edited
through the UI. Without a sync mechanism, that state only exists on
`home-server`'s disk — a lost/corrupted Pi, a bad `docker-compose` volume, or
a fat-fingered `rm` would destroy it with no history and no rollback.

Because HA is configured with plain YAML files (not the `.storage/*.json`
UI-registry format), the bind-mounted directory can be read directly —
no HA API/token needed for the sync itself.

`config-sync-cronjob.yaml` runs a scheduled Job (`configSync.schedule`,
default `0 4 * * *`) that:

1. Mounts `configSync.hostConfigPath` (`/opt/home_assistant/config` on
   `home-server`) read-only via `hostPath` — pinned to that node via
   `nodeSelector: kubernetes.io/hostname: home-server`, since this is a
   single-node cluster and the path only exists there.
2. Clones this repo at `configSync.gitBranch` (`master`).
3. Copies `automations.yaml`, `scripts.yaml`, `scenes.yaml` and `themes/`
   from the mount into `configSync.configDir` (`home_assistant/`) in the
   clone, overwriting what's there.
4. Commits and pushes only if something actually changed
   (`git diff --cached --quiet` short-circuits a no-op run).

The script refuses to run (exits non-zero without touching the repo) if any
of the four source paths is missing from the mount — better to fail loudly
than to push a commit that wipes tracked config because the mount didn't
come up.

It reuses the GitHub push token already sealed for the Grafana dashboard
sync CronJob (`k8s/charts/grafana/templates/dashboard-sync-sealedsecret.yaml`,
secret `grafana-dashboard-sync-secrets`, key `GITHUB_TOKEN`) — same repo,
same permission scope, so no separate secret was minted. See
`configSync.githubTokenSecretName`/`githubTokenSecretKey` in `values.yaml` if
that ever needs to change.

**Current state:** `scenes.yaml` is an empty list and `themes/` is empty
(only a `.gitkeep`) as of this writing — all 32 `scene.*` entities on this
instance are synced in from the Philips Hue Bridge integration (`platform:
hue`), not HA's own Scene Editor, so there is no local YAML config backing
them; and no custom frontend theme is configured (`ha_manage_theme` reports
only the built-in `default` theme). Don't be surprised if these files stay
empty — they'll pick up content automatically once someone creates a
HA-native scene or theme through the UI, and the next sync run will commit
it.

**Out of scope:** Lovelace dashboards are stored as UI-managed
`.storage/lovelace*` JSON, not plain YAML, so they are *not* covered by this
sync (same reasoning the issue used to exclude `.storage/` in general).
Dashboard changes have to be made/tracked separately.

## Disaster recovery — restoring HA config from this repo

If `/opt/home_assistant/config` on `home-server` is lost or corrupted:

1. Stop the `homeassistant` container:
   ```bash
   docker compose stop homeassistant
   ```
2. Recreate the config directory and restore the static files that are
   *not* git-synced (these aren't in this repo — restore from the encrypted
   backup used for Postgres/InfluxDB, or reconfigure manually):
   - `.storage/` (UI registries: entities, devices, areas, users,
     Lovelace dashboards, `.storage/core.config`, long-lived tokens, etc.)
   - `secrets.yaml`
   - any custom `www/`, `custom_components/`, or integration-specific files
     not covered by this repo.
3. Copy the git-tracked files back onto the host:
   ```bash
   git clone --branch master https://github.com/Marvin1912/smart-home-infrastructure.git /tmp/sh-infra
   cp /tmp/sh-infra/home_assistant/configuration.yaml /opt/home_assistant/config/
   cp /tmp/sh-infra/home_assistant/automations.yaml   /opt/home_assistant/config/
   cp /tmp/sh-infra/home_assistant/scripts.yaml       /opt/home_assistant/config/
   cp /tmp/sh-infra/home_assistant/scenes.yaml        /opt/home_assistant/config/
   rm -rf /opt/home_assistant/config/themes
   cp -a  /tmp/sh-infra/home_assistant/themes         /opt/home_assistant/config/themes
   ```
4. Start HA back up and watch the logs for `!include` errors:
   ```bash
   docker compose up -d homeassistant
   docker compose logs -f homeassistant
   ```
5. Re-check entity/device/area assignments and any Lovelace dashboards —
   these come back from `.storage/` (step 2), not from this repo. Automations
   and scenes reference entity_ids, so if the `.storage/` restore is from an
   older backup than the git history, some references may be stale; fix
   those up in the UI and let the next `home-assistant-config-sync` run
   commit the corrected state.
6. Once HA is healthy, trigger the sync CronJob manually to confirm it can
   still push (`kubectl create job --from=cronjob/home-assistant-config-sync
   home-assistant-config-sync-manual -n default`).

This restores automations/scripts/scenes/themes with full git history and a
known-good rollback point; it does **not** replace a full backup of `.storage/`
or `secrets.yaml`, which still need their own backup story.
