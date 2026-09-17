# Índice de guías de reconstrucción

**Actualizado:** 2026-09-16  
**Propósito:** poder explicar y repetir la infraestructura usando el material del proyecto. Estas guías describen procedimientos; por sí solas no prueban que una tarea se haya ejecutado ni aprobado. El resultado real está en las evidencias de .agents/evidencias.

## Orden de trabajo

Última revalidación documentada de P5.2, 2026-09-16 14:01–14:03 UYT: el canal SSH/WinRM permitió capturar pre/postestado y verificar DC1/DC2 `running`, quorum 3/3, servicios AD/DNS y replicación `0/5` en ambos sentidos. DC2/VMID 102 se encontró detenida y se inició una vez para restaurar su estado operativo; no se modificó su configuración. Se agregaron en DC1 únicamente `postgres.pft.test` → `192.168.50.16` y `zabbix.pft.test` → `192.168.50.17`, y ambos DNS los resolvieron. Las relaciones GG→DL ya existían antes del cambio. P5.2 sigue Bloqueado por los miembros de los grupos globales, los valores y alcance de GPO y confirmar si se requiere reversa VLAN 100. No se modificaron red, ACL ni GPO. Los bloqueos de acceso previos quedan como historial.

La secuencia prevista está en ../orden de creacion.txt y en PLAN_DE_TRABAJO_UNIFICADO.md. El orden es P4.4 → P4.5 → P5.1 → P5.2 → P5.3. P4.4, P4.5 y P5.1 tienen evidencia de ejecución; P5.2 tiene inventario real y está parcialmente ejecutada, pero continúa Bloqueada. La referencia HTTP 401 a `/wsman` del 2026-09-15 y los fallos de conectividad son historial anterior; el 2026-09-16 se estableció WinRM a ambos DC por túneles SSH temporales. Se verificaron las zonas directa, `_msdcs` e inversa, OUs, grupos, GPO y replicación. Las cinco relaciones GG→DL estaban presentes; los cuatro GG consultados no tienen usuarios. Las cinco GPO PFT sólo tienen `GPT.INI` en SYSVOL, y `Get-GPOReport` devuelve `Error in the application`. Faltan población de GG, valores/alcance/filtros de GPO y decidir la reversa para VLAN 100. El reenviador externo DNS de P5.1 sigue pendiente y P5.3 no comenzó. La guía P5.2 distingue el diseño, los cambios aplicados y las decisiones aún abiertas.

Hay una diferencia cronológica que debe conservarse en cualquier defensa: el cierre original de P5.1 está fechado a las 12:48 UYT del 2026-09-15 y la prueba P4.5 comenzó a las 14:10 UYT del mismo día. Por lo tanto, la ejecución histórica no respetó el orden previsto. Después de P4.5 se revalidaron quorum, estado de DC1/DC2 y consultas SRV; no se volvieron a ejecutar dcdiag ni repadmin. Esos resultados corresponden al cierre original de P5.1. La revalidación posterior no cambia el orden en que se ejecutaron originalmente las tareas. Al reconstruir desde cero, seguir P4.4, luego P4.5 y recién después P5.1.

## Guías de Proxmox

| Archivo | Uso |
|---|---|
| [7. Proxmox/1. QDevice.txt](<7. Proxmox/1. QDevice.txt>) | Preparación del nodo QDevice descrita para P4.1. Incluye QNetd y el tercer miembro etcd del diseño. |
| [7. Proxmox/2. Proxmox.pdf](<7. Proxmox/2. Proxmox.pdf>) | Referencia visual existente para instalar los appliances PVE. |
| [2. Instalación PVE, complemento textual](<7. Proxmox/2. Instalacion de Proxmox - complemento textual.txt>) | Transcripción operativa de los valores legibles del PDF, para instalar PVE-1 y PVE-2. |
| [7. Proxmox/3. Sincronización hora PVEs.txt](<7. Proxmox/3. Sincronizacion hora PVEs.txt>) | Sincronización horaria PVE documentada en el proyecto. |
| [7. Proxmox/4. Pasar ISOs a Proxmox.txt](<7. Proxmox/4. Pasar ISOs a Proxmox.txt>) | Transferencia temporal de medios desde el host al almacenamiento PVE. |
| [7. Proxmox/5. Habilitar VMs anidadas.txt](<7. Proxmox/5. Habilitar VMs anidadas.txt>) | Preparación KVM anidada y prueba efímera descrita. P4.3 conserva limitaciones: no se ejecutaron P4T-PVE2, la prueba VM-a-VM ni el aprendizaje MAC de ambas VMs. |
| [7. Proxmox/6. Crear cluster PFT-CLUSTER y QDevice (P4.4).txt](<7. Proxmox/6. Crear cluster PFT-CLUSTER y QDevice (P4.4).txt>) | Guía de reproducción del clúster y el voto externo QDevice. La implementación P4.4 tiene evidencia aprobada. |
| [7. Proxmox/7. Prueba de caída y recuperación PVE (P4.5).txt](<7. Proxmox/7. Prueba de caida y recuperacion PVE (P4.5).txt>) | Guía de caída controlada, recuperación y comprobación de quorum. P4.5 tiene evidencia aprobada; no demuestra HA de VM ni replicación. |

## Guía de Active Directory y DNS

[8. Active Directory/1. AD DS y DNS redundante (P5.1).md](<8. Active Directory/1. AD DS y DNS redundante (P5.1).md>) describe DC1, DC2, la réplica inicial y el DNS del frontend. Distingue pasos de repetición de comandos históricos: el conjunto de evidencias guarda resultados y algunos comandos, pero no una transcripción íntegra de cada paso de instalación.

[8. Active Directory/2. DNS, OUs, grupos AGDLP y GPO base (P5.2).md](<8. Active Directory/2. DNS, OUs, grupos AGDLP y GPO base (P5.2).md>) recoge los objetivos del diseño y el procedimiento P5.2 con resultados reales. Ya se verificaron zonas, registros, OUs, grupos y replicación; los A de VIP `postgres` y Zabbix se agregaron conforme al plan y se probaron desde ambos DNS. Sigue Bloqueado porque faltan usuarios para los grupos GG, detalles de GPO y confirmar si se extiende DNS inverso a VLAN 100. No comenzar P5.3 automáticamente.

## Alcance del resto de configs INFRA

La auditoría encontró que 1. ADvIOS, 2. Servers, 3. AccvIOS, 4. DistvIOS, 5. Routers y 6. Alpine-SSHClient contienen principalmente configuraciones por equipo, imágenes o capturas. config Docker Spring API sí contiene un texto de instalación y referencias visuales. Esos materiales sirven como fuentes, pero no todos forman todavía un recorrido consolidado desde la creación de nodos hasta aceptación y rollback.

Este índice no convierte fragmentos de configuración en evidencia ni atribuye resultados no verificados. Para cada tarea adicional, completar su guía en la carpeta del componente después de contrastar el Plan, el runbook, los archivos de configuración y la evidencia real correspondiente. No usar las guías P4.4/P4.5/P5.1 como aprobación de los hitos anteriores de P0–P4.3.

## Actualización de la guía P5.2 — 2026-09-16

La captura inicial de PVE restituyó DC1/VMID 101 a `running`; después se verificó por PVE que DC1 y DC2 están `running` y que el clúster conserva 3/3. El canal WinRM temporal permitió completar inventario y pruebas P5.2. Sólo se agregaron los dos A que define el diseño y se conservaron pre/postestado y rollback. El estado actual y las decisiones pendientes se encuentran en el [control](../.agents/evidencias/P5/2026-09-15_P5.2_AD-DNS_control.md), [pre de cambios](../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_pre_cambios.txt), [post de cambios](../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_post_cambios.txt), [inventario](../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_inventario.txt), [prueba DNS](../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_prueba.txt), [replicación](../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_replication_prueba.txt) y [recuperación DC2](../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_recovery_prueba.txt). P5.2 sigue Bloqueado, y P5.3 permanece pendiente.
