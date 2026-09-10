# FODA — Plano Ejecutivo de Reestructuración HA

**Documento evaluado:** `PLANO_EJECUTIVO_REESTRUCTURACION_HA.md`  
**Enfoque:** devil's advocate; se valora la solución propuesta, no la intención ni los componentes futuros.  
**Escala:** 1% = deficiente / riesgo crítico; 100% = sólido y comprobable.  
**Semáforo:** 🟢 75–100% · 🟡 50–74% · 🔴 1–49%.

> **Estado histórico, no normativo.** Esta evaluación conserva hallazgos de una versión anterior del diseño. Las decisiones vigentes están en `INSIGHTS_CONVERSACION_REESTRUCTURACION_HA.md`: TLS/certificados, migración de aplicación/datos, monitoreo del frontend y custodia/rotación de secretos están fuera de alcance; no interpretar recomendaciones de vault, TLS o aplicación de este FODA como requisitos del hito.

## Calificación global: 🟡 62%

El proyecto está bien planteado para demostrar continuidad de AD/DNS y PostgreSQL en un **laboratorio** ante la caída de un nodo virtual. No obstante, no alcanza una alta disponibilidad integral: un único host físico, discos locales sin reinicio de VMs, ausencia de respaldos/PITR y varios SPOF declarados hacen que su uso productivo sea inaceptable sin rediseño. La puntuación reconoce que esos límites están documentados con honestidad, pero no los convierte en riesgos resueltos.

## Fortalezas

| Aspecto evaluado | Semáforo | Nota | Lectura crítica |
|---|:---:|---:|---|
| Diagnóstico de capacidad IPv4 y ampliación mínima de VLAN 50 | 🟢 | 90% | Identifica correctamente que `/29` es insuficiente y conserva las IP relevantes al migrar a `/27`. Reduce el alcance del cambio. |
| Diseño de PostgreSQL con Patroni como única autoridad de promoción | 🟢 | 88% | Separar promoción (Patroni) y publicación de VIP (Keepalived) reduce el riesgo de doble primario por automatizaciones superpuestas. |
| DCS etcd de tres miembros y réplica síncrona estricta | 🟢 | 84% | Protege la consistencia y hace explícito el comportamiento: ante pérdida de la réplica se bloquean escrituras en lugar de aceptar pérdida de datos. |
| Redundancia de AD DS y DNS distribuida entre PVE | 🟢 | 82% | Dos DC/DNS, pruebas de replicación y diseño de tiempo de AD son adecuados para el objetivo académico. |
| Quorum Proxmox con QDevice externo al clúster | 🟢 | 80% | Evita el empate de dos nodos y demuestra conocimiento de la limitación típica de un clúster PVE de dos miembros. |
| Runbook de migración, rollback y pruebas de fallos | 🟢 | 85% | Define secuencia, validaciones y escenarios de caída, partición y reincorporación; es más operable que un diseño meramente diagramado. |
| Transparencia de límites y criterios de aceptación | 🟢 | 86% | Declara SPOF, ausencia de HA de VM y restricciones de recuperación. Esto evita prometer una disponibilidad que la solución no entrega. |
| Separación de administración en VLAN 90 y endurecimiento base de AD | 🟡 | 72% | Incluye LAPS, GPO base y acceso PVE desde gestión, pero faltan ACL concretas y pruebas de mínimo privilegio. |

## Oportunidades

| Aspecto evaluado | Semáforo | Nota | Lectura crítica / mejora que habilita |
|---|:---:|---:|---|
| Evolución a tres nodos PVE y almacenamiento compartido/distribuido | 🟢 | 92% | Es la mejora de mayor impacto: permitiría reinicio HA de VMs, quorum natural y tolerancia real a la caída de un nodo. |
| Separar redes y NIC para gestión, Corosync, migración y almacenamiento | 🟢 | 87% | Disminuye contención y fallas correlacionadas del único segmento VLAN 50; hoy todo depende del mismo dominio L2. |
| Implementar backup, WAL archive, PITR y restauraciones ensayadas | 🟢 | 98% | Convierte la continuidad operativa en recuperabilidad. Debe incluir pruebas periódicas, no solo copias configuradas. |
| Formalizar ACL por flujo y monitoreo SNMPv3 de la red | 🟢 | 83% | Reduce superficie lateral y permite detectar la caída del plano de red que sustenta la supuesta HA. |
| Añadir proxy de conexiones (PgBouncer/HAProxy) y métricas de aplicación | 🟡 | 74% | Haría más predecible la reconexión tras failover, aunque no corrige los riesgos físicos fundamentales. |
| Automatización declarativa, gestión de secretos y pruebas repetibles | 🟡 | 70% | Ansible/IaC, vault y pruebas automatizadas reducirían errores manuales; el documento lo menciona parcialmente, sin implementación verificable. |
| Dimensionamiento observado mediante prueba de carga | 🟡 | 66% | La memoria estimada es ajustada. Medir consumo, I/O, swap y latencia bajo CRUD/failover permitiría validar o corregir el supuesto. |

## Debilidades

| Aspecto evaluado | Semáforo | Nota | Lectura crítica |
|---|:---:|---:|---|
| Un único host físico GNS3 concentra todos los dominios de fallo | 🔴 | 20% | PVE, QDevice, tercer etcd, switches y VMs caen juntos ante fallo del host. La distribución lógica no ofrece tolerancia física. |
| Sin almacenamiento compartido, replicación PVE ni arranque HA de VMs | 🔴 | 28% | La caída de un PVE deja sus VMs apagadas; el clúster mantiene administración consistente, pero no disponibilidad de cómputo. |
| Ausencia de backup, WAL/PITR y restauración probada de PostgreSQL | 🔴 | 12% | La réplica síncrona propaga borrados, corrupción y errores de aplicación. RPO 0 para caída de nodo no equivale a capacidad de recuperación. |
| Capacidad de RAM y disco al límite, con cifras internas discordantes | 🔴 | 38% | Se estima PVE con 6 GB por nodo en el máximo, mientras la plantilla propone 8–12 GB y debe alojar DC/PG. Con 30 GB totales, el margen real es muy estrecho. |
| QDevice y tercer etcd en el mismo host del laboratorio | 🔴 | 30% | Aporta voto frente a una falla lógica/de nodo, pero no frente al fallo que más importa: host, energía, almacenamiento o GNS3. |
| DHCP en CorevIOS-1 como SPOF | 🟡 | 46% | No rompe servicios ya configurados, pero sí altas/renovaciones de clientes; es una dependencia innecesaria para una iniciativa presentada como HA. |
| Zabbix no HA y sin monitoreo de Core/distribución/acceso | 🟡 | 42% | Si cae PVE-2 se pierde observabilidad; además puede fallar el transporte entre servicios sin una alerta de infraestructura. |
| Política de segmentación permisiva y ACL sin reglas completas | 🟡 | 48% | Decir “por función” no demuestra el control. Sin ACL numeradas, sentido de aplicación y matriz puerto-origen-destino, no es auditable ni reproducible. |
| Dependencia de un único dominio L2 para servicio, Corosync y VRRP | 🟡 | 44% | Un error de STP, trunk, VLAN o tormenta de broadcast puede aislar simultáneamente los componentes que deben decidir el failover. |
| Operación y secretos aún poco especificados | 🟡 | 49% | Hay marcadores de secretos y recomendación de vault, pero no un mecanismo definido, rotación, cuentas de servicio ni procedimiento de emergencia. |

## Amenazas

| Aspecto evaluado | Semáforo | Nota | Escenario adverso |
|---|:---:|---:|---|
| Fallo eléctrico, físico o de almacenamiento del host GNS3 | 🔴 | 10% | Derriba todo el entorno y elimina el supuesto tercer voto. No hay continuidad ni RTO para este caso. |
| Corrupción lógica, ransomware o borrado replicado | 🔴 | 8% | Al no existir PITR ni respaldo aislado, la réplica síncrona replica el daño y no permite volver a un estado sano. |
| Error de cambio al migrar máscara, OSPF, ACL y NAT | 🟡 | 47% | El cambio es acotado pero transversal; una wildcard o SVI incoherente puede interrumpir VLAN 50 o exponer tráfico. |
| Partición de red, STP o falla del trunk Dist1–Dist2 | 🟡 | 45% | Puede degradar quorum, VRRP o reachability. Las pruebas planificadas ayudan, pero comparten infraestructura con los enlaces de servicio. |
| Pérdida de disponibilidad por réplica síncrona estricta | 🟡 | 52% | Es el costo deliberado de RPO 0: si el standby falla, las escrituras se bloquean. Sin acuerdo explícito de negocio, puede percibirse como indisponibilidad. |
| Saturación del host por virtualización anidada y picos de I/O | 🟡 | 43% | PostgreSQL, Windows, PVE dentro de QEMU y switches compiten por recursos; bajo presión, un “failover” puede ser solo degradación prolongada. |
| Configuración manual heterogénea y deriva operativa | 🟡 | 50% | Muchos pasos en Cisco, Windows, Linux, PVE y GNS3 aumentan la probabilidad de que el estado real difiera del documento. |
| Exposición de servicios de administración o de etcd por filtrado incompleto | 🟡 | 40% | APIs de Patroni, etcd, PVE y VRRP requieren controles estrictos. Una ACL permisiva o mal aplicada puede comprometer el plano de control. |

## Dictamen de devil's advocate

**Aprobable con reservas para el hito académico y demostración en laboratorio; no aprobable como plataforma productiva de alta disponibilidad.**

Antes de elevar la calificación a verde, deberían completarse como mínimo: (1) respaldos inmutables y restauración/PITR demostrada, (2) tres nodos o almacenamiento que habilite HA real de VMs, (3) separación física o al menos de host para los votos críticos, (4) ACL explícitas y validadas por flujo, y (5) prueba de carga que confirme RAM, I/O y el RTO observado.
