# Plan de trabajo unificado — PFT-S1 en GNS3

**Propósito.** Este es el documento operativo único para ejecutar y supervisar el hito. Integra el flujo de trabajo y el TO-DO: establece el método de control, los requisitos trazables, el orden de ejecución y los criterios de los hitos 50 %, 75 % y 100 %.

**Estado inicial (2026-08-29).** El material disponible describe un diseño; no una implementación comprobada. No declarar alta disponibilidad física ni cumplimiento de RTO/RPO hasta completar y registrar las pruebas de aceptación.

## Cómo se opera este plan

Cada cambio se ejecuta mediante un ciclo **PIV**: **Planificar → Implementar → Verificar → decisión humana**. Si algo falla o es ambiguo, se conserva evidencia, se aplica el rollback previsto cuando corresponda y se abre un PIV correctivo; no se avanza por apreciación visual de la topología.

| Momento | Responsabilidad del supervisor | Condición para avanzar |
|---|---|---|
| Planificar | Contrastar diseño y estado real; delimitar cambio, dependencia, riesgo, prueba y rollback. | No quedan datos críticos desconocidos ni marcadores por sustituir. |
| Implementar | Aplicar un cambio pequeño y controlado, sin combinar cambios no relacionados. | Se conserva configuración anterior y rollback ejecutable. |
| Verificar | Ejecutar pruebas positivas, negativas y de resiliencia; registrar salidas, contadores, tiempos y resultado. | Los criterios medibles se cumplen sin degradación no aceptada. |
| Decidir | Marcar `Aprobado`, `Fallido` o `Bloqueado`; actualizar evidencias y autorizar el siguiente PIV. | Los fallos de seguridad, disponibilidad o integridad están resueltos o impiden avanzar. |

Toda aprobación debe registrar fecha, responsable, comandos/acciones, resultado y ubicación de evidencia. Antes de persistir un cambio (`write memory`, cambio definitivo en VM o servicio), completar la prueba del PIV correspondiente.

### Fuentes de verdad

Leer antes de actuar, en este orden:

1. [Plano ejecutivo](/home/agmiar/Desktop/PFT-S1/.agents/PLANO_EJECUTIVO_REESTRUCTURACION_HA.md): arquitectura, direccionamiento, migración, pruebas y rollback.
2. [Matriz ACL y runbook](/home/agmiar/Desktop/PFT-S1/.agents/ACL_MATRIZ_Y_RUNBOOK.md): única norma para ACL.
3. [Decisiones de alcance](/home/agmiar/Desktop/PFT-S1/.agents/INSIGHTS_CONVERSACION_REESTRUCTURACION_HA.md).
4. Este documento.
5. [Registro de evidencias](/home/agmiar/Desktop/PFT-S1/.agents/EVIDENCIAS_DE_IMPLEMENTACION.md).

### Reglas y límites permanentes

- Mantener una copia recuperable del proyecto GNS3, configuraciones Cisco, VMs y discos antes de migrar; retenerla hasta aprobar la ventana integrada.
- Trabajar desde consola local o administración autorizada. Para red, cambiar un Core por vez; para servicios, un componente o hipótesis por vez.
- Capturar estado antes y después de cada cambio; usar nombres como `AAAA-MM-DD_PIV-03_ACL-Core1_pre.txt`.
- Nunca aplicar placeholders (`<IP_WEB_DMZ>`, `<NTP1>`, IP de gestión o secretos de ejemplo). No incluir contraseñas, claves privadas, communities ni secretos SNMPv3 en Markdown o evidencias.
- Detener y preservar evidencia ante pérdida inesperada de conectividad, dos escritores, pérdida de quorum, swap sostenido, disco insuficiente o resultado ambiguo.
- La práctica ofrece HA **lógica de servicios** dentro de un único host GNS3, no tolerancia a la caída del host físico. DHCP en CorevIOS-1 y Zabbix en PVE-2 son SPOF aceptados.
- Las ACL de SVI no aíslan tráfico local de VLAN 50 (Patroni, etcd y VRRP). PostgreSQL, Patroni y etcd no usan TLS en este laboratorio aislado; no trasladar esta decisión a producción.
- Quedan fuera de alcance: WSUS, DHCP redundante, réplica/arranque HA de VMs Proxmox, backup/WAL/PITR, migración de aplicación/esquema/datos, TLS/certificados, monitoreo del frontend y custodia/rotación de secretos.

## Requisitos trazables

| ID | Requisito | Criterio de cierre |
|---|---|---|
| RQ-01 | Ampliar VLAN 50 a `192.168.50.0/27` sin alterar las demás VLAN. | HSRP, OSPF y NAT usan `/27` en ambos lados y hay conectividad validada. |
| RQ-02 | Aplicar únicamente las ACL normativas. | Sin marcadores; cada SVI tiene el adjunto esperado y pasan las pruebas. |
| RQ-03 | Monitorear servicios definidos e infraestructura de red por SNMPv3. | Infraestructura inventariada sondeada; sin end hosts en Zabbix. |
| RQ-04 | Mantener AD DS y DNS redundantes. | Ante caída de un PVE, el DC restante resuelve DNS y autentica. |
| RQ-05 | Implementar PostgreSQL HA con Patroni como única autoridad de promoción. | Un `primary`, VIP en el primario y sin failback automático. |
| RQ-06 | Mantener RPO 0 para transacciones confirmadas mediante réplica síncrona estricta. | Si cae la réplica se bloquean escrituras y se conservan lecturas. |
| RQ-07 | Alcanzar RTO PostgreSQL de hasta 60 s ante caída de primario. | CRUD por VIP vuelve dentro del umbral medido. |
| RQ-08 | Evitar doble escritor ante partición de red. | Un único nodo acepta escrituras en la prueba de partición. |
| RQ-09 | Validar capacidad de la ventana integrada. | Sin swap, 2–3 GB RAM libres sostenidos y sin saturación atribuible a recursos. |

Cada requisito debe terminar con resultado, fecha, responsable y referencia a evidencia en `EVIDENCIAS_DE_IMPLEMENTACION.md`.

---

## Fase 1 — Alcanzar 50 % del trabajo terminado

**Objetivo acumulado.** Disponer de una plataforma conocida, respaldada y estable, con VLAN 50 ampliada y la red base validada. Esta fase comprende P0, P1 y P2. No desplegar servicios HA ni aplicar ACL funcionales antes de aprobarla.

### 1. Gobierno, resguardo y capacidad basal (P0)

| ID | Acción | Cierre mínimo |
|---|---|---|
| P0.2 | Leer las fuentes de verdad y confirmar exclusiones/SPOF. | Acta de alcance: HA lógica; sin WSUS, DHCP redundante, HA de VM, PITR, TLS, migración, frontend ni custodia de claves. |
| P0.3 | Respaldar `.gns3project`, `running-config`, configuración de VMs y discos/estado anterior recuperable. | Rutas, fecha y prueba de acceso; no confundir con PITR. |
| P0.4 | Validar KVM, virtualización anidada, imágenes/ISOs, licencias y baseline: PVE 8.4.x, Ubuntu 24.04.4, PostgreSQL 16.15, Patroni 4.0.10, etcd 3.5.x, Keepalived 2.2.8 y Zabbix 7.0 LTS. Crear discos QEMU independientes. | Versiones, hash ISO, salida KVM/nested e inventario de discos; ningún qcow2 compartido. Si falta una versión, abrir decisión correctiva. |
| P0.5 | Desde un host temporal validar salida exclusiva por Border NAT a repositorios HTTPS y NTP externo. | Evidencia de conectividad; tras crear AD sólo el PDC sincroniza NTP externo y clientes usan AD DNS. |
| P0.6 | Medir RAM, swap, disco, CPU e I/O; reservar 2–3 GB RAM y 30 GB disco. | Línea base y decisión de continuar o reducir carga. |
| P0.7 | Definir criterios de aborto, cronómetro de fallos y rollback por paquete. | Control de aborto y rollback de red, ACL, servicios y Web DMZ documentado; no exige fecha, hora ni duración de una ventana predefinida. |

Observar 10–15 minutos la carga prevista o la red base. Si aparece swap, saturación sostenida o se incumplen márgenes, reducir carga o redimensionar antes de desplegar HA.

### 2. Inventario real y compuertas técnicas (P1)

| ID | Acción | Cierre mínimo |
|---|---|---|
| P1.1 | Capturar en ambos Core SVI, HSRP, OSPF, trunks, EtherChannel, STP, ACL adjuntas y `NAT_INSIDE`; capturar NAT en ambos Border. | Salidas fechadas y respaldos por equipo. |
| P1.2 | Inventariar interfaz, IP/máscara, gateway, VLAN, rol y versión de los nodos. | Tabla de topología/direccionamiento real; discrepancias como ítems correctivos. |
| P1.3 | Confirmar IP estática, gateway, DNS y VLAN 100 de `WebUbuntuServer-1`. | `ip -br address`, rutas y pertenencia a DMZ; sin esto no hay ACL ni cliente Patroni. |
| P1.6 | Validar marcadores de ACL/NTP y el registro externo de contraseñas. | Ningún placeholder llega a producción; secretos fuera de evidencias. |

En ambos Core, capturar al menos:

```cisco
show running-config | section ^ip access-list|^access-list|^interface Vlan|ip access-group|ip nat
show ip interface brief
show ip interface Vlan50
show ip interface Vlan60
show ip interface Vlan90
show ip interface Vlan100
show standby brief
show ip ospf neighbor
show ip route 192.168.50.0
show interfaces trunk
show etherchannel summary
show spanning-tree vlan 50
```

Si VLAN 50, HSRP, OSPF o NAT no coinciden con el diseño `/27`, si falta la IP de Web, si el cableado no coincide o hay colisión estática, detener y actualizar el plan antes de modificar.

### 3. Capa 2, direccionamiento, enrutamiento, NAT y DHCP (P2)

| ID | Acción | Precondición | Cierre mínimo |
|---|---|---|---|
| P2.1 | Incorporar `ADvIOS-9a` y `ADvIOS-9b` como par L2 dedicado de Datacenter: un uplink trunk a cada Core y un EtherChannel LACP interswitch que transporte sólo VLAN 50/99 (99 nativa). No conecta ni transporta VLAN 100. La asignación y validación de puertos se realiza al implementar. | Control P0.7 y topología GNS3 disponible | Port-channel trunk y STP operativos sin loop; no se instala aún ningún PVE. |
| P2.2 | Ampliar Vlan50 a `/27` en ambos Core; actualizar OSPF y `NAT_INSIDE` a wildcard `0.0.0.31` en ambos Border. | P2.1 y control P0.7 | HSRP, vecinos, ruta y NAT funcionales; demás VLAN sin cambios. |
| P2.3 | En CorevIOS-1 excluir `.1-.30` de VLAN 50; entregar DNS `.12/.13` y sufijo `pft.test` en pools aplicables. | P2.2 | Sin colisiones; no hay pool DHCP para VLAN 50/100. |
| P2.4 | Probar HSRP, conectividad permitida, trunk/STP y failover HSRP controlado. | P2.2 y P2.3 | Resultados y tiempos; RQ-01 aprobado. |
| P2.5 | Si hay fallo, restaurar puertos, `/29`, OSPF y NAT desde respaldo antes de investigar. | Resultado fallido | Rollback y estado estable documentados. |

**Criterio del 50 %.** P0–P2 están aprobados, el inventario no tiene incógnitas críticas, RQ-01 tiene evidencia y la red permanece estable. Todo resultado fallido o bloqueado debe tener dependencia, responsable y condición de reanudación.

---

## Fase 2 — Alcanzar 75 % del trabajo terminado

**Objetivo acumulado.** Sumar segmentación ACL comprobada, plataforma Proxmox con quorum y servicios base AD/DNS/NTP/gestión. Esta fase comprende P3, P4 y P5. PostgreSQL HA no empieza hasta aprobar DNS, tiempo y replicación AD.

### 4. ACL funcionales y segmentación (P3)

| ID | Acción | Cierre mínimo |
|---|---|---|
| P3.1 | Instanciar ACL `PFT_*` del runbook con IP real de Web; confirmar rango RPC AD. | Sin marcadores aplicables a P3; las reglas SNMPv3 se incorporan en P7.2 tras configurar e inventariar gestión. |
| P3.2 | Cargar ACL sin adjuntarlas; revisar sintaxis, nombres y contadores iniciales. | `show access-lists PFT_*`. |
| P3.3 | Sustituir adjuntos SVI en un Core por vez; retirar filtros previos de VLAN 100 y adjuntar una sola ACL de entrada. | Capturas pre/post; una ACL IP por dirección. |
| P3.4 | Ejecutar pruebas positivas, negativas, contadores y failover HSRP; repetir en el segundo Core antes de guardar. | Evidencias del runbook, incluidos denies Guests/DMZ y administración PVE. |
| P3.5 | Documentar que tráfico local de VLAN 50 no está cubierto por ACL SVI. | Límite aceptado o control adicional aprobado fuera de alcance. |
| P3.6 | Ante fallo, restaurar adjuntos reales del Core afectado. | Rollback comprobado; RQ-02 sólo tras P3.4. |

Pruebas mínimas: desde VLAN 90, AD/DNS, PVE TCP/22 y 8006, y PostgreSQL VIP TCP/5432 para cuenta autorizada; desde Web DMZ, DNS de DC y SSL hacia la VIP; desde VLAN 60 negar PVE/gestión; desde VLAN 10/20/30/40 negar 22/8006; y desde DMZ no autorizada negar VLAN 90/VIP. Las pruebas SNMPv3 se ejecutan en P7.2. Confirmar incrementos de `permit` y `deny ... log`; un contador inmóvil puede ser tráfico same-VLAN.

### 5. QDevice, Proxmox y quorum (P4)

| ID | Acción | Cierre mínimo |
|---|---|---|
| P4.1 | Crear QDevice Debian `.90.28` en Datacenter, conectado por `eth0` a `ADvIOS-1 Gi2/0` como access VLAN 90; revisar conflicto de IP estática, instalar SSH Server, `corosync-qnetd` y tercer etcd; validar VLAN 90 y tiempo. | Puerto, IP, conectividad, acceso SSH desde AlpineSSHClient-1, QNetd y etcd preparados; roles independientes documentados. |
| P4.2 | Instalar PVE-1 `.50.10/27` y PVE-2 `.50.11/27`; asignar y confirmar sus puertos access VLAN 50, revisar conflictos de IP estática y configurar FQDN, hosts, DNS, tiempo y bridge VLAN 50. | Mapa de cableado PVE aprobado; puertos, IP, gateway, pares, DNS y tiempo correctos. |
| P4.3 | Crear una VM temporal en cada PVE; desde ambas validar gateway `.1`, VM remota, QDevice `.90.28` y Web VLAN 100 por `vmbr0`; revisar MAC en switches. | Pruebas aprobadas y VMs temporales retiradas. Si falla, no crear clúster ni VMs definitivas. |
| P4.4 | Crear clúster desde PVE-1, unir PVE-2 y configurar QDevice desde PVE-1. | `pvecm status`: tres votos y `Quorate: Yes`. |
| P4.5 | Probar caída controlada de un PVE y recuperar estado sano; verificar ausencia de `pvesr`/recursos HA de VM. | Comportamiento documentado, sin prometer reinicio automático. |

### 6. AD DS, DNS, NTP, DHCP y estaciones de gestión (P5)

| ID | Acción | Cierre mínimo |
|---|---|---|
| P5.1 | Crear DC1 AD DS + DNS `pft.test`; agregar DC2 como DC/DNS en PVE distinto. Tras validar ambos DNS, configurar `WebUbuntuServer-2` (frontend que será renombrado a `WebUbuntuServer-1`) para usar `.12/.13` y registrar la resolución efectiva requerida para cerrar P1.3. | Roles, IP/DNS cruzado y réplica inicial; P1.3 sólo se cierra con DNS efectivo verificado en el frontend. |
| P5.2 | Configurar zonas directa/reversa y registros PVE, PG, VIP, Zabbix y Web; crear OUs, grupos AGDLP y GPO base. | Configuración sin secretos y Web con IP real. |
| P5.3 | Configurar tiempo: PDC con NTP autorizado; DC2 y miembros por jerarquía del dominio. | `w32tm` y fuentes verificadas. |
| P5.4 | Sustituir `mgmtPC-1/2` por Windows, confirmar sus puertos access VLAN 90, renovar DHCP y revisar conflictos de lease, instalar drivers/agente, unir al dominio y mover a OU MGMT. | Mapa de cableado de clientes, leases sin conflicto, DNS `.12/.13`, SRV, GPO y acceso PVE autorizado. |
| P5.5 | Verificar `dcdiag`, `repadmin`, DNS, autenticación y GPO con un PVE caído. | RQ-04 aprobado; cualquier fallo bloquea P6. |

**Criterio del 75 %.** P0–P5 están aprobados; RQ-01, RQ-02 y RQ-04 tienen evidencia; los dos PVE tienen quorum con QDevice, y AD/DNS/tiempo funcionan durante la caída controlada de un PVE.

---

## Fase 3 — Alcanzar 100 % del trabajo terminado

**Objetivo acumulado.** Completar PostgreSQL HA, VIP, cliente DMZ, Zabbix, pruebas integradas, capacidad y cierre. Esta fase comprende P6 y P7.

### 7. PostgreSQL HA, VIP y frontend de prueba (P6)

| ID | Acción | Cierre mínimo |
|---|---|---|
| P6.1 | Instalar etcd en PG-1 `.14` y PG-2 `.15`; completar clúster de tres miembros con QDevice y validar quorum. | `etcdctl endpoint status` sano antes de Patroni. |
| P6.2 | Instalar PostgreSQL, Patroni y Keepalived; deshabilitar PostgreSQL de paquete competidor. | Servicios/configuración validados; secretos fuera de evidencias. |
| P6.3 | Configurar Patroni como promoción exclusiva, sincronía estricta, `pg_hba` mínimo sin TLS y reincorporación; iniciar líder y standby. | Un `Leader`, un `Sync Standby` y replicación síncrona. |
| P6.4 | Configurar Keepalived VRRP unicast para publicar VIP `.16` sólo si Patroni responde `/primary`; prohibir promociones alternativas. | Una única VIP y `keepalived --config-test` aprobado. |
| P6.5 | Instalar cliente PostgreSQL en Web; crear BD, usuario y tabla **de prueba** por líder; acceder únicamente a `postgres.pft.test`/VIP. | CRUD de prueba por VIP, sin TLS y sin IP directa de PG. |
| P6.6 | Ensayar por separado caída de primario/PVE, caída de réplica, partición y reincorporación, con cronómetro y evidencia PVE/etcd/Patroni/VIP/CRUD. | RQ-05 a RQ-08 aprobados; failover ≤60 s y sin doble escritor. |
| P6.7 | Ante doble escritor, VIP duplicada o divergencia, aislar el posible primario antiguo y detener. | Incidente/recuperación documentados; no declarar HA. |

Para cada ensayo registrar antes, durante y después: `pvecm status`, `etcdctl endpoint status`, `patronictl list`, dueño de VIP, estado de réplica y transacción. Aceptación: estado normal con un líder, sync standby, única VIP y CRUD; caída del primario con promoción/VIP/CRUD ≤60 s; caída de réplica con lecturas disponibles y nuevas escrituras bloqueadas; partición sin dos primarios ni dos escritores; reintegración del antiguo primario como réplica, sin failback automático.

### 8. Zabbix, capacidad integrada, cierre y rollback retenido (P7)

| ID | Acción | Cierre mínimo |
|---|---|---|
| P7.1 | Instalar Zabbix en PVE-2 con retención corta; Agent 2 en PVE, DC y PG; no reutilizar `appdb`. | Inventario de hosts y plantillas de servicio. |
| P7.2 | Configurar SNMPv3 e inventariar las IP de gestión de Core, distribución, acceso, Border, ISP y red intermedia; incorporarlos a Zabbix. No incluir end hosts. Ajustar las ACL SNMP sólo con las IP verificadas. | Sondas correctas, sin end hosts incluido frontend; SNMPv3 y ACL SNMP validados, sin secretos en evidencias. |
| P7.3 | Probar alerta y recuperación de cada familia. | Historial de alertas y recuperación. |
| P7.4 | Ejecutar ventana integrada 10–15 min con perfil crítico, CRUD y failover representativo; medir recursos. | Sin swap, 2–3 GB RAM libres, 30 GB disco libre y RQ-09 aprobado. |
| P7.5 | Revisar evidencias y actualizar plano/runbook si difieren de la realidad; cerrar/desbloquear pendientes. | RQ-01…RQ-09 con estado, fecha, responsable y referencia. |
| P7.6 | Retener respaldos, discos/BD anterior y rollback hasta aprobar ventana completa. | Acta de cierre; no destruir activos previos durante el hito. |

**Criterio del 100 %.** P0–P7 están cerrados; RQ-01…RQ-09 tienen evidencia suficiente; no quedan bloqueos P0/P1. El informe final separa resultados demostrados, fallos, riesgos aceptados y fuera de alcance.

## Cierre y autorización entre fases

Antes de pasar al siguiente paquete o fase, el supervisor debe responder **sí** a todas:

- ¿El cambio coincide con un plan aprobado y tiene rollback?
- ¿Inventario, interfaces, IP y dependencias son reales y no supuestos?
- ¿Las pruebas funcionales y de denegación pasaron con evidencia fechada?
- ¿Se comprobó el fallo relevante sin ocultar los SPOF aceptados?
- ¿Los recursos del host mantienen los márgenes?
- ¿Se actualizaron evidencias y documentación si el estado real difiere del diseño?

Si alguna respuesta es no, continuar en **Planificar**; no autorizar el siguiente hito. Conservar como mínimo inventario real, respaldos pre/post, topología final, IP/roles, configuraciones saneadas, estados PVE/AD/Patroni/etcd, pruebas ACL, capturas Zabbix, cronometrajes y decisiones.
