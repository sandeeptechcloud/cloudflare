#!/bin/bash

# Termux-based script for setting up Cloudflare (cloudflared)

# Ensure script uses Unix-style line endings
if file "$0" | grep -q CRLF; then
  echo "Converting script to Unix line endings..."
  sed -i 's/\r$//' "$0"
fi

# Check if internet connectivity is available
curl -s google.com >/dev/null 2>&1
if [ "$?" != '0' ]; then
    printf "\033[1;2;4;5;32m[\033[31m!\033[32m] \033[34mCheck your internet connection!\033[0;0;0;0;00m\n"
    exit 1
fi

# Notify the user about the setup process
printf "\033[32mSetting up Cloudflare in your system\033[00m\n"

# Set the Termux prefix directory
PREFIX="$HOME/.termux"

# Change to the directory where Cloudflare will be installed
cd $PREFIX/share >/dev/null 2>&1

# Clean up any existing Cloudflare UI installation
rm -rf $PREFIX/share/cloudflare >/dev/null 2>&1

# Clone the Cloudflare repository
git clone https://github.com/sandeeptechcloud/cloudflare

# Check if cloudflared is already installed
ver=$(cloudflared --version | awk '{print $2}')

# If cloudflared is not installed, clean up any existing binary
if [[ $ver != 'version' ]]; then
    rm -rf $PREFIX/bin/cloudflared >/dev/null 2>&1
fi

# If cloudflared is not found, install it using Termux package manager
if ! hash cloudflared >/dev/null 2>&1; then
    echo "cloudflared not found, installing via Termux package manager..."
    pkg update -y
    pkg install cloudflared -y
fi

# Create a wrapper script for Cloudflare
cat <<- 'VAR' > $PREFIX/bin/cloudflare
#!/bin/bash
arg1="$1"
arg2="$2"
arg3="$3"
cd $PREFIX/share/cloudflare
bash cloudflare ${arg1} ${arg2} ${arg3}
VAR

# Make the wrapper script executable
chmod +x $PREFIX/bin/cloudflare

# Notify the user that the configuration is complete
printf "\n\nConfiguration completed. Just run 'cloudflare --help' for help\n\n"
