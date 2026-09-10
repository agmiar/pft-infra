# FODA — HA en GNS3 con recursos limitados y sin infraestructura física externa

**Documento de referencia:** `PLANO_EJECUTIVO_REESTRUCTURACION_HA.md`  
**Documento adicional evaluado:** `ACL_MATRIZ_Y_RUNBOOK.md`  
**Supuesto obligatorio:** el laboratorio se ejecuta en un único proyecto GNS3 y en un único host físico. No es viable ubicar QDevice, QNetd, etcd, almacenamiento, monitoreo ni otro voto de quorum fuera de ese proyecto/host.  
**Enfoque:** devil's advocate; esta evaluación no modifica ni sustituye `FODA_final.md`.
**Escala:** 1% = deficiente / riesgo crítico; 100% = sólido y verificable.
**Semáforo:** 🟢 75–100% · 🟡 50–74% · 🔴 1–49%.

> **Uso:** evaluación de riesgos, no runbook. El alcance vigente excluye TLS/certificados, migración de aplicación/datos, monitoreo del frontend y custodia/rotación de secretos; esas exclusiones no reducen la obligación de documentarlas como límites de laboratorio.

## Calificación global: 🟢 76%

El diseño es una **práctica controlada de HA lógica de servicios**: permite ensayar Patroni, DNS redundante, VIP, quorum y recuperación ante la caída de una VM o de un PVE virtual. Esta nota evalúa la **solidez del plan**, no el resultado de su implementación; se limita deliberadamente a los objetivos académicos y a los recursos disponibles dentro del proyecto GNS3. La versión actual del plano incorpora el runbook ACL, fija el frontend objetivo en DMZ/VLAN 100 y documenta los límites de las ACL SVI.

## Fortalezas

| Aspecto evaluado | Semáforo | Nota | Lectura crítica bajo el supuesto de un único GNS3 |
|---|:---:|---:|---|
| Alcance académico explícito: HA de servicios, no HA física | 🟢 | 90% | El objetivo puede cumplirse si la evaluación mide fallas de VM, nodo PVE virtual o servicio, y no continuidad ante un desastre del host. |
| Patroni como autoridad única de promoción | 🟢 | 88% | Sigue previniendo promociones contradictorias dentro del proyecto y es una buena práctica transferible a entornos reales. |
| etcd de tres miembros distribuidos entre PG-1, PG-2 y una VM auxiliar | 🟢 | 80% | Mantiene mayoría lógica frente a la caída o aislamiento de uno de esos miembros dentro de GNS3. |
| Réplica síncrona estricta de PostgreSQL | 🟢 | 82% | Da una demostración clara del intercambio entre consistencia y disponibilidad: no confirma escrituras sin standby síncrono. |
| AD DS y DNS en VMs separadas en PVE-1/PVE-2 | 🟢 | 78% | Permite probar continuidad de autenticación y DNS si falla una VM o un PVE virtual, siempre que sobreviva GNS3. |
| VIP subordinada a Patroni y pruebas de failover | 🟢 | 84% | El frontend conserva un endpoint estable y se pueden medir reconexiones y RTO observado del servicio. |
| Documentación de migración, rollback y validaciones | 🟢 | 83% | Reduce la improvisación y hace que el laboratorio sea repetible pese a la heterogeneidad de componentes. |
| Manejo integrado de Cisco, PVE, Windows y Linux | 🟢 | 80% | Es una competencia central del laboratorio; el valor está en ejecutar y evidenciar el flujo completo con procedimientos claros. |
| Perfil de capacidad crítico definido para 30 GB de RAM | 🟢 | 80% | El plano define un rango de 24,5–28,5 GB, reserva margen y excluye Zabbix/nodos no esenciales de la prueba crítica. Es un diseño viable para el alcance, no una promesa de rendimiento productivo. |
| Zabbix ubicado en PVE-2 | 🟢 | 82% | Conserva la observabilidad cuando falla PVE-1, que aloja el primario PostgreSQL preferido. Es la distribución más coherente con dos nodos y el requisito de Zabbix. |
| Runbook de ACL con matriz, orden de aplicación, rollback y pruebas | 🟢 | 80% | El nuevo documento evita editar ACL en sitio, separa NAT de filtrado y define validaciones positivas/negativas en ambos Core. Es un avance sustantivo sobre una política declarativa. |
| Reconocimiento explícito del límite de ACL en SVI para tráfico same-VLAN | 🟢 | 82% | El runbook no promete erróneamente filtrar Patroni, etcd o VRRP entre hosts de VLAN 50 mediante una ACL inter-VLAN. |

## Oportunidades

| Aspecto evaluado | Semáforo | Nota | Mejora posible dentro de recursos limitados |
|---|:---:|---:|---|
| Documentar QDevice y etcd-qd como votos lógicos de laboratorio | 🟢 | 86% | Deja claro su papel en las pruebas de quorum y split-brain dentro del alcance académico. |
| Usar QDevice/etcd auxiliar liviano dentro de GNS3 | 🟢 | 78% | Una VM Debian mínima, encendida solo durante las pruebas de HA, consume mucho menos que un tercer PVE y conserva los escenarios de quorum lógico. |
| Ejecutar pruebas de fallo por capas y registrar evidencia | 🟢 | 91% | Probar VM, servicio Patroni, interfaz virtual, PVE virtual y partición simulada permite demostrar exactamente qué cubre y qué no cubre el diseño. |
| Encendido por fases y perfiles de prueba | 🟢 | 80% | Apagar Zabbix, clientes o VMs no esenciales fuera de la prueba reduce presión sobre 30 GB de RAM y hace viable la demostración. |
| Afinar Zabbix para laboratorio | 🟢 | 77% | Mantener Zabbix satisface el requisito; una retención corta, intervalos moderados y plantillas mínimas limitan su huella sin perder alertas relevantes. |
| Automatizar despliegue y recuperación de VMs | 🟡 | 70% | Scripts/Ansible reducen errores manuales y facilitan recrear nodos dentro del alcance del laboratorio. |
| Definir RTO/RPO exclusivamente para fallos internos simulados | 🟡 | 73% | Convertir “≤60 s” en una métrica de laboratorio repetible evita prometer objetivos para escenarios que la topología no puede cubrir. |
| Completar el inventario solicitado por el runbook | 🟡 | 76% | La IP real del Web en DMZ, las IP de gestión y el estado SNMPv3 pueden obtenerse con comandos `show` antes de aplicar reglas; el procedimiento para hacerlo ya está definido y el plano prohíbe cargar marcadores. |

## Plan de recursos transparente

La limitación de recursos está tratada mediante un perfil de prueba crítica explícito: se enciende sólo lo necesario para HA/CRUD y se mantienen apagados Zabbix y nodos no esenciales. Las VMs internas consumen memoria incluida dentro de la RAM asignada a cada PVE, por lo que no se suman dos veces.

| Componente activo durante la prueba crítica | RAM asignada | Justificación / control |
|---|---:|---|
| Host Ubuntu + proceso GNS3 | 4–6 GB | Incluye sistema, procesos GNS3 y caché; verificar que no haya swap. |
| Red vIOS imprescindible | 2–3 GB | Encender sólo Core, distribución/acceso y borde requeridos para VLAN 50/90/100 y la prueba. |
| PVE-1 | 6 GB | Contiene DC1 y PG-1 para la prueba; su memoria interna no se contabiliza aparte. |
| PVE-2 | 6 GB | Contiene DC2 y PG-2; Zabbix permanece apagado durante la ventana crítica. |
| QDevice + QNetd + etcd auxiliar | 0,5 GB | Debian mínimo, sin servicios no requeridos. |
| Un cliente Windows de validación | 2 GB | El segundo cliente puede encenderse en una prueba separada de administración/dominio. |
| WebUbuntuServer-1 en DMZ | 1–2 GB | Frontend y prueba CRUD contra la VIP. |
| Margen operativo | 3 GB | Reserva para picos de GNS3/KVM; suspender ante swap o saturación sostenida. |
| **Total** | **24,5–28,5 GB** | **Compatible con 30 GB físicos si se respeta el encendido por fases.** |

## Debilidades

| Aspecto evaluado | Semáforo | Nota | Lectura crítica dentro del alcance del laboratorio |
|---|:---:|---:|---|
| Inventario previo obligatorio para instanciar las ACL | 🟡 | 68% | `<IP_WEB_DMZ>` e `<IP_MGMT_EQUIPO_n>` no pueden llegar a configuración. El plano y el runbook lo tratan correctamente como una compuerta previa, pero la configuración final depende de ese inventario. |
| Asimetría conocida de ACL entre CorevIOS-1 y CorevIOS-2 | 🟡 | 62% | El documento ordena verificar el estado real antes de cambiar y sustituir un Core por vez; hasta reconciliarlo, el comportamiento bajo failover HSRP no está completamente determinado. |
| Controles de Patroni, etcd y VRRP dentro de VLAN 50 sin mecanismo L2 definido | 🟡 | 60% | El límite está correctamente declarado y aceptado: una ACL de SVI no ve esos flujos locales. Si se requiere aislamiento adicional, el siguiente paso es control de host o L2 compatible con vIOS. |

## Amenazas

| Aspecto evaluado | Semáforo | Nota | Escenario adverso |
|---|:---:|---:|---|
| Incumplir el perfil de capacidad acordado durante una prueba | 🟡 | 55% | Encender VMs adicionales o prolongar retenciones puede inducir timeouts; los umbrales de RAM, swap e I/O deben detener la prueba. |
| Falla de trunk, STP, VLAN o puente virtual durante la prueba | 🟡 | 60% | Es un escenario válido dentro de GNS3. Debe probarse de forma controlada y registrarse qué servicios, quorums y VIP sobreviven. |
| Sustitución de ACL con inventario o adjuntos sin confirmar | 🟡 | 58% | Una IP de Web/gestión incorrecta o una suposición sobre CorevIOS-2 puede bloquear servicios. El runbook mitiga el riesgo con compuerta de inventario, sustitución gradual, rollback y contadores. |
| ACL incompleta o aplicada en un sentido incorrecto | 🟡 | 68% | Puede bloquear AD/DNS, PVE o PostgreSQL, o dejar abiertos servicios de control. El runbook mitiga el riesgo con reglas por función, pruebas positivas/negativas, rollback y validación en ambos Core. |

## Dictamen de devil's advocate

**Aprobable para una demostración de HA lógica dentro de GNS3, con calificación verde. El diseño está coherente entre plano y runbook; antes de implementar sólo debe completarse el inventario de marcadores y confirmar los adjuntos reales en ambos Core.**

Para preservar el valor del ejercicio dentro del proyecto, conviene mantener una VM auxiliar mínima para **QDevice + etcd** durante las pruebas de quorum, encender por fases y reportar los resultados por escenario. La matriz de aceptación debe separar explícitamente:

| Escenario | Resultado que sí es razonable exigir |
|---|---|
| Caída de PG-1 o PG-2 | Un único líder Patroni, VIP correcta y reconexión de aplicación dentro del RTO medido. |
| Caída de PVE-1 o PVE-2 virtual | Continuidad únicamente de los servicios que ya están activos en el nodo superviviente; no reinicio automático de VMs del nodo caído. |
| Caída de la VM auxiliar QDevice/etcd | Degradación o pérdida de la mayoría según el estado de los otros miembros; registrar el comportamiento, no prometer HA. |
| Corte controlado de trunk/VLAN o ACL | Resultado coherente con la matriz de flujos, sin doble líder ni doble escritor, y evidencia de alertas/recuperación. |
| Pérdida de réplica síncrona | El líder conserva la VIP; lecturas continúan y las escrituras quedan bloqueadas hasta recuperar el standby. |

## Modos operativos y distribución de servicios

| Modo | PVE-1 | PVE-2 | Resultado esperado |
|---|---|---|---|
| Bootstrap de dominio | DC1 crea el bosque y DNS inicial | DC2 se incorpora después | Una vez replicado el dominio, DC2 puede atender DNS y autenticación por sí mismo. |
| HA integral / CRUD | DC1 + PG-1 | DC2 + PG-2 + Zabbix | CRUD por `WIN-MGMT → WebUbuntuServer → VIP PostgreSQL`; PG-1 y PG-2 sostienen la réplica síncrona estricta. |
| Operación liviana de administración | Puede permanecer apagado tras completar la réplica AD | DC2 + PG-2 + Zabbix | Administración, DNS y monitoreo son viables. Si PG-1 está apagado, las lecturas pueden continuar, pero el CRUD se bloquea por la sincronía estricta. |
| Modo degradado temporal (solo si se autoriza) | Apagado | PG-2 como único nodo de datos | Para habilitar CRUD habría que relajar la sincronía estricta antes del apagado; cambia la garantía de consistencia y no sustituye el modo HA integral. |

`WIN-MGMT-01/02` no residen dentro de PVE-2: son QEMU externos conectados a VLAN 90. La ubicación recomendada se mantiene: **PVE-1 = DC1 + PG-1** y **PVE-2 = DC2 + PG-2 + Zabbix**. Mover Zabbix a PVE-1 no habilita CRUD con un único PVE y reduciría la observabilidad precisamente ante la caída del nodo con PG-1.

## Conversación técnica: ACL, capa 2 y réplica síncrona

**ACL por función.** Ya existe una matriz concreta, reglas nuevas, orden de sustitución, rollback y pruebas. La ubicación definitiva del Web ya está reconciliada: `WebUbuntuServer-1` es el único frontend en DMZ/VLAN 100. Antes de aplicar sólo se deben sustituir los marcadores por la IP real del Web y las IP de gestión/SNMPv3, y confirmar el estado real de adjuntos en CorevIOS-2. Patroni, etcd y VRRP entre hosts de VLAN 50 requieren control de host o un mecanismo L2 si se desea aislarlos, pues las ACL de SVI no observan ese tráfico.

**Trunk, STP, VLAN y puente virtual.** No son una razón para descartar el diseño: son precisamente fallos de red que el laboratorio puede y debe reproducir. Lo importante es definir qué se espera de cada aislamiento y confirmar que Patroni/etcd no produzcan doble escritor. Conviene hacer estas pruebas una por vez, restaurar el estado y registrar `pvecm status`, `etcdctl endpoint status`, `patronictl list`, dueño de la VIP y transacciones de la aplicación.

**Réplica síncrona estricta.** No es una amenaza ni un defecto aquí; es una decisión de consistencia. Debe figurar como criterio de aceptación: si falta el standby, el primario mantiene lectura y VIP, pero bloquea escrituras. Así se demuestra que el laboratorio prioriza no confirmar una transacción que no tenga la réplica requerida.
