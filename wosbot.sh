#!/data/data/com.termux/files/usr/bin/bash

set -e  # stop if any command fails

# Ensure proper environment paths
export PATH=$PREFIX/bin:$PATH

# Initial update & install essential packages
echo "📦 Updating package repositories..."
yes | pkg update
yes | pkg upgrade
yes | pkg install proot git termux-tools wget

# Confirm installation of required tools
for cmd in git wget proot; do
  if ! command -v $cmd > /dev/null 2>&1; then
    echo "❌ $cmd not installed properly. Exiting."
    exit 1
  fi
done

# Clean up any previous failed installations
echo "🧹 Cleaning up previous installation..."
rm -rf ~/ubuntu-in-termux

# Clone Ubuntu installer
echo "📥 Downloading Ubuntu installer..."
cd ~
git clone https://github.com/MFDGaming/ubuntu-in-termux.git
cd ubuntu-in-termux

# Ensure proper permissions
chmod +x ubuntu.sh

# Run Ubuntu installer with error checking
echo "🚀 Installing Ubuntu..."
./ubuntu.sh -y || {
    echo "❌ Ubuntu installation failed. Cleaning up..."
    cd ~
    rm -rf ubuntu-in-termux
    exit 1
}

# Verify ubuntu-fs directory exists
if [ ! -d "ubuntu-fs" ]; then
    echo "❌ ubuntu-fs directory not found. Installation failed."
    exit 1
fi

# Create required directories
mkdir -p ubuntu-fs/root
mkdir -p ubuntu-fs/etc

# Ensure resolv.conf exists
echo "nameserver 8.8.8.8" > ubuntu-fs/etc/resolv.conf

# Write Ubuntu setup script
echo "📝 Creating setup scripts..."
cat > ubuntu-fs/root/ubuntu_setup.sh << 'EOF'
#!/bin/bash

set -e

# Update package lists
apt-get update
apt-get upgrade -y

# Install required packages
DEBIAN_FRONTEND=noninteractive apt-get install -y curl nano python3 python3-venv python3-pip

# Setup WosBot
mkdir -p ~/wosbot && cd ~/wosbot
curl -o install.py https://raw.githubusercontent.com/whiteout-project/install/main/install.py

python3 -m venv venv
source venv/bin/activate

python3 install.py -y

if [ -f "main.py" ]; then
    python3 main.py
else
    echo "⚠️ main.py not found. Please check install.py output."
fi

nano bot_token.txt
EOF

# Write WosBot startup script
cat > ubuntu-fs/root/wosbot.sh << 'EOF'
#!/bin/bash

cd ~/wosbot
if [ -f "main.py" ]; then
    source ./venv/bin/activate
    python3 main.py --autoupdate
else
    echo "⚠️ main.py not found. Please run: python3 install.py"
fi
EOF

# Set proper permissions
chmod +x ubuntu-fs/root/ubuntu_setup.sh
chmod +x ubuntu-fs/root/wosbot.sh
chmod +x startubuntu.sh

echo ""
echo "✅ Ubuntu installed successfully!"
echo "➡️ Run './startubuntu.sh' to enter Ubuntu"
echo "➡️ Then run 'bash ubuntu_setup.sh' to set up WosBot"
