#!/usr/bin/env bash
set -euo pipefail

ip addr flush dev eth0
ip addr add 192.168.160.10/27 dev eth0
ip route replace default via 192.168.160.1 dev eth0

mkdir -p /srv/bkp /var/log/samba
if ! id backup >/dev/null 2>&1; then
  adduser -D -H -s /sbin/nologin backup
fi

# Se crea una identidad local sin guardar ninguna credencial en el proyecto.
# La contraseña de demostración, si se necesita, se establece fuera del archivo
# mediante smbpasswd y queda sólo en la base de datos local del appliance.
if ! pdbedit -L 2>/dev/null | grep -q '^backup:'; then
  smbpasswd -a -n backup >/dev/null
fi
chown -R backup:backup /srv/bkp

exec smbd --foreground --no-process-group --debug-stdout
