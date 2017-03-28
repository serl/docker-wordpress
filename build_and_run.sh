#!/bin/bash

ValidHostnameRegex="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$"
here="$(dirname $(readlink -f "$0"))"

[ "$1" == 'debug' ] && cmd='bash' && shift

if [ "$1" == 'clean' ]; then
	[ -f "$here/hostnames" ] || exit
	hostnames="$(cat $here/hostnames)"
	echo "This copy has been configured for $hostnames."
	read -p "Do you want to delete everything? (it cannot be undone, sudo required) [yN] " -n 1 -r && echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		sudo rm -rf "$here/hostnames" "$here/output"
	fi
	exit
fi

if [ -f "$here/hostnames" ]; then
	hostnames="$(cat $here/hostnames)"
	hostname="${hostnames% *}"
	if [ $# -gt 0 ]; then
		echo "This copy has already been configured for $hostnames."
		echo "Run '$0' without arguments if you're happy with it; or '$0 clean' if you want to start over."
		exit
	fi
else
	if [ -z "$1" ] || ! [[ "$1" =~ $ValidHostnameRegex ]]; then
		echo "Usage: $0 [debug] <domain_name> [alternative_domain_name] ..."
		exit 1
	fi
	hostname="$1"
	hostnames="$hostname"
	shift
	for next_host in "$@"; do
		[[ "$next_host" =~ $ValidHostnameRegex ]] && hostnames="$hostnames $next_host"
	done
fi

read -p "Do you want to override $hostname with a local copy of WordPress? [yN] " -n 1 -r && echo
if ! [[ $REPLY =~ ^[Yy]$ ]]; then
	exit
fi
echo "$hostnames" > "$here/hostnames"

hosts_line="127.0.0.1 $hostnames"

echo "Adding the necessary line to /etc/hosts..."
echo $hosts_line | sudo tee -a /etc/hosts >/dev/null

mkdir -p "$here/output/www"
sudo docker build -t wordpress-image . &&
sudo docker run --sig-proxy=false \
	-p 127.0.0.1:80:80 \
	-e OVERRIDE_HOST="$hostname" \
	-v "$here"/output/www/:/var/www/html \
	-v "$here"/output/:/output \
	-v "$here"/tmp:/temporary \
	--name wordpress-image-running \
	-it --rm wordpress-image $cmd

echo "Cleaning /etc/hosts..."
sudo sed -i '/'"$hosts_line"'/d' /etc/hosts
