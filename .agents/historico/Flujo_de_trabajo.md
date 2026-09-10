# Flujo de trabajo supervisado — PFT-S1 en GNS3

**Propósito.** Este documento guía al supervisor humano durante el resto del proyecto. La ejecución técnica se realiza manualmente en GNS3, consolas Cisco, Proxmox y máquinas virtuales; el supervisor decide el avance, verifica cada resultado y conserva evidencia reproducible.

**Estado inicial (2026-08-29).** El material disponible describe un diseño, no una implementación comprobada. No se debe declarar alta disponibilidad física ni cumplimiento de RTO/RPO hasta completar y registrar las pruebas de aceptación.

## 1. Modelo de control: bucle PIV con humano en el circuito

Cada cambio se opera como un ciclo corto y trazable:

```text
PLANIFICAR → IMPLEMENTAR → VERIFICAR → decisión humana
     ↑                                        │
     └──── corregir / rollback / nuevo PIV ───┘
```

| Fase | El humano supervisor hace | Se puede avanzar sólo si |
|---|---|---|
| **Planificar** | Contrasta el diseño con el estado real, delimita el cambio, revisa dependencia, riesgo, prueba y rollback. | No quedan datos críticos desconocidos ni marcadores en la configuración que se aplicará. |
| **Implementar** | Ejecuta un cambio pequeño en GNS3, por consola y dentro de una ventana controlada. Nunca combina cambios no relacionados. | Se conserva la configuración anterior y existe un camino de rollback probado o claramente ejecutable. |
| **Verificar** | Ejecuta pruebas positivas, negativas y de resiliencia; registra salidas, contadores, tiempos y resultado. | Los criterios de aceptación son medibles y se cumplen sin degradación no aceptada. |
| **Decidir** | Marca el ítem como `Aprobado`, `Fallido` o `Bloqueado`; actualiza el TO-DO y autoriza el siguiente ciclo. | Un fallo de seguridad, disponibilidad o integridad queda resuelto o obliga a no avanzar. |

El supervisor no debe sustituir evidencia por una apreciación visual de la topología. Toda aprobación requiere fecha, responsable, comandos o acciones ejecutadas, resultado y ubicación de la evidencia.

## 2. Fuentes de verdad y límites de alcance

Leer antes de actuar, en este orden:

1. `./.agents/PLANO_EJECUTIVO_REESTRUCTURACION_HA.md`: arquitectura, direccionamiento, orden de migración, pruebas y rollback.
2. `./.agents/ACL_MATRIZ_Y_RUNBOOK.md`: única norma para ACL; incluye inventario previo, sustitución, validación y rollback.
3. `./.agents/INSIGHTS_CONVERSACION_REESTRUCTURACION_HA.md`: decisiones de alcance y comportamiento esperado de HA.
4. `./.agents/REQUERIMIENTOS_Y_TODO.md`: requisitos RQ-01 a RQ-09 y pendientes priorizados.
5. `./.agents/EVIDENCIAS_DE_IMPLEMENTACION.md`: registro que debe completarse durante la ejecución.

Los FODA son controles críticos, no instrucciones de configuración. El alcance del hito incluye VLAN 50 `/27`, ACL funcionales, PVE-1/PVE-2/QDevice, AD DS + DNS, PostgreSQL HA con Patroni/etcd/Keepalived, WebUbuntuServer-1 como cliente de prueba DMZ y Zabbix para infraestructura definida. Quedan fuera WSUS, DHCP redundante, réplica/arranque HA de VMs Proxmox, backup/WAL/PITR, migración de aplicación/esquema/datos, TLS/certificados, monitoreo del frontend y custodia/rotación de secretos.

Restricciones que el supervisor debe comunicar al evaluar resultados:

- La práctica demuestra HA **lógica de servicios** dentro de un único host GNS3; no tolera la caída de ese host físico.
- DHCP en CorevIOS-1 y Zabbix en PVE-2 son SPOF aceptados.
- Si falla una réplica PostgreSQL, la sincronía estricta debe bloquear nuevas escrituras; no es una falla del diseño.
- Las ACL de SVI no inspeccionan el tráfico local entre hosts de VLAN 50 (Patroni, etcd y VRRP). No afirmar que esos flujos estén aislados por las ACL Cisco.
- El tráfico de PostgreSQL, Patroni y etcd no usa TLS ni certificados en este laboratorio aislado; no trasladar esta decisión a producción.

## 3. Reglas permanentes de operación

1. Mantener una copia recuperable del proyecto `.gns3project`, de las configuraciones Cisco y de los discos/VM existentes antes de iniciar la migración. No eliminar el estado anterior hasta aprobar la ventana integrada.
2. Trabajar desde consola local o una sesión de administración autorizada. Para red, cambiar **un Core por vez**; para servicios, cambiar **un componente o una hipótesis por vez**.
3. Capturar el estado antes y después de cada cambio. Nombrar evidencias con fecha, fase e ítem, por ejemplo `2026-08-29_PIV-03_ACL-Core1_pre.txt`.
4. Sustituir todos los valores de ejemplo y marcadores antes de aplicarlos. Está prohibido cargar `<IP_WEB_DMZ>`, `<IP_MGMT_EQUIPO_n>`, `<NTP1>`, secretos de ejemplo o cualquier placeholder.
5. No guardar una configuración definitiva (`write memory`, cambios persistentes de VM o de servicio) hasta completar las pruebas del ciclo PIV correspondiente.
6. Ante una pérdida inesperada de conectividad, dos posibles escritores, pérdida de quorum, swap sostenido, falta de disco o resultado ambiguo: detener, preservar evidencia, ejecutar rollback si corresponde y marcar `Fallido` o `Bloqueado`.

## 4. Preparación única: PIV-0 — control del proyecto

### Planificar

- Asignar un responsable humano a cada RQ-01…RQ-09 y definir una carpeta o repositorio de evidencias sin credenciales ni claves SNMPv3.
- Definir una ventana de trabajo por fase y una segunda persona disponible para observación/cronometraje durante los ensayos de fallo, si es posible.
- Confirmar que GNS3 usa KVM, que VT-x/EPT o AMD-V/NPT y virtualización anidada están habilitados, y congelar la baseline: PVE 8.4.x, Ubuntu 24.04.4, PostgreSQL 16.15, Patroni 4.0.10, etcd 3.5.x, Keepalived 2.2.8 y Zabbix 7.0 LTS. Validar que las fuentes aprobadas resuelven esas versiones antes de instalar; registrar versión de GNS3/vIOS y hash del ISO VirtIO sin actualizarlos durante el hito.
- Validar desde un host temporal la salida única por Border NAT hacia repositorios oficiales HTTPS y NTP externo. Después de crear AD, los clientes usarán AD DNS hacia su upstream y sólo el PDC sincronizará NTP externo.
- Definir el perfil de capacidad: durante la prueba crítica, encender sólo red imprescindible, PVE-1, PVE-2, QDevice, un cliente Windows y el Web; mantener Zabbix y nodos no esenciales apagados si no participan.

### Implementar

- Crear el respaldo inicial de proyecto, configuraciones y discos existentes; registrar la ruta y una fecha.
- Crear la estructura de evidencias y copiar la plantilla de seguimiento de `EVIDENCIAS_DE_IMPLEMENTACION.md` al medio de trabajo elegido.
- Registrar capacidad basal del host: RAM libre, uso de swap, disco libre, CPU e I/O. Reservar 2–3 GB de RAM y al menos 30 GB de disco libre.

### Verificar y decidir

- Ejecutar una observación de 10–15 minutos con la carga prevista o, si todavía no existe, con los nodos de red base. Si aparece swap, saturación sostenida o se incumplen los márgenes, no desplegar la capa HA: reducir carga o redimensionar antes.
- Marcar RQ-09 como aprobado sólo después de la prueba integrada final, no en esta línea base.

## 5. PIV-1 — inventario real y compuerta de cambios

Esta fase es obligatoria. Convierte los supuestos documentales en datos de la topología GNS3 real.

### Planificar

Preparar una tabla con: equipo, consola, interfaz, VLAN, IP/máscara, gateway, rol, versión, configuración actual, cambio esperado y evidencia. Reservar columnas para la IP real de `WebUbuntuServer-1` y para todas las IP de gestión/SNMPv3 de Core, distribución, acceso, Border e ISP.

### Implementar: relevar, no modificar

En ambos Core capturar, como mínimo:

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

En Border Router-1 y Border Router-2, confirmar la ACL `NAT_INSIDE` y el NAT aplicado. En `WebUbuntuServer-1`, capturar `ip -br address`, ruta por defecto y DNS; confirmar que está en VLAN 100. En infraestructura de red, relevar IP de gestión, conectividad y estado/configuración SNMPv3 sin copiar usuarios, claves ni passphrases a la evidencia.

### Verificar y decidir

El supervisor compara resultados con el plano y resuelve estas compuertas:

| Compuerta | Decisión requerida |
|---|---|
| VLAN 50, HSRP, OSPF y NAT no coinciden con el diseño `/27` | Detener y actualizar el plan/runbook antes de modificar. |
| CorevIOS-2 tiene adjuntos ACL distintos de CorevIOS-1 | Documentar el estado real y preparar sustitución/rollback específico para cada Core. |
| Falta la IP del Web o una IP SNMPv3 | No aplicar ACL funcionales. |
| Interfaz o cableado real no coincide con el plano | Corregir el inventario y validar el impacto antes de seguir. |
| Hay una IP estática que colisiona con la propuesta | Reservarla o renumerar con un nuevo PIV aprobado. |

Registrar la primera fila de evidencia como `Aprobado` sólo cuando no quede información crítica pendiente.

## 6. PIV-2 — red base, VLAN 50 y conectividad L2/L3

### Planificar

- Usar el inventario aprobado para confirmar puertos de PVE, trunk Dist1–Dist2 y puerto del QDevice.
- Preparar configuraciones específicas y una copia de cada `running-config` antes del cambio.
- Separar el cambio de trunk/puertos del cambio de máscara, OSPF y NAT si el laboratorio no permite diagnosticar ambos a la vez.

### Implementar

1. Crear el trunk L2 DistvIOS-1 ↔ DistvIOS-2 y los puertos access VLAN 50 para PVE-1/PVE-2 conforme al plano; configurar el puerto VLAN 90 del QDevice. No modificar los puertos ya correctos de los clientes de gestión.
2. Verificar trunk, VLAN 50 y STP antes de conectar o arrancar PVE.
3. En ventana de mantenimiento, ampliar VLAN 50 a `192.168.50.0/27` en **ambos** Core, actualizar OSPF y la ACL estándar `NAT_INSIDE` en ambos Border. `NAT_INSIDE` selecciona NAT; no es una ACL de seguridad.
4. Actualizar DHCP sólo en CorevIOS-1: excluir `.1-.30` en VLAN 50 y entregar DNS `.12/.13` y sufijo `pft.test` en los pools definidos. No crear DHCP para VLAN 50 ni 100.

### Verificar

- VLAN 50 aparece en forwarding en los trunks esperados, y STP no presenta un loop inesperado.
- HSRP `.1` responde; OSPF tiene vecinos y ruta para `192.168.50.0/27`; ambos Border usan wildcard `0.0.0.31` para NAT.
- No existen leases DHCP sobre direcciones estáticas y las demás VLAN mantienen su prefijo y conectividad.
- Probar la continuidad tras un failover HSRP controlado cuando sea seguro hacerlo.

### Decidir / rollback

Si falla HSRP, OSPF, NAT, STP o conectividad de las VLAN no afectadas, restaurar máscara `/29`, wildcard OSPF/NAT y configuración de puertos desde las capturas. No continuar a servicios hasta aprobar RQ-01.

## 7. PIV-3 — ACL funcionales y segmentación verificable

### Planificar

- Leer completo `ACL_MATRIZ_Y_RUNBOOK.md`; sus bloques sustituyen cualquier resumen de este documento.
- Instanciar sus ACL `PFT_*` con la IP real del Web y las IP de gestión. Confirmar que los DC requieren el rango RPC documentado o acordar el rango fijo antes de reducirlo.
- Preparar una hoja de pruebas positivas/negativas y el rollback de adjuntos de cada Core.

### Implementar

1. Confirmar que VLAN 50, OSPF y `NAT_INSIDE` ya usan `/27`.
2. Cargar en ambos Core las ACL nuevas **sin adjuntarlas**. Revisar sintaxis, nombres y contadores iniciales.
3. Sustituir los adjuntos de SVI en un Core por vez. En VLAN 100, retirar las referencias anteriores reales —incluido `FILTRO_DMZ` cuando exista— antes de adjuntar una única `PFT_V100_FUNC_IN` de entrada.
4. Ejecutar pruebas y revisar contadores antes de guardar; repetir en el segundo Core y probar el comportamiento tras failover HSRP.

### Verificar

Pruebas mínimas obligatorias:

- Desde VLAN 90: AD/DNS, PVE TCP/22 y 8006 en ambos nodos, y PostgreSQL VIP TCP/5432 para la cuenta autorizada.
- Desde Web DMZ: DNS de DC y conexión SSL a `postgres.pft.test:5432` mediante la VIP.
- Desde VLAN 60: negar PVE/gestión; desde VLAN 10/20/30/40 representativas: negar TCP/22 y 8006 a PVE.
- Desde DMZ no autorizada: negar acceso a VLAN 90 y a la VIP PostgreSQL.
- Desde Zabbix: sondear por SNMPv3 únicamente cada equipo de infraestructura inventariado; no registrar end hosts.

Verificar que los `permit` y `deny ... log` relevantes incrementan. Un contador sin cambios puede deberse a tráfico same-VLAN; no usarlo para afirmar que existe un control L3 donde no lo hay.

### Decidir / rollback

Un permiso excesivo, un servicio esencial bloqueado o diferencia no explicada entre Core obliga a retirar `PFT_*`, restaurar exactamente los adjuntos respaldados y abrir un PIV correctivo. Aprobar RQ-02 y RQ-03 sólo con evidencia de ambos Core, failover y sondeos SNMPv3 requeridos.

## 8. PIV-4 — plataforma Proxmox y quorum

### Planificar

- Crear discos independientes para PVE-1, PVE-2, clientes y QDevice; nunca arrancar dos nodos desde el mismo qcow2.
- Confirmar asignación real de CPU/RAM y que la RAM de VMs internas no sobreasigna la RAM del PVE contenedor.
- Distribuir roles: PVE-1 alberga DC1 y PG-1; PVE-2 alberga DC2 y PG-2 y, fuera de la prueba crítica, Zabbix.

### Implementar

1. Crear QDevice Debian en VLAN 90, instalar QNetd y el tercer etcd.
2. Instalar PVE-1 `.10/27` y PVE-2 `.11/27` en VLAN 50; comprobar FQDN, ruta, DNS y tiempo antes del clúster.
3. **Compuerta bloqueante:** crear una VM temporal en cada PVE conectada a `vmbr0`. Desde ambas, comprobar gateway `.1`, la VM temporal opuesta, QDevice `.90.28` y Web en VLAN 100; revisar aprendizaje MAC en los switches. Retirar las VMs temporales tras registrar éxito. Si falla, detener y corregir la red anidada: no crear clúster ni VMs definitivas.
4. Sólo después de aprobar la compuerta, crear el clúster desde PVE-1, unir PVE-2 y configurar QDevice desde PVE-1. No crear `pvesr` ni recursos HA de VM.

### Verificar y decidir

- `pvecm status` informa `Quorate: Yes` y tres votos esperados.
- Se registra el comportamiento ante caída controlada de un PVE: sobreviven los servicios ya activos en el otro PVE, pero las VMs del nodo perdido no reinician automáticamente.
- Si se pierde quorum, hay errores de resolución/tiempo o la capacidad se satura, corregir antes de desplegar AD/BD. Aprobar la evidencia de quorum sólo después de recuperación a estado sano.

## 9. PIV-5 — AD DS, DNS, NTP, DHCP y clientes

### Planificar

- Definir nombres, OUs, grupos AGDLP y cuentas de servicio según el plano; guardar secretos fuera de los Markdown y de la evidencia.
- Confirmar que DC1 `.12` y DC2 `.13` tienen IP fija, DNS cruzado y ubicación en PVE distintos.

### Implementar

1. Instalar DC1 con AD DS + DNS y crear `pft.test`; incorporar DC2 como controlador adicional y DNS.
2. Configurar zona directa/reversa, registros de PVE, PG, VIP, Zabbix y Web (sólo con IP confirmada); configurar tiempo con DC1/PDC como fuente autorizada y DC2/miembros siguiendo la jerarquía.
3. Renovar DHCP de los clientes Windows de VLAN 90, unirlos al dominio, moverlos a su OU de gestión y aplicar GPO base.

### Verificar y decidir

- `dcdiag /test:dns /v`, `repadmin /replsummary` y consulta SRV LDAP sin fallos.
- Los clientes obtienen `.12/.13`, resuelven los nombres, se unen al dominio y aplican GPO.
- Con un PVE caído, el DC superviviente resuelve y autentica. Cualquier fallo de DNS, tiempo o replicación bloquea el despliegue de PostgreSQL, porque Patroni y los clientes dependen de esta base.

## 10. PIV-6 — PostgreSQL HA y frontend

### Planificar

- Verificar conectividad entre `PG-1 .14`, `PG-2 .15` y `QDevice .90.28`, y reservar una ventana exclusiva para ensayos de fallo.
- Definir el método de cronometraje: inicio de la caída, promoción, presencia de VIP, primera transacción CRUD exitosa. Preparar una transacción de prueba identificable.
- Confirmar que Patroni será la única autoridad de promoción y que Keepalived sólo observa la API `/primary`; no se permiten scripts `pg_ctl promote`, `notify_master` ni promoción basada sólo en `pg_isready`.

### Implementar

1. Instalar etcd en los tres miembros y verificar el quorum antes de iniciar Patroni.
2. Instalar Patroni/PostgreSQL en ambos PG con réplica síncrona estricta y credenciales reales protegidas; deshabilitar el servicio PostgreSQL de paquete que competiría por el mismo directorio de datos.
3. Iniciar Patroni en PG-1 y después PG-2; crear una base, usuario y tabla de **prueba** únicamente mediante el líder. La migración de aplicación/esquema/datos no pertenece a este hito.
4. Configurar Keepalived unicast para publicar `.16` sólo donde Patroni responda `/primary`.
5. Instalar el cliente PostgreSQL en `WebUbuntuServer-1` y usarlo como cliente de prueba contra `postgres.pft.test` y VIP `.16`, sin TLS y con reintentos con backoff; nunca con `.14` o `.15`. No se exige modificar o validar la lógica de una aplicación existente.

### Verificar: ensayos aislados y medidos

Registrar antes, durante y después: `pvecm status`, `etcdctl endpoint status`, `patronictl list`, dueño de VIP, estado de réplica y resultado de la transacción.

| Ensayo | Resultado de aceptación |
|---|---|
| Estado normal | Un `Leader`, un `Sync Standby`, una única VIP y CRUD vía frontend/VIP. |
| Caída de PG-1 o PVE-1 primario | PG-2 se promueve, recibe la VIP y CRUD vuelve en ≤ 60 s. |
| Caída de PG-2 réplica | PG-1 mantiene liderazgo/VIP; las lecturas siguen y nuevas escrituras se bloquean hasta recuperar la réplica. |
| Partición de PG-1 respecto de PG-2 y QDevice | No hay dos `primary` ni dos nodos aceptando escrituras. |
| Reintegración | El antiguo primario vuelve como réplica; no existe failback automático. |

### Decidir / rollback

Detener de inmediato el ensayo si aparecen dos escritores, una VIP duplicada o datos divergentes. Aislar el posible primario antiguo antes de cualquier reintegración y conservar evidencia. No aprobar RQ-05 a RQ-08 hasta cumplir las cuatro pruebas. No afirmar protección frente a borrado/corrupción: backup/PITR está fuera de alcance.

## 11. PIV-7 — monitoreo, capacidad integrada y aceptación final

### Planificar e implementar

- Instalar Zabbix en PVE-2 cuando la plataforma base esté estable; usar retención corta y plantillas mínimas para el laboratorio.
- Añadir Agent 2 a PVE, DC1/DC2 y PG-1/PG-2; monitorear por SNMPv3 sólo Core, distribución, acceso, Border, ISP y red intermedia inventariados.
- No agregar end hosts —incluido frontend— al inventario SNMP. Configurar alertas de PVE, DNS, replicación AD, Patroni/líder, réplica síncrona, VIP e indisponibilidad SNMP.

### Verificar y decidir

1. Probar al menos una alerta de cada familia y confirmar recuperación de la alerta.
2. Repetir la ventana integrada de 10–15 minutos con el perfil de recursos del hito, incluyendo CRUD y un failover representativo. Registrar RAM, swap, disco libre, CPU/I/O y tiempos.
3. Marcar RQ-09 como aprobado sólo si no hay swap, quedan 2–3 GB libres de forma sostenida y no hay pérdida de respuesta atribuible a saturación.
4. Cerrar cada fila de `EVIDENCIAS_DE_IMPLEMENTACION.md` con `Aprobado`, `Fallido` o `Bloqueado`, fecha, responsable y enlace/ubicación. Un fallo en seguridad, disponibilidad o integridad reabre el PIV correspondiente.

## 12. Cierre del hito y reporte del supervisor

El supervisor autoriza el cierre sólo cuando RQ-01…RQ-09 estén respaldados por evidencia y no queden bloqueos P0/P1. El informe final debe separar claramente resultados demostrados, fallos, riesgos aceptados y elementos fuera de alcance.

| Estado | Cómo reportarlo |
|---|---|
| Aprobado | Requisito, escenario, fecha, evidencia, métricas y limitaciones. |
| Fallido | Síntoma, impacto, evidencia, rollback aplicado y PIV correctivo pendiente. |
| Bloqueado | Dependencia concreta, responsable y condición para reanudar; no presentarlo como implementado. |
| Fuera de alcance | WSUS, DHCP redundante, HA/reinicio de VM y backup/PITR; no penalizar ni declarar cumplimiento implícito. |

Como mínimo, conservar: inventario real, respaldos pre/post, topología GNS3 final, tablas de IP/roles, configuraciones Cisco saneadas, estado PVE/AD/Patroni/etcd, pruebas ACL, capturas de Zabbix, cronometrajes de fallos y registro de decisiones. Nunca incluir contraseñas, claves privadas, communities ni secretos SNMPv3.

## 13. Lista breve de autorización por ciclo

Antes de pasar de un PIV al siguiente, el supervisor responde **sí** a todas estas preguntas:

- ¿El cambio aplicado coincide con un plan aprobado y tiene rollback?
- ¿El inventario, interfaces, IP y dependencias son datos reales, no supuestos?
- ¿Las pruebas funcionales y de denegación pasaron y tienen evidencia fechada?
- ¿Se verificó el comportamiento bajo el fallo relevante, sin ocultar los SPOF aceptados?
- ¿Los recursos del host siguen dentro del margen?
- ¿Se actualizó el registro de evidencias, TO-DO y documentación cuando el estado real difiere del diseño?

Si alguna respuesta es no, el ciclo continúa en **Planificar**; no se autoriza el siguiente hito.

## 14. Trazabilidad obligatoria con el plano ejecutivo

El TO-DO ejecutable de `./.agents/REQUERIMIENTOS_Y_TODO.md` descompone el orden de migración del plano para evitar pasos implícitos. Antes de comenzar cada paquete, el supervisor confirma esta correspondencia:

| Plano ejecutivo: orden de migración | Paquete TO-DO | Punto que no se debe asumir |
|---:|---|---|
| 1. Resguardo previo | P0.3, P0.7 | El respaldo debe ser recuperable y mantenerse hasta el cierre; no equivale a PITR. |
| 2. QDevice/QNetd/etcd | P4.1 y P6.1 | QNetd y etcd cumplen funciones distintas; ambos necesitan conectividad y quorum comprobados. |
| 3. Trunk y puertos PVE | P1.5, P2.1 | Interfaces reales, VLAN permitidas y estado STP deben validarse antes de conectar PVE. |
| 4. VLAN 50, OSPF y NAT | P2.2–P2.5 | El cambio alcanza ambos Core y ambos Border; NAT no sustituye ACL de seguridad. |
| 5. Web DMZ y ACL | P1.3–P1.6, P3.1–P3.6 | No se aplican ACL con marcadores ni se presupone simetría de Core. |
| 6. PVE y quorum | P4.2–P4.4 | Quorum no implica reinicio HA de VMs; no crear `pvesr`/recursos HA. |
| 7. DC1/DC2, DNS y NTP | P5.1–P5.3 | DNS, tiempo y replicación son dependencias de clientes y servicios posteriores. |
| 8. DHCP y clientes | P2.3, P5.4 | Los clientes deben renovar, recibir DNS correcto y aplicar GPO; VLAN 50/100 no reciben DHCP. |
| 9. PostgreSQL HA y fallos | P6.1–P6.7 | Patroni es la autoridad única; cada escenario se ensaya aislado, se mide y se reintegra sin failback. |
| 10. Cliente DMZ de prueba | P6.5 | `WebUbuntuServer-1` usa únicamente `postgres.pft.test`/VIP, sin TLS y sin IP de nodo PG; no se migra una aplicación existente. |
| 11. Zabbix | P7.1–P7.3 | Sólo infraestructura de red por SNMPv3, sin end hosts y con alertas verificadas. |
| 12. Windows MGMT | P5.4 | Reemplazo de mgmtPC, drivers, DHCP, dominio, DNS, GPO y acceso PVE autorizado. |
| 13. Web único y rollback retenido | P1.3, P6.5, P7.6 | El Web único permanece en DMZ; activos anteriores no se eliminan antes de aprobación integral. |
