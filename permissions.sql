-- create the zabbix user
CREATE USER IF NOT EXISTS 'zabbix'@'localhost' IDENTIFIED BY 'secure_password';

-- views for static queries
CREATE OR REPLACE VIEW zabbix_total_users AS 
SELECT count(user_id) AS total_users FROM users WHERE clubstation=0;

CREATE OR REPLACE VIEW zabbix_total_clubstations AS 
SELECT count(user_id) AS total_clubstations FROM users WHERE clubstation=1;

CREATE OR REPLACE VIEW zabbix_app_version AS 
SELECT option_value AS app_version FROM options WHERE option_name = 'version';

CREATE OR REPLACE VIEW zabbix_avail_version AS 
SELECT option_value AS avail_version FROM options WHERE option_name = 'latest_release';

CREATE OR REPLACE VIEW zabbix_mig_version AS 
SELECT version AS mig_version FROM migrations ORDER BY version DESC LIMIT 1;

CREATE OR REPLACE VIEW zabbix_total_locations AS 
SELECT count(station_id) AS total_locations FROM station_profile;

CREATE OR REPLACE VIEW zabbix_total_logbooks AS 
SELECT count(logbook_id) AS total_logbooks FROM station_logbooks;

-- view permissions
GRANT SELECT ON wavelog.zabbix_total_users TO 'zabbix'@'localhost';
GRANT SELECT ON wavelog.zabbix_total_clubstations TO 'zabbix'@'localhost';
GRANT SELECT ON wavelog.zabbix_app_version TO 'zabbix'@'localhost';
GRANT SELECT ON wavelog.zabbix_avail_version TO 'zabbix'@'localhost';
GRANT SELECT ON wavelog.zabbix_mig_version TO 'zabbix'@'localhost';
GRANT SELECT ON wavelog.zabbix_total_locations TO 'zabbix'@'localhost';
GRANT SELECT ON wavelog.zabbix_total_logbooks TO 'zabbix'@'localhost';

-- permissions for dynamic queries
GRANT SELECT (last_seen) ON wavelog.users TO 'zabbix'@'localhost';
GRANT SELECT (COL_PRIMARY_KEY) ON wavelog.TABLE_HRD_CONTACTS_V01 TO 'zabbix'@'localhost';

FLUSH PRIVILEGES;
