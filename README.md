![Banner](https://github.com/11notes/defaults/blob/main/static/img/banner.png?raw=true)

# 🏔️ Alpine - volume rsync
![size](https://img.shields.io/docker/image-size/11notes/volume-rsync/stable?color=0eb305) ![version](https://img.shields.io/docker/v/11notes/volume-rsync/stable?color=eb7a09) ![pulls](https://img.shields.io/docker/pulls/11notes/volume-rsync?color=2b75d6)

**Sync a volume of two containers in real time, across the globe!**

![diagram](https://github.com/11notes/docker-volume-rsync/blob/main/diagram.png?raw=true)

# SYNOPSIS
**What can I do with this?** Create a sender and attach the volume you want to sync in real time, then create a receiver on the other side of the world and attach another volume. Both the sender volume will now be synced in real time on any file changes with the receiver volume via rsync. Since the sender can use any networking available to it, this works via Wireguard, Tailscale, Zerotier, you name it.

This image can help you synchronize your Traefik configuration in a HA pair or your Nginx www data as well as any other configuration or variable files for high-available file-based setups and configurations. Sync your Traefik ACME generated certs between multiple Traefik nodes.

# IMPORTANT
The sync direction is **unidirectional**, from sender to receiver. It will also delete all files in the receiver which are not present in the sender!

Since inotifyd is used to watch a directory and all files within, the sender container will spawn an inotifyd for each subfolder (recursive). If you have 200 subfolders, this will result in 200 inotifyd processes running in the sender! This image is not meant to sync thousands of files, there are better solutions for this which don’t work in *realtime*. Realtime file sync is very **expensive** in terms of CPU cycles and network bandwidth. Use with **care**! Each inotifyd uses about **64kB** of memory.

If you need to synchronize multiple volumes, simply use /rsync as your base path and mount as many volumes as you want. Do not forget that every directory needs to be owned by 1000:1000!

You can also local sync (no SSH) any volumes by using the RSYNC_LOCAL environment variables.

# COMPOSE
```yaml
services:
  chown:
    image: "11notes/chown:stable"
    container_name: "chown"
    environment:
      TZ: "Europe/Zurich"
    volumes:
      - "sender:/chown/sender"
      
  receiver1:
    image: "11notes/volume-rsync:stable"
    container_name: "receiver1"
    command: ["receiver"]
    environment:
      TZ: Europe/Zurich
      SSH_PORT: 8022
      SSH_AUTHORIZED_KEYS: |-
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICoR1q9aW+tGwQJLV1Yx23xHPDxtg3QnGhBlVoXFYmqZ sender:8022
      SSH_HOST_KEY: |-
        -----BEGIN OPENSSH PRIVATE KEY-----
        b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
        QyNTUxOQAAACCVvFZeNXWqIVpyVjZTzig0g5xCNkwWL4NRL5YBsWTIkQAAAJjiM55K4jOe
        SgAAAAtzc2gtZWQyNTUxOQAAACCVvFZeNXWqIVpyVjZTzig0g5xCNkwWL4NRL5YBsWTIkQ
        AAAEC68u0POEIVVWNw3dsUs4qOFmub3JL66ehRQZUfV8Qfq5W8Vl41daohWnJWNlPOKDSD
        nEI2TBYvg1EvlgGxZMiRAAAAEXJvb3RAYzFkNmZkODYyY2UzAQIDBA==
        -----END OPENSSH PRIVATE KEY-----
    volumes:
      - "receiver:/rsync"
    networks:
      - "rsync"
    restart: always

  receiver2:
    image: "11notes/volume-rsync:stable"
    container_name: "receiver2"
    command: ["receiver"]
    environment:
      TZ: Europe/Zurich
      SSH_PORT: 8022
      SSH_AUTHORIZED_KEYS: |-
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICoR1q9aW+tGwQJLV1Yx23xHPDxtg3QnGhBlVoXFYmqZ sender:8022
      SSH_HOST_KEY: |-
        -----BEGIN OPENSSH PRIVATE KEY-----
        b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
        QyNTUxOQAAACCVvFZeNXWqIVpyVjZTzig0g5xCNkwWL4NRL5YBsWTIkQAAAJjiM55K4jOe
        SgAAAAtzc2gtZWQyNTUxOQAAACCVvFZeNXWqIVpyVjZTzig0g5xCNkwWL4NRL5YBsWTIkQ
        AAAEC68u0POEIVVWNw3dsUs4qOFmub3JL66ehRQZUfV8Qfq5W8Vl41daohWnJWNlPOKDSD
        nEI2TBYvg1EvlgGxZMiRAAAAEXJvb3RAYzFkNmZkODYyY2UzAQIDBA==
        -----END OPENSSH PRIVATE KEY-----
    volumes:
      - "receiver:/rsync"
    networks:
      - "rsync"
    restart: always

  sender:
    image: "11notes/volume-rsync:stable"
    container_name: "sender"
    depends_on:
      receiver:
        condition: service_healthy
        restart: true
      chown:
        condition: service_completed_successfully
    command: ["sender"]
    environment:
      DEBUG: true
      TZ: Europe/Zurich
      SSH_HOSTS: |-
        receiver1:8022
        receiver2:8022
      SSH_KNOWN_HOSTS: |-
        [receiver1]:8022 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJW8Vl41daohWnJWNlPOKDSDnEI2TBYvg1EvlgGxZMiR
        [receiver2]:8022 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJW8Vl41daohWnJWNlPOKDSDnEI2TBYvg1EvlgGxZMiR
      SSH_PRIVATE_KEY: |-
        -----BEGIN OPENSSH PRIVATE KEY-----
        b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
        QyNTUxOQAAACAqEdavWlvrRsECS1dWMdt8Rzw8bYN0JxoQZVaFxWJqmQAAAJiEAwhChAMI
        QgAAAAtzc2gtZWQyNTUxOQAAACAqEdavWlvrRsECS1dWMdt8Rzw8bYN0JxoQZVaFxWJqmQ
        AAAEAIchARmgWd/hZQVvk0MZKTizC50zj89vsQRTSXsvKnFSoR1q9aW+tGwQJLV1Yx23xH
        PDxtg3QnGhBlVoXFYmqZAAAAEXJvb3RAZGUxYzU4ZTA0NTc2AQIDBA==
        -----END OPENSSH PRIVATE KEY-----
    tmpfs:
      - "/run/inotifyd:uid=1000,gid=1000"
    volumes:
      - "sender:/rsync"
    networks:
      - "rsync"
    restart: always

  sender.local:
    image: "11notes/volume-rsync:stable"
    container_name: "sender.local"
    depends_on:
      receiver:
        condition: service_healthy
        restart: true
      chown:
        condition: service_completed_successfully
    command: ["sender"]
    environment:
      DEBUG: true
      TZ: Europe/Zurich
      RSYNC_LOCAL_SOURCE: "/rsync/source"
      RSYNC_LOCAL_DESTINATION: "/rsync/destination"
    tmpfs:
      - "/run/inotifyd:uid=1000,gid=1000"
    volumes:
      - "sender.source:/rsync/source"
      - "sender.destination:/rsync/destination"
    networks:
      - "rsync"
    restart: always
volumes:
  receiver:
  sender:
  sender.source:
  sender.destination:
networks:
  rsync:
    internal: true
```

# DEFAULT SETTINGS
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user docker |
| `uid` | 1000 | user id 1000 |
| `gid` | 1000 | group id 1000 |
| `home` | /rsync | home directory of user docker |

# ENVIRONMENT
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Show debug information | |
| `RECEIVER:SSH_PORT` | TCP port of SSH daemon | 22 |
| `RECEIVER:SSH_AUTHORIZED_KEYS` | The public SSH keys of the senders |  |
| `RECEIVER:SSH_HOST_KEY` | The host key used for the SSH daemon |  |
| `SENDER:MASK` | The mask used for [inotifyd](https://wiki.alpinelinux.org/wiki/Inotifyd) | cdym |
| `SENDER:SSH_HOSTS` | The receivers IP:port or FQDN:port |  |
| `SENDER:SSH_KNOWN_HOSTS` | The public keys of the receivers SSH daemons (correlates to RECEIVER:SSH_HOST_KEY) |  |
| `SENDER:SSH_PRIVATE_KEY` | The private key of the sender (correlates to RECEIVER:SSH_AUTHORIZED_KEY) |  |
| `SENDER:RSYNC_TRANSFER_DELAY` | The delay in seconds between file events and the actual transfer (timeout) | 5 |
| `SENDER:RSYNC_DELETE` | Delete flag of rsync (set to "" if no mirror is needed) | --delete |
| `SENDER:RSYNC_LOCAL_SOURCE` | Local sync source (if set, no SSH will be used) |  |
| `SENDER:RSYNC_LOCAL_DESTINATION` | Local sync destination (if set, no SSH will be used)  |  |

# SOURCE

# BUILT WITH
* [alpine](https://alpinelinux.org)

# TIPS
* Use a reverse proxy like Traefik, Nginx to terminate TLS with a valid certificate
* Use Let’s Encrypt certificates to protect your SSL endpoints

# ElevenNotes<sup>™️</sup>
This image is provided to you at your own risk. Always make backups before updating an image to a new version. Check the changelog for breaking changes. You can find all my repositories on [github](https://github.com/11notes).
    