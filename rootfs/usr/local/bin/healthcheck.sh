#!/bin/ash
  CMD=$(cat /run/command)
  case "${CMD}" in
    receiver)
      netstat -nlp | grep -qE "sshd -D -f"
    ;;

    sender)
      ps ax | grep -q "[/]sbin/inotifyd"
    ;;
  esac