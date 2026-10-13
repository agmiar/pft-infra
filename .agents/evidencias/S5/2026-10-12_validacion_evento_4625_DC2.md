# Validación Zabbix — evento Windows 4625 en DC2

**Fecha:** 2026-10-12 18:13 UYT.

## Resultado

**Validado desde ZBX-1:** el agente de DC2 responde desde el origen real del servidor Zabbix (`agent.ping=1`, `system.hostname=DC2-PFT`), el ítem `eventlog[Security,,,,^4625$,,skip]` está configurado y su tabla `history_log` contiene 6 registros. La prueba directa del ítem mediante `zabbix_get` devuelve `ZBX_NOTSUPPORTED` porque `eventlog` no se puede probar en modo pasivo individual; esto es una limitación del método de prueba, no un fallo de red ni del ítem activo.

Se intentó validar la cadena completa del evento `4625`: generar una autenticación fallida controlada, comprobar el evento en el registro `Security` de DC2 y consultar el ítem Zabbix `eventlog[Security,,,,^4625$,,skip]`.

## Precondiciones observadas

| Prueba | Resultado |
|---|---|
| PVE-2 → ZBX-1 `192.168.115.17` ICMP | 2/2 respuestas, 0 % de pérdida |
| PVE-2 → ZBX-1 TCP/80 | Abierto |
| PVE-2 → ZBX-1 TCP/10051 | Abierto |
| PVE-2 → DC2 `192.168.115.12` ICMP | 0/2 respuestas, 100 % de pérdida |
| PVE-2 → DC2 TCP/10050 | Timeout |
| QEMU Guest Agent de DC2 | No está ejecutándose |
| ZBX-1 → DC2 `agent.ping` | `1` |
| ZBX-1 → DC2 `system.hostname` | `DC2-PFT` |
| Ítem DC2 `eventlog[Security,,,,^4625$,,skip]` | Configurado; `itemid=70772`; 6 filas en `history_log` |
| Prueba puntual del `eventlog` con `zabbix_get` | `ZBX_NOTSUPPORTED` esperado en modo pasivo individual |

DC2 volvió a estar en ejecución y su arranque quedó persistido sobre el disco existente `sata0`. La ruta de switching se validó desde DistvIOS-2 (`5/5` ICMP) y el mismo origen abrió TCP/10050. Una prueba same-VLAN desde `192.168.115.30/27` obtuvo `3/3` ICMP y TCP/10050 `open`. El origen de gestión PVE (`192.168.110.10`) sigue expirando en TCP/10050, por lo que no se utiliza como sustituto del origen real ZBX-1. El agente ya no está aislado por capa 2; la disponibilidad desde ZBX-1 y la persistencia histórica del ítem quedaron verificadas en la validación posterior.

## Cierre

La configuración del ítem no se modificó. La consulta desde ZBX-1 confirmó transporte y hostname; la inspección local de la base de Zabbix confirmó el ítem exacto y seis registros de `history_log` para DC2. El `ZBX_NOTSUPPORTED` de `zabbix_get` se conserva como resultado esperado para un ítem `eventlog` en una comprobación pasiva individual. Se corrigió y persistió únicamente el arranque automático de las VM en PVE-2 y se limpiaron las rutas/recursos temporales de diagnóstico.

## Revalidación de conectividad del agente

**Fecha:** 2026-10-12 20:45–20:56 UYT.

| Origen | Prueba | Resultado |
|---|---|---|
| DistvIOS-2 (`192.168.115.3`) | ICMP a DC2 | `5/5` |
| DistvIOS-2 (`192.168.115.3`) | TCP/10050 a DC2 | `Open`; cierre remoto normal |
| PVE-2 same-VLAN (`192.168.115.30`, temporal) | ICMP a DC2 | `3/3` |
| PVE-2 same-VLAN (`192.168.115.30`, temporal) | TCP/10050 a DC2 | `open` |
| PVE-2 gestión (`192.168.110.10`) | TCP/10050 a DC2 | `Connection timed out` |

La dirección `192.168.115.30/27` y su ruta específica fueron retiradas después de la prueba. La diferencia entre el origen same-VLAN y el origen de gestión demuestra que la topología L2 no es la causa del fallo; la validación posterior desde la propia VM ZBX-1 completó el sondeo y documentó la persistencia histórica del ítem `4625`.

## Validación directa desde el origen real ZBX-1

**Fecha:** 2026-10-12 22:00–22:30 UYT.

Se restableció la contraseña de `root` de ZBX-1 directamente sobre su disco existente de 32 GiB (`local-lvm:vm-301-disk-0`), conservando la instalación y la configuración de la VM. Tras arrancar nuevamente la VM, el acceso por `qm terminal 301` fue confirmado hasta `zbx-1:~#`; la contraseña queda persistida en el sistema de archivos, no como cambio temporal de sesión. La VM quedó en estado `running`.

Desde ese prompt se ejecutó:

```text
zabbix_get -s 192.168.115.12 -k agent.ping
1

zabbix_get -s 192.168.115.12 -k system.hostname
DC2-PFT

zabbix_get ... -k eventlog[Security,,,,^4625$,,skip]
ZBX_NOTSUPPORTED: The "eventlog" key is not supported in test or single passive check mode
```

La evidencia de persistencia del ítem se obtuvo en la base local de Zabbix: para `DC2` (`hostid=10786`), el ítem `itemid=70772` conserva la clave exacta `eventlog[Security,,,,^4625$,,skip]`; la consulta de `history_log` devolvió `6` filas. El servidor Zabbix y su agente local permanecen activos, y no se dejaron montajes, loops ni rutas temporales del procedimiento de recuperación.
