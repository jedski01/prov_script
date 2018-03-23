#!/bin/bash

mysql -u root < /mariadb_config/mariadb_security_config.sql
mysql -u root < /mariadb_config/wp_mariadb_config.sql