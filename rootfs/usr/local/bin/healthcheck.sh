#!/bin/ash
  CMD=$(cat /run/command)
  case "${CMD}" in
    receiver)
      netstat -nlp | grep -qE "sshd"
    ;;

    sender)
      ps ax | grep -q "[/]sbin/inotifyd"
    ;;
  esac