# wavelog-zabbix

Zabbix template to monitor a [Wavelog](https://github.com/wavelog/wavelog) instance.

Metrics are read directly from the Wavelog MySQL/MariaDB database (via a read-only
user) and from the filesystem, using Zabbix agent2 UserParameters. Database
credentials are supplied as Zabbix macros. No changes to Wavelog itself are
required.

## What it monitors

- **Instance stats** – total QSOs, users, clubstations, station locations and logbooks, active users
- **Versions** – installed app version, available release, DB migration version vs. migration file (detects failed/pending migrations)
- **Cronjobs** – mastercron last run + per-cron discovery (status, enabled, last/next run) with health triggers
- **Users** – per-user discovery: callsign, e-mail, last seen, type, failed login attempts
- **CAT interfaces** – per-radio discovery: frequency, mode, power, operator, last used
- **Worker** *(optional)* – status, version, connected clients and topics of a [Wavelog Worker](https://github.com/wavelog/wavelog_worker)

## Requirements

- Zabbix Server/Frontend **7.4** (the template is exported in 7.4 format)
- **Zabbix agent2** installed on the Wavelog host
- `mysql` client available on the Wavelog host (the UserParameters shell out to it)
- Read access to the Wavelog webroot for the agent user (for the migration file check)

## Setup

The agent runs on the **Wavelog host** and talks to the local database.

### 1. Create a read-only database user

Edit `permissions.sql` (set a strong password, adjust the database name if it isn't
`wavelog`) and apply it:

```bash
mysql -u root -p < permissions.sql
```

This creates `zabbix@localhost` with `SELECT` on the Wavelog database only.

### 2. Install the UserParameters

Copy the UserParameter file into the agent2 include directory and restart the agent:

```bash
cp userparams.d/wavelog.conf /etc/zabbix/zabbix_agent2.d/
systemctl restart zabbix-agent2
```

> agent2 includes `/etc/zabbix/zabbix_agent2.d/*.conf` by default. Verify with the
> `Include=` line in `/etc/zabbix/zabbix_agent2.conf` if your paths differ.

Optionally test a key locally (parameters: user, password, database):

```bash
zabbix_agent2 -t 'wavelog.total_users[zabbix,secure_password,wavelog]'
```

### 3. Import the template

In the Zabbix frontend: **Data collection → Templates → Import** and select
`wavelog_template.yml`.

### 4. Link the template to your host and set macros

Link *Wavelog by Zabbix agent2* to the host running the agent, then adjust the
macros (see below). At minimum you must set `{$DB_PASS}`.

## Macros

| Macro | Default | Description |
|-------|---------|-------------|
| `{$DB_USER}` | `zabbix` | Read-only database user |
| `{$DB_PASS}` | `your_secret_password` | **Required** – password for the DB user |
| `{$DB_NAME}` | `wavelog` | Wavelog database name |
| `{$DB_HOST}` | `localhost` | Database host (informational; the agent connects via the local socket) |
| `{$QSO_TABLE}` | `TABLE_HRD_CONTACTS_V01` | QSO table name; leave default unless renamed |
| `{$WAVELOG_PATH}` | `/var/www/html` | Wavelog webroot (used for the migration file check) |
| `{$ACTIVE_THRESHOLD}` | `3` | Minutes a user is counted as "active" |
| `{$MAX_LOGIN_ATTEMPTS}` | `3` | Failed login attempts before a trigger fires; keep in sync with `config.php` |
| `{$WAVELOG_WORKER_ENABLED}` | `0` | Set to `1` to enable Worker discovery |
| `{$WAVELOG_WORKER_HOST}` | `127.0.0.1` | Worker bind address |
| `{$WAVELOG_WORKER_PORT}` | `9001` | Worker internal port |

## Optional: Wavelog Worker

If you run a [Wavelog Worker](https://github.com/wavelog/wavelog_worker):

1. Uncomment the two `wavelog.worker.*` UserParameters at the bottom of
   `userparams.d/wavelog.conf` and set your Worker secret.
2. Restart the agent.
3. Set macro `{$WAVELOG_WORKER_ENABLED}` to `1` (adjust host/port if needed).

## License

See [LICENSE](LICENSE).

Prepared by HB9HIL.
