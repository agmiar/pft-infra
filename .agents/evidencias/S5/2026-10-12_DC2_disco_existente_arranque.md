# DC2 — Corrección de arranque sobre el disco existente

**Fecha:** 2026-10-12, UYT.

## Cambio aplicado

- VM Proxmox de DC2: VMID `102`, alojada en PVE-2.
- Se retiró del hardware de la VM la ISO de instalación de Windows que estaba conectada como `ide2`.
- Se fijó el orden de arranque a `sata0`.
- Se conservó el disco existente sin recrearlo ni reemplazarlo: `local-lvm:vm-102-disk-0`, tamaño `60G`.
- La ISO `p5.1-drivers.iso` permanece conectada como `ide0`, pero no forma parte del orden de arranque.

## Verificación

- La VM quedó en estado `running` después de detenerla y arrancarla nuevamente.
- `qm config 102` mostró `boot: order=sata0` y el disco `sata0` de 60 GB.
- El monitor QEMU confirmó `drive-sata0` adjunto a `sata0` y no mostró `drive-ide2`.

La prueba de conectividad posterior se conserva separada de esta corrección: durante el intervalo de validación DC2 no respondió a ICMP ni a los puertos 10050, 445, 5985 y 3389; por tanto, esta evidencia confirma el arranque sobre el disco persistente, no la ingesta histórica de eventos 4625.
