# Matriz S4 — requisitos, pruebas y evidencia

| Requisito | Implementación S4 | Prueba de cierre |
|---|---|---|
| VIR-01–04 | Dos PVE independientes por sede, gestión separada y dimensionamiento. | Inventario, bridges, VLAN, acceso de gestión. |
| VIR-05–07 | BKP-1, backup/restauración y recuperación manual PVE. | Backup DC1/FS-HQ, restore FS-HQ, video fechado. |
| AD-01–03 | DC1/HQ y DC2/BRANCH, DNS/GC, Sites y site link. | `dcdiag`, `repadmin`, `nltest /dsgetsite`. |
| AD-04–06 | OUs por sede/área, cuentas/grupos, DHCP relay. | Membresías, `gpresult`, `ipconfig /all`. |
| AD-07–09 | FS-HQ, NTFS/SMB, tiempo y respaldo AD. | SMB permitido/denegado, `w32tm`, System State. |
| GPO-01/03/05/06/07 | Cinco GPO, dos casos de alcance y excepción TI. | `gpresult /h`, evento y efecto real. |
| NET-01–09 | VLAN/subredes, L3 intersede, OSPF, ACL mínima y monitoreo. | Rutas, caída enlace, pruebas positivas/negativas. |
| HA-01–06 | RTO/RPO declarados, DC disponible, backup/restore y falla enlace/nodo. | Cronómetro, bitácora y recuperación. |
| SEC-01–06 | RBAC, cuentas nominativas, auditoría/eventos y secretos fuera de entregables. | Grupos delegados, alertas/eventos, procedimiento de baja. |
| ADA-01–03 | API local LDAP + JWT/RBAC. | Login válido/fallido y eventos AD. |
| T01–T12 | Matriz de aceptación final. | Resultado esperado/obtenido y referencias. |

