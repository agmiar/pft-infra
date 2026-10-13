# T10 — Alertas y recuperación de clientes Windows

**Estado:** Aprobado.

**Fecha:** 2026-10-12, UYT.

## Procedimiento

- Se utilizó la API local de GNS3 para detener y volver a iniciar cada appliance, sin modificar sus discos ni su configuración de red.
- La comprobación de estado posterior confirmó `WIN-MGMT-HQ-01`, `WIN-MGMT-BR-01` y `PVE-2` en estado `started`.
- La alerta evaluada fue la específica de disponibilidad del agente del host: `Windows: Zabbix agent is not available (for 3m)`.

## WIN-MGMT-HQ-01

- Nodo GNS3: `9b3bf1d3-7dc3-4b9c-91fc-cb0f8892506b`; la detención y el arranque por API devolvieron HTTP 200.
- Desde ZBX-1, `zabbix_get -s 192.168.90.12 -k agent.ping` dejó de responder durante la caída.
- Zabbix registró el trigger `32735`, con eventos de problema `695`/`23209` y la descripción de indisponibilidad del agente.
- Tras iniciar nuevamente el nodo, `agent.ping` devolvió `1`; los eventos de recuperación `17978`/`23219` quedaron con valor `0`.

## WIN-MGMT-BR-01

- Nodo GNS3: `ee078982-7f01-4ec5-8215-b642f756286b`; la detención y el arranque por API devolvieron HTTP 200.
- Durante la caída, Zabbix registró el trigger `32758`, con eventos de problema `696`/`24429` y la descripción de indisponibilidad del agente.
- Tras completar el arranque de Windows, desde ZBX-1 se obtuvo `zabbix_get -s 192.168.110.11 -k agent.ping` = `1`.
- Los eventos de recuperación `17285`/`24437` quedaron con valor `0`.

## Resultado

T10 queda verificado para ambos clientes Windows: se generó la alerta real por caída controlada, se confirmó la recuperación desde el origen ZBX-1 y se conservaron los eventos de problema/recuperación en la base de Zabbix. Los nodos quedaron iniciados al cierre.

No se incluyen credenciales ni secretos en esta evidencia.
