# Registro de evidencias de implementación

**Estado:** pendiente de ejecución. Este archivo es una plantilla de control; no prueba que ningún cambio esté aplicado.

## Regla de avance

No se inicia el siguiente hito hasta que cada requisito de la tabla tenga resultado, fecha, operador y enlace o ubicación de su evidencia. Un resultado fallido debe generar un ítem en el TO-DO y bloquear el avance cuando afecte seguridad, disponibilidad o integridad de datos.

## Controles P0

| Tarea | Estado | Resultado / referencia |
|---|---|---|
| P0.2 — Alcance, exclusiones y SPOF | Aprobado | 2026-08-30: [acta de alcance](evidencias/P0/2026-08-30_P0.2_alcance_acta-alcance.md). Confirma HA lógica de laboratorio, exclusiones y SPOF aceptados; no acredita implementación técnica. |
| P0.3 — Resguardo de proyecto, configuraciones y discos | Aprobado | 2026-08-30: copias TAR del proyecto estable, proyecto de trabajo e imágenes compartidas ubicadas en `/home/agmiar/Desktop/PFT-S1/resguardos/PFT-S1/2026-08-30_P0.3`; lectura validada y SHA-256 registrados en el [inventario de resguardos](evidencias/P0/2026-08-30_P0.3_GNS3_inventario.md). P1.1 deberá capturar `running-config` en ejecución antes de cambios de red. |
| P0.4 — Baseline de plataforma | Aprobado | 2026-08-30: KVM, VT-x/anidación, GNS3 2.2.61, ISOs PVE/Ubuntu Server/Windows/VirtIO y cinco `qcow2` independientes sin backing file verificados. Desde `Alpine-SSHClient-1` por Border NAT se verificaron PostgreSQL 16.15, Patroni 4.0.10, etcd v3.5.33 —parche congelado para sus tres miembros—, Keepalived 1:2.2.8-1build2 y Zabbix 1:7.0.30-1+ubuntu24.04. Ver [baseline de plataforma](evidencias/P0/2026-08-30_P0.4_plataforma_baseline.md). |
| P0.5 — Salida controlada por Border NAT | Aprobado | 2026-08-30: `AlpineSSHClient-1` alcanzó Internet real (`1.1.1.1`), resolvió DNS por `192.168.122.1`, recibió `HTTP 200` de un repositorio oficial Alpine y completó NTP externo contra `164.73.225.4` (estrato 2; salida `0`) a través de Border NAT. Ver [prueba P0.5](evidencias/P0/2026-08-30_P0.5_AlpineSSHClient-1_prueba.txt) y [control](evidencias/P0/2026-08-30_P0.5_Border-NAT_control.md). |
| P0.6 — Capacidad basal | Aprobado | 2026-08-30: línea base de red de 10 min 06 s y 12 muestras en el host GNS3. RAM disponible mínima 18,94 GiB, disco libre mínimo 140,69 GiB, sin paginación ni espera de I/O atribuibles y CPU máxima ocupada 31 %. Ver [baseline](evidencias/P0/2026-08-30_P0.6_host_baseline-capacidad.csv) y [decisión](evidencias/P0/2026-08-30_P0.6_host_decision-capacidad.md). No acredita RQ-09, que exige la ventana integrada de P7.4. |
| P0.7 — Control de aborto y rollback por paquete | Aprobado | 2026-08-30: [control de ventana y rollback](evidencias/P0/2026-08-30_P0.7_ventana_control.md) define criterios de aborto, hitos de cronómetro y rollback de red, ACL, servicios y Web DMZ. No acredita ningún cambio técnico ni prueba de aceptación posterior. |

## Evidencia mínima requerida

## Controles P1

| Tarea | Estado | Resultado / referencia |
|---|---|---|
| P1.1 — Inventario de Core y Border | Aprobado | 2026-08-30: capturas previas de [CorevIOS-1](evidencias/P1/2026-08-30_P1.1_CorevIOS-1_pre.txt), [CorevIOS-2](evidencias/P1/2026-08-30_P1.1_CorevIOS-2_pre.txt), [BorderRouter-1](evidencias/P1/2026-08-30_P1.1_BorderRouter-1_pre.txt) y [BorderRouter-2](evidencias/P1/2026-08-30_P1.1_BorderRouter-2_pre.txt) registradas. HSRP, OSPF, trunks, EtherChannel y RSTP están operativos; VLAN 50 continúa en `/29`. Ambos Border usan ACL `1`, no `NAT_INSIDE`, para selección NAT: discrepancia documentada que debe resolverse antes de P2.2. |
| P1.2 — Inventario de topología y direccionamiento | Aprobado | 2026-08-30: inventario consolidado de interfaz, IP/máscara, gateway, VLAN, rol y versión en [CSV P1.2](evidencias/P1/2026-08-30_P1.2_topologia_inventario.csv). Fuentes: configuraciones aceptadas por el operador, planilla de direccionamiento y salidas reales de consola. PCs restantes: Alpine 3.18.4; DummyInternet: Alpine 3.24.1 con `iptables` declarado instalado; NAT GNS3: 2.2.61. |
| P1.3 — Inventario de Web DMZ | Bloqueado | 2026-08-30: el frontend actual `WebUbuntuServer-2`/`ubuntu-server` fue confirmado en `192.168.100.6/29`, gateway estático `192.168.100.1`, conectado a ADvIOS-10 `Gi1/1` access VLAN 100. `resolvectl` no mostró DNS configurado. No se aplicaron cambios; la condición de reanudación queda vinculada a P5.1: desplegar y validar DNS en DC1/DC2, configurar `.12/.13` en el frontend y comprobar `resolvectl` más `web.pft.test`. Ver [inventario P1.3](evidencias/P1/2026-08-30_P1.3_WebUbuntuServer-1_inventario.txt) y [control](evidencias/P1/2026-08-30_P1.3_WebUbuntuServer-1_control.md). |
| P1.6 — Marcadores ACL/NTP y secretos | Bloqueado | 2026-08-30: no hay fuentes NTP creadas, implementadas ni autorizadas para sustituir `<NTP1>`/`<NTP2>`; no se autoriza configurar el PDC hasta definirlas y verificarlas en P5.3. Las contraseñas se conservan manualmente fuera del proyecto y de las evidencias por alcance académico; no hay vault, rotación, custodia formal ni almacenamiento seguro. Los marcadores SNMP quedan diferidos a P7.2 y el marcador Web no se instancia hasta cerrar P1.3. Ver [control P1.6](evidencias/P1/2026-08-30_P1.6_marcadores_control.md). |

## Controles P2

| Tarea | Estado | Resultado / referencia |
|---|---|---|
| P2.1 — Par L2 Datacenter ADvIOS-9a–ADvIOS-9b | Aprobado | 2026-08-30: Po9 LACP está `SU` con Gi0/1–2 `P` en ambos ADvIOS; los cuatro trunks del dominio permiten sólo VLAN 50/99, con 99 nativa y sin VLAN 100. CDP confirma ADvIOS-9a Gi0/0↔CorevIOS-1 Gi2/1 y ADvIOS-9b Gi0/0↔CorevIOS-2 Gi2/1. STP VLAN 50 está estable, con CorevIOS-1 como root. Ver [control](evidencias/P2/2026-08-30_P2.1_ADvIOS-9a-ADvIOS-9b_control.md), post de [ADvIOS-9a](evidencias/P2/2026-08-30_P2.1_ADvIOS-9a_etherchannel_post.txt), [ADvIOS-9b](evidencias/P2/2026-08-30_P2.1_ADvIOS-9b_etherchannel_post.txt), [CorevIOS-1](evidencias/P2/2026-08-30_P2.1_CorevIOS-1_post.txt), [CorevIOS-2](evidencias/P2/2026-08-30_P2.1_CorevIOS-2_post.txt) e [incidente corregido](evidencias/P2/2026-08-30_P2.1_ADvIOS-9a-ADvIOS-9b_incidente.md). |
| P2.2 — Ampliación VLAN 50, OSPF y NAT | Aprobado | 2026-08-30: pre de [CorevIOS-1](evidencias/P2/2026-08-30_P2.2_CorevIOS-1_pre.txt), [CorevIOS-2](evidencias/P2/2026-08-30_P2.2_CorevIOS-2_pre.txt), [BorderRouter-1](evidencias/P2/2026-08-30_P2.2_BorderRouter-1_pre.txt) y [BorderRouter-2](evidencias/P2/2026-08-30_P2.2_BorderRouter-2_pre.txt); post de [CorevIOS-1](evidencias/P2/2026-08-30_P2.2_CorevIOS-1_post.txt), [CorevIOS-2](evidencias/P2/2026-08-30_P2.2_CorevIOS-2_post.txt), [BorderRouter-1](evidencias/P2/2026-08-30_P2.2_BorderRouter-1_post.txt), [BorderRouter-2](evidencias/P2/2026-08-30_P2.2_BorderRouter-2_post.txt) y [DummyInternet](evidencias/P2/2026-08-30_P2.2_DummyInternet_post.txt). VLAN 50 `/27`, HSRP/OSPF/STP, ACL ampliada, NAT ACL 1 y [salida NAT extremo a extremo](evidencias/P2/2026-08-30_P2.2_AlpineSSHClient-1_prueba.txt) comprobados; `startup-config` de ambos Core confirma persistencia. RQ-01 sigue pendiente de P2.4. |
| P2.3 — DHCP CorevIOS-1 | Aprobado | 2026-08-30: la evidencia real de [pre](evidencias/P2/2026-08-30_P2.3_CorevIOS-1_pre.txt) y [post](evidencias/P2/2026-08-30_P2.3_CorevIOS-1_post.txt) confirma exclusión `.1-.30`, los seis pools con DNS `.12/.13` y `pft.test`, sin bindings/conflictos y sin pools VLAN50/VLAN100. `do wr` terminó con `[OK]` y `startup-config` confirma la persistencia. El [incidente](evidencias/P2/2026-08-30_P2.3_CorevIOS-1_incidente.md) quedó cerrado. Renovación DHCP/DNS efectiva: diferida a P5.4, tras desplegar DC/DNS. |
| P2.4 — HSRP, conectividad, trunk/STP y failover | Aprobado | 2026-08-30 (consolas UTC del 31): CorevIOS-2 tomó HSRP VLAN 50 6,750 s después del `shutdown` controlado de Vlan50 en CorevIOS-1; tras `no shutdown`, CorevIOS-1 recuperó el activo. Alpine verificó VIP 5/5 y HTTPS 200 antes y después. Po9 LACP y la restricción VLAN 50/99 se verificaron; el supervisor humano confirmó la convergencia L2 y el funcionamiento adecuado. La pérdida ICMP durante el intervalo exacto no quedó cuantificada. Ver [control](evidencias/P2/2026-08-30_P2.4_CorevIOS_control.md) y [failover](evidencias/P2/2026-08-30_P2.4_Core-HSRP_failover.md). RQ-01 aprobado. |

## Controles P4

| Tarea | Estado | Resultado / referencia |
|---|---|---|
| P4.1 — QDevice Debian, QNetd y tercer etcd | Aprobado | 2026-08-31: QDevice ubicado en Datacenter, conectado por `eth0` a `ADvIOS-1 Gi2/0` access VLAN 90, MAC `0c93.d2ae.0000`, gateway 4/4 y ausencia de conflicto `.90.28` confirmada por el operador. SSH Server está instalado y el acceso desde AlpineSSHClient-1 fue confirmado. QNetd está activo/TCP 5403; etcd 3.5.33 fue verificado, su `ExecStart` validado por systemd y queda intencionalmente `disabled`/`inactive` hasta P6.1. Tiempo sincronizado por chrony con fuente registrada; ver [control](evidencias/P4/2026-08-30_P4.1_QDevice_control.md) y [resultado](evidencias/P4/2026-08-31_P4.1_QDevice_qdevice-etcd.md). |
| P4.2 — PVE-1 y PVE-2, red y bridge | Aprobado | 2026-08-31: PVE-1 `.10` y PVE-2 `.11` están instalados, conectados como `ens3` a ADvIOS-9a/9b `Gi0/3` access VLAN 50, con `vmbr0`, gateway y conectividad entre pares comprobados. El operador confirmó que no existieron conflictos IP; PVE-2 corrigió su hosts y ambos nodos sincronizan Chrony contra `164.73.225.4` (`System clock synchronized: yes`, `Leap status: Normal`). La resolución DNS efectiva queda diferida a P5.1. Ver [control](evidencias/P4/2026-08-31_P4.2_PVE_control.md), [PVE-1](evidencias/P4/2026-08-31_P4.2_PVE-1_post.md), [PVE-2](evidencias/P4/2026-08-31_P4.2_PVE-2_post.md), [cableado](evidencias/P4/2026-08-31_P4.2_PVE_inventario.md) e [incidente resuelto](evidencias/P4/2026-08-31_P4.2_PVE_incidente.md). |
| P4.3 — Compuerta de red anidada PVE | Aprobado | 2026-08-31: **aprobación manual explícita del operador (human in the loop)**. P4T-PVE1 (VMID 901) arrancó con `.18/27` por `vmbr0`, alcanzó HSRP `.1`, Web `.100.6` y QDevice `.90.28` 4/4; la corrección PVE-1/PVE-2→QDevice TCP/5403 fue comprobada desde PVE-1 (código `0`; contador 75 de CorevIOS-1 = 1). Limitaciones aceptadas: no se ejecutaron P4T-PVE2, prueba VM-a-VM ni verificación MAC en switches. Pendiente de cierre técnico: retirar ACL temporal 77/78 y eliminar VMs efímeras. Ver [control](evidencias/P4/2026-08-31_P4.3_PVE_control.md), [post Core](evidencias/P4/2026-08-31_P4.3_CorevIOS_post.txt) e [incidente](evidencias/P4/2026-08-31_P4.3_PVE_incidente.md). |

| Requisito | Estado | Evidencia esperada | Resultado / referencia |
|---|---|---|---|
| Inventario de SVI, HSRP, OSPF, `NAT_INSIDE` y adjuntos ACL | Pendiente | Salidas `show` fechadas de ambos Core y equipos de red | — |
| Inventario de IP de `WebUbuntuServer-1` | Bloqueado | `ip -br address` y verificación de VLAN 100 | 2026-08-30: IP/gateway/VLAN confirmados para el frontend actual, pero DNS ausente. Reanudar dentro de P5.1 con DC1/DC2 disponibles, `.12/.13` configurados y DNS efectivo verificado; ver evidencia P1.3. |
| Baseline y salida externa controlada | Pendiente | Versiones congeladas, hash VirtIO, resolución AD DNS, repositorios HTTPS y NTP del PDC vía Border NAT | — |
| Gate de red anidada PVE | Pendiente | VM temporal en cada PVE llega a gateway, VM del otro PVE, QDevice/VLAN90 y Web/VLAN100 por `vmbr0` | — |
| ACL sin marcadores, aplicada un Core por vez y con rollback capturado | Pendiente | Configuración, contadores y captura de adjuntos anterior/posterior | — |
| Pruebas ACL positivas y negativas | Pendiente | Resultados de la sección 6 del runbook | — |
| Monitoreo Zabbix de PVE, AD/DNS, PostgreSQL/VIP e infraestructura de red por SNMPv3 | Pendiente | P7.2: configuración SNMPv3 e inventario de gestión reales, sondeos y alertas de prueba; sin end hosts, incluido frontend | — |
| Capacidad integrada | Pendiente | Registro de RAM, swap, disco libre, I/O y prueba de 10–15 min | — |
| Quorum PVE | Pendiente | `pvecm status` antes/durante/después de la prueba | — |
| AD/DNS con caída de un PVE | Pendiente | Resolución DNS, autenticación y replicación AD | — |
| Caída del primario PostgreSQL | Pendiente | `patronictl list`, dueño de VIP y CRUD dentro de RTO | — |
| Partición PostgreSQL | Pendiente | Evidencia de un solo `primary` y ausencia de doble escritura | — |
| Caída de réplica PostgreSQL | Pendiente | Liderazgo conservado y bloqueo de escrituras según sincronía estricta | — |
| Reintegración PostgreSQL | Pendiente | Antiguo primario como réplica, sin failback automático | — |

## Criterio de cierre documental

Al cerrar una fila, sustituir `Pendiente` por `Aprobado`, `Fallido` o `Bloqueado`, completar la última columna y enlazar el artefacto conservado. La evidencia debe ser reproducible y no contener secretos, credenciales ni claves SNMPv3.
