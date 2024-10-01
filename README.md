# TollGateNostrToolKit

Run `./build_coordinator.sh` to build for all routers listed under
`./routers/*_config` using `./install_script.sh` to place
configurations from `./files/` into the filesystem of the
`sysupgrade.bin` file.


# Setup build environment from scratch
```
curl -sSL https://raw.githubusercontent.com/OpenTollGate/TollGateNostrToolKit/refs/heads/main/setup_from_scratch.sh | bash && passwd username && ssh username@localhost
```

Set password for user called `username`:
```
root@ubuntu-32gb-nbg1-1:~# passwd username
New password: 
Retype new password: 
passwd: password updated successfully
```

Login as non root user:
```
root@ubuntu-32gb-nbg1-1:~# ssh username@localhost
```

Run build script:
```
username@ubuntu-32gb-nbg1-1:~/TollGateNostrToolKit$ ./build_coordinator.sh 
Running setup_dependencies.sh
[sudo] password for username:
```

# Collecting logs
```
make -j$(nproc) V=sc > make_logs.md 2>&1
```



Usage: `./sign_event_local <message_hash> <private_key_hex>`


## Some basic documentation

- [Setup from Scratch](setup_from_scratch.md): Detailed instructions for setting up the build environment in a new VPS.

- [Updating Feeds Configuration in OpenWrt](updating_feeds_conf_in_openwrt.md): Guide on how to update the feeds configuration in OpenWrt.

- [Uploading Binaries to GitHub Releases](upload_binaries_to_github.md): Instructions for uploading binaries to GitHub releases without adding them to the git repository.

- [Setting DNS Server](setting_dns_server.md): Instructions for setting DNS server.

- [Find error in logs](find_error_in_logs.md): Commands for parsing through `build_logs.md` to find relevant lines.

- [Syncronize nodogsplash.conf with UCI](nodogsplash_configuration.md): nodogsplash gets its commands from `/etc/nodogsplash/nodogsplash.conf`, but the UCI commands modify `/etc/config/nodogsplash`. Logic is required to transfer the UCI settings to `nodogsplash.conf` on startup.

- [Squashing a diverged branch](squash_commits_since_main.md): squash all commits on current branch since the point where it diverged from main. This makes the branch easier to rebase onto main.

- [Updating Feeds Configuration in OpenWRT](updating_feeds_conf_in_openwrt.md): the feeds are used to specify which repos should be cloned and built when building openwrt.
