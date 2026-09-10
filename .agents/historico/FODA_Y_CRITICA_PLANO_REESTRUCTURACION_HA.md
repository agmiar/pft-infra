# FODA y revisión crítica — Plano de reestructuración HA

**Documento evaluado:** `PLANO_EJECUTIVO_REESTRUCTURACION_HA.md`  
**Enfoque:** *devil's advocate*, priorizando correcciones fáciles de implementar  
**Resultado global:** **56/100 — 🟡 Amarillo**

> **Estado histórico, no normativo.** Este diagnóstico precede al modelo Patroni/etcd y a las decisiones vigentes de alcance. Sus observaciones sobre TLS/certificados, vault, WSUS, PITR o promoción anterior son antecedentes críticos, no tareas obligatorias del hito actual.

## 1. Criterio de calificación

La puntuación representa cuánto favorece cada aspecto la ejecución exitosa del proyecto en su estado actual, no cuán importante o grave es el tema.

| Rango | Semáforo | Interpretación |
|---:|:---:|---|
| 75–100 | 🟢 Verde | Sólido o suficientemente controlado |
| 50–74 | 🟡 Amarillo | Viable con correcciones o validaciones |
| 1–49 | 🔴 Rojo | Bloqueante, frágil o no demostrado |

La nota evalúa el plano como proyecto implementable, no solo como documento técnico. Una explicación detallada no compensa una dependencia que no cabe en los recursos disponibles o un mecanismo de HA que puede corromper datos.

## 2. Veredicto ejecutivo

La propuesta está bien estructurada, conserva gran parte de la red existente y demuestra conocimiento de sus limitaciones. Sin embargo, actualmente es **un buen diseño de laboratorio con aspiraciones de HA, no una plataforma HA demostrada**.

Los tres problemas más importantes son:

1. **La capacidad de almacenamiento no cierra.** Cada PVE se define con 96 GB, pero un solo DC requiere 80 GB + 120 GB para WSUS, antes de PostgreSQL, Zabbix, snapshots, ZFS y réplicas.
2. **Las ACL propuestas no habilitan el uso completo de AD y WSUS desde las VLAN de usuarios.** Se agregan DNS y NTP, pero Kerberos, LDAP/LDAPS, SMB, RPC y WSUS seguirían alcanzando el `deny` inter-VLAN.
3. **Keepalived puede promover PostgreSQL en ambos lados durante una partición de red.** `pg_isready` considera saludable a un standby y `notify_master` lo promociona sin un árbitro ni fencing de base de datos. Esto contradice la promesa de promoción controlada y expone a *split-brain*.

Hasta resolver estos tres puntos, no conviene ejecutar el plano completo ni presentar la solución como HA automática.

## 3. Calificación ponderada

| Dimensión | Peso | Nota | Estado | Observación crítica |
|---|---:|---:|:---:|---|
| Claridad, inventario y alcance | 15% | 88 | 🟢 | El documento es detallado, ordenado y conserva cambios mínimos. |
| Factibilidad en GNS3 y capacidad | 20% | 42 | 🔴 | Disco, RAM, virtualización anidada y tiempos de despliegue no están cerrados. |
| Alta disponibilidad real | 20% | 46 | 🔴 | Persisten SPOF y mecanismos de recuperación manual presentados junto con HA. |
| Red, segmentación y seguridad | 15% | 55 | 🟡 | Buena intención, pero hay flujos imprescindibles ausentes y reglas demasiado amplias. |
| Integridad y recuperación de datos | 15% | 45 | 🔴 | No hay diseño ejecutable de backup/PITR; PostgreSQL puede sufrir doble promoción. |
| Operación, pruebas y mantenibilidad | 10% | 62 | 🟡 | Hay validaciones, pero faltan RTO/RPO, responsables y resultados medibles. |
| Migración y rollback | 5% | 75 | 🟢 | El orden y la conservación de activos antiguos reducen el riesgo. |
| **Total ponderado** | **100%** | **56** | **🟡** | **Viable después de corregir bloqueantes y recortar alcance.** |

## 4. Mejoras priorizadas por facilidad de implementación

La prioridad combina facilidad, impacto y dependencia. La primera tanda debería resolverse en el propio documento antes de construir VMs.

### 4.1 Muy fáciles y de alto impacto

| Prioridad | Mejora | Facilidad | Impacto | Estado actual |
|---:|---|:---:|:---:|:---:|
| 1 | Añadir una tabla de capacidad real por host: disco provisionado, uso esperado, margen, réplica y snapshots. | Alta | Crítico | 🔴 20/100 |
| 2 | Definir explícitamente RPO y RTO por servicio: AD/DNS, DHCP, PostgreSQL, frontend, PVE, WSUS y Zabbix. | Alta | Alto | 🔴 35/100 |
| 3 | Renombrar los comportamientos: “HA automática”, “failover manual”, “recuperación” y “sin redundancia”. | Alta | Alto | 🟡 55/100 |
| 4 | Añadir una matriz de flujos AD/WSUS completa antes de modificar ACL: origen, destino, protocolo, puerto y justificación. | Alta | Crítico | 🔴 30/100 |
| 5 | Cambiar la prueba PostgreSQL para incluir una partición de red, no solo apagar PG-1/PVE-1. | Alta | Crítico | 🔴 25/100 |
| 6 | Documentar quién ejecuta cada paso, evidencia esperada y condición de aborto. | Alta | Medio | 🟡 55/100 |
| 7 | Separar criterios de aceptación obligatorios de mejoras industriales opcionales. | Alta | Medio | 🟡 65/100 |
| 8 | Definir versiones exactas soportadas y congelarlas para el laboratorio. | Alta | Medio | 🟡 60/100 |

### 4.2 Fáciles o moderadas, necesarias antes del despliegue

| Prioridad | Mejora | Facilidad | Impacto | Estado actual |
|---:|---|:---:|:---:|:---:|
| 9 | Aumentar los discos PVE o reducir radicalmente WSUS. Como mínimo, calcular almacenamiento local más réplica y 25–30% libre. | Media | Crítico | 🔴 20/100 |
| 10 | Sacar WSUS de los DC o, si es requisito académico, limitarlo a un solo WSUS y documentar que no es servicio crítico. | Media | Alto | 🔴 40/100 |
| 11 | Corregir ACL para permitir únicamente los servicios AD/WSUS requeridos desde cada VLAN. Probar unión al dominio, inicio de sesión y GPO. | Media | Crítico | 🔴 30/100 |
| 12 | Evitar recrear ACL aplicadas sin una estrategia atómica; preparar ACL nueva, validar y cambiar la referencia en ventana. | Media | Alto | 🟡 50/100 |
| 13 | Definir backup PostgreSQL independiente de la réplica: base backup, WAL/PITR, retención y restauración probada. | Media | Crítico | 🔴 30/100 |
| 14 | Hacer que clientes WSUS puedan cambiar de servidor o aceptar expresamente que DC2 no proporciona failover automático. | Media | Alto | 🔴 40/100 |
| 15 | Adoptar split-scope DHCP en ambos Core para el laboratorio o declarar DHCP como SPOF aceptado. | Media | Medio | 🟡 50/100 |
| 16 | Reducir la carga inicial: primero red + PVE + AD/DNS + PostgreSQL; después WSUS y Zabbix. | Alta | Alto | 🟡 55/100 |

### 4.3 Más costosas; no deberían ser la primera respuesta

| Mejora | Motivo para postergarla | Cuándo justificarla |
|---|---|---|
| Tercer nodo PVE | Aumenta mucho el consumo del laboratorio. | Si se exige HA de plataforma demostrable y no solo quorum. |
| Patroni + DCS de tres miembros | Resuelve mejor la elección de primario, pero añade operación y componentes. | Si PostgreSQL debe tener failover automático seguro. |
| Redes separadas para gestión, Corosync, migración y VMs | Requiere más NIC, VLAN y cambios Cisco. | Después de demostrar estabilidad funcional en una sola red. |
| Ceph o SAN redundante | Es desproporcionado para dos nodos GNS3 y recursos limitados. | Solo con tres nodos y capacidad de I/O suficiente. |
| MLAG/vPC y dual-homing | vIOS/GNS3 no representa necesariamente la plataforma física final. | Para una maqueta de producción con switches compatibles. |

## 5. FODA semaforizado

### Fortalezas

| Aspecto | Nota | Estado | Lectura crítica |
|---|---:|:---:|---|
| Cambio L3 mínimo: conservar VLAN 50 y ampliar a `/27` | 90 | 🟢 | Reduce renumeración y riesgo de migración. Debe confirmarse que no exista ningún host con máscara `/29` olvidado. |
| Inventario explícito de IP, VMID, roles y ubicaciones | 85 | 🟢 | Facilita implementación y revisión; falta asociar consumo real de recursos. |
| Reconocimiento explícito de límites de dos nodos y de *split-brain* | 80 | 🟢 | Es una fortaleza documental, aunque la implementación propuesta aún no elimina el riesgo. |
| Orden de migración y rollback conservador | 78 | 🟢 | Preserva sistemas anteriores y evita borrado temprano. Faltan tiempos máximos y puntos de no retorno. |
| Redundancia AD/DNS distribuida entre nodos | 82 | 🟢 | El principio es correcto si las ACL y la afinidad realmente permiten operar durante fallos. |
| Uso de DNS/VIP para desacoplar frontend de los nodos PostgreSQL | 80 | 🟢 | Reduce cambios de aplicación; no garantiza por sí solo consistencia ni elección segura del primario. |
| Validaciones por tecnología | 76 | 🟢 | Hay comandos útiles, pero varios criterios son binarios y no miden duración, pérdida de datos o degradación. |
| Segmentación y monitoreo considerados desde el diseño | 72 | 🟡 | La intención es buena; algunas reglas son excesivamente amplias y el propio Zabbix no es redundante. |

**Promedio de fortalezas: 80/100 — 🟢 Verde.**

### Oportunidades

| Aspecto | Nota | Estado | Lectura crítica |
|---|---:|:---:|---|
| Convertir el plano en una implementación por fases | 90 | 🟢 | Es fácil y reduce presión de RAM, disco y diagnóstico simultáneo. |
| Añadir matriz de dependencias y flujos | 88 | 🟢 | Corrección documental barata que descubriría las carencias de AD, RPC y WSUS antes de tocar Cisco. |
| Hacer pruebas de caos simples y repetibles | 82 | 🟢 | Apagar enlace, nodo, proceso y QDevice por separado aporta evidencia sin rediseñar todo. |
| Definir perfiles “mínimo demostrable” y “objetivo industrial” | 85 | 🟢 | Evita construir componentes caros solo para satisfacer una etiqueta de HA. |
| Automatizar comprobaciones y captura de evidencia | 70 | 🟡 | Scripts sencillos pueden validar DNS, puertos, quorum y réplica; requiere cuidado con credenciales. |
| Aplicar split-scope DHCP en los Core | 68 | 🟡 | Mejora disponibilidad con poco equipamiento, aunque no ofrece sincronización de estado. |
| Usar backup/PITR como prioridad antes que failover sofisticado | 88 | 🟢 | Protege mejor los datos y es más fácil de demostrar que Patroni/Ceph. |
| Reducir o posponer WSUS | 92 | 🟢 | Libera gran parte del disco y simplifica el primer hito sin afectar el núcleo AD/DNS/BD. |

**Promedio de oportunidades: 83/100 — 🟢 Verde.**

### Debilidades

En esta sección, una nota baja significa que la debilidad está poco controlada.

| Aspecto | Nota | Estado | Consecuencia probable |
|---|---:|:---:|---|
| Capacidad de disco incompatible con el inventario de VMs | 20 | 🔴 | El despliegue no cabe; snapshots y réplicas agravan el déficit. |
| PostgreSQL sin elección de líder ni fencing propio | 20 | 🔴 | Una partición puede generar dos escritores y pérdida/corrupción lógica. |
| ACL insuficiente para AD, GPO y WSUS desde VLAN de usuarios | 25 | 🔴 | DNS funcionará, pero unión al dominio, autenticación o actualización pueden fallar. |
| QDevice y nodos comparten el mismo host GNS3 | 35 | 🔴 | Añade votos, pero no un dominio de fallo físico real. |
| Una NIC y una VLAN para gestión, Corosync, réplica y VMs | 38 | 🔴 | Congestión o fallo de enlace afecta simultáneamente control y servicio. |
| DHCP solo en Core1 en la solución base | 45 | 🔴 | Nuevos clientes y renovaciones pueden fallar durante la caída. |
| WSUS en ambos controladores de dominio | 40 | 🔴 | Aumenta superficie, disco, mantenimiento y acoplamiento de roles críticos. |
| Cliente WSUS configurado solo contra DC1 | 35 | 🔴 | La réplica en DC2 no produce failover automático de clientes. |
| Backup y restauración sin diseño ejecutable | 30 | 🔴 | La réplica puede copiar errores; no se demuestra recuperación histórica. |
| Ausencia de RTO/RPO cuantificados | 35 | 🔴 | No existe criterio objetivo para afirmar que la prueba de HA fue exitosa. |
| ACL VLAN 50 con permisos muy amplios para DC y Zabbix | 48 | 🔴 | Una cuenta o servicio comprometido obtiene alcance lateral elevado. |
| Zabbix como VM y base única | 55 | 🟡 | Se pierde observabilidad durante el fallo que más interesa diagnosticar. |
| Complejidad global alta para una maqueta anidada | 42 | 🔴 | Muchas capas pueden fallar por recursos y ocultar la causa original. |

**Promedio de control de debilidades: 37/100 — 🔴 Rojo.**

### Amenazas

En esta sección, una nota baja significa que la amenaza tiene mitigación insuficiente.

| Aspecto | Nota | Estado | Riesgo externo o de ejecución |
|---|---:|:---:|---|
| Virtualización anidada sin rendimiento o soporte suficiente | 35 | 🔴 | PVE puede instalar, pero Windows y VMs anidadas pueden ser inoperables. |
| Falta de RAM/I/O del equipo anfitrión | 30 | 🔴 | Se producirán timeouts que pueden confundirse con fallos de red o clúster. |
| Bucle L2 y elección STP no verificada al añadir Dist1–Dist2 | 45 | 🔴 | Un enlace puede bloquearse en un punto no previsto o causar convergencia disruptiva. |
| Cambio simultáneo de máscara, ACL, OSPF y NAT | 48 | 🔴 | Un error deja VLAN 50 aislada y complica identificar la causa. |
| Promoción automática durante una partición parcial | 15 | 🔴 | Es el escenario de mayor daño para la base de datos. |
| Dependencia de imágenes, licencias y versiones compatibles | 58 | 🟡 | Puede frenar instalación, drivers VirtIO o WSUS. |
| Certificados/TLS no desplegados pese a usar `hostssl` y HTTPS | 40 | 🔴 | La configuración puede no funcionar o cifrar sin validar identidad. |
| QDevice accesible por un único puerto/switch de acceso | 52 | 🟡 | El voto externo puede desaparecer junto con parte de la red de gestión. |
| Operación manual bajo presión sin roles asignados | 45 | 🔴 | El antiguo primario podría reiniciarse antes del reseed y provocar divergencia. |
| Deriva entre documento y topología real de GNS3 | 55 | 🟡 | Las interfaces o nodos pueden no coincidir después de cambios posteriores. |

**Promedio de mitigación de amenazas: 42/100 — 🔴 Rojo.**

## 6. Observaciones técnicas de *devil's advocate*

### 6.1 “Tres votos” no equivale a “tres dominios de fallo”

El QDevice mejora la decisión de quorum del clúster, pero PVE-1, PVE-2 y QDevice siguen ejecutándose sobre el mismo ordenador y proceso general de laboratorio. Ante fallo del host GNS3, almacenamiento anfitrión o saturación severa, todo cae. El plano debe calificar esto como simulación lógica de quorum, no resiliencia física.

### 6.2 La HA de VMs depende del dato, no solo del quorum

ZFS local y replicación programada implican RPO mayor que cero. También requieren suficiente disco en ambos nodos y una prueba real de reinicio desde la réplica tras perder el origen. Sin esa evidencia, el clúster puede estar `Quorate: Yes` y aun así no poder arrancar la VM necesaria.

### 6.3 Keepalived comprueba disponibilidad, no autoridad

`pg_isready` responde correctamente tanto en un primario como en un standby operativo. Si PG-2 pierde contacto con PG-1 pero mantiene su propia red, VRRP puede hacerlo MASTER y `notify_master` lo promociona. PG-1 puede seguir aceptando escrituras desde otro segmento. `nopreempt` evita un *failback*, pero no evita la doble promoción inicial.

La corrección mínima es **no automatizar la promoción**: Keepalived solo debe publicar la VIP en el nodo que un operador haya confirmado como primario después de aislar el anterior. Si la promoción automática es un requisito, hace falta un mecanismo de consenso/fencing como Patroni + DCS o equivalente.

### 6.4 La matriz ACL está incompleta

Permitir DNS y NTP desde las VLAN 10/20/30/40/60 no basta para usar Active Directory. Como mínimo deben evaluarse Kerberos, LDAP/LDAPS, catálogo global, SMB, RPC endpoint mapper, rango RPC dinámico y puertos WSUS. No conviene copiar una lista genérica: se debe limitar por origen, destino y función, y comprobar con capturas/contadores qué necesita realmente el laboratorio.

Además, eliminar y recrear una ACL aplicada puede abrir una ventana sin filtrado o producir una política incompleta durante la edición. Es más seguro crear una ACL con otro nombre, verificarla y sustituir la referencia de la SVI.

### 6.5 La réplica WSUS no da continuidad por sí sola

La GPO apunta solamente a `dc1-pft.pft.test`. Si DC1 cae, el cliente no migra automáticamente a DC2 por el mero hecho de que DC2 sea réplica. Debe diseñarse el cambio de endpoint o aceptar que WSUS no tiene RTO corto. Para una maqueta, la solución más simple es un solo WSUS no crítico o posponerlo.

### 6.6 El presupuesto de recursos debe preceder a la topología

Un PVE de 96 GB no puede alojar un DC de 200 GB nominales más PostgreSQL, Zabbix, ZFS, réplicas y margen. Aunque qcow2 sea *thin*, WSUS y las actualizaciones consumen bloques reales. También debe evitarse prometer 24–32 GB totales si el inventario asignado, los dos PVE invitados y la sobrecarga del host superan ese valor durante pruebas simultáneas.

### 6.7 Réplica no es backup

La replicación de PVE y el *streaming replication* de PostgreSQL copian borrados accidentales, corrupción lógica y algunos errores operativos. El criterio de aceptación debe incluir restaurar una base a un momento anterior en una ubicación aislada. Sin una restauración probada, la protección de datos permanece en rojo.

## 7. Versión mínima viable recomendada

Para maximizar la facilidad de implementación, el primer hito debería contener únicamente:

1. VLAN 50 `/27`, ACL corregidas y pruebas de conectividad.
2. Dos PVE + QDevice, aclarando que representan dominios lógicos dentro de un solo host físico.
3. Dos DC con AD/DNS, sin WSUS inicialmente.
4. Dos PostgreSQL con replicación y **promoción manual documentada**, sin Keepalived automático hasta disponer de fencing.
5. Frontend apuntando a un nombre DNS que el operador cambia durante el failover, o VIP asignada manualmente al primario confirmado.
6. Backups PostgreSQL con restauración y RPO/RTO medidos.
7. Zabbix y WSUS como segunda fase, una vez establecida la plataforma base.

Este recorte conserva el valor académico principal y elimina gran parte del riesgo operativo. Solo después de demostrarlo conviene agregar failover automático, réplica WSUS y HA de VMs.

## 8. Condiciones para subir la calificación

| Evidencia requerida | Mejora estimada |
|---|---:|
| Capacidad de almacenamiento corregida y validada con margen | +7 puntos |
| ACL completas validadas con unión al dominio, GPO y WSUS | +6 puntos |
| PostgreSQL sin doble promoción en prueba de partición | +10 puntos |
| Backup/PITR restaurado y cronometrado | +6 puntos |
| RPO/RTO definidos y pruebas con resultados registrados | +4 puntos |
| DHCP redundante o SPOF formalmente aceptado | +2 puntos |

Con esas evidencias, el proyecto podría pasar de **56/100 🟡** a aproximadamente **80–85/100 🟢** sin necesidad inmediata de Ceph, MLAG ni una arquitectura de producción completa.
