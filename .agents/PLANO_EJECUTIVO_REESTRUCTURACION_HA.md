# Plano ejecutivo S4 — HQ, BRANCH y servicios mínimos

**Estado:** diseño aprobado; implementación pendiente de inventario real.

## Arquitectura

```text
HQ: CorevIOS-1/2 + POP/Border + Datacenter + DMZ
  ├─ PVE-1 (gestión VLAN 90) → DC1, FS-HQ
  ├─ WebUbuntuServer-1/DMZ → React + Spring + PostgreSQL Docker
  └─ WIN-MGMT-HQ-01 (appliance QEMU GNS3, VLAN 90)

BRANCH: DistvIOS-1/2 + acceso Edificios B/C
  ├─ PVE-2 (gestión VLAN 110) → DC2, ZBX-1
  ├─ BKP-1 (fuera de Proxmox)
  └─ WIN-MGMT-BR-01 (appliance QEMU GNS3, VLAN 110)

CorevIOS-1/2 <── cuatro enlaces L3 /30, OSPF ──> DistvIOS-1/2
```

No hay clúster PVE, QDevice, Patroni, etcd ni PostgreSQL HA en el diseño activo. Los antecedentes pre-S4 se preservan en `historico/pre-s4-2026-09-19`.

## Direccionamiento acordado

| Sede | VLAN | Propósito | Red |
|---|---:|---|---|
| HQ | 10 | Administración | `192.168.10.0/27` |
| HQ | 50 | Servidores | `192.168.50.0/27` |
| HQ | 60 | Invitados | `192.168.60.0/26` |
| HQ | 90 | Gestión | `192.168.90.0/27` |
| HQ | 100 | DMZ | `192.168.100.0/29` |
| BRANCH | 110 | Gestión | `192.168.110.0/27` |
| BRANCH | 115 | Servidores | `192.168.115.0/27` |
| BRANCH | 120 | Finanzas | `192.168.120.0/26` |
| BRANCH | 130 | Recursos Humanos | `192.168.130.0/26` |
| BRANCH | 140 | TI | `192.168.140.0/26` |
| BRANCH | 150 | Operaciones | `192.168.150.0/26` |
| BRANCH | 160 | Backup | `192.168.160.0/27` |

Los cuatro enlaces Core–Dist usan `10.0.5.0/30` a `10.0.8.0/30`, previa verificación de que están libres. No se asignan interfaces ni extremos hasta completar S0.3.

| Equipo | Dirección | Nota |
|---|---|---|
| PVE-1 | `192.168.90.20/27` | AlpineSSHClient-1 conserva `.90.10`. |
| DC1-PFT | `192.168.50.12/27` | AD DS, DNS y GC HQ. |
| FS-HQ | `192.168.50.18/27` | SMB/NTFS por área. |
| WebUbuntuServer-1 | `192.168.100.6/29` | Docker app; no publicar PostgreSQL. |
| PVE-2 | `192.168.110.10/27` | Gestión BRANCH. |
| DC2-PFT | `192.168.115.12/27` | AD DS, DNS y GC BRANCH. |
| ZBX-1 | `192.168.115.17/27` | Zabbix + MariaDB local. |
| BKP-1 | `192.168.160.10/27` | Repositorio externo a PVE. |

## Diseño AD y aplicación

- Bosque/dominio: `pft.test`.
- Sites: `HQ` y `BRANCH`, vínculo permanente de bajo costo; subredes asociadas a su sede.
- Usuarios: cuatro por Administración, Finanzas, RR. HH., TI y Operaciones (20 total).
- Domain Admins: `admin.amiranda` y `admin.bcollazo`; las restantes cuentas administrativas usan delegación.
- Cuentas de servicio: `svc_backup` y `svc_ldap_bind`, sin inicio interactivo.
- La API Spring Boot autentica por LDAP interno contra DC1/DC2 y conserva JWT/RBAC de aplicación. LDAPS/truststore Java quedan fuera de alcance; los secretos quedan fuera del repositorio.

## Capacidad

PVE-1 y PVE-2: 6 GiB cada uno para sus VMs de servicio. Cada cliente Windows es un appliance QEMU independiente de GNS3 con 2 GiB asignados; no forma parte del presupuesto de RAM de PVE. Web Docker: 2 GiB. BKP-1: 1 GiB. Los nodos históricos QDevice/PG permanecen apagados y fuera del presupuesto activo. Se encienden por demo; si hay swap o menos de 2 GiB disponibles, apagar ZBX-1 y cargas no esenciales. Disco libre actual observado el 2026-09-19: 62 GiB; validar nuevamente antes de crear discos.
