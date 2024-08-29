#!/bin/bash

set -e

SCRIPT_DIR="$HOME/TollGateNostrToolKit"
OPENWRT_DIR="$HOME/openwrt"
cd $OPENWRT_DIR

# Clean the build environment
# echo "Cleaning the build environment..."
# make clean

cp $SCRIPT_DIR/feeds.conf $OPENWRT_DIR/feeds.conf

# Update the custom feed
echo "Updating custom feed..."
./scripts/feeds update -a

# Install the dependencies from the custom feed
echo "Installing dependencies from custom feed..."
./scripts/feeds install -a

# Copy configuration files again
cp $SCRIPT_DIR/routers/archer_c7_v2/.config $OPENWRT_DIR/.config

# Ensure toolchain directory exists
TOOLCHAIN_DIR="$OPENWRT_DIR/staging_dir/toolchain-mips_24kc_gcc-12.3.0_musl/host"
if [ ! -d "$TOOLCHAIN_DIR" ]; then
    echo "Creating missing toolchain directory: $TOOLCHAIN_DIR"
    mkdir -p "$TOOLCHAIN_DIR"
fi

make oldconfig


# Check for feed install errors
if [ $? -ne 0 ]; then
    echo "Feeds install failed"
    exit 1
fi


# Build the specific packages
# echo "Building libwebsockets..."
# make -j$(nproc) package/libwebsockets/download V=s
# make -j$(nproc) package/libwebsockets/check V=s
# make -j$(nproc) package/libwebsockets/compile V=s
# make -j$(nproc) package/libwebsockets/install V=s

# echo "Building secp256k1..."
# make -j$(nproc) package/secp256k1/download V=s
# make -j$(nproc) package/secp256k1/check V=s
# make -j$(nproc) package/secp256k1/compile V=s
# make -j$(nproc) package/secp256k1/install V=s

# echo "Building libwally..."
# make -j$(nproc) package/libwally/download V=s
# make -j$(nproc) package/libwally/check V=s
# make -j$(nproc) package/libwally/compile V=s
# make -j$(nproc) package/libwally/install V=s

# echo "Building gltollgate..."
# make -j$(nproc) package/gltollgate/download V=s
# make -j$(nproc) package/gltollgate/check V=s
# make -j$(nproc) package/gltollgate/compile V=s


echo "Build with dependencies before using them..."
make -j$(nproc) V=sc
if [ $? -ne 0 ]; then
   echo "Firmware build failed."
   exit 1
fi


# echo "Building nostr_client_relay..."
# make -j$(nproc) package/nostr_client_relay/download V=s
# make -j$(nproc) package/nostr_client_relay/check V=s
# make -j$(nproc) package/nostr_client_relay/compile V=s

# Build the firmware
# echo "Building the firmware..."
# make -j$(nproc) V=s
# if [ $? -ne 0 ]; then
#    echo "Firmware build failed."
#     exit 1
# fi

# Find and display the generated IPK file
echo "Finding the generated IPK file..."
TARGET_DIR="bin/packages/*/*"
find $TARGET_DIR -name "*secp256k1*.ipk"
find $TARGET_DIR -name "*libwebsockets*.ipk"
find $TARGET_DIR -name "*libwally*.ipk"
find $TARGET_DIR -name "*nodogsplash*.ipk"
# find $TARGET_DIR -name "*nostr_client_relay*.ipk"
# find $TARGET_DIR -name "*gltollgate*.ipk"

# cp /home/username/openwrt/staging_dir/target-mips_24kc_musl/root-ath79/usr/bin/generate_npub /home/username/TollGateNostrToolKit/generate_npub_with_debug
# cp /home/username/openwrt/build_dir/target-mips_24kc_musl/gltollgate-1.0/ipkg-mips_24kc/gltollgate/usr/bin/generate_npub /home/username/TollGateNostrToolKit/generate_npub_optimized

cp /home/username/openwrt/build_dir/target-mips_24kc_musl/gltollgate-1.0/ipkg-mips_24kc/gltollgate/usr/bin/generate_npub /home/username/TollGateNostrToolKit/generate_npub_optimized || {
   echo "Error: Failed to copy generate_npub to the TollGateNostrToolKit directory." >&2
   exit 1
}

echo "OpenWrt build completed successfully!"

