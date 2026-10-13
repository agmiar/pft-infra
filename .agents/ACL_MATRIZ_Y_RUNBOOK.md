# Segmentación mínima S4 — matriz y runbook

**Estado:** Pendiente. Este documento no autoriza cambios hasta inventariar puertos, SVIs y preestado.

## Principios acordados

- No hay firewall appliance ni Windows Firewall en este laboratorio.
- No se aplica ACL a los enlaces de tránsito OSPF; se usa autenticación de vecinos.
- Las ACL son pocas, por frontera funcional, y se prueban antes de persistirlas.
- Nunca aplicar listas con IP/puerto marcadores. Si falta un dato, bloquear la tarea.

## Controles mínimos

| Origen | Destino | Control |
|---|---|---|
| VLAN 90/110 gestión | PVE-1/PVE-2 | Permitir SSH/8006 sólo desde gestión. |
| DC1, DC2, FS-HQ y PVE | BKP-1 | Permitir sólo protocolos de backup acordados. |
| VLAN 60 invitados | Redes RFC1918 corporativas | Denegar; permitir DNS/NAT externo según preestado. |
| WebUbuntuServer-1 | DC1/DC2 | Permitir DNS y LDAP interno requeridos por la API. |
| Usuarios | DC/DNS y FS-HQ | Permitir los flujos AD/DNS/SMB necesarios; no reducir RPC sin prueba. |

## Secuencia obligatoria

1. Guardar preestado y `startup-config` de Core/Dist; inventariar adjuntos ACL y quién es gateway activo.
2. Crear ACL sin adjuntar; revisar sintaxis y contadores en cero.
3. Aplicar una frontera por vez, desde consola local, con rollback preparado.
4. Ejecutar prueba permitida y denegada; registrar contadores.
5. Persistir sólo si ambas pruebas y conectividad AD/DNS funcionan.

## Rollback

Retirar exclusivamente la ACL nueva de la interfaz afectada y reponer el adjunto real capturado en preestado. No borrar listas ni cambiar OSPF, DHCP o interfaces como rollback genérico.

