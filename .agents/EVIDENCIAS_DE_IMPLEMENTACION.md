# Registro de evidencias S4

**Estado:** S1–S4 verificados según sus evidencias; S0.2–S0.4 y P3.1 excluidos por decisión explícita del operador el 2026-10-10; S5 documentado con T11/S0.4 excluido.

Las evidencias anteriores están preservadas en `.agents/historico/pre-s4-2026-09-19/` y no prueban por sí solas esta nueva arquitectura. Este registro se actualizará sólo con resultados reales obtenidos al iniciar cada tarea S0–S5.

| Fase | Estado | Resultado / referencia |
|---|---|---|
| S0 — Rebaselinar | Excluido | S0.2, S0.3 y S0.4 excluidos por decisión explícita del operador (2026-10-10). S0.1 y los documentos de alcance se conservan como contexto. |
| S1 — Red HQ–BRANCH | Aprobado | S1.1–S1.4 conservan evidencias reales. S1.5 quedó verificado con DC1/FS-HQ/PVE-1/PVE-2 accesibles desde gestión, BKP-1 no expuesto desde gestión y denegación BKP-1→PVE-2; S1.6 conserva la prueba real de caída/restauración de enlace. Evidencia de cierre S1.5: `.agents/evidencias/S1/2026-09-25_S1.5_segmentacion_prueba.md`. |
| S2 — Virtualización | Aprobado | S2.1 Aprobado con evidencia real de separación de gestión y bridges: `.agents/evidencias/S2/2026-09-20_S2.1_PVE_control.md`, `2026-09-20_S2.1_PVE_inventario.md`, `2026-09-20_S2.1_PVE_pre.txt`, `2026-09-20_S2.1_PVE_post.txt` y `2026-09-20_S2.1_PVE_prueba.md`; el incidente y rollback están en `2026-09-20_S2.1_PVE_incidente.md` y `2026-09-20_S2.1_PVE_rollback.md`. S2.2 Aprobado: PVE-1/PVE-2 independientes, Corosync/QDevice retirados del diseño activo, VMs y respaldos locales conservados, recuperación manual declarada. Evidencias: `.agents/evidencias/S2/2026-09-20_S2.2_PVE_control.md`, `2026-09-20_S2.2_PVE_pre.txt`, `2026-09-20_S2.2_PVE_post.txt`, `2026-09-20_S2.2_PVE_prueba.md`, `2026-09-20_S2.2_PVE_rollback.md` y el incidente resuelto en `2026-09-20_S2.2_PVE_incidente.md`. S2.3 Aprobado con corrección asentada: DC1, FS-HQ, DC2 y ZBX-1 son VMs de servicio PVE; WIN-MGMT-HQ-01 y WIN-MGMT-BR-01 son appliances QEMU Windows independientes dentro de GNS3, enlazados a VLAN 90/110. Las VMs PVE 104/105 fueron retiradas tras verificarse detenidas y sin SO. Evidencias: `.agents/evidencias/S2/2026-09-20_S2.3_VMs_control.md`, `2026-09-20_S2.3_VMs_pre.txt`, `2026-09-20_S2.3_VMs_post.txt`, `2026-09-20_S2.3_VMs_inventario.md`, `2026-09-20_S2.3_VMs_prueba.md`, `2026-09-20_S2.3_clientes_pre.txt`, `2026-09-20_S2.3_clientes_post.txt` y `2026-09-20_S2.3_VMs_rollback.md`. Configuración declarativa: `configs INFRA/7. Proxmox/2. Inventario S2.3.txt`, `configs INFRA/8. Windows-GNS3/WIN-MGMT-HQ-01.txt`, `WIN-MGMT-BR-01.txt`, puertos en `configs INFRA/1. ADvIOS/ADvIOS-1.txt` y `configs INFRA/3. AccvIOS/AccvIOS-1.txt`; tabla actualizada en `Direccionamiento y VLANs.xlsx`. S2.4 queda excluido por decisión expresa del operador humano (2026-09-20): no se ejecutarán ni acreditarán su documentación, el video/captura fechado ni la prueba de caída de nodo o enlace. |
| S3 — AD, GPO y archivos | Aprobado | S3.1–S3.4 aprobados. S3.5: GPO de dominio aplicadas en HQ/BRANCH y filtrado TI documentado; S3.6: cinco shares, AGDLP y casos SMB permitido/denegado reales; S3.7: clientes unidos, DNS/DHCP/GPO, RDP y PVE por sede verificados. Cierres: `.agents/evidencias/S3/2026-09-25_S3.5_GPO_control.md`, `2026-09-25_S3.6_SMB_control.md` y `2026-09-25_S3.7_clientes_control.md`. |
| S3.3 — OUs, usuarios y grupos | Aprobado | Estructura `Usuarios-PFT`/`Equipos-PFT`, cinco OUs de área, OU de clientes, 20 usuarios, cinco grupos globales, cinco cuentas administrativas y dos cuentas de servicio verificadas en runtime. Evidencias: `.agents/evidencias/S3/2026-09-22_S3.3_AD-OUs_users_groups_control.md`, `2026-09-22_S3.3_AD-OUs_users_groups_prueba.txt`, `configs INFRA/8. Windows-GNS3/DC1-PFT_S3.3.txt` y `DC2-PFT_S3.3.txt`. |
| S3.4 — DHCP y relay | Aprobado | 13 pools en CorevIOS-1, exclusiones y DNS `192.168.50.12`/`192.168.115.12` persistidos; siete relays BRANCH verificados en cada Dist; concesión real `192.168.90.11/27` y binding activo probados con Alpine. Evidencias: `.agents/evidencias/S3/2026-09-22_S3.4_DHCP_control.md`, `2026-09-22_S3.4_DHCP_prueba.txt`, `configs INFRA/0. CorevIOS/CorevIOS-1_S3.4.txt`, `CorevIOS-2_S3.4.txt`, `configs INFRA/4. DistvIOS/DistvIOS-1_S3.4.txt` y `DistvIOS-2_S3.4.txt`. |
| S3.5 — GPO | Aprobado | Cinco GPO creadas/enlazadas; `gpupdate` y `gpresult` reales en HQ y BRANCH confirmaron políticas de dominio, baseline, actualización y aviso; el filtrado de GPO-07 conserva GG-TI. Evidencia: `.agents/evidencias/S3/2026-09-25_S3.5_GPO_control.md`. |
| S3.6 — FS-HQ/SMB AGDLP | Aprobado | FS-HQ unido a pft.test, AGDLP, cinco shares y ACL NTFS verificadas. Se enumeraron los recursos y se observaron casos permitido/denegado reales. Evidencia: `.agents/evidencias/S3/2026-09-25_S3.6_SMB_control.md`. |
| S3.7 — clientes Windows | Aprobado | HQ y BR unidos, DHCP/DNS/GPO y RDP/TCP 3389 verificados; PVE-1/PVE-2 accesibles desde su sede, y TCP/445/5985 no expuestos en las estaciones. Evidencia: `.agents/evidencias/S3/2026-09-25_S3.7_clientes_control.md`. |
| S4 — App y backup | Aprobado | S4.1 stack local operativo; S4.2 LDAP real contra AD con UPN/down-level, JWT preservado y HTTP 401 inválido; S4.3 BKP-1 con System State, VHDX/catálogo fresh y puntos previos conservados. S4.4 conserva restauración real. Evidencias: `.agents/evidencias/S4/2026-09-25_S4.1_app_control.md`, `2026-09-25_S4.2_LDAP_incidente.md` y `2026-09-25_S4.3_backup_control.md`. |
| S5 — Monitoreo y cierre | Aprobado parcial | S5.1 ZBX-1/MariaDB/frontend e inventario implementados; S5.2 agentes PVE/Windows, FS-HQ, ambos clientes, SNMPv3 Core y eventos Windows verificados, incluido DC2 desde el origen real ZBX-1 con seis registros históricos para 4625; S5.3 probó recuperación de agente PVE-1, agente DC1, enlace Core–Dist, ambos clientes y restauración formal de archivo FS-HQ. T01–T12 queda documentada con T09/T10/T12 aprobados y T11 excluido por omisión de S0.4. Evidencias: `.agents/evidencias/S5/2026-10-11_S5.1_zabbix-inventario.md`, `.agents/evidencias/S5/2026-10-11_S5.2_zabbix-snmp-alertas.md`, `.agents/evidencias/S5/2026-10-11_S5.3_pruebas-alertas-recuperacion.md`, `.agents/evidencias/S5/2026-10-12_S5.1-S5.2_FS-HQ_reintento.md`, `.agents/evidencias/S5/2026-10-12_S5.3_clientes_reintento.md`, `.agents/evidencias/S5/2026-10-12_T10_clientes_alertas_recuperacion.md`, `.agents/evidencias/S5/2026-10-12_S5.3_FS-HQ_restauracion-formal.md`, `.agents/evidencias/S5/2026-10-12_T01-T12_cierre.md`, `.agents/evidencias/S5/2026-10-11_S5.4_ventana-integrada.md`, `.agents/evidencias/S5/2026-10-11_S5.4_cierre-requisitos.md` y `.agents/evidencias/S5/2026-10-11_S5.4_acta-retencion-rollback.md`. |

## Actualización S5 — revalidación de DC2

La revalidación del 2026-10-12 confirmó que DC2 responde `5/5` ICMP y TCP/10050 desde `DistvIOS-2`, y `3/3` ICMP/TCP abierto desde un origen temporal same-VLAN. La dirección temporal fue retirada y la ruta original de PVE quedó restaurada. Desde ZBX-1, `agent.ping=1` y `system.hostname=DC2-PFT`; el ítem 4625 de DC2 mantiene seis registros en `history_log`. Ver `evidencias/S5/2026-10-12_reintento_conectividad_DC2.md` y `evidencias/S5/2026-10-12_validacion_evento_4625_DC2.md`.

## Revalidación S3.1 — 2026-10-14

**Estado: Aprobado.** La captura inicial mostró un bloqueo real de conectividad/DNS hacia `DC2-PFT` y quedó conservada como incidente en `.agents/evidencias/S3/2026-10-14_S3.1_AD-DNS_incidente.md`. La revalidación posterior aportada desde las consolas de DC1/DC2 y desde BRANCH confirmó TCP/53, /389 y /445, DNS directo/SRV, `dcdiag` PASS, `repadmin` con `0/5` fallos en origen y destino, tiempo sincronizado y sitios `hq`/`branch`. Postestado y capturas: `.agents/evidencias/S3/2026-10-14_S3.1_AD-DNS_post.md`. Persisten como limitación documentada eventos DFSR históricos, aunque el test DFSR y la replicación actual resultaron correctos. No se ejecutaron cambios técnicos ni rollback.

## Revalidación S3.2/S3.3 — 2026-10-14

**S3.2: Aprobado.** Las 11 subredes de la topología vigente quedaron configuradas y replicadas en DC1-PFT y DC2-PFT: seis en HQ (`192.168.10.0/27`, `192.168.50.0/27`, `192.168.60.0/26`, `192.168.90.0/27`, `192.168.100.0/29`, `192.168.160.0/27`) y cinco en BRANCH (`192.168.20.0/26`, `192.168.30.0/26`, `192.168.40.0/26`, `192.168.110.0/27`, `192.168.115.0/27`). Las subredes obsoletas 120–150 fueron retiradas de AD. La sincronización forzada terminó sin errores. Evidencia: `.agents/evidencias/S3/2026-10-14_S3.2_AD-Sites_subnets_post.md`.

**S3.3 — criterio adicional de uniformidad: Aprobado.** Los equipos ya fueron ubicados en OUs con alcance de GPO y las funciones fueron alineadas: `Finanzas` pasó a `Docentes`, `RRHH` a `Estudiantes` y `Operaciones` a `Lab-IT`; también se renombraron grupos funcionales y cuentas. Los grupos de gestión heredados de PVE/DB/Zabbix continúan vacíos y no fueron asignados ni eliminados por falta de autorización de roles. Evidencias: `.agents/evidencias/S3/2026-10-14_S3.3_AD-OUs_groups_GPOs_revalidacion.md`, `.agents/evidencias/S3/2026-10-14_S3.3_AD-computers_GPO_post.md` y `.agents/evidencias/S3/2026-10-14_S3.3_AD-functional_rename_post.md`.

**Corrección S3.3 de equipos/GPO — Aprobado con limitación.** `FS-HQ` quedó en `OU=Servers,OU=PFT`; `WIN-MGMT-HQ-01` y `WIN-MGMT-BR-01` quedaron en `OU=Clientes,OU=Equipos-PFT`. Las GPO PFT fueron enlazadas a las ramas que contienen usuarios y equipos reales y la sincronización AD terminó con resultado 0. DC2 confirmó las ubicaciones de equipo; su consulta independiente de herencia GPO devolvió el error COM `0x80072020`, por lo que queda como limitación de lectura y no como fallo de la modificación. Evidencia: `.agents/evidencias/S3/2026-10-14_S3.3_AD-computers_GPO_post.md`.

## Seguimiento complementario PX.Y

La tarea P3.1 fue solicitada el 2026-09-20 como revisión documental de la línea base ACL anterior. No modifica la secuencia activa S0–S5 ni acredita requisitos por sí sola.

| Tarea | Estado | Resultado / referencia |
|---|---|---|
| P3.1 | Excluido | Excluido por decisión explícita del operador el 2026-10-10. La falta de revisión documental adicional de ACL queda como limitación y no bloquea S5. Evidencia histórica: `.agents/evidencias/P3/2026-09-20_P3.1_ACL_control.md`. |

## Decisión complementaria S3.6 — 2026-10-14

**Estado:** Aprobado.

El operador confirmó que los nombres finales de los directorios y shares de `FS-HQ` deben ser `Administracion`, `Docentes`, `Estudiantes`, `TI` y `Lab-IT`. El mapeo aplicado fue `Finanzas→Docentes`, `RRHH→Estudiantes` y `Operaciones→Lab-IT`; `Administracion` y `TI` permanecieron sin cambio. La verificación real con `Get-SmbShare`, `Get-SmbShareAccess` y `net view \\FS-HQ` confirmó rutas, nombres y ACL. Evidencias: `.agents/evidencias/S3/2026-10-14_S3.6_FS-HQ_renombrado_control.md`, `2026-10-14_S3.6_FS-HQ_renombrado_pre.txt`, `2026-10-14_S3.6_FS-HQ_renombrado_post.txt` y `2026-10-14_S3.6_FS-HQ_renombrado_prueba.md`.

## Revisión complementaria S3.6 — acceso administrativo — 2026-10-14

**Estado:** Aprobado.

La evidencia existente registraba `Access is denied` para `pft\\Administrator` en recursos de FS-HQ. La verificación real confirmó que la cuenta no estaba en `GG-Administradores`; se agregó, se mantuvieron las ACL por área y se añadió `PFT\\Administrator` en `Full` en los cinco shares. `Test-Path` y pruebas temporales de creación/eliminación funcionaron en los cinco UNC. Evidencias: `.agents/evidencias/S3/2026-10-14_S3.6_FS-HQ_admin_access_control.md`, `2026-10-14_S3.6_FS-HQ_admin_access_pre.txt`, `2026-10-14_S3.6_FS-HQ_admin_access_post.txt` y `2026-10-14_S3.6_FS-HQ_admin_access_prueba.md`.

## Convención

`AAAA-MM-DD_<Sx.y>_<equipo-o-servicio>_<pre|post|inventario|prueba|failover|rollback|captura|baseline|control|incidente>.<extensión>`

No incluir contraseñas, tokens, claves privadas, tickets, communities ni secretos SNMPv3.
