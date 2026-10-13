# Cobertura y excepciones S4

**Estado:** cobertura de diseño; validación real pendiente de S5.

| Área del PDF | Cobertura planificada | Excepción, riesgo o condición |
|---|---|---|
| Dos sedes, virtualización y red | HQ/BRANCH, dos PVE, VLAN/subredes, cuatro enlaces L3 y OSPF. | Ambos sitios comparten un host GNS3: no hay tolerancia a su caída física. |
| AD DS/DNS, Sites, usuarios, DHCP y clientes | Dos DC/DNS/GC, Sites HQ/BRANCH, 20 usuarios, dos clientes y DHCP relay. | La redacción docente sobre cliente por área/sede es ambigua; se usan dos clientes por límite de RAM y 20 identidades por área. Confirmar si el docente exige más endpoints. |
| GPO y SMB | Cinco GPO exigidas, herencia/filtrado/excepción; FS-HQ con SMB/NTFS/AGDLP. | Debe demostrarse con `gpresult /h` y acceso permitido/denegado. |
| Backup, recuperación y HA | BKP-1, System State DC1, backup/restore FS-HQ y recuperación manual. | No hay HA de VM, almacenamiento compartido ni DR físico; el PDF permite justificar recuperación manual. |
| Seguridad y segmentación | Cuentas nominativas, dos Domain Admins, delegación, secretos fuera de evidencia, OSPF autenticado y ACL L3 mínimas. | No habrá firewall appliance ni Windows Firewall: es una limitación explícita frente a SEC-01/NET-05; las ACL no son equivalencia total. |
| Monitoreo y eventos | Zabbix mínimo para PVE, Core, DC, clientes y FS-HQ; eventos de autenticación Windows. | ZBX-1 no es HA y debe comprobarse que recolecta eventos requeridos. |
| Aplicación/AD | React + Spring + PostgreSQL Docker local; LDAP interno, JWT y RBAC de aplicación. | LDAPS y truststore Java quedan fuera de alcance; documentar como control de producción. |
| Entregables | Matriz T01–T12, videos con fecha/hora, documento, diagramas, presentación y GNS3 portable. | Requiere ejecución y evidencia real; el diseño no sustituye la demostración. |

## Compromiso de trazabilidad

El plan cubre todos los bloques obligatorios mediante una tarea, evidencia y prueba identificadas. No asegura una calificación ni cumplimiento real antes de implementar. Cualquier excepción de esta tabla debe presentarse al docente como limitación de recursos/contexto académico, no como requisito cumplido.

