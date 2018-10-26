#!/bin/bash

set -e

filestat="stat -c '%a'"
: ${CONFIGLOG:="s100000\nn6\nN3\nt86400\n!logwatcher"}
: ${SRCDIR:="/opt/numrp3/runit"}
: ${CFGDIR:="/opt/numrp3/build"}
: ${USEDHPARAM:-}

# if python2 not installed, make python3 as default
if [ ! -f /usr/bin/python ]; then
	ln -s /usr/bin/python3 /usr/bin/python
fi

set_logsvc() {
	if grep -P '^(?=exec)(?=.*svlogd)' $1; then
		if [ $2 == "mysql" ] || [ $2 == "postfix" ]; then
			mkdir -p /var/log/$2
			chown $2.$2 /var/log/$2
		fi
		echo -e $CONFIGLOG > /var/log/$2/config
	fi
}

set_svc() {
	# local sv=$1
	if [ $1 == "postgresql" ]; then
		: ${PGDATA:="/var/lib/postgresql/data"}
		#if [ -z "$(ls -A "$PGDATA")" ]; then
		if [ ! -d $PGDATA ]; then
			su-exec postgres /usr/bin/initdb
			sed -ri "s/^#(listen_addresses\s*=\s*)\S+/\1'*'/" "$PGDATA"/postgresql.conf
			: ${POSTGRES_USER:="postgres"}
			: ${POSTGRES_DB:=$POSTGRES_USER}
			if [ ! -z "$POSTGRES_PASSWORD" ]; then
				pass="PASSWORD '$POSTGRES_PASSWORD'"
				authMethod=md5
			else
				echo "==============================="
				echo "!!! Use \$POSTGRES_PASSWORD env var to secure your database !!!"
				echo "==============================="
				pass=
				authMethod=trust
			fi
			echo
			if [ "$POSTGRES_DB" != 'postgres' ]; then
				createSql="CREATE DATABASE $POSTGRES_DB;"
				echo $createSql | su-exec postgres /usr/bin/postgres --single -jE
				echo
			fi
			if [ "$POSTGRES_USER" != 'postgres' ]; then op=CREATE; else op=ALTER; fi
			userSql="$op USER $POSTGRES_USER WITH SUPERUSER $pass;"
			echo $userSql | su-exec postgres /usr/bin/postgres --single -jE
			{ echo; echo "host all all 0.0.0.0/0 $authMethod"; } >> "$PGDATA"/pg_hba.conf
		fi
	elif [ $1 == "mysql" ]; then
		: ${defaults:="--defaults-file"}
		: ${MYCNF:="/etc/$1/my.cnf"}
		if [ ! -f $MYCNF ]; then
			cp $CFGDIR/$(basename $MYCNF) $MYCNF
			mkdir -p $(dirname $MYCNF)"/conf.d"
		fi
		if [ ! -d /var/tmp/$1 ]; then
			mkdir /var/tmp/$1
			chown $1.$1 /var/tmp/$1
			chmod 777 /var/tmp
		fi

		# parameters
		: ${MYSQL_ROOT_PWD:="$1"}
		: ${MYSQL_USER:-}
		: ${MYSQL_USER_PWD:-}
		: ${MYSQL_USER_DB:-}

		if [ ! -d /var/lib/$1/$1 ]; then
			echo "[i] MySQL data directory not found, creating initial DBs"
			if [ ! -d /var/run/${1}d ]; then
				mkdir -p /var/run/${1}d
				chown -R $1.$1 /var/run/${1}d
			fi
			# init database
			echo 'Initializing database'
			mysql_install_db ${defaults}=${MYCNF} --user=$1 > /dev/null
			echo 'Database initialized'
			echo "[i] MySql root password: $MYSQL_ROOT_PWD"
			# create temp file
			tfile=`mktemp`
			if [ ! -f "$tfile" ]; then return 1; fi
			# save sql
			echo "[i] Create temp file: $tfile"
			cat << EOF > $tfile
USE $1;
FLUSH PRIVILEGES;
DELETE FROM mysql.user;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PWD' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PWD' WITH GRANT OPTION;
EOF
			# Create new database
			if [ "$MYSQL_USER_DB" ]; then
				echo "[i] Creating database: $MYSQL_USER_DB"
				echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_USER_DB\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile
				# set new User and Password
				if [ "$MYSQL_USER" ] && [ "$MYSQL_USER_PWD" ]; then
				echo "[i] Creating user: $MYSQL_USER with password $MYSQL_USER_PWD"
				echo "GRANT ALL ON \`$MYSQL_USER_DB\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_USER_PWD';" >> $tfile
				fi
			else
				# don`t need to create new database, Set new User to control all database.
				if [ "$MYSQL_USER" ] && [ "$MYSQL_USER_PWD" ]; then
				echo "[i] Creating user: $MYSQL_USER with password $MYSQL_USER_PWD"
				echo "GRANT ALL ON *.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_USER_PWD';" >> $tfile
				fi
			fi
			echo 'FLUSH PRIVILEGES;' >> $tfile
			# run sql in tempfile
			echo "[i] run tempfile: $tfile"
			/usr/bin/mysqld ${defaults}=${MYCNF} --user=$1 --bootstrap --verbose=0 < $tfile > /dev/null
			rm -f $tfile
		fi
	elif [ $1 == "nginx" ]; then
		if [ ! -f "/etc/$1/conf.d/default.conf.save" ]; then mv /etc/$1/conf.d/default.conf /etc/$1/conf.d/default.conf.save; fi
		if [ ! -f /etc/$1/conf.d/apptest.conf ]; then cp $CFGDIR/apptest.conf /etc/$1/conf.d/; fi
		if [ ! -d /etc/ssl/$1 ]; then
			mkdir -p /etc/ssl/$1
			chmod 755 /etc/ssl/$1
			if [ ! -z $USEDHPARAM ]; then /usr/bin/openssl dhparam -out /etc/ssl/$1/dhparam.pem 2048; fi
		fi
		if [ ! -d /run/$1 ]; then
			mkdir /run/$1
			#chown $1.$1 /run/$1
		fi
	elif [ $1 == "uwsgi" ]; then
		if [ ! -d /var/lib/nginx/html/wsgiapp ]; then
			mkdir -p /var/lib/nginx/html/wsgiapp/apptest
			cp $CFGDIR/apptest.py /var/lib/nginx/html/wsgiapp/apptest/
			chown -R $1.$1 /var/lib/nginx/html/wsgiapp
			chmod 755 /var/lib/nginx
		fi
		if [ ! -f /etc/$1/$1.ini.save ]; then
			mv /etc/$1/$1.ini /etc/$1/$1.ini.save
			cp $CFGDIR/$1.ini /etc/$1/$1.ini
			chown $1.$1 /etc/$1/$1.ini
			cp $CFGDIR/apptest.ini /etc/$1/conf.d/apptest.ini
			chown $1.$1 /etc/$1/conf.d/apptest.ini
		fi
		if [ ! -d /run/$1 ]; then
			mkdir /run/$1
			chown $1.$1 /run/$1
		fi
	elif [ $1 == "ssh" ]; then
    	# make sure we get fresh keys
    	rm -rf /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_dsa_key
    	ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
    	ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
		sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config
		# echo "root:tiger" | chpasswd
		sed -ie 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
		sed -ri 's/#HostKey \/etc\/ssh\/ssh_host_key/HostKey \/etc\/ssh\/ssh_host_key/g' /etc/ssh/sshd_config
		sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_rsa_key/HostKey \/etc\/ssh\/ssh_host_rsa_key/g' /etc/ssh/sshd_config
		sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_dsa_key/HostKey \/etc\/ssh\/ssh_host_dsa_key/g' /etc/ssh/sshd_config
		sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/g' /etc/ssh/sshd_config
		sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_ed25519_key/HostKey \/etc\/ssh\/ssh_host_ed25519_key/g' /etc/ssh/sshd_config
		/usr/bin/ssh-keygen -A
	fi
}

for i in $SRCDIR/*; do
	fn=`basename $i`
	#fn=$(basename $i)
	if [[ $fn =~ .*"_log" ]]; then
		svc=${fn%_*}
		mkdir -p /etc/sv/$svc/log
		cp $SRCDIR/$fn /etc/sv/$svc/log/run
		chmod +x /etc/sv/$svc/log/run
		set_logsvc $i $svc
	else
		mkdir /etc/sv/$fn
		cp $SRCDIR/$fn /etc/sv/$fn/run
		chmod +x /etc/sv/$fn/run
		ln -s /etc/sv/$fn /etc/service/
		set_svc $fn
	fi
done
