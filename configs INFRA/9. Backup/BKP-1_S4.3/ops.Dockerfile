FROM alpine:3.24
RUN apk add --no-cache openssh-client py3-impacket socat
ENTRYPOINT ["sh"]
