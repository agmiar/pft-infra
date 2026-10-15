BKP-1 — S4.3

Diseño local y austero:
- Appliance Docker GNS3 basado en Alpine/Samba.
- IP: 192.168.160.10/27.
- Gateway HSRP: 192.168.160.1.
- Share SMB: BKP.
- Volumen persistente GNS3: /srv/bkp.

Archivos del appliance:
- Dockerfile: imagen runtime del servicio.
- start-bkp.sh: dirección, ruta por defecto y arranque Samba.
- smb.conf: servicio y share restringido al segmento de backup.
- ops.Dockerfile: herramienta temporal de verificación; no es un nodo de producción.

Seguridad:
- El usuario técnico de Samba se introduce sólo en runtime.
- Las credenciales no se almacenan en este archivo ni en evidencias.
- La retención es manual por hitos; no se declara almacenamiento externo ni HA.

Evidencias:
- .agents/evidencias/S4/2026-09-25_S4.3_backup_control.md
- .agents/evidencias/S4/2026-09-24_S4.3_backup_pre.txt
- .agents/evidencias/S4/2026-09-24_S4.3_backup_prueba.txt
- .agents/evidencias/S4/2026-09-24_S4.3_backup_post.txt
- .agents/evidencias/S4/2026-09-24_S4.4_restore_control.md

## Verificación runtime — 2026-09-25

- BKP-1 mantuvo `192.168.160.10/27` y TCP/445 activo.
- El share `BKP` fue mapeado desde DC1 con resultado exitoso.
- System State de DC1 generó VHDX, `BackupSpecs.xml`, catálogo y XML de writers en `fresh/WindowsImageBackup/DC1-PFT/Backup 2026-09-25 130558/`.
- Se conservaron sin borrar los puntos `Backup 2026-09-25 125545/` y `fresh/WindowsImageBackup/DC1-PFT/Backup 2026-09-25 130558/`.
- El repositorio verificado mide aproximadamente 698.5 MiB en el árbol histórico y 27.8 MiB en el punto fresh.
- La salida final de `wbadmin get versions` queda preparada para la demostración porque la consola anidada no expuso una sesión Windows interactiva estable en este cierre.
- Evidencia: `.agents/evidencias/S4/2026-09-25_S4.3_backup_control.md`.
