#!/bin/ash
  elevenLogJSON debug "event: ${1}, dir: ${2}, file: ${3}"

  case "${1}" in
    x)
      elevenLogJSON debug "stopped watching directory ${2}:${MASK}"
      elevenLogJSON debug "starting directory rsync: ${2%/*}/ ${2%/*}"
        if [ ${RSYNC_TRANSFER_DELAY} -gt 0 ]; then nq -q sleep ${RSYNC_TRANSFER_DELAY}; fi
        nq -q /usr/bin/rsync -az --delete --mkpath --rsh="ssh -p${SSH_PORT}" ${2%/*}/ docker@${SSH_HOST}:${2%/*}
    ;;

    *)
      if [ -d "${2}/${3}" ]; then
        elevenLogJSON debug "starting to watch directory ${2}/${3}:${MASK}"
        /sbin/inotifyd /usr/local/bin/io.sh ${2}/${3}:${MASK} &
        
        elevenLogJSON debug "starting directory rsync: ${2}/${3}/ ${2}/${3}"
        if [ ${RSYNC_TRANSFER_DELAY} -gt 0 ]; then nq -q sleep ${RSYNC_TRANSFER_DELAY}; fi
        nq -q /usr/bin/rsync -az --delete --mkpath --rsh="ssh -p${SSH_PORT}" ${2}/${3}/ docker@${SSH_HOST}:${2}/${3}
      else
        elevenLogJSON debug "starting file rsync: ${2}/ ${2}"
        if [ ${RSYNC_TRANSFER_DELAY} -gt 0 ]; then nq -q sleep ${RSYNC_TRANSFER_DELAY}; fi
        nq -q /usr/bin/rsync -az --delete --mkpath  --rsh="ssh -p${SSH_PORT}"${2}/ docker@${SSH_HOST}:${2}
      fi
    ;;
  esac