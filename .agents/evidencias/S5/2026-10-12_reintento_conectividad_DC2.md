# Reintento de conectividad de DC2

**Fecha:** 2026-10-12  
**Proyecto GNS3:** `PFT-sprint2-preview1`  
**Nodo PVE:** `PVE-2`  
**VM:** `DC2` / VMID `102`  
**Objetivo:** descartar un fallo de switchport/VLAN antes de continuar con la validación Zabbix.

## Resultado

El primer reintento no fue exitoso: `DC2` no respondía por ICMP ni por TCP/10050. El diagnóstico final identificó que, después del reinicio de `PVE-2`, las VM `DC2` y `ZBX-1` habían quedado detenidas porque no tenían `onboot`. No se modificaron los switchports: la ruta de capa 2 está correctamente configurada.

## Evidencia de switches vía consola GNS3

### AccvIOS-1

- `Gi2/0` está `connected` y en VLAN de acceso `115 (BRANCH-SERVIDORES)`.
- `show interfaces Gi2/0 switchport`: modo administrativo y operativo `static access`.
- `show interfaces trunk`: `Gi0/1` y `Gi0/2` están en trunking, VLAN nativa 99, y ambos permiten VLAN 115.
- `show mac address-table interface Gi2/0` aprende:
  - `bc24.1113.3571` en VLAN 115 — MAC de `DC2`.
  - `bc24.1114.0ba5` en VLAN 115 — MAC de `ZBX-1`.

### DistvIOS-2

- `Vlan115` está `up/up` con `192.168.115.3`.
- HSRP de VLAN 115 está `Active` en este switch.
- ARP para `192.168.115.12` resuelve a `bc24.1113.3571`.
- Los trunks `Gi1/1` y `Gi1/2` están en trunking y permiten VLAN 115.

Esto descarta la hipótesis de que el fallo se deba a la ausencia de `switchport mode access` o a una VLAN 115 no permitida en los switches intermedios.

## Reintentos desde PVE-2

- `ping -c 3 -W 2 192.168.115.12`: **100% de pérdida**.
- `nc -zvw 2 192.168.115.12 10050`: **Connection timed out**.
- La VM 102 permanece encendida y conserva el disco existente de 60 GB configurado para arrancar desde `sata0`.

## Segundo reintento y aislamiento de la ruta

**Ventana:** 2026-10-12 19:40 UYT.

- Desde PVE-2, cuya dirección de gestión es `192.168.110.10/27`, la ruta a DC2 es `192.168.115.0/27 via 192.168.110.2 dev vmbr1`; el gateway de gestión respondió `1/1`.
- Desde PVE-2, `192.168.115.2` (DistvIOS-2, SVI activa) respondió `1/1` y `192.168.115.17` (ZBX-1) respondió `1/1`.
- Desde la consola real de DistvIOS-2, el comando `ping 192.168.115.12` devolvió **5/5 respuestas, 0 % de pérdida**, con RTT de 6–18 ms.
- Por tanto, la VLAN 115, el trunk, el ARP de DC2 y el enlace hacia el switch están operativos. La falta de respuesta sólo se reproduce desde el origen de gestión de PVE-2 (`192.168.110.10`) hacia DC2; no justifica cambiar los switchports.
- La consola serial de ZBX-1 está disponible, pero el agente invitado QEMU no está activo (`qm agent 301` no responde) y no se obtuvo una sesión de sistema válida en esta corrida; por eso no se sustituyó la evidencia histórica de Zabbix por una afirmación nueva.

## Consola de DC2

La consola QEMU de `DC2` muestra `QEMU (DC2)` y alcanza `C:\Windows\System32\LogonUI.exe`, con el usuario `PFT\Administrator` y la pantalla de bienvenida/autenticación. Por tanto, el sistema ya supera el arranque del disco; no se obtuvo todavía una sesión Windows operativa que permita comprobar el firewall, el agente Zabbix o el servicio de red.

## Persistencia y limpieza

- No se aplicaron cambios de switchport.
- No se ejecutó `write memory`, porque no hubo una corrección que persistir.
- Se eliminaron los recursos temporales de diagnóstico del QEMU de `PVE-2` (`hostfwdev` y `hostfw`, incluido el forward TCP local 5905). `info network` volvió a mostrar únicamente las interfaces `gns3-0` y `gns3-1`.

## Estado para Zabbix

La validación del ítem `eventlog[Security,,,,^4625$,,skip]` en `DC2` sigue sin poder repetirse desde PVE-2 porque TCP/10050 expira desde `192.168.110.10`. El siguiente punto a revisar es el propio Windows de `DC2` —perfil de red/firewall y servicio Zabbix Agent para ese origen—, no la configuración de los switchports. La prueba positiva desde DistvIOS-2 evita atribuir el fallo a la capa 2.

## Aislamiento agotado y corrección aplicada

**Ventana:** 2026-10-12, 20:00–20:32 UYT.

Las observaciones de esta sección corresponden al primer estado posterior al arranque de las VM. La revalidación posterior, cuando el agente terminó de inicializar, se documenta al final y prevalece para el estado actual.

- Tras el reinicio de `PVE-2`, `qm list` mostró `102 DC2 stopped` y `301 ZBX-1 stopped`. Con DC2 detenida, la prueba válida desde VLAN 115 (`192.168.115.30/27` temporal sobre `vmbr0`) devolvió `Destination Host Unreachable` y el vecino `192.168.115.12` quedó en `FAILED`.
- `192.168.115.30` sí alcanzó `192.168.115.2` con `3/3` respuestas. El switch registró la MAC de PVE en VLAN 115 y mantuvo la MAC de DC2 en VLAN 115. Esto descarta un fallo de `switchport mode access`, una VLAN permitida ausente o un trunk intermedio.
- Se ejecutó `qm start 102`. Después del arranque, el vecino de DC2 pasó a `REACHABLE` (`bc24.1113.3571`) y DistvIOS-2 volvió a obtener `5/5` respuestas ICMP hacia `192.168.115.12`.
- La prueba de origen PVE siguió dando `0/3` ICMP y timeout TCP/10050 desde `192.168.110.10`; desde el origen temporal `.30` la ARP quedó `REACHABLE`, pero ICMP y TCP/10050 no fueron aceptados. DistvIOS-2 mantiene ICMP positivo, mientras que su intento TCP/10050 también quedó en `Trying...`/timeout. Por tanto, tras corregir la disponibilidad de la VM, el remanente está en el invitado Windows —firewall y/o servicio Zabbix— y no en la capa 2. No se hizo un cambio destructivo en Windows sin una sesión autenticada y una regla identificada.
- La configuración de DC2 conservó el disco existente `sata0` de 60 GB; no se recreó ni se reemplazó el almacenamiento.

## Persistencia y estado final

- Se persistió `qm set 102 --onboot 1` para DC2 y se dejó `qm set 301 --onboot 1` para ZBX-1, evitando que un reinicio posterior de PVE vuelva a dejar ambos servicios apagados.
- `qm list` final: `102 DC2 running` y `301 ZBX-1 running`.
- Se restauró la ruta original de PVE-2: `192.168.115.12/32 via 192.168.110.2 dev vmbr1 src 192.168.110.10`.
- Se eliminó la IP temporal `192.168.115.30/27` de `vmbr0`; `vmbr0` quedó sin dirección IPv4 temporal.
- Se retiraron `hostfwdev` y `hostfw` del QEMU de PVE-2; `info network` volvió a mostrar sólo `gns3-0` y `gns3-1`, y no quedó el forward TCP local 5905.

La causa de la pérdida total reproducida quedó aislada: las VM de servicio estaban detenidas tras el reinicio de PVE y no tenían arranque automático. La disponibilidad de DC2 quedó corregida y persistida; la validación del agente y del valor histórico 4625 quedó completada posteriormente desde el origen real ZBX-1, como se documenta en `2026-10-12_validacion_evento_4625_DC2.md`.

## Revalidación posterior

**Ventana:** 2026-10-12 20:45–20:56 UYT.

- Con `DC2` y `ZBX-1` todavía `running`, `DistvIOS-2` obtuvo `5/5` respuestas ICMP a `192.168.115.12` y resolvió ARP `bc24.1113.3571` en `Vlan115`.
- Desde `DistvIOS-2`, `telnet 192.168.115.12 10050` abrió la conexión y ésta fue cerrada por el agente remoto: TCP/10050 está escuchando en DC2.
- Se añadió temporalmente `192.168.115.30/27` sobre `PVE-2/vmbr0` sólo para una prueba same-VLAN. Desde ese origen se obtuvo `3/3` ICMP y `nc -zvw 2 192.168.115.12 10050` devolvió `open`.
- Después de la prueba se eliminó la dirección global temporal y la ruta específica. `vmbr0` quedó sin IPv4 temporal y `ip route get 192.168.115.12` volvió a `via 192.168.110.2 dev vmbr1 src 192.168.110.10`.
- Desde la gestión de PVE (`192.168.110.10`) el TCP/10050 continúa expirando. Esto es una diferencia de política/origen en el recorrido enrutado, no un fallo de access VLAN, trunk ni ARP. La comprobación histórica posterior desde ZBX-1 se realizó dentro de la VM y confirmó `agent.ping=1`, `system.hostname=DC2-PFT` y seis filas del ítem 4625; no se sustituyó ese origen por la gestión de PVE.

La prueba same-VLAN confirma que el agente de DC2 responde y que el camino de capa 2 está sano. La causa inicial de aislamiento total fue la falta de arranque automático de las VM; la validación posterior desde ZBX-1 confirmó el agente y la persistencia histórica del evento `4625`.
