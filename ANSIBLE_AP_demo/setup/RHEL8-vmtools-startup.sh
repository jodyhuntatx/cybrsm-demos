sudo mount -t fuse.vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other
ls /mnt/hgfs
mkdir -p ~/Conjur
sudo mount /mnt/hgfs/Conjur ~/Conjur 
