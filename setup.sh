#!/bin/bash

# Detecting OS and handling permission check only on Windows (MSYS/Windows environments)
OS=$(uname -o)
if [[ ${OS^^} == *'MSYS'* || ${OS^^} == *'WINDOWS'* ]]; then
  PREFIX="/usr"
  adminPerm=$(net user administrator | grep active | awk '{print $NF}')
  case ${adminPerm,,} in
    yes) opposite="no";;
    no) opposite="yes";;
    *) printf "Not possible to run this\n"; exit 1;;
  esac
  net user administrator /active:${opposite} >/dev/null 2>&1
  adminPerm=$(net user administrator | grep active | awk '{print $NF}')
  if [[ ${adminPerm,,} != "${opposite}" ]]; then
    printf "\033[31m[!] Run this command prompt or shell in Administrator mode.\033[0m\n"
    exit 1
  fi
fi

# Checking internet connectivity
curl -s google.com >/dev/null 2>&1
if [ "$?" != '0' ]; then
    printf "\033[1;31m[!] Check your internet connection!\033[0m\n"
    exit 1
fi

# Setting up Cloudflare UI
printf "\033[32mSetting up Cloudflare in your system...\033[0m\n"
cd $PREFIX/share >/dev/null 2>&1
rm -rf $PREFIX/share/cloudflare-ui >/dev/null 2>&1
git clone https://github.com/sandeeptechcloud/cloudflare.git

# Check if cloudflared is installed and if not, attempt to install
ver=$(cloudflared --version 2>/dev/null | awk '{print $2}')
if [[ $ver != 'version' ]]; then
    rm -rf $PREFIX/bin/cloudflared >/dev/null 2>&1
fi
if ! hash cloudflared >/dev/null 2>&1; then
    printf "\033[32mInstalling cloudflared...\033[0m\n"
    source <(curl -fsSL "https://raw.githubusercontent.com/sandeeptechcloud/test/refs/heads/main/setup.sh") || { echo "Cloudflared installation failed"; exit 1; }
fi

# Create a new cloudflare command in $PREFIX/bin
cat <<- 'VAR' > $PREFIX/bin/cloudflare
#!/bin/bash
arg1="$1"
arg2="$2"
arg3="$3"
cd $PREFIX/share/cloudflare-ui
bash cloudflare ${arg1} ${arg2} ${arg3}
VAR

# Make it executable
chmod +x $PREFIX/bin/cloudflare

# Final message
printf "\n\nConfiguration completed! Just run 'cloudflare --help' for help.\n\n"
