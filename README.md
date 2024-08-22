![Banner](https://github.com/11notes/defaults/blob/main/static/img/banner.png?raw=true)

# 🏔️ Alpine Linux
![size](https://img.shields.io/docker/image-size/11notes/volume-rsync/0.1.0?color=0eb305) ![version](https://img.shields.io/docker/v/11notes/volume-rsync/0.1.0?color=eb7a09) ![pulls](https://img.shields.io/docker/pulls/11notes/volume-rsync?color=2b75d6) ![stars](https://img.shields.io/docker/stars/11notes/volume-rsync?color=e6a50e) [<img src="https://img.shields.io/badge/github-11notes-blue?logo=github">](https://github.com/11notes)

**Sync a volume of two containers in real time, across the globe!**

![diagram](https://github.com/11notes/docker-volume-sync/blob/main/static/diagram.png)

# SYNOPSIS
What can I do with this? Create a sender and attach the volume you want to sync in real time, then create a receiver on the other side of the world and attach another volume. Both the sender volume will now be synced in real time on any file changes with the receiver volume via rsync. Since the sender can use any networking available to it, this works via Wireguard, Tailscale, Zerotier, you name it.

# IMPORTANT
The sync direction is from sender to receiver **only**. It will also delete all files in the receiver which are not present in the sender!

Since inotifyd is used to watch a directory and all files within, the sender container will spawn a inotifyd for each subfolder (recursive). If you have 200 subfolders, this will result in 200 inotifyd processes running in the sender! This image is not meant to sync thousands of files, there are better solutions for this which don’t work in *realtime*. Realtime file sync is very **expensive** in terms of CPU cycles and network bandwidth. Use with **care**!

# VOLUMES
* **/rsync** - Directory of the volume that will be synced. Simply attach your volume to this path on both receiver and sender

# COMPOSE
```yaml
services:
  receiver:
    image: "11notes/volume-rsync"
    container_name: "receiver"
    command: ["receiver"]
    environment:
      TZ: Europe/Zurich
      SSH_PORT: 2222
      SSH_AUTHORIZED_KEY: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICoR1q9aW+tGwQJLV1Yx23xHPDxtg3QnGhBlVoXFYmqZ
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
    image: "11notes/volume-rsync"
    container_name: "sender"
    depends_on:
      receiver:
        condition: service_healthy
        restart: true
    command: ["sender"]
    environment:
      DEBUG: true
      TZ: Europe/Zurich
      SSH_HOST: receiver
      SSH_PORT: 2222
      SSH_KNOWN_HOSTS: receiver ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJW8Vl41daohWnJWNlPOKDSDnEI2TBYvg1EvlgGxZMiR
      SSH_PRIVATE_KEY: |-
        -----BEGIN OPENSSH PRIVATE KEY-----
        b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
        QyNTUxOQAAACAqEdavWlvrRsECS1dWMdt8Rzw8bYN0JxoQZVaFxWJqmQAAAJiEAwhChAMI
        QgAAAAtzc2gtZWQyNTUxOQAAACAqEdavWlvrRsECS1dWMdt8Rzw8bYN0JxoQZVaFxWJqmQ
        AAAEAIchARmgWd/hZQVvk0MZKTizC50zj89vsQRTSXsvKnFSoR1q9aW+tGwQJLV1Yx23xH
        PDxtg3QnGhBlVoXFYmqZAAAAEXJvb3RAZGUxYzU4ZTA0NTc2AQIDBA==
        -----END OPENSSH PRIVATE KEY-----
      RSYNC_TRANSFER_DELAY: 5
    volumes:
      - "sender:/rsync"
    networks:
      - "rsync"
    restart: always
volumes:
  receiver:
  sender:
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
| `MASK` | The mask used for [inotifyd](inotifydhttps://wiki.alpinelinux.org/wiki/Inotifyd) | cdnym |
| `RECEIVER:SSH_PORT` | TCP port of SSH daemon | 22 |
| `RECEIVER:SSH_AUTHORIZED_KEY` | The public SSH key of the sender |  |
| `RECEIVER:SSH_HOST_KEY` | The host key used for the SSH daemon |  |
| `SENDER:SSH_HOST` | The receiver IP or FQDN |  |
| `SENDER:SSH_PORT` | TCP port of receiver SSH daemon | 22 |
| `SENDER:SSH_KNOWN_HOSTS` | The public key of the receivers SSH daemon (correlates to RECEIVER:SSH_HOST_KEY) |  |
| `SENDER:SSH_PRIVATE_KEY` | The private key of the sender (correlates to RECEIVER:SSH_AUTHORIZED_KEY) |  |
| `SENDER:RSYNC_TRANSFER_DELAY` | The delay in seconds between file events and the actual transfer (timeout) | 0 |

# BUILT WITH
* [mimalloc](https://github.com/microsoft/mimalloc)
* [alpine](https://alpinelinux.org)

# TIPS
* Use a reverse proxy like Traefik, Nginx to terminate TLS with a valid certificate
* Use Let’s Encrypt certificates to protect your SSL endpoints

# ElevenNotes<sup>™️</sup>
This image is provided to you at your own risk. Always make backups before updating an image to a new version. Check the changelog for breaking changes. You can find all my repositories on [github](https://github.com/11notes).
    