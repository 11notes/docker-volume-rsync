#!/bin/ash
  elevenLogJSON debug "event: ${1}, dir: ${2}, file: ${3}"

  inotifyd_queue(){
    find ${IODIR} -type f -not -newermt "-${RSYNC_TRANSFER_DELAY} seconds" -exec rm -f {} \;
    INOTIFYD_PATH=$(echo "${1}" | sed -e "s@\/@_@g")
    INOTIFYD_FILE="${IODIR}/${INOTIFYD_PATH}"
    if [ -f "${INOTIFYD_FILE}" ]; then
      elevenLogJSON debug "queue busy for ${1}"
      return 1
    fi
    elevenLogJSON debug "queue created for ${1}"
    touch ${INOTIFYD_FILE}
    return 0
  }  

  case "${1}" in
    x)
      elevenLogJSON debug "stopped watching directory ${2}:${MASK}"
    ;;

    *)
      if [ -d "${2}/${3}" ]; then
        elevenLogJSON debug "starting to watch directory ${2}/${3}:${MASK}"
        /sbin/inotifyd /usr/local/bin/io.sh ${2}/${3}:${MASK} &

        if inotifyd_queue "${2}/${3}"; then
          if [ ${RSYNC_TRANSFER_DELAY} -gt 0 ]; then nq -q sleep ${RSYNC_TRANSFER_DELAY}; fi
          for HOST in ${SSH_HOSTS}; do
            SSH_HOST=$(echo "${HOST}" | awk '{split($0,a,":"); print a[1]}')
            SSH_PORT=$(echo "${HOST}" | awk '{split($0,a,":"); print a[2]}')
            elevenLogJSON debug "starting directory rsync: ${2}/${3}/ ${2}/${3} for ${SSH_HOST}:${SSH_PORT}"
            nq -q /usr/bin/rsync -az --delete --mkpath --rsh="ssh -p${SSH_PORT}" ${2}/${3}/ docker@${SSH_HOST}:${2}/${3}
          done
        fi
      else
        if inotifyd_queue "${2}"; then
          if [ ${RSYNC_TRANSFER_DELAY} -gt 0 ]; then nq -q sleep ${RSYNC_TRANSFER_DELAY}; fi
          for HOST in ${SSH_HOSTS}; do
            SSH_HOST=$(echo "${HOST}" | awk '{split($0,a,":"); print a[1]}')
            SSH_PORT=$(echo "${HOST}" | awk '{split($0,a,":"); print a[2]}')
            elevenLogJSON debug "starting file rsync: ${2}/ ${2} for ${SSH_HOST}:${SSH_PORT}"
            nq -q /usr/bin/rsync -az --delete --mkpath  --rsh="ssh -p${SSH_PORT}" ${2}/ docker@${SSH_HOST}:${2}
          done  
        fi      
      fi
    ;;
  esac

  find ${NQDIR} -mmin +15 -type f -exec rm -f {} \;