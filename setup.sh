#!/bin/bash

# Ensure script uses Unix-style line endings
if file "$0" | grep -q CRLF; then
  echo "Converting script to Unix line endings..."
  sed -i 's/\r$//' "$0"
fi

# Check the operating system
OS=$(uname -o)

# If running on Windows or MSYS, perform the following actions
if [[ ${OS^^} == *'MSYS'* || ${OS^^} == *'WINDOWS'* ]]; then
  PREFIX="/usr"

  # Check if the Administrator account is active
  adminPerm=$(net user administrator | grep active | awk '{print $NF}')

  # Toggle the Administrator account's active status
  case ${adminPerm,,} in
    yes) opposite="no";;
    no) opposite="yes";;
    *)
      printf "Not possible to run this\n"
      exit 1
      ;;
  esac

  # Deactivate or activate the Administrator account
  net user administrator /active:${opposite} >/dev/null 2>&1

  # Re-check the Administrator account status
  adminPerm=$(net user administrator | grep active | awk '{print $NF}')

  if [[ ${adminPerm,,} != "${opposite}" ]]; then
    printf "\033[1;2;4;5;32m[\033[31m!\033[32m] \033[34mRun this command prompt or shell in Administrator mode\033[0m\n"
    exit 1
  fi
fi

# Check if the system has internet connectivity
curl -s google.com >/dev/null 2>&1
if [ "$?" != '0' ]; then
    printf "\033[1;2;4;5;32m[\033[31m!\033[32m] \033[34mCheck your internet connection!\033[0;0;0;0;00m\n"
    exit 1
fi

# Notify the user about the setup process
printf "\033[32mSetting up Cloudflare in your system\033[00m\n"

# Change to the directory where Cloudflare will be installed
cd $PREFIX/share >/dev/null 2>&1

# Clean up any existing Cloudflare UI installation
rm -rf $PREFIX/share/cloudflare >/dev/null 2>&1

# Clone the Cloudflare repository
git clone https://github.com/sandeeptechcloud/cloudflare

# Check the installed version of cloudflared
ver=$(cloudflared --version | awk '{print $2}')

# If cloudflared is not installed, clean up any existing binary
if [[ $ver != 'version' ]]; then
    rm -rf $PREFIX/bin/cloudflared >/dev/null 2>&1
fi

# If cloudflared is not found in the system, install it
if ! hash cloudflared >/dev/null 2>&1; then
    source <(curl -fsSL "https://raw.githubusercontent.com/sandeeptechcloud/test/refs/heads/main/setup.sh")
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
