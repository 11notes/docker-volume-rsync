#!/bin/ash
  if [ -z "${1}" ]; then
    elevenLogJSON warning "you must start this image either as receiver or sender"
    exit 1
  else
    echo "${1}" > /run/command
    
    case "${1}" in
      receiver)
        elevenLogJSON debug "ENV:SSH_PORT=${SSH_PORT}"

        if ! cat /.ssh/authorized_keys | grep -q "${SSH_AUTHORIZED_KEY}"; then 
          elevenLogJSON info "authorized key ${SSH_AUTHORIZED_KEY} added"
          echo "${SSH_AUTHORIZED_KEY}" >> /.ssh/authorized_keys
        fi

        sed -i 's/^Port.*/Port '${SSH_PORT}'/' /etc/ssh/sshd_config
        echo "${SSH_HOST_KEY}" > /etc/ssh/ssh_host_ed25519_key

        elevenLogJSON info "starting SSH on 0.0.0.0:${SSH_PORT}"
        set -- "/usr/sbin/sshd" \
          -D \
          -e;
      ;;

      sender)
        elevenLogJSON debug "ENV:MASK=${MASK}"
        elevenLogJSON debug "ENV:RSYNC_TRANSFER_DELAY=${RSYNC_TRANSFER_DELAY}"
        elevenLogJSON debug "ENV:SSH_HOST=${SSH_HOST}"
        elevenLogJSON debug "ENV:SSH_PORT=${SSH_PORT}"

        if ! cat /.ssh/known_hosts | grep -q "${SSH_KNOWN_HOSTS}"; then 
          elevenLogJSON info "known host ${SSH_KNOWN_HOSTS} added"
          echo "${SSH_KNOWN_HOSTS}" >> /.ssh/known_hosts
        fi
        echo "${SSH_PRIVATE_KEY}" > /.ssh/id_ed25519

        elevenLogJSON debug "starting directory rsync: ${APP_ROOT}/ ${APP_ROOT}"
        nq -q /usr/bin/rsync -az --delete --mkpath --rsh="ssh -p${SSH_PORT}" ${APP_ROOT}/ docker@${SSH_HOST}:${APP_ROOT}

        recurseinotifyd() {
          for d in ${1}/*; do
            if [ -d "$d" ]; then
              /sbin/inotifyd /usr/local/bin/io.sh $d:${MASK} &
              recurseinotifyd $d
            fi
            done
        }

        recurseinotifyd ${APP_ROOT}

        elevenLogJSON info "starting ${1}"
        set -- "/sbin/inotifyd" \
          /usr/local/bin/io.sh \
          ${APP_ROOT}:${MASK};
      ;;

      *)
        elevenLogJSON warning "${1} is not a valid command. you must start this image either as receiver or sender"
        exit 1
      ;;
    esac
  fi

  exec "$@"