#!/bin/ash
  if [ -z "${1}" ]; then
    elevenLogJSON warning "you must start this image either as receiver or sender"
    exit 1
  else
    echo "${1}" > /run/command
    
    case "${1}" in
      receiver)
        echo "${SSH_AUTHORIZED_KEYS}" > /.ssh/authorized_keys
        echo "${SSH_HOST_KEY}" > /etc/ssh/ssh_host_ed25519_key
        sed -i 's/^Port.*/Port '${SSH_PORT}'/' /etc/ssh/sshd_config

        elevenLogJSON info "starting SSH on 0.0.0.0:${SSH_PORT}"
        set -- "/usr/sbin/sshd" \
          -D \
          -e;
      ;;

      sender)
        echo "${SSH_KNOWN_HOSTS}" > /.ssh/known_hosts    
        echo "${SSH_PRIVATE_KEY}" > /.ssh/id_ed25519

        elevenLogJSON debug "starting directory rsync: ${APP_ROOT}/ ${APP_ROOT}"
        for HOST in ${SSH_HOSTS}; do
          SSH_HOST=$(echo "${HOST}" | awk '{split($0,a,":"); print a[1]}')
          SSH_PORT=$(echo "${HOST}" | awk '{split($0,a,":"); print a[2]}')
          nq -q /usr/bin/rsync -az --delete --mkpath --rsh="ssh -p${SSH_PORT}" ${APP_ROOT}/ docker@${SSH_HOST}:${APP_ROOT}
        done

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