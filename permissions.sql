-- Create a dedicated user for Zabbix monitoring with read-only access to the wavelog database
-- Replace 'secure_password' with a strong password of your choice
-- If the database runs on a different host than the Zabbix agent, replace 'localhost'
-- with the host the agent connects from
CREATE USER IF NOT EXISTS 'zabbix'@'localhost' IDENTIFIED BY 'secure_password';

-- Grant read-only access to the wavelog database. Change database name if necessary
GRANT SELECT ON wavelog.* TO 'zabbix'@'localhost';

-- Apply the changes
FLUSH PRIVILEGES;
