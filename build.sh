#!/bin/bash

# Exit on any error
# set -e

# Function to check if the script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "Please do not run this script as root"
  exit 1
fi

# Get the directory of the script
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Check if the script has been run today
LAST_UPDATE_FILE="/tmp/last_update_check"

# Update system if it hasn't been updated today
if [ ! -f "$LAST_UPDATE_FILE" ] || [ "$(date +%Y-%m-%d)" != "$(cat $LAST_UPDATE_FILE)" ]; then
  sudo apt-get update
  echo "$(date +%Y-%m-%d)" > "$LAST_UPDATE_FILE"
else
  echo "System already updated today"
fi

# Install necessary dependencies only if they are not already installed
declare -a packages=("build-essential" "libncurses5-dev" "libncursesw5-dev" "git" "python3" "rsync" "file" "wget")

for pkg in "${packages[@]}"; do
  if ! dpkg -l | grep -qw "$pkg"; then
    sudo apt-get install -y "$pkg"
  else
    echo "$pkg is already installed"
  fi
done

# Variables
OPENWRT_DIR=~/openwrt
CONFIG_FILE=".config"
SOURCE_FILE="$PWD/sign_event.c"
MIPS_BINARY="$PWD/sign_event_mips"
FEED_NAME="custom"
PACKAGE_NAME="secp256k1"
TARGET_DIR="bin/packages/*/*"

OPENWRT_DIR=~/openwrt
BUILD_DIR="$OPENWRT_DIR/build_dir/target-*/secp256k1-*/"
STAGING_DIR="$OPENWRT_DIR/staging_dir/target-*/"
TOOLCHAIN_DIR="$STAGING_DIR/toolchain-*/"

STAGING_DIR=$(pwd)/staging_dir
TOOLCHAIN_DIR=$STAGING_DIR/toolchain-mips_24kc_gcc-11.2.0_musl
export PATH=$TOOLCHAIN_DIR/bin:$PATH
export STAGING_DIR

# Make sure secp256k1 headers and libraries are available
SECP256K1_DIR="$LIB_DIR/secp256k1"
INCLUDE_DIR="$SECP256K1_DIR/include"
LIBS="-L$SECP256K1_DIR/.libs -lsecp256k1 -lgmp"

# Source file and output binary
SOURCE_FILE="$PWD/sign_event.c"
MIPS_BINARY="$PWD/sign_event_mips"

# Paths to secp256k1 library and include directories
INCLUDE_DIR="$STAGING_DIR/usr/include"
LIB_DIR="$STAGING_DIR/usr/lib"

# Set toolchain path
export PATH=$TOOLCHAIN_DIR/bin:$PATH

# Clone the OpenWrt repository if it doesn't exist
if [ ! -d "$OPENWRT_DIR" ]; then
  echo "Cloning OpenWrt repository..."
  git clone --depth 1 --branch v23.05.3 https://github.com/openwrt/openwrt.git $OPENWRT_DIR
  if [ $? -ne 0 ]; then
    echo "Failed to clone OpenWrt repository"
    exit 1
  fi
else
  echo "OpenWrt directory already exists."
fi

# Navigate to the existing OpenWrt build directory
cd $OPENWRT_DIR

# Copy configuration files
cp $SCRIPT_DIR/.config $OPENWRT_DIR/.config
cp $SCRIPT_DIR/feeds.conf $OPENWRT_DIR/feeds.conf

# Update and install all feeds
./scripts/feeds update -a
./scripts/feeds install -a

make -j$(nproc) toolchain/install
if [ $? -ne 0 ]; then
    echo "Toolchain install failed"
    exit 1
fi

# Copy configuration files again
cp $SCRIPT_DIR/.config $OPENWRT_DIR/.config
cp $SCRIPT_DIR/feeds.conf $OPENWRT_DIR/feeds.conf

# Verify if secp256k1 is set to true in .config
if ! grep -q "^CONFIG_PACKAGE_secp256k1=y" .config; then
  echo "After toolchain install, Error: secp256k1 is not set to true in the .config file."
  exit 1
fi

# Update the custom feed
echo "Updating custom feed..."
./scripts/feeds update custom

# Verify if secp256k1 is set to true in .config
if ! grep -q "^CONFIG_PACKAGE_secp256k1=y" .config; then
  echo "After custom update, Error: secp256k1 is not set to true in the .config file."
  exit 1
fi

# Install the secp256k1 package from the custom feed
echo "Installing secp256k1 package from custom feed..."
./scripts/feeds install $PACKAGE_NAME

# Check for feed install errors
if [ $? -ne 0 ]; then
    echo "Feeds install failed"
    exit 1
fi

# Verify if secp256k1 is set to true in .config
if ! grep -q "^CONFIG_PACKAGE_secp256k1=y" .config; then
  echo "After custom install, Error: secp256k1 is not set to true in the .config file."
  exit 1
fi

# Build the specific package
echo "Building the $PACKAGE_NAME package..."
make -j$(nproc) package/$PACKAGE_NAME/download V=s
if [ $? -ne 0 ]; then
    echo "$PACKAGE_NAME download failed."
    exit 1
fi

make -j$(nproc) package/$PACKAGE_NAME/check V=s
if [ $? -ne 0 ]; then
    echo "$PACKAGE_NAME check failed."
    exit 1
fi

make -j$(nproc) package/$PACKAGE_NAME/compile V=s
if [ $? -ne 0 ]; then
    echo "$PACKAGE_NAME compile failed."
    exit 1
fi

# Verify if secp256k1 is set to true in .config
if ! grep -q "^CONFIG_PACKAGE_secp256k1=y" .config; then
  echo "After compile, Error: secp256k1 is not set to true in the .config file."
  exit 1
fi

# Build the firmware
echo "Building the firmware..."
make -j$(nproc) V=s
if [ $? -ne 0 ]; then
    echo "Firmware build failed."
    exit 1
fi

# Find and display the generated IPK file
echo "Finding the generated IPK file..."
find $TARGET_DIR -name "*$PACKAGE_NAME*.ipk"

echo "OpenWrt build completed successfully!"

# Compile the sign_event program for MIPS architecture
echo "Compiling sign_event.c for MIPS architecture..."
mips-openwrt-linux-gcc -I$INCLUDE_DIR -o $MIPS_BINARY $SOURCE_FILE $LIBS -static

if [ $? -eq 0 ]; then
    echo "Compilation successful: $MIPS_BINARY"
else
    echo "Failed to compile sign_event.c for MIPS architecture."
    exit 1
fi

# Transfer the binary to the router
ROUTER_IP="192.168.8.1"
REMOTE_PATH="/tmp"
REMOTE_USER="root"
REMOTE_PASS="1"

# Check if the router is reachable
if ping -c 1 $ROUTER_IP &> /dev/null; then
  echo "Router is reachable. Proceeding with file transfer and execution..."

  echo "Transferring $MIPS_BINARY to the router..."
  scp $MIPS_BINARY $REMOTE_USER@$ROUTER_IP:$REMOTE_PATH/

  echo "Running $MIPS_BINARY on the router..."
  sshpass -p $REMOTE_PASS ssh $REMOTE_USER@$ROUTER_IP << EOF
chmod +x $REMOTE_PATH/$(basename $MIPS_BINARY)
$REMOTE_PATH/$(basename $MIPS_BINARY)
EOF

  echo "Done!"
else
  echo "Error: Router is not reachable. Skipping file transfer and execution."
fi

echo "Done!"

