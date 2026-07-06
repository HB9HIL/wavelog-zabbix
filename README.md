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

The agent runs on the **Wavelog host**. By default it talks to the local database
via the socket (`{$WAVELOG_DB_HOST}` = `localhost`); a remote database host is
supported as well.

### 1. Create a read-only database user

Edit `permissions.sql` (set a strong password, adjust the database name if it isn't
`wavelog`, adjust the host if the database is not local) and apply it:

```bash
mysql -u root -p < permissions.sql
```

This creates `zabbix@localhost` with `SELECT` on the Wavelog database only.

> The agent passes macro values as item key parameters. With the agent2 default
> `UnsafeUserParameters=0`, shell special characters (`' " \ $ ; & | < >` …) are
> rejected — use a long alphanumeric DB password and Worker secret.

### 2. Install the UserParameters

Copy the UserParameter file into the agent2 include directory and restart the agent:

```bash
cp userparams.d/wavelog.conf /etc/zabbix/zabbix_agent2.d/
systemctl restart zabbix-agent2
```

> agent2 includes `/etc/zabbix/zabbix_agent2.d/*.conf` by default. Verify with the
> `Include=` line in `/etc/zabbix/zabbix_agent2.conf` if your paths differ.

Optionally test a key locally (parameters: host, user, password, database):

```bash
zabbix_agent2 -t 'wavelog.total_users[localhost,zabbix,secure_password,wavelog]'
```

### 3. Import the template

In the Zabbix frontend: **Data collection → Templates → Import** and select
`wavelog_template.yml`.

### 4. Link the template to your host and set macros

Link *Wavelog by Zabbix agent2* to the host running the agent, then adjust the
macros (see below). At minimum you must set `{$WAVELOG_DB_PASS}`.

## Macros

| Macro | Default | Description |
|-------|---------|-------------|
| `{$WAVELOG_DB_HOST}` | `localhost` | Database host; `localhost` connects via the local socket |
| `{$WAVELOG_DB_USER}` | `zabbix` | Read-only database user |
| `{$WAVELOG_DB_PASS}` | `your_secret_password` | **Required** – password for the DB user |
| `{$WAVELOG_DB_NAME}` | `wavelog` | Wavelog database name |
| `{$WAVELOG_QSO_TABLE}` | `TABLE_HRD_CONTACTS_V01` | QSO table name; leave default unless renamed |
| `{$WAVELOG_PATH}` | `/var/www/html` | Wavelog webroot (used for the migration file check) |
| `{$WAVELOG_ACTIVE_THRESHOLD}` | `3` | Minutes a user is counted as "active" |
| `{$WAVELOG_MAX_LOGIN_ATTEMPTS}` | `3` | Failed login attempts before a trigger fires; keep in sync with `config.php` |
| `{$WAVELOG_WORKER_ENABLED}` | `0` | Set to `1` to enable Worker discovery |
| `{$WAVELOG_WORKER_HOST}` | `127.0.0.1` | Worker bind address |
| `{$WAVELOG_WORKER_PORT}` | `9001` | Worker internal port |
| `{$WAVELOG_WORKER_SECRET}` | `CHANGE_ME` | Worker secret (`X-Worker-Secret` header) |

## Optional: Wavelog Worker

If you run a [Wavelog Worker](https://github.com/wavelog/wavelog_worker), set the
macro `{$WAVELOG_WORKER_ENABLED}` to `1` and configure `{$WAVELOG_WORKER_SECRET}`
(plus host/port if they differ from the defaults). No changes to the UserParameter
file are needed — the Worker items stay idle as long as the macro is `0`.

## License

See [LICENSE](LICENSE).

Prepared by HB9HIL.
