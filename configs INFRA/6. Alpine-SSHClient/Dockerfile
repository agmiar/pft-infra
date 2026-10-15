FROM alpine:latest

RUN apk update && apk add --no-cache \
    openssh-client \
    bash \
    iproute2 \
    iputils

# Contraseña de root
RUN echo "root:gns3" | chpasswd

VOLUME ["/etc/network", "/root"]
CMD ["/bin/bash"]
