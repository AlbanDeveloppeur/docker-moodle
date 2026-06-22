#!/bin/sh

php /var/www/html/admin/cli/install.php \
    --wwwroot=http://localhost:8080 \
    --dataroot=/var/www/moodledata \
    --dbtype=$MOODLE_DB_TYPE \
    --dbhost=$MOODLE_DB_HOST \
    --dbname=$MOODLE_DB_NAME \
    --dbuser=$MOODLE_DB_USER \
    --dbpass=$MOODLE_DB_PASS \
    --dbport=$MOODLE_DB_PORT \
    --fullname='Moodle Practice' \
    --shortname='moodlepractice' \
    --adminuser=admin \
    --adminpass=!Azerty12345 \
    --adminemail=admin@example.com \
    --agree-license \
    --non-interactive
