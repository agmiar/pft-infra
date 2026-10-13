# Decisiones de alcance S4 — 2026-09-19

| Decisión | Estado |
|---|---|
| Reutilizar la topología actual; no crear proyecto desde cero. | Aprobado |
| HQ = Edificio A/POP/Core/Datacenter/DMZ; BRANCH = Edificios B/C. | Aprobado |
| Cuatro enlaces Core–Dist existentes pasan a L3, OSPF área 0/10 y autenticación. | Aprobado |
| Sin VLAN extendidas entre sedes; usar `10.0.5.0/30`–`10.0.8.0/30` si el inventario confirma disponibilidad. | Aprobado condicionado |
| PVE independientes; sin clúster, HA de VM, Patroni ni PostgreSQL HA. | Aprobado |
| DC1/HQ y DC2/BRANCH; Sites HQ/BRANCH obligatorio. | Aprobado |
| DHCP central CorevIOS-1 con relay BRANCH. | Aprobado |
| Dos clientes Windows: uno en gestión HQ y otro en gestión BRANCH. | Aprobado |
| Los clientes Windows son appliances QEMU independientes dentro de GNS3, no VMs de Proxmox; HQ usa VLAN 90 y BRANCH VLAN 110. | Aprobado — decisión asentada el 2026-09-20 |
| Cinco GPO: 01, 03, 05, 06 y 07. | Aprobado |
| FS-HQ será el servicio SMB/NTFS y la VM de restauración. | Aprobado |
| BKP-1 externo a PVE; backup manual por hito de DC1 System State y FS-HQ. | Aprobado |
| ZBX-1 mínimo para PVE, Core, DC, clientes y FS-HQ. | Aprobado |
| App local Docker en Web DMZ; API LDAP interno, JWT/RBAC app; LDAPS fuera de alcance. | Aprobado |
| Sin firewall appliance ni Windows Firewall; ACL L3 mínimas. | Riesgo aceptado/documentado |
