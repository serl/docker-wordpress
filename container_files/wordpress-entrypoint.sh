#!/bin/bash

function shutdown {
	echo "Shutting down container..."
	/etc/init.d/mysql stop
	sleep 3
	pkill -P $$
}

trap "shutdown" SIGHUP SIGINT SIGTERM

if ! [ -f index.php ]; then
	echo "Downloading and decompressing WordPress..." && \
	(cd /tmp && curl -O https://wordpress.org/latest.tar.gz) && \
	tar -xvzf /tmp/latest.tar.gz --strip-components=1 && \
	chown -R www-data:www-data .

	if [ ! -e .htaccess ]; then
		# NOTE: The "Indexes" option is disabled in the php:apache base image
		cat > .htaccess <<-'EOF'
			# BEGIN WordPress
			<IfModule mod_rewrite.c>
			RewriteEngine On
			RewriteBase /
			RewriteRule ^index\.php$ - [L]
			RewriteCond %{REQUEST_FILENAME} !-f
			RewriteCond %{REQUEST_FILENAME} !-d
			RewriteRule . /index.php [L]
			</IfModule>
			# END WordPress
		EOF
		chown www-data:www-data .htaccess
	fi

	cat > wp-config.php <<-'EOF'
		<?php
		define('DB_NAME', 'wordpress');
		define('DB_USER', 'root');
		define('DB_PASSWORD', 'easy');
		define('DB_HOST', '127.0.0.1');
		define('DB_CHARSET', 'utf8');
		define('DB_COLLATE', '');
		$table_prefix = 'wp_';
	EOF
	curl https://api.wordpress.org/secret-key/1.1/salt/ >> wp-config.php
	cat >> wp-config.php <<-'EOF'
		define('WP_DEBUG', false);
		if ( !defined('ABSPATH') )
			define('ABSPATH', dirname(__FILE__) . '/');
		require_once(ABSPATH . 'wp-settings.php');
	EOF

fi

/etc/init.d/mysql start
mysql --user=root --password=easy -e "CREATE DATABASE wordpress;"
[ -e /output/dump.sql ] && (mysql --user=root --password=easy wordpress < /output/dump.sql)
(while true; do sleep 30; mysqldump --user=root --password=easy wordpress > /output/dump.sql; echo "Database dumped!"; done) &

docker-php-entrypoint "$@"
shutdown
