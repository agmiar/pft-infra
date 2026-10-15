# Plan de trabajo unificado — PFT-S1 / S4

**Estado:** Pendiente de implementación. **Fecha de replanificación:** 2026-09-19.

**Exclusiones explícitas del operador — 2026-10-10:** S0.2, S0.3, S0.4 y P3.1 no se ejecutarán ni se exigirán como compuertas de este hito. S5 se implementa sobre el estado operativo existente y con las limitaciones de trazabilidad que correspondan.

Este plan reemplaza la línea base pre-S4, archivada en `.agents/historico/pre-s4-2026-09-19/`. Conserva las evidencias históricas como antecedente, pero no las usa para acreditar los requisitos S4 hasta revalidarlos en la arquitectura HQ–BRANCH.

## Alcance acordado

- Dos sedes lógicas: **HQ** (Edificio A, POP, Core, DMZ y Datacenter) y **BRANCH** (Edificios B y C).
- Cuatro enlaces L3 existentes Core–Dist reutilizados como tránsito HQ–BRANCH; OSPF, autenticación de vecinos y ACL mínimas. Sin extender VLAN entre sedes.
- PVE-1/HQ y PVE-2/BRANCH son nodos independientes. No hay clúster Proxmox, réplica de VM ni failover automático de VM.
- AD DS/DNS con DC1/HQ y DC2/BRANCH; DHCP central en CorevIOS-1 con relay en BRANCH; AD Sites and Services obligatorio.
- FS-HQ, BKP-1 y ZBX-1 mínimos; dos clientes Windows de gestión como appliances QEMU independientes dentro de GNS3, fuera de PVE; aplicación local en Docker sobre WebUbuntuServer-1.
- PostgreSQL/Patroni como infraestructura HA quedan fuera. PostgreSQL incluido en el `docker compose` de la aplicación es una dependencia local no-HA.

## Reglas de operación

1. Ejecutar PIV: planificar, implementar un cambio pequeño, verificar y decidir.
2. Capturar pre/post y rollback antes de persistir cambios. No inventar puertos, resultados, versiones ni secretos.
3. Usar sólo estados `Pendiente`, `Aprobado`, `Fallido` o `Bloqueado`.
4. Si falla, registrar incidente, impacto, evidencia, rollback y condición de reanudación.
5. Las tareas se ejecutan una por una tras confirmación del operador. Los artefactos de evidencia se crean sólo al iniciar la tarea.

## Modelo de ejecución acordado

La implementación es lineal S0 → S5. Se evita la verificación repetitiva: cada fase conserva un único preestado/backup y realiza una **compuerta mínima** al terminar, sólo para confirmar que se puede iniciar la siguiente. Las pruebas de costo o impacto se concentran en S5: caída de DC, caída de enlace, restauración de FS-HQ y matriz T01–T12. Este modelo no elimina las capturas obligatorias ni permite declarar resultados sin prueba real.

## Fases y compuertas

| Fase | Tareas | Objetivo de cierre |
|---|---|---|
| S0 — Rebaselinar | S0.1–S0.4 | Copia recuperable, inventario real, capacidad y rollback confirmados. |
| S1 — Red de sedes | S1.1–S1.6 | HQ/BRANCH separados por L3, OSPF y DHCP relay comprobados. |
| S2 — Virtualización | S2.1–S2.4 | PVE independientes, redes de gestión/VM, VMs de servicio, appliances GNS3 de clientes y recuperación manual documentadas. |
| S3 — AD y archivos | S3.1–S3.7 | AD Sites, usuarios, GPO, SMB, clientes y DNS/DHCP por sede validados. |
| S4 — App y backup | S4.1–S4.4 | Webapp LDAP/JWT local, backup por hito y restauración demostrada. |
| S5 — Observabilidad y cierre | S5.1–S5.4 | Zabbix mínimo, fallas, matriz T01–T12 y paquete de defensa completos. |

### S0 — Rebaselinar

| ID | Acción | Cierre mínimo |
|---|---|---|
| S0.1 | Archivar diseño pre-S4 y registrar decisiones aprobadas. | Índice nuevo y decisión de alcance sin resultados supuestos. |
| S0.2 | Respaldar proyecto GNS3, configuraciones, discos y estados actuales. | Lectura/hash y ubicación comprobadas. |
| S0.3 | Inventariar enlaces Core–Dist, puertos, VLAN, IP, rutas, PVE/DC y conflictos. | Tabla real; no se cambia cableado por inferencia. |
| S0.4 | Medir 10–15 min de RAM, swap, CPU, I/O y disco con el perfil mínimo. | Sin swap y al menos 2 GiB libres; si no, reducir carga. |

### S1 — Red HQ y BRANCH

| ID | Acción | Cierre mínimo |
|---|---|---|
| S1.1 | Convertir los cuatro enlaces existentes Core–Dist a L3 después de preestado y rollback. | Cuatro `/30` en `10.0.5.0/30`–`10.0.8.0/30`; sin trunk/VLAN extendida. |
| S1.2 | Configurar OSPF: área 0 HQ, área 10 BRANCH, vecinos autenticados y ruta por defecto controlada. | Rutas de ambas sedes; caída de un enlace reconverge ≤60 s medida. |
| S1.3 | Crear VLAN/subredes BRANCH 110, 115, 120, 130, 140, 150 y 160. | SVIs/gateways y DHCP relay comprobados. |
| S1.4 | Mantener HQ: VLAN 10, 50, 60, 90 y 100; preservar invitados VLAN 60 aislados. | No se altera NAT/Internet existente salvo evidencia y rollback. |
| S1.5 | Aplicar segmentación mínima. | Sólo gestión→PVE, backup→destinos autorizados e invitados bloqueados hacia interno. |
| S1.6 | Pruebas intersede positivas, negativas y de caída/restauración de enlaces. | DNS, SMB, rutas, aislamiento y tiempos registrados. |

### S2 — Virtualización y capacidad

| ID | Acción | Cierre mínimo |
|---|---|---|
| S2.1 | Separar gestión de PVE y bridges de VMs mediante segunda NIC. | PVE-1 `192.168.90.20`; PVE-2 `192.168.110.10`; acceso sólo desde gestión. |
| S2.2 | Retirar PVE cluster/QDevice del diseño activo, conservando antecedentes. | Nodos independientes y recuperación manual declarada. |
| S2.3 | Crear/ajustar DC1, DC2, FS-HQ y ZBX-1 en PVE; crear dos clientes Windows como appliances QEMU independientes dentro de GNS3. | Inventario de VMs de servicio y appliances de clientes, recursos, disco/ISO, enlaces y ubicación por sede. |
| S2.4 | **Excluida por decisión expresa del operador humano (2026-09-20).** No se ejecutará ni acreditará la documentación de instalación, actualización, operación o recuperación manual PVE. | No aplica; se excluyen también el video/captura fechado y la prueba de caída de nodo o enlace. |

### S3 — AD, DNS, DHCP, GPO y archivos

| ID | Acción | Cierre mínimo |
|---|---|---|
| S3.1 | Revalidar DC1/DC2, DNS cruzado, GC, FSMO, tiempo y DNS directo/inverso. | `dcdiag`, `repadmin`, `w32tm` y DNS desde ambas sedes. |
| S3.2 | Crear AD Sites HQ/BRANCH, subredes y vínculo permanente. | `nltest /dsgetsite` y replicación intersede correctos. |
| S3.3 | Crear árbol OU, 20 usuarios, cinco grupos por área, cinco cuentas admin y dos de servicio. | Membresías y delegaciones sin secretos. |
| S3.4 | Configurar ámbitos DHCP HQ/BRANCH, exclusiones, reservas/opciones y relay. | `ipconfig /all` de ambos clientes. |
| S3.5 | Aplicar GPO-01, 03, 05, 06 y 07; comprobar herencia/filtrado/excepción. | `gpresult /h`, eventos y prueba de excepción TI. |
| S3.6 | Implementar FS-HQ y shares SMB por área con AGDLP. | Acceso permitido/denegado desde HQ y BRANCH. |
| S3.7 | Instalar Windows cliente y unir los appliances GNS3 WIN-MGMT-HQ-01 y WIN-MGMT-BR-01 al dominio. | DNS, login, GPO, PVE autorizado y SMB validados. |

### S4 — Aplicación y recuperación

| ID | Acción | Cierre mínimo |
|---|---|---|
| S4.1 | Desplegar React, Spring Boot y PostgreSQL local de la app en Docker sobre WebUbuntuServer-1. | PostgreSQL no expuesto; API y frontend operativos en DMZ. |
| S4.2 | Integrar LDAP interno a la API y conservar JWT/RBAC dinámico de aplicación. | Login correcto/fallido y eventos AD; LDAPS queda fuera de alcance documentado. |
| S4.3 | Implementar BKP-1 y backup manual por hito de DC1 System State y FS-HQ. | Baseline, pre/post demo y retención de tres puntos verificables. |
| S4.4 | Restaurar FS-HQ o su servicio en entorno controlado. | SMB/permisos funcionales tras restauración; no revertir DC por snapshot. |

### S5 — Monitoreo, pruebas y entrega

| ID | Acción | Cierre mínimo |
|---|---|---|
| S5.1 | Desplegar ZBX-1 con MariaDB local. | PVE, Core, DC, clientes y FS-HQ inventariados. |
| S5.2 | Configurar agentes y SNMPv3 de Core; recolectar eventos Windows relevantes. | CPU/RAM/disco/enlaces y login válido/fallido visibles. |
| S5.3 | Ejecutar T01–T12 y fallas de DC, enlace y restauración. | Resultado esperado/obtenido, tiempos y correcciones. |
| S5.4 | Generar documento final, diagramas, videos fechados, presentación y proyecto portable. | Defensa reproducible; activos pre-S4 retenidos hasta cierre. |

## RTO/RPO y límites aceptados

| Servicio | Objetivo | Límite declarado |
|---|---|---|
| AD/DNS | RTO ≤5 min; sin RPO para cambios no replicados. | Un DC disponible debe resolver/autenticar. |
| Enlace HQ–BRANCH | Reconvergencia ≤60 s ante un enlace. | Si caen los cuatro, no hay servicio intersede. |
| FS-HQ | RTO ≤30 min manual; RPO desde último backup por hito. | Sin HA automática. |
| ZBX-1 | Recuperación manual, sin RTO comprometido. | Observabilidad es SPOF. |
| Host GNS3 | Sin RTO/RPO. | Un único host físico es SPOF fuera de alcance. |

## Excepción de secuencia aprobada — 2026-09-20

S1.5 y S1.6 quedan deliberadamente pendientes hasta completar S4.3. La segmentación de S1.5 incluye el flujo `backup → BKP-1`, pero `BKP-1` se implementa formalmente en S4.3. Por tanto, no se aplicarán ACL con marcadores ni se declarará cerrada la fase S1 antes de disponer de `BKP-1`, sus protocolos/puertos autorizados y las pruebas reales. Una vez terminado S4.3, se retomarán S1.5 y luego S1.6 con preestado, pruebas y rollback propios.

## Exclusiones posteriores — 2026-10-10

Por decisión explícita del operador, quedan fuera de este hito S0.2 (respaldo/hash adicional), S0.3 (nuevo inventario operativo), S0.4 (nueva medición de capacidad) y P3.1 (revisión documental adicional de ACL instanciadas). Estas exclusiones no bloquean la implementación de S5 y se conservarán como limitaciones del cierre.

## Decisión registrada — clientes de gestión — 2026-09-20

`WIN-MGMT-HQ-01` y `WIN-MGMT-BR-01` son equipos cliente Windows independientes del plano de servidores. Se implementan como appliances QEMU independientes dentro del proyecto GNS3, de forma análoga a `AlpineSSHClient-1`, y no como VMs de Proxmox. Los clientes se conectan a VLAN 90/HQ y VLAN 110/BRANCH, respectivamente. La ISO aprobada es `en-us_windows_10_enterprise_ltsc_2021_x64_dvd_d289cf96.iso`; la instalación y unión al dominio se validan en S3.7.
