# Requerimientos y TO-DO inicial — PFT-S1

**Estado:** documento de control inicial. Los responsables están pendientes de asignación; ningún ítem se considera realizado sin evidencia en [EVIDENCIAS_DE_IMPLEMENTACION.md](EVIDENCIAS_DE_IMPLEMENTACION.md).

## Requerimientos trazables

| ID | Requerimiento | Criterio de cierre | Evidencia | Responsable |
|---|---|---|---|---|
| RQ-01 | Ampliar VLAN 50 a `192.168.50.0/27` sin alterar las demás VLAN. | HSRP, OSPF y NAT usan `/27` en ambos lados y hay conectividad validada. | Inventario y pruebas de red. | Por asignar |
| RQ-02 | Aplicar únicamente las ACL normativas del runbook. | No quedan marcadores, cada SVI tiene el adjunto esperado y las pruebas pasan. | Configuración, contadores y pruebas ACL. | Por asignar |
| RQ-03 | Monitorear por Zabbix los servicios definidos y toda la infraestructura de red por SNMPv3. | Core, distribución, acceso, Border, ISP y red intermedia están sondeados; no hay end hosts en Zabbix. | Inventario Zabbix y sondeos. | Por asignar |
| RQ-04 | Mantener AD DS y DNS redundantes. | Ante la caída de un PVE, el DC restante resuelve DNS y atiende autenticación. | Prueba AD/DNS. | Por asignar |
| RQ-05 | Implementar PostgreSQL HA con Patroni como única autoridad de promoción. | Existe un solo `primary`; la VIP corresponde al primario y no hay failback automático. | Pruebas Patroni, VIP y reintegración. | Por asignar |
| RQ-06 | Mantener RPO 0 para transacciones confirmadas mediante réplica síncrona estricta. | La caída de la réplica bloquea escrituras y conserva lecturas; no se confirma escritura sin réplica sana. | Prueba de caída de réplica. | Por asignar |
| RQ-07 | Alcanzar RTO PostgreSQL de hasta 60 segundos ante caída del primario. | CRUD por VIP vuelve a operar dentro del umbral medido. | Cronometraje de failover y CRUD. | Por asignar |
| RQ-08 | Evitar doble escritor ante una partición de red. | La prueba de partición confirma un solo nodo aceptando escrituras. | `patronictl`, estado etcd y pruebas de escritura. | Por asignar |
| RQ-09 | Validar la capacidad de la ventana integrada. | No hay swap, se preservan 2–3 GB libres y CRUD/failover termina sin saturación atribuible a recursos. | Registro de capacidad de 10–15 min. | Por asignar |

## TO-DO ejecutable y secuencial

**Regla de ejecución.** Los paquetes se realizan en orden. Un paquete no se inicia mientras su precondición no esté aprobada. Cada fila debe tener responsable, fecha, resultado (`Aprobado`, `Fallido` o `Bloqueado`) y un enlace o ruta de evidencia en `EVIDENCIAS_DE_IMPLEMENTACION.md`. Si una comprobación revela una diferencia con el plano, detener y abrir un ítem correctivo: no adaptar una configuración sobre la marcha sin actualizar antes la fuente de verdad.

### P0 — Gobierno, resguardo y capacidad basal

| ID | Acción obligatoria | Precondición | Cierre / evidencia mínima |
|---|---|---|---|
| P0.1 | Asignar responsable de ejecución, revisión y aprobación a RQ-01…RQ-09; definir la ruta de evidencias. | Ninguna | Responsables, rutas y convención de nombres registrados. |
| P0.2 | Leer plano, runbook ACL, acuerdos de alcance y flujo de trabajo; confirmar exclusiones y SPOF aceptados. | P0.1 | Acta breve: HA lógica de servicios; sin WSUS, DHCP redundante, HA de VM, PITR, TLS, migración de aplicación/datos, monitoreo de frontend ni rotación/custodia de claves. |
| P0.3 | Respaldar `.gns3project`, `running-config` de red, configuración de VMs y discos/estado anterior recuperable. | P0.1 | Rutas, fecha y prueba de acceso al respaldo. No confundirlo con backup/PITR de PostgreSQL. |
| P0.4 | Verificar KVM, virtualización anidada, imágenes/ISOs soportadas y licencias; comprobar que las fuentes aprobadas resuelven la baseline (PVE 8.4.x, Ubuntu 24.04.4, PostgreSQL 16.15, Patroni 4.0.10, etcd 3.5.x, Keepalived 2.2.8 y Zabbix 7.0 LTS); crear discos QEMU independientes. | P0.3 | Salidas de KVM/nested y `apt-cache policy`/equivalente, inventario/versiones/ISO hash y nombres de discos; ningún qcow2 se comparte entre nodos. Si una fuente no ofrece la versión prevista, no instalar una alternativa sin abrir decisión correctiva. |
| P0.5 | Validar desde un host temporal la salida única por Border NAT hacia repositorios oficiales HTTPS y NTP externo. Tras crear AD, los clientes usarán AD DNS y sólo el PDC sincronizará NTP externo. | P0.4 | Evidencia de conectividad; sin DNS público en clientes ni rutas/proxies alternativos. |
| P0.6 | Medir línea base de RAM, swap, disco, CPU e I/O; reservar 2–3 GB RAM y 30 GB de disco. | P0.5 | Registro de capacidad basal y decisión de continuar/reducir carga. |
| P0.7 | Definir ventana, criterio de aborto, cronómetro para fallos y plan de rollback por paquete. | P0.3 | Ventana aprobada y rollback identificado para red, ACL, servicios y cliente de prueba DMZ. |

### P1 — Inventario real y compuertas técnicas

| ID | Acción obligatoria | Precondición | Cierre / evidencia mínima |
|---|---|---|---|
| P1.1 | Capturar en ambos Core SVI, HSRP, OSPF, trunks, EtherChannel, STP, ACL adjuntas y `NAT_INSIDE`; capturar NAT en ambos Border. | P0 completo | Salidas `show` fechadas y respaldos específicos por equipo. |
| P1.2 | Inventariar interfaz, IP/máscara, gateway, VLAN, rol y versión de todos los nodos implicados. | P1.1 | Tabla real de topología y direccionamiento; discrepancias abiertas como ítems correctivos. |
| P1.3 | Confirmar IP estática, gateway, DNS y VLAN 100 de `WebUbuntuServer-1`. | P1.2 | `ip -br address`, rutas y prueba de pertenencia a DMZ. Sin esto no se aplican ACL ni Patroni para Web. |
| P1.4 | Inventariar IP de gestión y estado SNMPv3 de Core, distribución, acceso, Border, ISP y red intermedia. | P1.2 | Inventario sin secretos; lista cerrada de objetivos permitidos para Zabbix. |
| P1.5 | Confirmar puertos reales para PVE-1, PVE-2, trunk Dist1–Dist2, QDevice y clientes Windows; confirmar que no existen conflictos IP o leases sobre IP estáticas. | P1.2 | Mapa cableado/interfaz aprobado y lista de conflictos resueltos. |
| P1.6 | Validar marcadores de ACL/NTP y el registro manual externo de contraseñas. TLS/certificados, vault, rotación y custodia formal no se implementan. | P1.3, P1.4 | Ningún placeholder llega a equipo real; contraseñas fuera de Markdown/evidencias y exclusiones registradas. |

### P2 — Capa 2, direccionamiento, enrutamiento, NAT y DHCP

| ID | Acción obligatoria | Precondición | Cierre / evidencia mínima |
|---|---|---|---|
| P2.1 | Configurar trunk Dist1–Dist2 con VLAN 50/99 y puertos access VLAN 50 para PVE; configurar puerto VLAN 90 de QDevice. | P1.5 | `show interfaces trunk`, `show spanning-tree vlan 50` y puertos operativos sin loop inesperado. |
| P2.2 | Ampliar Vlan50 a `/27` en ambos Core, actualizar OSPF y cambiar `NAT_INSIDE` a wildcard `0.0.0.31` en ambos Border. | P2.1 y ventana aprobada | HSRP, vecinos OSPF, ruta `/27` y NAT funcionales; demás VLAN sin cambios. |
| P2.3 | Actualizar DHCP en CorevIOS-1: exclusión `.1-.30` de VLAN 50, DNS `.12/.13` y sufijo `pft.test` en los pools aplicables. | P2.2 | Configuración y bindings sin colisiones; no hay pool para VLAN 50/100. |
| P2.4 | Probar HSRP, conectividad inter-VLAN permitida, trunk/STP y continuidad tras failover HSRP controlado. | P2.2, P2.3 | Resultados y tiempos; RQ-01 aprobado. |
| P2.5 | Si P2.1–P2.4 fallan, restaurar puertos, `/29`, OSPF y NAT desde respaldo antes de investigar. | Resultado fallido | Rollback documentado y estado estable restaurado. |

### P3 — ACL funcionales y segmentación

| ID | Acción obligatoria | Precondición | Cierre / evidencia mínima |
|---|---|---|---|
| P3.1 | Instanciar las ACL `PFT_*` del runbook con IP real de Web y de gestión; confirmar necesidad del rango RPC AD. | P1.3, P1.4, P1.6, P2.4 | ACL sin marcadores, revisada contra matriz de flujos. |
| P3.2 | Cargar ACL nuevas sin adjuntarlas y verificar sintaxis, nombres y contadores iniciales. | P3.1 | Salida `show access-lists PFT_*`. |
| P3.3 | Sustituir adjuntos SVI en un Core por vez; retirar exactamente los filtros anteriores de VLAN 100 antes de adjuntar una única ACL de entrada. | P3.2 | Captura pre/post de cada SVI; una ACL IP por dirección. |
| P3.4 | Ejecutar pruebas ACL positivas, negativas, contadores y failover HSRP; repetir en el segundo Core antes de guardar. | P3.3 | Evidencias del runbook sección 6, incluidos denies de Guests/DMZ y administración PVE. |
| P3.5 | Confirmar explícitamente que tráfico local VLAN 50 no queda cubierto por ACL SVI; no declararlo segmentado. | P3.4 | Nota de límite aceptado o diseño adicional de control de host/L2 aprobado fuera de este hito. |
| P3.6 | Si falla una prueba, restaurar los adjuntos reales de ese Core; no suponer simetría entre CorevIOS-1 y CorevIOS-2. | Resultado fallido | Rollback comprobado; RQ-02 aprobado sólo tras P3.4. |

### P4 — QDevice, Proxmox y quorum

| ID | Acción obligatoria | Precondición | Cierre / evidencia mínima |
|---|---|---|---|
| P4.1 | Crear QDevice Debian `.90.28`, instalar `corosync-qnetd` y el tercer miembro etcd; validar VLAN 90 y tiempo. | P2.4 | Conectividad, servicio QNetd y etcd preparados; roles QNetd/etcd documentados como independientes. |
| P4.2 | Instalar PVE-1 `.50.10` y PVE-2 `.50.11`, configurar FQDN, hosts, DNS, tiempo y bridge VLAN 50. | P2.4 | Ping gateway/pares, DNS y tiempo correctos en ambos PVE. |
| P4.3 | **Gate bloqueante:** crear una VM temporal en cada PVE y validar desde cada una gateway `.1`, VM temporal del otro PVE, QDevice `.90.28` y Web VLAN 100 por `vmbr0`; comprobar aprendizaje MAC en switches. | P4.1, P4.2 | Pruebas y capturas aprobadas; retirar VMs temporales. Si falla, no crear clúster ni VMs definitivas. |
| P4.4 | Crear clúster desde PVE-1, unir PVE-2 y configurar QDevice desde PVE-1. | P4.3 | `pvecm status`: tres votos esperados y `Quorate: Yes`. |
| P4.5 | Probar caída controlada de un PVE y recuperar estado sano; comprobar que no hay `pvesr` ni recursos HA de VM. | P4.4 | Evidencia de comportamiento esperado, sin prometer reinicio automático de VM. |

### P5 — AD DS, DNS, NTP, DHCP y estaciones de gestión

| ID | Acción obligatoria | Precondición | Cierre / evidencia mínima |
|---|---|---|---|
| P5.1 | Crear DC1 con AD DS + DNS y dominio `pft.test`; instalar DC2 como DC/DNS adicional en PVE distinto. | P4.4 | Roles instalados, IP/DNS cruzado y réplica inicial completada. |
| P5.2 | Configurar zonas DNS directa/reversa y registros PVE, PG, VIP, Zabbix y Web; crear OUs, grupos AGDLP y GPO base. | P5.1, P1.3 | Configuración documentada sin secretos; Web usa IP real. |
| P5.3 | Configurar tiempo: PDC con fuentes NTP autorizadas, DC2 y miembros por jerarquía de dominio. | P5.1 | `w32tm` y fuentes de tiempo verificadas. |
| P5.4 | Sustituir `mgmtPC-1/2` por Windows, instalar drivers/agent requeridos, renovar DHCP, unir a dominio y ubicar en OU MGMT. | P2.3, P5.2 | Clientes reciben DNS `.12/.13`, resuelven SRV, aplican GPO y acceden a PVE autorizado. |
| P5.5 | Verificar `dcdiag`, `repadmin`, DNS, autenticación y GPO con un PVE caído. | P5.1–P5.4 | RQ-04 aprobado; cualquier fallo de DNS/tiempo/replicación bloquea P6. |

### P6 — PostgreSQL HA, VIP y frontend

| ID | Acción obligatoria | Precondición | Cierre / evidencia mínima |
|---|---|---|---|
| P6.1 | Instalar etcd en PG-1 `.14` y PG-2 `.15`, completar clúster de tres miembros con QDevice y validar quorum. | P4.1, P5.1 | `etcdctl endpoint status` sano antes de Patroni. |
| P6.2 | Instalar PostgreSQL, Patroni y Keepalived; deshabilitar PostgreSQL de paquete que competiría por el directorio de datos. | P6.1 | Servicios y configuración validados, secretos fuera de evidencias. |
| P6.3 | Configurar Patroni con promoción exclusiva, sincronía estricta, `pg_hba` mínimo sin TLS y reincorporación; iniciar líder y standby. | P6.2, P1.3 | Un `Leader`, un `Sync Standby` y `pg_stat_replication` síncrono; uso sin TLS documentado como exclusivo de laboratorio. |
| P6.4 | Configurar Keepalived VRRP unicast para publicar VIP `.16` sólo si API Patroni responde `/primary`; prohibir scripts de promoción alternativos. | P6.3 | Una única VIP en líder; `keepalived --config-test` aprobado. |
| P6.5 | Instalar cliente PostgreSQL en `WebUbuntuServer-1`; crear BD, usuario y tabla de **prueba** mediante líder; usar Web sólo como cliente DMZ hacia `postgres.pft.test`, sin TLS y sin IP de PG. | P6.4, P1.3 | CRUD de prueba por VIP. Migración de aplicación/esquema/datos y rollback funcional quedan fuera de alcance. |
| P6.6 | Probar caída de primario/PVE, caída de réplica, partición y reincorporación en ensayos separados, con cronómetro y evidencia de PVE/etcd/Patroni/VIP/CRUD. | P6.5 | RQ-05 a RQ-08 aprobados; failover ≤60 s y sin doble escritor. |
| P6.7 | Ante doble escritor, VIP duplicada o divergencia, aislar el posible primario antiguo, detener ensayo y restaurar sólo tras diagnóstico. | Resultado inseguro | Incidente y recuperación documentados; no continuar ni declarar HA. |

### P7 — Zabbix, capacidad integrada, cierre y rollback retenido

| ID | Acción obligatoria | Precondición | Cierre / evidencia mínima |
|---|---|---|---|
| P7.1 | Instalar Zabbix en PVE-2 con retención corta; agregar Agent 2 a PVE, DC y PG; no reutilizar `appdb`. | P5.5, P6.5 | Inventario de hosts y plantillas de servicio. |
| P7.2 | Incorporar por SNMPv3 sólo infraestructura inventariada y configurar alertas de PVE, DNS, AD, Patroni/réplica, VIP y SNMP. | P1.4, P3.4, P7.1 | Sondas correctas, sin end hosts —incluido frontend— y retorno ACL SNMP validado. |
| P7.3 | Probar al menos una alerta y recuperación por cada familia. | P7.2 | Historial de alertas y recuperación. |
| P7.4 | Ejecutar ventana integrada 10–15 min con perfil crítico, CRUD y failover representativo; medir RAM, swap, disco, CPU/I/O. | P6.6, P7.3 | Sin swap, 2–3 GB libres sostenidos, 30 GB disco libre y RQ-09 aprobado. |
| P7.5 | Revisar todas las evidencias, actualizar plano/runbook si difieren del estado real y cerrar/desbloquear pendientes. | P7.4 | RQ-01…RQ-09 con resultado, fecha, responsable y referencia. |
| P7.6 | Conservar respaldos, discos/BD anterior y rollback de migración hasta aprobar la ventana completa y todas las pruebas. | P7.5 | Acta de cierre; no destruir activos previos durante el hito. |
| P7.7 | Definir hitos 50 %, 75 % y 100 % sólo después de completar P0–P7 o documentar explícitamente el bloqueo. | P7.5 | Hitos con alcance, criterio, evidencia y responsable. |

## Límites vigentes

WSUS, backup/WAL/PITR de PostgreSQL, réplica/arranque HA de VMs PVE, DHCP redundante, migración de aplicación/esquema/datos, TLS/certificados, monitoreo del frontend y custodia/rotación de claves permanecen fuera de alcance. No se incluyen como requisitos de cierre de este hito.
