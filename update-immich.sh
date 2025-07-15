#!/bin/bash

if [[ $# -eq 1 ]]; then
  version="$1"

  echo "Upgrading to Version $version";

  cd /tmp
  rm -rf immich-native
  git clone https://github.com/arter97/immich-native
  cd immich-native

  sed -i "s/^REV=v.*/REV=v$version/" "install.sh"

  ./install.sh

  systemctl restart immich
  systemctl status immich
else
  echo "enter version (X.Y.Z) as argument"
fi
