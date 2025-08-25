#!/data/data/com.termux/files/usr/bin/bash

# This script installs the Whiteout-Project bot directly into Termux
# without needing an Ubuntu environment.

set -e  # Exit on first command failure

# 1. Update Termux and install required packages
# The -y flag automatically confirms all prompts.
echo "🔄 Updating Termux and installing required packages..."
pkg update -y
pkg upgrade -y
pkg install -y python python-pip git curl

# 2. Check for required packages
for cmd in python git curl; do
  if ! command -v $cmd > /dev/null 2>&1; then
    echo "❌ $cmd not installed properly. Exiting."
    exit 1
  fi
done
echo "✅ All required packages installed."

# 3. Create a directory and clone the project files
echo "📁 Setting up project directory..."
mkdir -p ~/wosbot && cd ~/wosbot
curl -o install.py https://raw.githubusercontent.com/whiteout-project/install/main/install.py

# 4. Create and activate a Python virtual environment
# This keeps the bot's dependencies separate from your main Termux environment.
echo "🐍 Creating and activating a virtual environment..."
python -m venv venv
source venv/bin/activate

# 5. Run the installation script
echo "🚀 Running the bot installation script..."
python install.py -y

# 6. Create a simple startup script for convenience
cat > wosbot.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# This script starts the bot with autoupdate
if [ -f "main.py" ]; then
  cd "$(dirname "$0")" # Go to script's directory
  source ./venv/bin/activate
  python main.py --autoupdate
else
  echo "⚠️ main.py not found. Please check your installation or run: python3 install.py."
fi
EOF

# 7. Make the startup script executable
chmod +x wosbot.sh

echo ""
echo "✅ Installation complete!"
echo "➡️ To start the bot, run the following commands:"
echo "   cd ~/wosbot"
echo "   ./wosbot.sh"

