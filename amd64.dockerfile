# :: Util
  FROM alpine as util

  RUN set -ex; \
    apk add --no-cache \
      git; \
    git clone https://github.com/11notes/util.git;

# :: Header
  FROM 11notes/alpine:stable
  COPY --from=util /util/linux/shell/elevenLogJSON /usr/local/bin
  ENV APP_ROOT=/rsync
  ENV APP_VERSION=stable
  ENV NQDIR=/run/nq
  ENV MASK=cdnym
  ENV RSYNC_TRANSFER_DELAY=1
  ENV SSH_PORT=22
  
# :: Run
  USER root

  # :: prepare image
    RUN set -ex; \
      apk --no-cache --update add \
        tini \
        rsync \
        inotify-tools \
        openssh \
        nq \
        openssl; \
      apk --no-cache --update upgrade; \
      mkdir -p ${APP_ROOT}; \
      mkdir -p /.ssh; \
      mkdir -p ${NQDIR}; \
      touch /.ssh/authorized_keys; \
      touch /.ssh/known_hosts; \
      touch /.ssh/id_ed25519; \
      chmod 0600 /.ssh/id_ed25519; \
      touch /etc/ssh/ssh_host_ed25519_key; \
      chmod 0600 /etc/ssh/ssh_host_ed25519_key; \
      usermod -s /bin/ash docker; \
      rm /etc/motd;

  # :: copy root filesystem changes and add execution rights to init scripts  
    COPY ./rootfs /
    RUN set -ex; \
      chmod +x -R /usr/local/bin; \
      chown -R 1000:1000 \
        /.ssh \
        /run \
        /etc/ssh \
        ${APP_ROOT};

# :: Monitor
  HEALTHCHECK --interval=5s --timeout=2s CMD /usr/local/bin/healthcheck.sh || exit 1

# :: Start
  USER docker
  ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]