# Índice histórico de evidencias P5 — fuentes de captura

Proyecto activo: sprint1-preview1, ID 47a3267f-9b02-4e97-a0e8-0aacb46d5ffd.

Este índice conserva los nombres de las fuentes históricas de P5. La carpeta canónica aprobada para evidencia versionable es `.agents/evidencias/P5`; el [control canónico P5.1](../../.agents/evidencias/P5/2026-09-15_P5.1_AD-DNS_control.md) y el [índice maestro](../../.agents/EVIDENCIAS_DE_IMPLEMENTACION.md) enlazan estado y artefactos. Los archivos técnicos de esta carpeta histórica no contienen contraseñas, claves privadas, tickets ni tokens. No se trasladan a evidencia técnica documentos de credenciales ni capturas de contraseña.

## P5.1 preestado

- 2026-09-15_P5.1_AD-DNS_pre_frontend.txt — anfitrión, API GNS3, PVE/VMs antes de iniciar el frontend.
- 2026-09-15_P5.1_pre_conectividad_frontend.txt — preestado antes de iniciar ADvIOS-10.
- 2026-09-15_P5.1_frontend_pre_dns.txt — IP/ruta/MAC/DNS del invitado antes de crear web.
- 2026-09-15_P5.1_frontend_pre_resolver.txt — preestado inmediato antes de configurar DNS del frontend.
- 2026-09-15_P5.1_AD-DNS_pre-reanudacion.txt, 2026-09-15_P5.1_AD-DNS_pre.txt y 2026-09-15_P5.1_DC2_pre-install.txt — checkpoints históricos de reanudación/aprovisionamiento.

## P5.1 postestado y resultado

- 2026-09-15_P5.1_post.txt — estado final de GNS3, PVE, DCs, DNS, frontend, anfitrión y rollback.
- 2026-09-15_P5.1_resultado.md — matriz de aceptación, eventos transitorios, salvedad de forwarder y límites de alcance.
- 2026-09-15_P1.3_cierre.md — addendum a la condición DNS de P1.3, sin editar la plantilla fuente.
- 2026-09-14_P5.1_AD-DNS_control.md y 2026-09-14_P5.1_AD-DNS_ad-dns-inicial.md — controles de trabajo históricos con la actualización final anexada.
- 2026-09-15_P5.1_AD-DNS_interrupcion_conectividad.txt — interrupción anterior y recuperación.
- 2026-09-15_P5.1_AD-DNS_post-preinstalacion.txt, 2026-09-15_P5.1_AD-DNS_post_bloqueo_credencial.txt, 2026-09-15_P5.1_AD-DNS_prueba_bloqueo_credencial.txt, 2026-09-15_P5.1_DC1_post_password-inicial.txt — checkpoints previos, conservados como historial, no como estado final.

Los archivos con nombre pre describen capturas tomadas antes del cambio correspondiente. El postestado final está en 2026-09-15_P5.1_post.txt. Las capturas temporales remotas de PVE se eliminaron después de revisar las salidas. La captura de cambio de contraseña no se incluye en esta carpeta versionable. La prueba P0.5 de salida y sus límites siguen registrados, y no se declara salida/forwarding externo funcional.

## Alcance al cierre de P5.1 y estado documental actual

Al cierre histórico de P5.1 no se habían iniciado P5.2 ni P5.3. P5.2 comenzó el 2026-09-15 y sigue Bloqueado. El operador autorizó comprobar el canal de consola Windows mediante un puente local `qm vncproxy`; no se obtuvo el marco de DC1 ni se usó la referencia de Windows. DC1/VMID 101 se encontró detenida, se inició una vez y luego se confirmó `running` con quorum 3/3 y QDevice. Las consultas DNS anónimas devolvieron SOA de `pft.test` y `_msdcs.pft.test` desde ambos DC, pero no demuestran replicación. Una solicitud HTTP POST vacía a `/wsman` devolvió HTTP 401; no se envió SOAP/WMI ni se probaron variantes. No hubo cambios en AD/DNS o ACL; faltaba inventario interno de Windows. Ver [control P5.2](../../.agents/evidencias/P5/2026-09-15_P5.2_AD-DNS_control.md), [preestado](../../.agents/evidencias/P5/2026-09-15_P5.2_AD-DNS_pre.txt), [postestado](../../.agents/evidencias/P5/2026-09-15_P5.2_AD-DNS_post.txt), [incidente de autenticación](../../.agents/evidencias/P5/2026-09-15_P5.2_AD-DNS_incidente.md), [incidente de acceso a VMs](../../.agents/evidencias/P5/2026-09-15_P5.2_GNS3-access_incidente.md) y [guía P5.2](<../../configs INFRA/8. Active Directory/2. DNS, OUs, grupos AGDLP y GPO base (P5.2).md>). No se copiaron ni descargaron proyectos GNS3. Las omisiones de P4.3 siguen siendo limitaciones: no se ejecutaron P4T-PVE2, prueba VM-a-VM ni aprendizaje de MAC de ambas VMs. P5.3 sigue pendiente.

## Revalidación de acceso P5.2 — 2026-09-15

El primer intento de SSH se detuvo antes del saludo del servidor. En una comprobación posterior se autenticó SSH y la API GNS3 local mostró el proyecto y los nodos PVE iniciados. La consola PVE-1 quedó en `pve-1 login:` tras un único intento; no se confirmó un shell ni se reintentó. DC1/quorum no se revalidaron tras perder ese canal. P5.2 siguió Bloqueado. Ver [control P5.2](../../.agents/evidencias/P5/2026-09-15_P5.2_AD-DNS_control.md) e [incidente GNS3/acceso](../../.agents/evidencias/P5/2026-09-15_P5.2_GNS3-access_incidente.md).

## Revalidación SSH y ruta administrativa P5.2 — 2026-09-15

La sesión SSH y la API GNS3 confirmaron el proyecto y los nodos iniciados, pero el acceso directo por la red existente no alcanzó la GUI de PVE-1. No se repitió autenticación PVE, no se revalidaron DC1/quorum y no hubo cambios en AD/DNS. P5.2 continuó Bloqueado. Esta prueba inicial quedó superada por el enlace temporal documentado más abajo.


## P5.2 — revalidación final de acceso, 2026-09-16

- [Preestado PVE](../../.agents/evidencias/P5/2026-09-16_P5.2_PVE_pre.txt) y [postestado PVE](../../.agents/evidencias/P5/2026-09-16_P5.2_PVE_post.txt): DC1/VMID 101 restituida a `running`, quorum 3/3.
- [Incidente del puente PVE/GNS3](../../.agents/evidencias/P5/2026-09-15_P5.2_GNS3-access_incidente.md): saludo RFB real, sin framebuffer ni shell Windows.
- [Control P5.2](../../.agents/evidencias/P5/2026-09-15_P5.2_AD-DNS_control.md) y [registro SSH/Ubuntu](../../.agents/evidencias/P5/2026-09-15_P5.2_LaptopUbuntu_post.txt) mantienen el estado **Bloqueado**. No se ejecutaron cambios de AD/DNS.

## P5.2 — estado técnico revalidado, 2026-09-16 13:11–13:13 UYT

- [Recuperación PVE/DC2](../../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_recovery_prueba.txt): DC2/VMID 102 se encontró detenida, se inició una vez y la lectura posterior confirmó DC1/DC2 `running` y quorum 3/3.
- [Inventario interno](../../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_inventario.txt): zonas, A/PTR, OUs, grupos, GPO, vínculos y filtros; se deja constancia de GPO sin payload y grupos sin membresías.
- [DNS y servicios](../../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_prueba.txt): ambos DC responden las zonas AD-integradas y los registros observados. Faltan los A `postgres` y `zabbix`; sus PTR `.16` y `.17` existen.
- [Replicación](../../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_replication_prueba.txt): tras la sincronización de Schema, ambos `repadmin /replsummary` muestran `0/5` fallos y `showrepl` registra éxito en las cinco particiones. Se conserva la limitación operacional 110 de consulta remota.

P5.2 continúa **Bloqueado**. No se escribieron DNS, membresías AD ni GPO: el diseño aún no fija las cuentas, los valores/alcance/filtros de GPO ni la reversa de VLAN 100, y la autorización para materializar los dos A y el anidamiento GG→DL debe quedar explícita. P5.3 sigue pendiente.

## P5.2 — cambios DNS autorizados y verificados, 2026-09-16 14:01–14:03 UYT

- [Preestado inmediato](../../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_pre_cambios.txt): los A `postgres`/`zabbix` faltaban en ambos DNS. La consulta directa a ambos DC confirmó que las cinco relaciones GG→DL del diseño ya existían y que los cuatro GG de rol no tenían miembros directos.
- [Postestado y rollback](../../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_post_cambios.txt): se añadieron sólo `postgres.pft.test` → `192.168.50.16` y `zabbix.pft.test` → `192.168.50.17` en DC1. Ambos DNS devolvieron esos valores y los registros PVE/PG/Web; `repadmin /replsummary` siguió 0/5 en cada sentido. El postestado contiene los comandos para retirar exactamente los dos A si fuera necesario.
- [Inventario](../../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_inventario.txt), [prueba DNS](../../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_prueba.txt), [prueba de replicación](../../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_replication_prueba.txt) y [recuperación PVE/DC2](../../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_recovery_prueba.txt) preservan el resto de los resultados.

P5.2 permanece **Bloqueado**. No se tocaron los grupos (las relaciones GG→DL ya estaban presentes) ni las GPO (son esqueletos sin payload). Faltan las cuentas de los GG, la configuración y alcance de las GPO, y confirmar si se requiere reversa de VLAN 100. P5.3 sigue pendiente.

## P5.2 — búsqueda documental y fallo de sesión al crear cuentas, 2026-09-16 15:52–15:55 UYT

- [Incidente de aprovisionamiento](../../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_incidente_cuentas.md): no se encontraron identidades concretas en los documentos. El operador autorizó crear cuatro cuentas de laboratorio por rol; la sesión New-PSSession falló con 1312 antes de ejecutar comandos de AD, por lo que no se crearon cuentas ni se modificaron grupos.
- Se cerraron el relay y el túnel SSH temporales y se verificó que no quedaron listeners ni archivos auxiliares. Se conservó el estado started de Alpine-SSHClient-1, PVE-1/2 y QDevice; los routers siguieron detenidos.

P5.2 continúa **Bloqueado**. Para reanudar, capturar un preestado AD actual y comprobar duplicados con un canal PowerShell administrativo funcional. P5.3 sigue pendiente.

## P5.2 — aclaración de autorización y comprobación de acceso, 2026-09-16 16:35–16:39 UYT

El operador confirmó que la autorización para crear las cuentas ya estaba concedida. SSH a LaptopUbuntu y PVE-1 desde Alpine funcionó; el clúster seguía 3/3 y DC1/VMID 101 `running`. QEMU Guest Agent no está ejecutándose. No se abrió administración PowerShell de Windows ni se repitió autenticación contra DC1; no hubo escrituras AD. El bloqueo actual es de acceso técnico a Windows, no de autorización. Ver [incidente actualizado](../../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_incidente_cuentas.md). P5.2 permanece **Bloqueado** y P5.3 sigue pendiente.

## P5.2 — diagnóstico del canal WinRM, 2026-09-16 16:39–17:01 UYT

El operador confirmó DC1/VMID 101 `running` y HTTP 405 en `/wsman` desde PVE-1; esto prueba transporte, no autenticación. Windows local y Ubuntu no tienen ruta directa a PVE/DC1, y el túnel local `127.0.0.1:15991` está cerrado. PVE-1 no tiene cliente WinRM; el acceso usado a PVE fue por AlpineSSHClient-1 mediante la API local de GNS3. La recomendación anterior de `TrustedHosts` queda pospuesta hasta que exista un túnel verificable. Sin reintentos de credenciales ni cambios de AD/red. P5.2 permanece **Bloqueado** y P5.3 sigue pendiente. Ver [incidente actualizado](../../.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_incidente_cuentas.md).

## Preparación del entorno P5.2 — 2026-09-17

- [Preestado GNS3](../../.agents/evidencias/P5/2026-09-17_P5.2_GNS3_pre.txt) y [postestado GNS3](../../.agents/evidencias/P5/2026-09-17_P5.2_GNS3_post.txt): proyecto abierto, API/consolas sólo en loopback, doce nodos necesarios iniciados y NAT1 conservado; 13/45 iniciados.
- [Preestado PVE](../../.agents/evidencias/P5/2026-09-17_P5.2_PVE_pre.txt) y [postestado PVE](../../.agents/evidencias/P5/2026-09-17_P5.2_PVE_post.txt): DC1/DC2 estaban detenidas, se arrancaron y quedaron `running`; quorum 3/3 con QDevice. SOA directo a ambos DNS devolvió `NOERROR`; GET `/wsman` sin autenticación devolvió 405. No se autenticó en Windows ni se modificó AD/DNS.

P5.2 continúa **Bloqueado**. El arranque del laboratorio no es una aceptación: siguen pendientes el canal PowerShell administrativo, miembros GG, definición de GPO y decisión de inversa VLAN 100. Los PVE tienen ahora `nameserver 192.168.122.1`, divergente del `.12` histórico; quedó documentado sin corrección.

## Diagnóstico de acceso a la GUI PVE y estado P5.3 — 2026-09-17


La primera prueba directa a TCP/8006 no obtuvo respuesta. Después se comprobó el acceso a la GUI por el segmento temporal `172.31.255.0/24`, descrito en la guía P5.2 y el procedimiento de transferencia. El primer intento queda como antecedente y no demuestra que PVE estuviera apagado.

P5.3 no se inició. Según el Plan, requiere configurar el PDC con NTP autorizado y DC2/miembros mediante jerarquía del dominio. P1.6 permanece Bloqueado hasta definir y verificar dos fuentes NTP autorizadas y alcanzables por Border NAT. La secuencia aprobada requiere cerrar P5.2 antes de P5.3; no se ejecutaron comandos w32tm ni se capturó evidencia de tiempo AD.

## P5.2 — acceso temporal a la GUI PVE-1 desde LaptopUbuntu — 2026-09-17 17:24–17:58 UYT

- [Preestado del anfitrión y GNS3](../../.agents/evidencias/P5/2026-09-17_P5.2_AccesoPVE_pre.txt) y [preestado PVE-1](../../.agents/evidencias/P5/2026-09-17_P5.2_PVE-1_pre.txt): se registraron antes de crear el puente y subir la segunda NIC de PVE-1.
- [Prueba](../../.agents/evidencias/P5/2026-09-17_P5.2_AccesoPVE_prueba.txt) y [postestado/rollback](../../.agents/evidencias/P5/2026-09-17_P5.2_AccesoPVE_post.txt): `https://172.31.255.2:8006` respondió HTTP 200 desde Ubuntu; DC1/101 quedó `running`. La instalación/console de Windows no quedó verificada.
- [Incidente PVE-2](../../.agents/evidencias/P5/2026-09-17_P5.2_PVE-2_incidente.md): GNS3 lo marca iniciado y la consola VNC local responde RFB 3.8, pero PVE-2 no responde desde Alpine ni se obtuvo la pantalla del invitado; el quorum observado en PVE-1 está con un nodo más QDevice. DC2 no se inició.

P5.2 permanece **Bloqueado**. El estado de 17:58 antecede al reporte posterior del operador: éste informó que inició sesión en la consola Windows de DC1 y vio SConfig en Windows Server 2022 Standard Evaluation. No se conservó captura de esa observación en esta sesión y no se afirma como inventario técnico; tampoco se modificaron AD/DNS/GPO. P5.3 sigue sin iniciar.

## P5.2 — acceso temporal directo a PVE-2 desde Ubuntu — 2026-09-17 19:00–19:09 UYT

- [Preestado](2026-09-17_P5.2_PVE-2_pre.txt), [prueba](2026-09-17_P5.2_PVE-2_prueba.txt), [postestado/rollback](2026-09-17_P5.2_PVE-2_post.txt) y [control](2026-09-17_P5.2_PVE-2_control.md) registran el uso temporal de `172.31.255.3/24` en PVE-2 `ens4`. El procedimiento del proyecto asigna `.1` al puente de Ubuntu, `.2` a PVE-1 y `.3` a PVE-2; es direccionamiento manual del segmento de transferencia/gestión, no DHCP ni VLAN 50.
- Desde Ubuntu, ping 3/3 y 2/2, TCP/22 y TCP/8006 abiertos y HTTPS/8006 devolvió HTTP 200. El puente `.1`, PVE-1 `.2`, Cloud1 puerto 1 y los enlaces existentes al switch se reutilizaron; sólo se levantó `ens4` y se agregó temporalmente `.3` en PVE-2.
- PVE-2 conserva su ruta productiva por `vmbr0`; `pvecm status` informa `Quorate: No`, QDevice 0 votos y DC2/102 detenida. El acceso directo no repara Corosync/QDevice. La IP temporal se pierde al reiniciar PVE-2 y el puente al reiniciar Ubuntu; cerrar el navegador sólo cierra la sesión web. P5.2 permanece **Bloqueado** y P5.3 no se inicia.

## Consola de Windows Server en DC1 — reporte del operador — 2026-09-17

El operador informó que, desde `https://172.31.255.2:8006` → `pve-1` → VM `101 (DC1)` → **Console**, pudo iniciar sesión y vio SConfig en Windows Server 2022 Standard Evaluation. La observación no fue capturada ni repetida por esta sesión; se registra como reporte, no como prueba de aceptación P5.2. No se guardó la contraseña. Esto confirma sólo el acceso interactivo al sistema operativo según el operador; no demuestra roles AD/DNS, replicación, membresías ni GPO. P5.2 sigue **Bloqueado** y P5.3 no se inició.
