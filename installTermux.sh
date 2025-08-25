#!/data/data/com.termux/files/usr/bin/bash

set -e  # stop if any command fails
set -x  # debug mode

# Initial setup
export PATH=$PREFIX/bin:$PATH
UBUNTU_FS="$HOME/ubuntu-in-termux/ubuntu-fs"

# Install required packages
pkg update -y && pkg upgrade -y
pkg install -y proot wget tar gzip

# Create base directory structure
cd $HOME
rm -rf ubuntu-in-termux
mkdir -p ubuntu-in-termux
cd ubuntu-in-termux

# Create essential directories
mkdir -p ubuntu-fs/{root,tmp,proc,sys,dev,etc,usr/{local/{bin,sbin},bin,sbin}}
chmod 1777 ubuntu-fs/tmp

# Download and setup Ubuntu
wget https://raw.githubusercontent.com/MFDGaming/ubuntu-in-termux/master/ubuntu.sh
chmod +x ubuntu.sh
./ubuntu.sh -y

# Configure DNS
echo "nameserver 8.8.8.8" > ubuntu-fs/etc/resolv.conf
echo "nameserver 8.8.4.4" >> ubuntu-fs/etc/resolv.conf

# Create startup script
cat > startubuntu.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
cd $(dirname $0)
unset LD_PRELOAD

# Setup command
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r ubuntu-fs"
command+=" -b /dev"
command+=" -b /proc"
command+=" -b /sys"
command+=" -b ubuntu-fs/root:/dev/shm"
command+=" -b ubuntu-fs/tmp:/tmp"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin"
command+=" TERM=$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"

# Execute
com="$@"
if [ -z "$1" ]; then
    exec $command
else
    $command -c "$com"
fi
EOF

chmod +x startubuntu.sh

# Create basic profile
cat > ubuntu-fs/root/.profile << 'EOF'
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export TERM=xterm-256color
export LANG=C.UTF-8
EOF

echo "✅ Installation complete!"
echo "➡️ Run './startubuntu.sh' to start Ubuntu"
