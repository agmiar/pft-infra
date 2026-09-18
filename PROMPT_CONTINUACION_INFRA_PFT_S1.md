# Prompt de continuación — PFT-S1

Copia y pega este texto como primer mensaje en el nuevo chat. Trabaja siempre sobre `C:\Users\admin\Downloads\pft-infra-main` y deja allí toda la documentación del proyecto.

## Directrices obligatorias

Antes de actuar, lee completos y en este orden:

1. `AGENTS.md`
2. `PLAN_DE_TRABAJO_UNIFICADO.md`
3. `.agents/PLANO_EJECUTIVO_REESTRUCTURACION_HA.md`
4. `.agents/ACL_MATRIZ_Y_RUNBOOK.md`
5. `.agents/INSIGHTS_CONVERSACION_REESTRUCTURACION_HA.md`
6. `.agents/EVIDENCIAS_DE_IMPLEMENTACION.md`
7. `.agents/ALINEACION_REQ_INFRA_S4_2026.md`
8. `orden de creacion.txt`

Antes de reanudar P5.2, lee su criterio de aceptación/runbook disponible, `configs INFRA/README - guias de reconstruccion.md`, `configs INFRA/8. Active Directory/1. AD DS y DNS redundante (P5.1).md`, `configs INFRA/8. Active Directory/2. DNS, OUs, grupos AGDLP y GPO base (P5.2).md` y las evidencias canónicas de P4.4, P4.5, P5.1 y P5.2. Si no existe un runbook específico de P5.2 o P5.3, dilo; no inventes uno.

No cambies red, VMs, servicios, ACL, AD/DNS ni GNS3 sin orden explícita. Trabaja una tarea a la vez, captura preestado antes de una escritura, captura postestado después y documenta rollback. No marques pruebas como hechas por la existencia de archivos. Usa sólo los estados `Pendiente`, `Aprobado`, `Fallido` y `Bloqueado`. Edita documentación con `apply_patch`. Nunca guardes contraseñas, claves privadas, tokens, communities ni secretos SNMPv3 en evidencias, logs, capturas o este prompt.

## Orden y estado actual

El orden operativo solicitado es **P4.4 → P4.5 → P5.1 → P5.2 → P5.3**. P4.4, P4.5 y P5.1 figuran como **Aprobados** con evidencia real. P5.2 figura como **Bloqueado** y P5.3 todavía no fue iniciado. No comiences P5.3 mientras P5.2 siga bloqueado y no avances automáticamente: espera la indicación del operador.

Hay una desviación cronológica que debe conservarse en cualquier defensa: P5.1 cerró a las 12:48 UYT del 2026-09-15 y P4.5 comenzó a las 14:10 UYT del mismo día. Después de P4.5 se revalidaron quorum, estado de DC1/DC2 y consultas SRV, pero no se repitieron `dcdiag` ni `repadmin`. Al reconstruir desde cero se debe seguir el orden P4.4, P4.5, P5.1, P5.2 y P5.3.

### P4.4 — Aprobado

`PFT-CLUSTER` tiene PVE-1 `192.168.50.10`, PVE-2 `192.168.50.11` y QDevice/QNetd `192.168.90.28`. La evidencia muestra 3 votos esperados/recibidos, quorum 2 y `Quorate: Yes`, con QDevice. No hay VMs HA ni trabajos `pvesr`. Las limitaciones de P4.3 se mantienen: no se ejecutaron P4T-PVE2, la prueba VM-a-VM ni el aprendizaje de MAC de ambas VMs.

### P4.5 — Aprobado

Se apagó PVE-1 de forma controlada; PVE-2 y QDevice conservaron quorum 2/2. PVE-1 volvió a 3/3. No se afirma failover ni reinicio automático de VMs. DC1 debió iniciarse manualmente porque no tenía autoarranque.

### P5.1 — Aprobado según el cierre mínimo del plan

DC1-PFT está en `192.168.50.12/27` sobre PVE-1 y DC2-PFT en `192.168.50.13/27` sobre PVE-2, con AD DS/DNS, DNS cruzado, zonas integradas y réplica inicial comprobada en las evidencias históricas. El frontend `192.168.100.6/29` usa DNS `.12/.13` y `web.pft.test` resolvió a esa IP. El forwarder externo no fue configurado ni probado. La evidencia de VLAN 100 es histórica y el puerto no se recapturó en el cierre.

### P5.2 — Bloqueado; no hay estado vivo posterior al último corte documentado

Referencias de sesiones anteriores, ordenadas por fecha en el registro central:

- `.agents/evidencias/P5/2026-09-15_P5.2_AD-DNS_control.md`
- `.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_pre.txt` y `2026-09-16_P5.2_AD-DNS_DC2_pre.txt`
- `.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_pre_cambios.txt`
- `.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_post_cambios.txt`
- `.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_inventario.txt`
- `.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_prueba.txt`
- `.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_replication_prueba.txt`
- `.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_recovery_prueba.txt`
- `.agents/evidencias/P5/2026-09-16_P5.2_PVE_pre.txt` y `2026-09-16_P5.2_PVE_post.txt`
- `outputs/P5/2026-09-17_P5.2_PVE-2_pre.txt`, `2026-09-17_P5.2_PVE-2_prueba.txt`, `2026-09-17_P5.2_PVE-2_post.txt` y `2026-09-17_P5.2_PVE-2_control.md`

En la sesión del 2026-09-16, el acceso WinRM a DC1/DC2 por túneles SSH temporales funcionó. DC2/VMID 102 estaba `stopped`; se inició una vez y luego se verificaron DC1/DC2 `running`, quorum PVE 3/3, servicios AD/DNS y replicación `0/5` en ambos sentidos. Se añadieron en DC1 sólo los A definidos en el diseño: `postgres.pft.test` → `192.168.50.16` y `zabbix.pft.test` → `192.168.50.17`. Ambos DNS respondieron con esos valores y con los A PVE/PG/Web. El preestado confirmó que las cinco relaciones GG→DL ya existían; no se modificaron grupos. El error operativo 110 de consulta del socio remoto queda documentado. Esa captura es histórica, no describe el último estado conocido.

P5.2 no está terminada: los grupos globales consultados no tienen usuarios; las cinco GPO PFT son esqueletos sin payload de configuración (SYSVOL sólo contiene `GPT.INI` y `Get-GPOReport` falla); faltan los valores y la población/filtros de GPO, y confirmar si se requiere zona inversa/PTR para VLAN 100. `PFT-MGMT-Workstations` está enlazada en la OU raíz `PFT` y en `MGMT-VLAN90`; resolver su alcance antes de configurar la política. Se observó una diferencia de zona horaria entre LaptopUbuntu y DCs; se reserva a P5.3. No avanzar a P5.3 automáticamente.

El operador informó el 2026-09-17 que pudo iniciar sesión en la consola de DC1 y vio Windows Server 2022 Standard Evaluation con SConfig. Es un resultado reportado por el operador, no una captura o lectura verificada por esta sesión. Confirma acceso interactivo al sistema operativo según ese reporte; no prueba por sí mismo el estado de AD DS/DNS, replicación, membresías ni GPO. El canal PowerShell administrativo desde esta sesión no se ha verificado.

La actualización más reciente registrada, 2026-09-17 19:00–19:09 UYT, informó PVE-2 `Quorate: No`, QDevice con 0 votos y DC2/VMID 102 detenida, pese a que el endpoint web de PVE-2 respondía. Consultar `outputs/P5/2026-09-17_P5.2_PVE-2_prueba.txt` y el cierre en `.agents/EVIDENCIAS_DE_IMPLEMENTACION.md`. No afirmar que ambos DC estén operativos ni que el clúster tenga quorum sin una revalidación nueva.

El operador autorizó expresamente aplicar lo que esté descrito por el Plan/diseño. Esa autorización cubrió los dos A explícitos, ya aplicados; las relaciones GG→DL ya estaban hechas. El 2026-09-16 también autorizó crear cuentas de laboratorio si no estaban documentadas. No se encontraron identidades asignadas a los cuatro GG y se propusieron `lab-pve-admin`, `lab-app-user`, `lab-db-admin` y `lab-zabbix-admin`; no se crearon porque la única apertura de PowerShell `New-PSSession` falló con 1312 antes de cualquier comando AD. No pedir nuevamente los nombres: al recuperar el canal, capturar preestado nuevo, verificar duplicados y OUs, y continuar con esa autorización. Aún faltan los valores/alcance/filtros de GPO y confirmar la zona inversa VLAN 100. No avanzar a P5.3 antes de cerrar P5.2.

## Acceso GNS3 autorizado

El proyecto activo es `sprint1-preview1`, ID `47a3267f-9b02-4e97-a0e8-0aacb46d5ffd`, en el anfitrión Ubuntu. El usuario es `bruno`; determina la IP vigente al iniciar una sesión remota y no dependas de direcciones antiguas. Usa la instancia activa y la API local. Si necesitas SSH, fuerza autenticación por contraseña (`PubkeyAuthentication=no`) y deja que el operador ingrese el valor interactivamente. No crees claves ni guardes credenciales. Mantén API GNS3 y VNC en loopback; usa túnel SSH si corresponde y no expongas TCP/3080 o VNC directamente.

## Requisito docente S4 recibido el 2026-09-18

Leer `.agents/ALINEACION_REQ_INFRA_S4_2026.md` antes de informar cobertura del proyecto. El plan operativo PFT-S1 no cubre por sí solo todos los requisitos del PDF: las diferencias de alcance, estado y evidencia se describen en esa matriz. No trasladar una brecha docente a una configuración o tarea PX.Y sin actualizar primero el alcance y el plan con el operador.

## Credenciales

Las credenciales académicas no están almacenadas en la copia actual bajo `outputs/P5/CREDENCIALES_ACADEMICAS.md` ni en otro archivo con nombre de credenciales encontrado por búsqueda de nombres. El operador puede proporcionarlas en el chat cuando sean necesarias. Úsalas sólo de forma interactiva, no las repitas, no las escribas en archivos y no las pruebes en variantes. La contraseña DSRM, si existe, no sustituye el inicio de sesión administrativo normal.

## Higiene de la copia

La raíz contiene `sprint1-preview1/Sprint1.png` como referencia visual, y se observó un archivo temporal no enlazado `.pft_dc1.png` junto con `__pycache__`; no uses esos archivos como evidencia ni los abras automáticamente. Pide autorización antes de eliminar algo. No existe `.git` en la raíz, por lo que no inicialices un repositorio ni afirmes estado Git.

Al iniciar el nuevo chat, lee los documentos obligatorios, informa el estado actualizado y continúa únicamente P5.2 cuando haya datos suficientes para los puntos abiertos. No vuelvas a pedir autorización para los cambios explícitos del Plan ya realizados; no inventes los datos faltantes. Cuando P5.2 esté completada, informa el resultado y espera indicación antes de pasar a P5.3.

### Actualización P5.2 — 2026-09-16 15:52–15:55 UYT

El operador pidió buscar cuentas/personas asignadas a los cuatro GG en la documentación y crearlas si no estaban definidas. No se encontraron identidades de rol para esos grupos. Se seleccionó una propuesta de cuatro identidades de laboratorio por rol: lab-pve-admin, lab-app-user, lab-db-admin y lab-zabbix-admin, pero no se crearon porque la única apertura PowerShell New-PSSession por WinRM devolvió error 1312. No se ejecutaron cmdlets AD ni hubo escrituras; no se probó otra variante de credenciales. Ver .agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_incidente_cuentas.md.

En la reanudación, conseguir un canal administrativo WinRM funcional, capturar preestado AD inmediato, comprobar duplicados y confirmar OU antes de crear. La propuesta es mantener las cuentas deshabilitadas y sin contraseña hasta que el operador las habilite con credenciales asignadas de forma segura. Las GPO y el alcance DNS inverso VLAN 100 siguen pendientes. No avanzar a P5.3.

El operador aclaró el 2026-09-16 que la autorización para crear las cuentas ya está concedida; no vuelvas a pedir permiso. La revalidación más reciente confirmó `qm status 101` → `running` y HTTP 405 en `/wsman` desde PVE-1, lo cual verifica transporte hacia DC1 pero no autenticación. PVE-1 puede alcanzar WinRM en DC1, pero no tiene `pwsh`, `pywinrm` ni `requests_ntlm`; DC1 no tiene SSH abierto, no declara consola serial, y el QEMU Guest Agent no está ejecutándose. Windows local no alcanza PVE-1 ni DC1, Ubuntu tampoco llega directamente a los nodos, y el puerto local `127.0.0.1:15991` está cerrado. La API local de GNS3 se usó en memoria para acceder a AlpineSSHClient-1 y de allí a PVE-1; sus credenciales no se imprimieron ni guardaron.

La propuesta anterior de añadir `127.0.0.1` a `TrustedHosts` queda **pospuesta** hasta establecer y verificar primero un túnel real. No ejecutar ese comando todavía, no repetir la autenticación que falló y no probar variantes. Para reanudar P5.2 hace falta un cliente PowerShell administrativo con ruta a DC1. Antes de cualquier escritura, capturar un preestado AD actual y revisar duplicados de las cuatro cuentas propuestas. El incidente actualizado es `.agents/evidencias/P5/2026-09-16_P5.2_AD-DNS_incidente_cuentas.md`. P5.2 permanece **Bloqueado** y no se inicia P5.3.

### Actualización del entorno — 2026-09-17

Se inició la API GNS3 existente limitada a `127.0.0.1:3080` y se abrió `sprint1-preview1`; quedaron registrados pre/post de GNS3 y PVE. DC1/VMID 101 y DC2/VMID 102 se arrancaron y quedaron `running`; ese preestado mostró quorum 3/3 con QDevice. Desde PVE, consultas directas a ambos DC devolvieron SOA `pft.test` `NOERROR`, serial 69; esto no prueba replicación. GET anónimo a `/wsman` devolvió 405 y no fue autenticado. Las evidencias de GNS3/PVE están en `.agents/evidencias/P5/2026-09-17_P5.2_GNS3_pre.txt`, `2026-09-17_P5.2_GNS3_post.txt`, `2026-09-17_P5.2_PVE_pre.txt` y `2026-09-17_P5.2_PVE_post.txt`.

El procedimiento temporal de GUI documentado en `configs INFRA/7. Proxmox/4. Pasar ISOs a Proxmox.txt` y en la guía P5.2 usa Ubuntu `.1`, PVE-1 `.2` y PVE-2 `.3`. La topología Cloud1–switch ya existía; para el acceso PVE-2 sólo se levantó `ens4` y se añadió `.3` en ejecución. HTTPS/8006 respondió HTTP 200 en ambas direcciones durante sus pruebas. PVE-2 seguía sin quorum (1/2 votos, QDevice 0) y DC2/102 detenida al capturar el postestado; el enlace temporal no repara Corosync/QDevice. Los comandos, pruebas, reinicios y rollback constan en `outputs/P5/2026-09-17_P5.2_PVE-2_control.md` y sus artefactos asociados.

El operador informó después que pudo iniciar sesión en la consola Windows de DC1 y vio SConfig. No se conservó una captura de esa observación en esta sesión ni se hicieron cambios en AD desde esa consola. P5.2 continúa **Bloqueado** por los puntos de grupos, alcance/configuración GPO y decisión de zona inversa VLAN 100. El resolver PVE `.122.1` frente al `.12` histórico permanece como observación sin corregir. P5.3 no se inició.
