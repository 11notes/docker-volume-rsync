#!/bin/ash
  if [ -z "${1}" ]; then
    elevenLogJSON warning "you must start this image either as receiver or sender"
    exit 1
  else
    echo "${1}" > /run/command
    
    case "${1}" in
      receiver)
        for KEY in "${SSH_AUTHORIZED_KEYS}"; do
          if ! cat /.ssh/authorized_keys | grep -q "${KEY}"; then 
            elevenLogJSON info "authorized key ${KEY} added"
            echo "${KEY}" >> /.ssh/authorized_keys
          fi
        done

        sed -i 's/^Port.*/Port '${SSH_PORT}'/' /etc/ssh/sshd_config
        echo "${SSH_HOST_KEY}" > /etc/ssh/ssh_host_ed25519_key

        elevenLogJSON info "starting SSH on 0.0.0.0:${SSH_PORT}"
        set -- "/usr/sbin/sshd" \
          -D \
          -e;
      ;;

      sender)
        for HOST in "${SSH_KNOWN_HOSTS}"; do
          if ! cat /.ssh/known_hosts | grep -q "${HOST}"; then 
            elevenLogJSON info "known host ${HOST} added"
            echo "${HOST}" >> /.ssh/known_hosts
          fi
        done
    
        echo "${SSH_PRIVATE_KEY}" > /.ssh/id_ed25519

        elevenLogJSON debug "starting directory rsync: ${APP_ROOT}/ ${APP_ROOT}"
        for HOST in "${SSH_HOSTS}"; do
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