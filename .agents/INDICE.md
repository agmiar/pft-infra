# PFT-S1 — índice documental y punto de entrada para agentes

**Estado documental (revisado 2026-09-18; evidencia más reciente: 2026-09-17):** el proyecto combina diseño y resultados de implementación verificados. El registro acredita P0.2–P0.7, P1.1–P1.3, P2.1–P2.4 y P4.1–P4.5, además de P5.1. P1.6 y P5.2 están Bloqueados; P5.3 está Pendiente. Sólo RQ-01 está aprobado; RQ-02–RQ-09 siguen abiertos. El corte no es una verificación en vivo. La matriz de alineación al nuevo requerimiento docente está en [ALINEACION_REQ_INFRA_S4_2026.md](ALINEACION_REQ_INFRA_S4_2026.md).

## Inicio rápido

1. Leer el [plan de trabajo unificado](../PLAN_DE_TRABAJO_UNIFICADO.md) para ejecutar el hito por fases (50 %, 75 % y 100 %), con sus criterios de avance, evidencias y rollback. Contrastar el alcance del semestre con la matriz docente enlazada arriba.
2. Leer el [plano ejecutivo](PLANO_EJECUTIVO_REESTRUCTURACION_HA.md) para conocer la topología, direccionamiento, orden de migración y pruebas.
3. Antes de cualquier cambio Cisco, leer completo el [runbook de ACL](ACL_MATRIZ_Y_RUNBOOK.md). Es la fuente normativa de las reglas, inventario previo, sustitución, validación y rollback.
4. Consultar los [acuerdos de alcance](INSIGHTS_CONVERSACION_REESTRUCTURACION_HA.md) para distinguir lo incluido de lo expresamente excluido.
5. Registrar resultados en las [evidencias de implementación](EVIDENCIAS_DE_IMPLEMENTACION.md).
6. Usar los FODA sólo como control crítico y antecedente; no ejecutar configuraciones desde ellos.

## Fuente de verdad y precedencia

| Prioridad | Documento | Uso y estado |
|---:|---|---|
| Requisito externo | [ALINEACION_REQ_INFRA_S4_2026.md](ALINEACION_REQ_INFRA_S4_2026.md) | Matriz de Req_Infra_Proyecto_S4_2026_V2.pdf frente al plan y a la evidencia. Registra brechas; no convierte los requisitos docentes en cambios ejecutados ni cierra requisitos por sí sola. |
| 1 operativo | [PLAN_DE_TRABAJO_UNIFICADO.md](../PLAN_DE_TRABAJO_UNIFICADO.md) | **Vigente para el alcance interno PFT-S1 y sus tareas actuales.** Integra el flujo de trabajo en fases acumulativas 50 %, 75 % y 100 %. La cobertura completa del nuevo requerimiento docente está pendiente según la matriz de alineación. |
| 1 | [PLANO_EJECUTIVO_REESTRUCTURACION_HA.md](PLANO_EJECUTIVO_REESTRUCTURACION_HA.md) | **Vigente, fuente principal.** Plan de implementación del hito: topología, IP, Proxmox, AD/DNS, Patroni, migración, pruebas y rollback. |
| 1 para ACL | [ACL_MATRIZ_Y_RUNBOOK.md](ACL_MATRIZ_Y_RUNBOOK.md) | **Vigente, fuente normativa especializada.** Sus bloques Cisco y procedimiento prevalecen sobre el resumen de ACL del plano. Está listo para ejecutar sólo después de completar su inventario y compuertas. |
| 2 | [INSIGHTS_CONVERSACION_REESTRUCTURACION_HA.md](INSIGHTS_CONVERSACION_REESTRUCTURACION_HA.md) | **Vigente como decisión de alcance.** Registra las decisiones que guiaron el plano. Úsese para resolver alcance, no como runbook técnico. |
| 3 | [FODA_sin_fisico.md](FODA_sin_fisico.md) | **Vigente como evaluación crítica.** Evalúa el plano y el runbook actuales en el contexto de recursos limitados; no prescribe cambios. |
| Histórico | [FODA_final.md](historico/FODA_final.md) | Evaluación anterior parcialmente superada: indica que faltaban ACL completas y que Zabbix no monitoreaba red, puntos que luego cambiaron en el runbook/plano. Conserva valor como registro de riesgos físicos, PITR y capacidad. |
| Histórico | [FODA_Y_CRITICA_PLANO_REESTRUCTURACION_HA.md](historico/FODA_Y_CRITICA_PLANO_REESTRUCTURACION_HA.md) | Diagnóstico anterior que motivó los acuerdos de `INSIGHTS`. Contiene alcance ya descartado (WSUS, HA de VMs) y el modelo previo de promoción PostgreSQL; no es una guía de implementación actual. |

## Estado objetivo del hito

- VLAN 50 pasa de `192.168.50.0/29` a `192.168.50.0/27`; se conservan HSRP `.1` y Core `.2/.3`.
- Servicios incluidos: PVE-1/PVE-2/QDevice, AD DS + DNS redundantes, PostgreSQL con Patroni + etcd + réplica síncrona, VIP `.16`, WebUbuntuServer-1 como cliente de prueba en DMZ/VLAN 100, ACL inter-VLAN y Zabbix limitado.
- PostgreSQL: Patroni es la única autoridad de promoción. Keepalived sólo publica la VIP en el nodo que Patroni declara `primary`; no hay failback automático.
- Exclusiones aceptadas: WSUS, réplica/arranque HA de VMs PVE, backup/WAL/PITR de PostgreSQL, DHCP redundante, migración de aplicación/esquema/datos, TLS/certificados, monitoreo del frontend y custodia/rotación de secretos. El host físico GNS3, DHCP de CorevIOS-1 y Zabbix en PVE-2 son SPOF aceptados.
- Informar estado por requisito y enlazar su evidencia. No generalizar aprobaciones internas como cobertura total S4 ni como HA física.

## Compuertas antes del siguiente PIV

1. Antes de un cambio Cisco, capturar el estado real actual de ambos Core/Border; las evidencias P1/P2 están fechadas 2026-08-30 y no sustituyen un preestado nuevo.
2. P3 sigue sin cierre: usar el runbook ACL, confirmar las IP actuales de Web/gestión/SNMPv3, dejar las ACL sin adjuntar para revisión, cambiar un Core por vez y guardar pre/post y rollback.
3. El clúster PVE ya existe. P4.3 recibió aprobación manual con las limitaciones explicitadas en el registro; no describir como ejecutadas las pruebas P4T-PVE2, VM-a-VM ni aprendizaje de MAC.
4. Antes de reanudar P5.2, verificar de nuevo quorum, votos QDevice y estados de ambos DC. La última captura del 2026-09-17 informó PVE-2 no quorate, QDevice con 0 votos y DC2 detenida; no asumir que ese estado persiste ni que se corrigió.
5. Para nuevas pruebas de capacidad, AD/DNS o PostgreSQL, seguir las precondiciones y evidencias de Pn.m; no extrapolar aprobaciones de una prueba histórica a un estado actual.
6. Antes de declarar cobertura S4, resolver las brechas y cantidades pendientes de la [matriz docente](ALINEACION_REQ_INFRA_S4_2026.md) e integrar tareas/evidencias al plan operativo.

## Estado de evidencia y alcance docente — corte 2026-09-17

- El registro de evidencias contiene resultados reales enlazados; no es correcto describir el proyecto completo como “sólo diseño”. Los hitos aprobados y sus límites están en [EVIDENCIAS_DE_IMPLEMENTACION.md](EVIDENCIAS_DE_IMPLEMENTACION.md).
- La última observación técnica del 2026-09-17 registró PVE-2 sin quorum, QDevice con 0 votos y DC2 detenida. P5.2 quedó Bloqueado. No se ha hecho una comprobación en vivo posterior; no afirmar que ese sea el estado actual sin revalidarlo.
- La evidencia interna aprobó RQ-01. RQ-02–RQ-09 todavía no tienen cierre aprobado en el registro.
- El PDF docente S4 pide dos sitios lógicos/de red, enlace intersedes, AD Sites and Services, DHCP por sede, servicio de archivos, al menos cinco GPO efectivas, backup/restauración y autenticación de la aplicación contra AD, entre otros. El plan vigente sólo cubre parcialmente ese alcance; la matriz de alineación detalla cada brecha y las decisiones pendientes.
- Aclarar antes de rebaselinar cuántos clientes se esperan por sede/área y cómo se interpreta el escenario de 1.500 usuarios frente al mínimo explícito de 20 cuentas de prueba.

Las decisiones internas ya resueltas siguen vigentes: Zabbix debe monitorear por SNMPv3 la infraestructura de red, excepto end hosts; `ACL_MATRIZ_Y_RUNBOOK.md` es la única fuente normativa de ACL.

## Convenciones para futuras actualizaciones

- Mantener el plano y el runbook alineados; si una decisión de alcance cambia, actualizar también `INSIGHTS` o reemplazarlo con una decisión fechada.
- Marcar los documentos de evaluación como históricos cuando una recomendación quede incorporada en el plano.
- Añadir fecha, estado y evidencia enlazable a toda configuración realmente aplicada o prueba ejecutada.
- Usar `PLAN_DE_TRABAJO_UNIFICADO.md` para gestionar los hitos 50 %, 75 % y 100 %, con responsable, cierre y evidencia esperada.
