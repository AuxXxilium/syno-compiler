FROM alpine:3.19 AS stage
ARG PLATFORMS="r1000nk:5.10.55 v1000nk:5.10.55 epyc7002:5.10.55 broadwellnkv2:4.4.302 broadwellntbap:4.4.302 geminilake:4.4.302 r1000:4.4.302 v1000:4.4.302 apollolake:4.4.302 denverton:4.4.302 purley:4.4.302 broadwell:4.4.302 geminilakenk:5.10.55 broadwellnk:4.4.302"
ARG TOOLKIT_VER="7.3"
ARG GCCLIB_VER="gcc1220_glibc236"

# Copy downloaded toolkits
ADD cache-7.3 /cache
# Extract toolkits
RUN for V in ${PLATFORMS}; do \
      echo "${V}" | while IFS=':' read PLATFORM KVER; do \
        echo -e "${PLATFORM}\t${KVER}" >> /opt/platforms && \
        echo "Extracting ds.${PLATFORM}-${TOOLKIT_VER}.dev.txz" && \
        mkdir "/opt/${PLATFORM}" && \
        tar -xaf "/cache/ds.${PLATFORM}-${TOOLKIT_VER}.dev.txz" -C "/opt/${PLATFORM}" --strip-components=9 \
          "usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib/modules/DSM-${TOOLKIT_VER}" && \
        echo "Extracting ${PLATFORM}-${GCCLIB_VER}_x86_64-GPL.txz" && \
        tar -xaf "/cache/${PLATFORM}-${GCCLIB_VER}_x86_64-GPL.txz" -C "/opt/${PLATFORM}" --strip-components=1; \
        KVER_MAJOR="`echo ${KVER} | rev | cut -d. -f2- | rev`"; \
        if [ ! -d "/opt/linux-${KVER_MAJOR}.x" -a -f "/cache/linux-${KVER_MAJOR}.x.txz" ]; then \
          echo "Extracting linux-${KVER_MAJOR}.x.txz" && \
          tar -xaf "/cache/linux-${KVER_MAJOR}.x.txz" -C "/opt"; \
          rm -rf /opt/${PLATFORM}/source && \
          ln -s /opt/linux-${KVER_MAJOR}.x /opt/${PLATFORM}/source; \
        fi; \
      done; \
    done

# Final image
FROM debian:12-slim
ENV SHELL=/bin/bash \
    ARCH=x86_64

RUN apt update --yes && \
    apt install --yes --no-install-recommends --no-install-suggests --allow-unauthenticated \
      ca-certificates nano curl bc kmod git gettext texinfo autopoint gawk sudo \
      build-essential make ncurses-dev libssl-dev autogen automake pkg-config libtool xsltproc gperf \
      flex bison libelf-dev libfile-fcntllock-perl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    useradd --create-home --shell /bin/bash --uid 1000 --user-group arc && \
    echo "arc ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/arc && \
    mkdir /output && chown 1000:1000 /output

COPY --from=stage --chown=1000:1000 /opt /opt
COPY files/ /

USER arc
WORKDIR /input
VOLUME /input /output

ENTRYPOINT ["/opt/do.sh"]
