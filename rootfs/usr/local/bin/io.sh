#!/bin/ash
  inotifyd_event_to_text(){
      case "${1}" in
        a)
          return "access"
        ;;
        c)
          return "modify"
        ;;
        e)
          return "meta"
        ;;
        w)
          return "close"
        ;;
        r)
          return "open"
        ;;
        D)
          return "delete"
        ;;
        M)
          return "removed"
        ;;
        u)
          return "unmount"
        ;;
        x)
          return "destroy"
        ;;
        y)
          return "move"
        ;;
        m)
          return "removed"
        ;;
        n)
          return "create"
        ;;
        d)
          return "delete"
        ;;
        *)
          return "${1}"
        ;;
      esac
  }

  INOTIFYD_EVENT=$(inotifyd_event_to_text ${1})
  elevenLogJSON debug "event: ${INOTIFYD_EVENT}, dir: ${2}, file: ${3}"
  
  case "${1}" in
    x)
      elevenLogJSON debug "stopped watching directory ${2}:${MASK}"
    ;;

    *)
      if [ -d "${2}/${3}" ]; then
        elevenLogJSON debug "starting to watch directory ${2}/${3}:${MASK}"
        /sbin/inotifyd /usr/local/bin/io.sh ${2}/${3}:${MASK} &

        if [ ${RSYNC_TRANSFER_DELAY} -gt 0 ]; then nq -q sleep ${RSYNC_TRANSFER_DELAY}; fi

        if [ -z "${RSYNC_LOCAL_SOURCE}" ]; then
          for HOST in ${SSH_HOSTS}; do
            SSH_HOST=$(echo "${HOST}" | awk '{split($0,a,":"); print a[1]}')
            SSH_PORT=$(echo "${HOST}" | awk '{split($0,a,":"); print a[2]}')
            elevenLogJSON debug "starting rsync for directory event: ${2}/${3}/ ${2}/${3} for ${SSH_HOST}:${SSH_PORT}"
            nq -q /usr/bin/rsync -aze ${RSYNC_OPT} ${RSYNC_DELETE} --mkpath --rsh="ssh -p${SSH_PORT}" ${2}/${3}/ docker@${SSH_HOST}:${2}/${3}
          done
        else
          elevenLogJSON debug "starting rsync for directory event: ${2}/${3}/ ${2}/${3}"
          nq -q /usr/bin/rsync -az ${RSYNC_OPT} ${RSYNC_DELETE} --mkpath ${RSYNC_LOCAL_SOURCE}/ ${RSYNC_LOCAL_DESTINATION}
        fi

      else
        if [ ${RSYNC_TRANSFER_DELAY} -gt 0 ]; then nq -q sleep ${RSYNC_TRANSFER_DELAY}; fi
        if [ -z "${RSYNC_LOCAL_SOURCE}" ]; then
          for HOST in ${SSH_HOSTS}; do
            SSH_HOST=$(echo "${HOST}" | awk '{split($0,a,":"); print a[1]}')
            SSH_PORT=$(echo "${HOST}" | awk '{split($0,a,":"); print a[2]}')
            elevenLogJSON debug "starting rsync for file event: ${2}/${3}/ ${2} for ${SSH_HOST}:${SSH_PORT}"
            nq -q /usr/bin/rsync -aze ${RSYNC_OPT} ${RSYNC_DELETE} --mkpath --rsh="ssh -p${SSH_PORT}" ${2}/ docker@${SSH_HOST}:${2}
          done 
        else
          elevenLogJSON debug "starting rsync for file event: ${2}/${3}/ ${2}/${3}"
          nq -q /usr/bin/rsync -az ${RSYNC_OPT} ${RSYNC_DELETE} --mkpath ${RSYNC_LOCAL_SOURCE}/ ${RSYNC_LOCAL_DESTINATION}
        fi     
      fi
    ;;
  esac

  find ${NQDIR} -mmin +15 -type f -exec rm -f {} \;