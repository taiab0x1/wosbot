#!/data/data/com.termux/files/usr/bin/bash

set -e  # stop if any command fails
set -x  # debug mode

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

# Clone and run Ubuntu installer
cd ~
rm -rf ubuntu-in-termux
git clone https://github.com/MFDGaming/ubuntu-in-termux.git
cd ubuntu-in-termux
chmod +x ubuntu.sh

echo "🚀 Installing Ubuntu..."
./ubuntu.sh -y || {
    echo "❌ Ubuntu installation failed"
    exit 1
}

# Verify ubuntu-fs exists
if [ ! -d "ubuntu-fs" ]; then
    echo "❌ ubuntu-fs directory not found. Installation failed."
    exit 1
fi

# Create required directories
mkdir -p ubuntu-fs/root
mkdir -p ubuntu-fs/etc

# Write Ubuntu setup script
echo "📝 Creating setup scripts..."
cat > ubuntu-fs/root/ubuntu_setup.sh << 'EOF'
#!/bin/bash
set -e

# Update package lists
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y curl nano python3 python3-venv python3-pip git

# Setup WosBot
mkdir -p "$HOME/wosbot" && cd "$HOME/wosbot"
curl -o install.py https://raw.githubusercontent.com/whiteout-project/install/main/install.py

python3 -m venv venv
source venv/bin/activate
python3 install.py -y

if [ -f "main.py" ]; then
    echo "✅ WosBot installed successfully!"
    nano bot_token.txt
else
    echo "❌ main.py not found. Installation failed."
    exit 1
fi
EOF

# Write WosBot startup script
cat > ubuntu-fs/root/wosbot.sh << 'EOF'
#!/bin/bash

if [ -f "$HOME/wosbot/main.py" ]; then
    cd "$HOME/wosbot"
    source ./venv/bin/activate
    python3 main.py --autoupdate
else
    echo "❌ WosBot not found. Please run: bash ubuntu_setup.sh"
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
