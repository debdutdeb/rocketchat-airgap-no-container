#!/bin/bash

readonly dir="/opt/Rocket.Chat"

[[ -d $dir ]] && { echo "[Error] $dir already exists" >&2; exit 1; }

mkdir -v $dir

cp start_rocketchat.sh $dir

mkdir $dir/rootfs

tar xf rootfs.tar -C $dir/rootfs

cp ./rocketchat.service /etc/systemd/system/rocketchat.service

systemctl daemon-reload
