-- Create ERPNext database and user in MariaDB
CREATE DATABASE IF NOT EXISTS erpnext;
CREATE USER IF NOT EXISTS 'erpnext'@'%' IDENTIFIED BY 'erpnext_secure_2024_london!';
GRANT ALL PRIVILEGES ON erpnext.* TO 'erpnext'@'%';
FLUSH PRIVILEGES;

-- Create Bookstack database and user
CREATE DATABASE IF NOT EXISTS bookstack;
CREATE USER IF NOT EXISTS 'bookstack'@'%' IDENTIFIED BY 'bookstack_secure_2024_london!';
GRANT ALL PRIVILEGES ON bookstack.* TO 'bookstack'@'%';
FLUSH PRIVILEGES;
