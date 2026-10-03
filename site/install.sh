#!/usr/bin/env bash
# Installs the latest websitino: curl https://trikko.github.io/websitino/install.sh | bash

echo ""

ARCH="$(uname -m)"

case "$OSTYPE" in
   linux*)
      case "$ARCH" in
         x86_64|amd64)  PACKAGE="linux/websitino";;
         aarch64|arm64) PACKAGE="linux-arm64/websitino";;
         *)
            echo "auto-install not supported on linux/$ARCH."
            exit 1
            ;;
      esac
      ;;
   darwin*)
      case "$ARCH" in
         arm64)  PACKAGE="macos-14/websitino";;
         x86_64) PACKAGE="macos-15-intel/websitino";;
         *)
            echo "auto-install not supported on macOS/$ARCH."
            exit 1
            ;;
      esac
      ;;
   msys*|cygwin*|win*)
      echo "auto-install not supported on windows. Download package here: https://trikko.github.io/websitino/windows/websitino.exe"
      exit 1
      ;;
   *)
      echo "$OSTYPE auto-install not supported."
      exit 1
      ;;
esac

bin_candidate=( "$HOME/.local/bin" "$HOME/.bin" "$HOME/bin" "/usr/local/bin" )
user_bin_dir=( )
sudo_bin_dir=( )

# Which dir is writable?
for p in "${bin_candidate[@]}"; do

   if [[ ":$PATH:" == *":$p:"* ]]
   then
      if [[ -w $p ]]
      then
         user_bin_dir+=("$p")
      else
         sudo_bin_dir+=("$p")
      fi;
   fi;

done;

# Trying user dir
if [[ ${#user_bin_dir[@]} -gt 0 ]]
then
   if curl -fsLo "${user_bin_dir[0]}/websitino" "https://trikko.github.io/websitino/$PACKAGE"
   then
      chmod +x "${user_bin_dir[0]}/websitino"
      echo "Installed: '${user_bin_dir[0]}/websitino'"
      exit 0
   else
      echo "Installation fail"
      exit 1
   fi;
fi;

# System dir
if [[ ${#sudo_bin_dir[@]} -gt 0 ]]
then
   echo "websitino will be installed in '${sudo_bin_dir[0]}'"

   if sudo curl -fsLo "${sudo_bin_dir[0]}/websitino" "https://trikko.github.io/websitino/$PACKAGE"
   then
      sudo chmod +x "${sudo_bin_dir[0]}/websitino"
      echo "Installed: '${sudo_bin_dir[0]}/websitino'"
      exit 0
   else
      echo "Installation fail"
      exit 1
   fi;
fi;

echo "Can't find a directory to install websitino. Please report this issue."
echo "You can download the binary package here: https://trikko.github.io/websitino/$PACKAGE"
exit 1
