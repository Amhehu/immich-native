cd /tmp
rm -rf immich-native
git clone https://github.com/arter97/immich-native
cd immich-native
./install.sh

systemctl restart immich
systemctl status immich
