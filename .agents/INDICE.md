# PFT-S1 — índice documental y punto de entrada para agentes

**Estado de la documentación:** diseño de laboratorio; no hay evidencia de cambios aplicados en GNS3, Cisco, Proxmox o las VMs. Los objetivos de capacidad, ACL, quorum y failover siguen en amarillo hasta ejecutar y registrar las pruebas de aceptación.

## Inicio rápido

1. Leer el [plan de trabajo unificado](../PLAN_DE_TRABAJO_UNIFICADO.md) para ejecutar el hito por fases (50 %, 75 % y 100 %), con sus criterios de avance, evidencias y rollback.
2. Leer el [plano ejecutivo](PLANO_EJECUTIVO_REESTRUCTURACION_HA.md) para conocer la topología, direccionamiento, orden de migración y pruebas.
3. Antes de cualquier cambio Cisco, leer completo el [runbook de ACL](ACL_MATRIZ_Y_RUNBOOK.md). Es la fuente normativa de las reglas, inventario previo, sustitución, validación y rollback.
4. Consultar los [acuerdos de alcance](INSIGHTS_CONVERSACION_REESTRUCTURACION_HA.md) para distinguir lo incluido de lo expresamente excluido.
5. Registrar resultados en las [evidencias de implementación](EVIDENCIAS_DE_IMPLEMENTACION.md).
6. Usar los FODA sólo como control crítico y antecedente; no ejecutar configuraciones desde ellos.

## Fuente de verdad y precedencia

| Prioridad | Documento | Uso y estado |
|---:|---|---|
| 1 operativo | [PLAN_DE_TRABAJO_UNIFICADO.md](../PLAN_DE_TRABAJO_UNIFICADO.md) | **Vigente, punto de control operativo.** Integra el flujo de trabajo y el TO-DO en las fases acumulativas 50 %, 75 % y 100 %; define responsables, compuertas, evidencia y criterios de cierre. |
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
- No describir el resultado como HA física integral ni como implementación comprobada hasta registrar las pruebas.

## Compuertas antes de implementar

1. Confirmar en equipos reales SVI, HSRP, OSPF, prefijo `/27`, `NAT_INSIDE` y adjuntos ACL de ambos Core.
2. Inventariar la IP estática de `WebUbuntuServer-1` y las IP de gestión/SNMPv3. No cargar ACL con `<IP_WEB_DMZ>` ni `<IP_MGMT_EQUIPO_n>`.
3. Crear las nuevas ACL sin adjuntarlas; cambiar referencias en un Core por vez y conservar la captura para rollback.
4. Ejecutar y registrar pruebas de capacidad, quorum PVE, AD/DNS, caída de primario PostgreSQL, partición, caída de réplica y reintegración.
5. Antes de crear el clúster PVE, demostrar con VMs temporales que `vmbr0` reenvía tráfico desde cada PVE anidado hacia gateway, el otro PVE y VLAN 90/100; un fallo bloquea el despliegue posterior.

## Divergencias documentales que requieren decisión antes de cambiar

1. **Evidencia de ejecución.** Ningún Markdown aporta resultados de pruebas ni inventario completo. La evidencia práctica es una compuerta obligatoria antes del siguiente hito; no convertir supuestos de diseño en hechos.

Las decisiones ya resueltas son: Zabbix monitorea por SNMPv3 toda la infraestructura de red, excepto end hosts; y `ACL_MATRIZ_Y_RUNBOOK.md` es la única fuente normativa de ACL. Los documentos afectados fueron alineados con esas decisiones.

## Convenciones para futuras actualizaciones

- Mantener el plano y el runbook alineados; si una decisión de alcance cambia, actualizar también `INSIGHTS` o reemplazarlo con una decisión fechada.
- Marcar los documentos de evaluación como históricos cuando una recomendación quede incorporada en el plano.
- Añadir fecha, estado y evidencia enlazable a toda configuración realmente aplicada o prueba ejecutada.
- Usar `PLAN_DE_TRABAJO_UNIFICADO.md` para gestionar los hitos 50 %, 75 % y 100 %, con responsable, cierre y evidencia esperada.
