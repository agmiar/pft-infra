FROM alpine:3.24

RUN apk add --no-cache bash iproute2 samba-server samba-client samba-common-tools

COPY smb.conf /etc/samba/smb.conf
COPY start-bkp.sh /usr/local/sbin/start-bkp.sh
RUN chmod 0755 /usr/local/sbin/start-bkp.sh && mkdir -p /srv/bkp

CMD ["/usr/local/sbin/start-bkp.sh"]
