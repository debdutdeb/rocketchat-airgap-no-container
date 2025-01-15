#!/bin/bash

set -e
set -o pipefail

readonly version="$1"

: ${version?version must be passed}

readonly tmpdir="$(mktemp -d)"

cleanup() {
	sudo rm -rf "$tmpdir"
	[[ -f rootfs.tar ]] && rm -rf rootfs.tar || :
	:
}

trap cleanup EXIT

error() {
	echo "[Error] $*" >&2
	exit 1
}

verify_command_exists() {
	command -v "$1" > /dev/null || error "command $1 doesn't exist, please install first"
}

info() {
	echo "[Info] $*"
}

main() {
	# TODO: use umoci or runc
	pushd $tmpdir

	local image="registry.rocket.chat/rocketchat/rocket.chat:$version"

	verify_command_exists docker

	info "pulling $image"

	docker pull $image

	info "generating final root filesystem"

	docker save $image > image.tar

	mkdir image

	tar xf image.tar -C image

	pushd image

	mkdir rootfs

	local manifest="$(jq -r '.manifests | .[] | .digest' < index.json | cut -d: -f2)"

	info "manifest hash $manifest"

	jq '.layers | .[] | .digest' -r < blobs/sha256/$manifest | cut -d: -f2 | xargs -I {} sudo tar --overwrite -xf blobs/sha256/{} -C rootfs

	local opq

	# opaques
	find rootfs -name ".wh..wh..opq" | while read -r opq; do
		pushd $(dirname $opq)
		sudo rm -rf *
		popd
	done


	local whiteout
	find rootfs -name '.wh.*' | while read whiteout; do
		echo "$whiteout" | sed 's|.wh.||' | xargs sudo rm -rf
		sudo rm -f "$whiteout"
	done

	popd
	popd

	tar -cf rootfs.tar -C $tmpdir/image/rootfs .

	tar -cf $version.tar rootfs.tar rocketchat.service start_rocketchat.sh install.sh
}

main "$@"
