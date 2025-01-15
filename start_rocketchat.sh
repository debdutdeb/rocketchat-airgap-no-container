#!/bin/bash

mount -t proc none /opt/Rocket.Chat/rootfs/proc
mount --bind /dev /opt/Rocket.Chat/rootfs/dev
mount --bind /mnt /opt/Rocket.Chat/rootfs/mnt

export MONGO_URL=${MONGO_URL:-mongodb://localhost:27017/rocketchat?directConnection=true}
export ROOT_URL=${ROOT_URL:-http://localhost:3000}
export PORT=${PORT:-3000}

chroot /opt/Rocket.Chat/rootfs node /app/main.js
