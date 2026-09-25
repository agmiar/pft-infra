# ACL por función: matriz y runbook verificable

**Proyecto:** PFT-S1 / GNS3  
**Estado:** diseño implementable; no se aplicó ningún cambio en los equipos.  
**Alcance:** ACL IPv4 de tránsito inter-VLAN en CorevIOS-1 y CorevIOS-2.

## 1. Evidencia, supuestos y límites

### Hallazgos confirmados en los artefactos disponibles

| Elemento | Hallazgo |
|---|---|
| CorevIOS-1 | Tiene `VLAN_10_IN`, `VLAN_20_IN`, `VLAN_30_IN`, `VLAN_40_IN`, `VLAN_50_IN`, `VLAN_60_IN`, `VLAN_90_IN`, `VLAN_100_IN` y `FILTRO_DMZ`; las ocho primeras están aplicadas **in** sobre sus SVI. `FILTRO_DMZ` vuelve a estar aplicado **in** en `Vlan100`, por lo que es una segunda ACL de entrada sobre la misma SVI y debe retirarse al sustituir la referencia. |
| CorevIOS-2 | La captura real del 2026-09-23 confirma `VLAN_10_IN`, `VLAN_20_IN`, `VLAN_30_IN`, `VLAN_40_IN`, `VLAN_50_IN`, `VLAN_60_IN`, `VLAN_90_IN` y `FILTRO_DMZ` adjuntas de entrada sobre sus SVI. El archivo histórico que sólo mostraba `FILTRO_DMZ` estaba desactualizado; la sustitución y rollback se harán homogéneamente en ambos Core. |
| Direccionamiento vigente en los `.txt` | VLAN 50 aún figura como `192.168.50.0/29` y las ACL usan wildcard `0.0.0.7`. El plano aprobado cambia VLAN 50 a `192.168.50.0/27` (`0.0.0.31`); esta matriz usa el estado objetivo, no el libro/archivo antiguo. |
| Objetivo de hosts actualizado | `WebUbuntuServer-1` es el único Web Server en VLAN 100 (IP pendiente de confirmar); PVE-1 `.10`, PVE-2 `.11`, DC1 `.12`, DC2 `.13`, PG-1 `.14`, PG-2 `.15`, VIP PostgreSQL `.16`, Zabbix `.17`, QDevice `.90.28`. VLAN 90 es `192.168.90.0/27`; VLAN 60, `192.168.60.0/26`; VLAN 100, `192.168.100.0/29`. |
| NAT | Ambos Border Router usan la ACL estándar `NAT_INSIDE` para `ip nat inside source list NAT_INSIDE ... overload`. Es una ACL de selección de NAT, no de seguridad; debe conservarse separada. Sólo requiere sustituir su línea `/29` por `/27`, como ya prevé el plano. |
| Acceso a equipos Cisco | La ACL estándar `7` limita SSH VTY a `192.168.90.10` en ambos Core. No se cambia en este runbook. |

La planilla fue consultada sólo como referencia histórica de VLANs. No se usa como fuente de prefijos o servicios para este cambio porque el plano documenta que está desactualizada.

### Supuestos de política que deben confirmarse antes de aplicar

1. Las VLAN 10, 20, 30 y 40 son clientes autorizados de AD y del frontend Web en DMZ `<IP_WEB_DMZ>`; no se les concede administración PVE ni PostgreSQL. Si alguna no debe ser cliente de dominio, omitir su ACL nueva y mantener la vigente hasta decidir su matriz.
2. Las estaciones Windows de administración están en VLAN 90 y son los únicos orígenes autorizados a PVE. La autorización de persona/grupo continúa siendo AD/PVE; la ACL sólo restringe la red de origen.
3. SNMPv3 no está configurado inicialmente en la infraestructura. En P7.2 se configurará e inventariará sólo Core, distribución, acceso, Border, ISP y red intermedia que corresponda; Zabbix excluirá end hosts. Las reglas ACL de UDP/161 y, si se habilitan, UDP/162 se añadirán entonces con IP de gestión verificadas. No se autorizan Agent 2, API PVE ni Patroni para Zabbix en esta versión.
4. Para no perder funcionalidad de dominio se permite el rango dinámico RPC TCP `49152-65535` sólo de los clientes autorizados a DC1/DC2. En laboratorio puede reducirse a un rango fijo, por ejemplo `50000-50100`, **únicamente** después de configurar el mismo rango en ambos DC y comprobar AD/GPO/replicación.

### Límite material de una ACL SVI

`ip access-group ... in` en una SVI sólo ve tráfico que se enruta. PVE `.10/.11`, DC `.12/.13`, PG `.14/.15/.16` y Zabbix `.17` comparten VLAN 50; sus flujos locales no cruzan `Vlan50`. Por ello esta ACL Cisco **no puede** hacer exclusivos en L3 `8008`, `2379`, `2380` o IP protocol 112 entre esos hosts. Esos controles quedan fuera de esta fase; no se presenta una ACL SVI como protección falsa de tráfico same-VLAN.

Los comandos de confirmación obligatorios son:

```cisco
show running-config | section ^ip access-list|^access-list|^interface Vlan|ip access-group|ip nat
show ip interface Vlan50
show ip interface Vlan60
show ip interface Vlan90
show ip interface Vlan100
show access-lists
show standby brief
show ip route 192.168.50.0
```

Si el resultado difiere de los hallazgos, detener el cambio y actualizar esta matriz con los nombres, SVI y dirección reales.

## 2. Matriz de flujos

`ACL/SVI` indica dónde se aplica el control de tránsito. Los marcadores entre `<...>` requieren inventario real antes de pegar la ACL.

| Origen | Destino | Protocolo / puerto | Acción | Motivo | ACL / punto de aplicación |
|---|---|---|---|---|---|
| VLAN 10/20/30/40/90 autorizadas | DC1 `.12`, DC2 `.13` | UDP/TCP 53 | Permitir | DNS AD-integrado | `PFT_Vxx_FUNC_IN`, SVI origen in |
| VLAN 10/20/30/40/90 autorizadas | DC1/DC2 | TCP 88,135,389,445,464,636,3268,3269 y TCP 49152-65535; UDP 88,123,389,464 | Permitir | Kerberos, RPC EPM/dinámico, LDAP(S), GC, SMB/GPO y tiempo | `PFT_Vxx_FUNC_IN`, SVI origen in; respuestas TCP/UDP en `PFT_V50_FUNC_IN` |
| VLAN 10/20/30/40/90 autorizadas | Web DMZ `<IP_WEB_DMZ>` | TCP 80,443 | Permitir | Frontend del laboratorio | `PFT_Vxx_FUNC_IN`, SVI origen in |
| VLAN 90 | PVE-1 `.10`, PVE-2 `.11` | TCP 22,8006 | Permitir | Administración exclusiva | `PFT_V90_FUNC_IN`, `Vlan90 in` |
| VLAN distinta de 90 | PVE `.10/.11` | TCP 22,8006 | Denegar y registrar | Administración PVE explícitamente prohibida | `PFT_V10/20/30/40/50/60/100_FUNC_IN`, SVI origen in; el tráfico same-VLAN no cruza la SVI |
| `WebUbuntuServer-1` en DMZ `<IP_WEB_DMZ>` | VIP PG `.16` | TCP 5432 | Permitir | Único Web Server hacia su DB HA | `PFT_V100_FUNC_IN`, `Vlan100 in`; retorno en `PFT_V50_FUNC_IN` |
| VLAN 90 | PG-1 `.14`, PG-2 `.15`, VIP `.16` | TCP 5432 | Permitir | Administración DB autorizada | `PFT_V90_FUNC_IN`, SVI origen in |
| Cualquier otro origen inter-VLAN | PG `.14/.15/.16` | TCP 5432 | Denegar | Mínimo privilegio DB | ACL de SVI origen |
| PG-1 `.14`, PG-2 `.15` | Patroni en PG `.14/.15` | TCP 8008 | Pendiente de control L2 | Estado/health Patroni | No es visible en SVI por compartir VLAN 50 |
| PG-1 `.14`, PG-2 `.15`, QDevice `.90.28` | mismos tres etcd | TCP 2379 cliente y TCP 2380 peer | Permitir | consenso etcd de Patroni | `PFT_V90_FUNC_IN` permite `.28 -> .14/.15`; tráfico `.14/.15` local no cruza SVI |
| PG-1 `.14` | PG-2 `.15` y viceversa | IP protocol 112 | Pendiente de control L2 | VRRP unicast Keepalived | No es visible en SVI por compartir VLAN 50 |
| Zabbix `.17` | Interfaces de gestión verificadas en P7.2 de Core, distribución, acceso, Border, ISP y red intermedia | UDP 161 | Permitir | Sondeo SNMPv3 de infraestructura; no end hosts | Añadir a `PFT_V50_FUNC_IN` y ACL SVI de retorno durante P7.2, sólo después de configurar SNMPv3 e inventariar IP reales |
| Equipos de red con SNMPv3 configurado en P7.2 | Zabbix `.17` | UDP 161 retorno; UDP 162 si traps | Permitir | Respuesta SNMPv3 / traps opcionales | Añadir a la ACL SVI de origen durante P7.2, sólo con IP verificadas |
| PVE `.10/.11` | QDevice `.90.28` | TCP 5403 | Permitir | QNetd, excepción del plano | `PFT_V50_FUNC_IN` y retorno `PFT_V90_FUNC_IN` |
| Guests VLAN 60 | DC `.12/.13` | UDP/TCP 53 | Permitir | DNS entregado por DHCP; excepción mínima | `PFT_V60_FUNC_IN`, `Vlan60 in` |
| Guests VLAN 60 | VLAN 50 o VLAN 90, salvo DNS anterior | IP | Denegar y registrar | Aislamiento guests | `PFT_V60_FUNC_IN`, `Vlan60 in` |
| DMZ VLAN 100 | VLAN 50/VLAN 90 | IP | Denegar y registrar, salvo DNS a DC y `WebUbuntuServer-1 -> VIP:5432` | Web único requiere nombre de DB y DB HA | `PFT_V100_FUNC_IN`, `Vlan100 in` |
| VLAN 60/100 | Internet | IP | Permitir después de denegaciones internas | Conserva salida NAT | ACL SVI origen; `NAT_INSIDE` permanece independiente |

## 3. Orden de evaluación y retornos

Las ACL son first-match y stateless. El orden es: DHCP, excepciones funcionales concretas, denegaciones críticas PVE/segmentos internos, retorno TCP `established`, salida externa y `deny` final con `log`. No se usa `permit ip any any` ni `permit ip <VLAN> any` antes de denegar redes internas.

El retorno TCP se permite con `established` en la ACL de VLAN 50 hacia clientes, VLAN 90 hacia PVE/QDevice y, donde corresponde, desde cada SVI de cliente. Para DNS/Kerberos/NTP UDP se incluyen retornos de DC1/DC2 desde VLAN 50. ICMP no se permite por defecto; agregar una regla `echo`/`echo-reply` limitada sólo si una prueba de aceptación lo exige.

## 4. Configuración Cisco propuesta

Ejecutar este bloque **en ambos Core**, una vez aplicada la máscara `/27` de VLAN 50 indicada por el plano. Los nombres son nuevos; no edita una ACL existente. Sustituye los adjuntos sólo al final.

```cisco
conf t
! Clientes de dominio: se repite una ACL independiente por SVI para poder aplicarla.
ip access-list extended PFT_V10_FUNC_IN
 remark Clientes VLAN10: AD/DNS/Web; PVE prohibido
 permit udp any eq bootpc any eq bootps
 permit udp 192.168.10.0 0.0.0.31 host 192.168.50.12 eq domain
 permit udp 192.168.10.0 0.0.0.31 host 192.168.50.13 eq domain
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.12 eq domain
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.13 eq domain
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.12 eq 88
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.13 eq 88
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.12 eq 135
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.13 eq 135
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.12 eq 389
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.13 eq 389
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.12 eq 445
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.13 eq 445
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.12 eq 464
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.13 eq 464
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.12 eq 636
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.13 eq 636
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.12 eq 3268
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.13 eq 3268
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.12 eq 3269
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.13 eq 3269
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.12 range 49152 65535
 permit tcp 192.168.10.0 0.0.0.31 host 192.168.50.13 range 49152 65535
 permit udp 192.168.10.0 0.0.0.31 host 192.168.50.12 eq 88
 permit udp 192.168.10.0 0.0.0.31 host 192.168.50.13 eq 88
 permit udp 192.168.10.0 0.0.0.31 host 192.168.50.12 eq 123
 permit udp 192.168.10.0 0.0.0.31 host 192.168.50.13 eq 123
 permit udp 192.168.10.0 0.0.0.31 host 192.168.50.12 eq 389
 permit udp 192.168.10.0 0.0.0.31 host 192.168.50.13 eq 389
 permit udp 192.168.10.0 0.0.0.31 host 192.168.50.12 eq 464
 permit udp 192.168.10.0 0.0.0.31 host 192.168.50.13 eq 464
 permit tcp 192.168.10.0 0.0.0.31 host <IP_WEB_DMZ> eq 80
 permit tcp 192.168.10.0 0.0.0.31 host <IP_WEB_DMZ> eq 443
 deny tcp 192.168.10.0 0.0.0.31 host 192.168.50.10 eq 22 log
 deny tcp 192.168.10.0 0.0.0.31 host 192.168.50.10 eq 8006 log
 deny tcp 192.168.10.0 0.0.0.31 host 192.168.50.11 eq 22 log
 deny tcp 192.168.10.0 0.0.0.31 host 192.168.50.11 eq 8006 log
 deny ip 192.168.10.0 0.0.0.31 192.168.0.0 0.0.255.255 log
 permit ip 192.168.10.0 0.0.0.31 any
!
! VLAN20, VLAN30 y VLAN40: misma funcion, con su prefijo propio.
ip access-list extended PFT_V20_FUNC_IN
 permit udp any eq bootpc any eq bootps
 permit udp 192.168.20.0 0.0.0.63 host 192.168.50.12 eq domain
 permit udp 192.168.20.0 0.0.0.63 host 192.168.50.13 eq domain
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.12 eq domain
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.13 eq domain
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.12 eq 88
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.13 eq 88
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.12 eq 135
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.13 eq 135
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.12 eq 389
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.13 eq 389
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.12 eq 445
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.13 eq 445
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.12 eq 464
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.13 eq 464
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.12 eq 636
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.13 eq 636
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.12 eq 3268
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.13 eq 3268
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.12 eq 3269
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.13 eq 3269
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.12 range 49152 65535
 permit tcp 192.168.20.0 0.0.0.63 host 192.168.50.13 range 49152 65535
 permit udp 192.168.20.0 0.0.0.63 host 192.168.50.12 eq 88
 permit udp 192.168.20.0 0.0.0.63 host 192.168.50.13 eq 88
 permit udp 192.168.20.0 0.0.0.63 host 192.168.50.12 eq 123
 permit udp 192.168.20.0 0.0.0.63 host 192.168.50.13 eq 123
 permit udp 192.168.20.0 0.0.0.63 host 192.168.50.12 eq 389
 permit udp 192.168.20.0 0.0.0.63 host 192.168.50.13 eq 389
 permit udp 192.168.20.0 0.0.0.63 host 192.168.50.12 eq 464
 permit udp 192.168.20.0 0.0.0.63 host 192.168.50.13 eq 464
 permit tcp 192.168.20.0 0.0.0.63 host <IP_WEB_DMZ> eq 80
 permit tcp 192.168.20.0 0.0.0.63 host <IP_WEB_DMZ> eq 443
 deny tcp 192.168.20.0 0.0.0.63 192.168.50.0 0.0.0.31 eq 22 log
 deny tcp 192.168.20.0 0.0.0.63 192.168.50.0 0.0.0.31 eq 8006 log
 deny ip 192.168.20.0 0.0.0.63 192.168.0.0 0.0.255.255 log
 permit ip 192.168.20.0 0.0.0.63 any
ip access-list extended PFT_V30_FUNC_IN
 permit udp any eq bootpc any eq bootps
 permit udp 192.168.30.0 0.0.0.63 host 192.168.50.12 eq domain
 permit udp 192.168.30.0 0.0.0.63 host 192.168.50.13 eq domain
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.12 eq domain
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.13 eq domain
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.12 eq 88
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.13 eq 88
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.12 eq 135
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.13 eq 135
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.12 eq 389
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.13 eq 389
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.12 eq 445
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.13 eq 445
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.12 eq 464
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.13 eq 464
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.12 eq 636
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.13 eq 636
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.12 eq 3268
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.13 eq 3268
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.12 eq 3269
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.13 eq 3269
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.12 range 49152 65535
 permit tcp 192.168.30.0 0.0.0.63 host 192.168.50.13 range 49152 65535
 permit udp 192.168.30.0 0.0.0.63 host 192.168.50.12 eq 88
 permit udp 192.168.30.0 0.0.0.63 host 192.168.50.13 eq 88
 permit udp 192.168.30.0 0.0.0.63 host 192.168.50.12 eq 123
 permit udp 192.168.30.0 0.0.0.63 host 192.168.50.13 eq 123
 permit udp 192.168.30.0 0.0.0.63 host 192.168.50.12 eq 389
 permit udp 192.168.30.0 0.0.0.63 host 192.168.50.13 eq 389
 permit udp 192.168.30.0 0.0.0.63 host 192.168.50.12 eq 464
 permit udp 192.168.30.0 0.0.0.63 host 192.168.50.13 eq 464
 permit tcp 192.168.30.0 0.0.0.63 host <IP_WEB_DMZ> eq 80
 permit tcp 192.168.30.0 0.0.0.63 host <IP_WEB_DMZ> eq 443
 deny tcp 192.168.30.0 0.0.0.63 192.168.50.0 0.0.0.31 eq 22 log
 deny tcp 192.168.30.0 0.0.0.63 192.168.50.0 0.0.0.31 eq 8006 log
 deny ip 192.168.30.0 0.0.0.63 192.168.0.0 0.0.255.255 log
 permit ip 192.168.30.0 0.0.0.63 any
ip access-list extended PFT_V40_FUNC_IN
 permit udp any eq bootpc any eq bootps
 permit udp 192.168.40.0 0.0.0.63 host 192.168.50.12 eq domain
 permit udp 192.168.40.0 0.0.0.63 host 192.168.50.13 eq domain
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.12 eq domain
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.13 eq domain
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.12 eq 88
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.13 eq 88
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.12 eq 135
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.13 eq 135
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.12 eq 389
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.13 eq 389
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.12 eq 445
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.13 eq 445
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.12 eq 464
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.13 eq 464
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.12 eq 636
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.13 eq 636
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.12 eq 3268
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.13 eq 3268
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.12 eq 3269
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.13 eq 3269
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.12 range 49152 65535
 permit tcp 192.168.40.0 0.0.0.63 host 192.168.50.13 range 49152 65535
 permit udp 192.168.40.0 0.0.0.63 host 192.168.50.12 eq 88
 permit udp 192.168.40.0 0.0.0.63 host 192.168.50.13 eq 88
 permit udp 192.168.40.0 0.0.0.63 host 192.168.50.12 eq 123
 permit udp 192.168.40.0 0.0.0.63 host 192.168.50.13 eq 123
 permit udp 192.168.40.0 0.0.0.63 host 192.168.50.12 eq 389
 permit udp 192.168.40.0 0.0.0.63 host 192.168.50.13 eq 389
 permit udp 192.168.40.0 0.0.0.63 host 192.168.50.12 eq 464
 permit udp 192.168.40.0 0.0.0.63 host 192.168.50.13 eq 464
 permit tcp 192.168.40.0 0.0.0.63 host <IP_WEB_DMZ> eq 80
 permit tcp 192.168.40.0 0.0.0.63 host <IP_WEB_DMZ> eq 443
 deny tcp 192.168.40.0 0.0.0.63 192.168.50.0 0.0.0.31 eq 22 log
 deny tcp 192.168.40.0 0.0.0.63 192.168.50.0 0.0.0.31 eq 8006 log
 deny ip 192.168.40.0 0.0.0.63 192.168.0.0 0.0.255.255 log
 permit ip 192.168.40.0 0.0.0.63 any
!
ip access-list extended PFT_V50_FUNC_IN
 remark Retornos inter-VLAN y qnetd; no ve trafico local de VLAN50
 permit tcp 192.168.50.0 0.0.0.31 192.168.10.0 0.0.0.31 established
 permit tcp 192.168.50.0 0.0.0.31 192.168.20.0 0.0.0.63 established
 permit tcp 192.168.50.0 0.0.0.31 192.168.30.0 0.0.0.63 established
 permit tcp 192.168.50.0 0.0.0.31 192.168.40.0 0.0.0.63 established
 permit tcp 192.168.50.0 0.0.0.31 192.168.90.0 0.0.0.31 established
 permit udp host 192.168.50.12 eq domain 192.168.10.0 0.0.0.31
 permit udp host 192.168.50.13 eq domain 192.168.10.0 0.0.0.31
 permit udp host 192.168.50.12 eq domain 192.168.20.0 0.0.0.63
 permit udp host 192.168.50.13 eq domain 192.168.20.0 0.0.0.63
 permit udp host 192.168.50.12 eq domain 192.168.30.0 0.0.0.63
 permit udp host 192.168.50.13 eq domain 192.168.30.0 0.0.0.63
 permit udp host 192.168.50.12 eq domain 192.168.40.0 0.0.0.63
 permit udp host 192.168.50.13 eq domain 192.168.40.0 0.0.0.63
 permit udp host 192.168.50.12 eq domain 192.168.90.0 0.0.0.31
 permit udp host 192.168.50.13 eq domain 192.168.90.0 0.0.0.31
 permit udp host 192.168.50.12 eq domain host <IP_WEB_DMZ>
 permit udp host 192.168.50.13 eq domain host <IP_WEB_DMZ>
 permit tcp host 192.168.50.12 host <IP_WEB_DMZ> established
 permit tcp host 192.168.50.13 host <IP_WEB_DMZ> established
 permit tcp host 192.168.50.16 host <IP_WEB_DMZ> established
 ! Zabbix a infraestructura: reemplazar una linea por cada IP de gestion confirmada.
 ! permit udp host 192.168.50.17 host <IP_MGMT_EQUIPO_1> eq snmp
 ! permit udp host 192.168.50.17 host <IP_MGMT_EQUIPO_2> eq snmp
 permit udp host 192.168.50.12 eq 88 192.168.10.0 0.0.0.31
 permit udp host 192.168.50.13 eq 88 192.168.10.0 0.0.0.31
 permit udp host 192.168.50.12 eq 88 192.168.20.0 0.0.0.63
 permit udp host 192.168.50.13 eq 88 192.168.20.0 0.0.0.63
 permit udp host 192.168.50.12 eq 88 192.168.30.0 0.0.0.63
 permit udp host 192.168.50.13 eq 88 192.168.30.0 0.0.0.63
 permit udp host 192.168.50.12 eq 88 192.168.40.0 0.0.0.63
 permit udp host 192.168.50.13 eq 88 192.168.40.0 0.0.0.63
 permit tcp host 192.168.50.10 host 192.168.90.28 eq 5403
 deny tcp 192.168.50.0 0.0.0.31 host 192.168.50.10 eq 22 log
 deny tcp 192.168.50.0 0.0.0.31 host 192.168.50.10 eq 8006 log
 deny tcp 192.168.50.0 0.0.0.31 host 192.168.50.11 eq 22 log
 deny tcp 192.168.50.0 0.0.0.31 host 192.168.50.11 eq 8006 log
 deny ip 192.168.50.0 0.0.0.31 192.168.0.0 0.0.255.255 log
 permit ip 192.168.50.0 0.0.0.31 any
!
ip access-list extended PFT_V60_FUNC_IN
 remark Guests: DNS excepcional, sin acceso a servidores ni gestion
 permit udp any eq bootpc any eq bootps
 permit udp 192.168.60.0 0.0.0.63 host 192.168.50.12 eq domain
 permit udp 192.168.60.0 0.0.0.63 host 192.168.50.13 eq domain
 permit tcp 192.168.60.0 0.0.0.63 host 192.168.50.12 eq domain
 permit tcp 192.168.60.0 0.0.0.63 host 192.168.50.13 eq domain
 deny ip 192.168.60.0 0.0.0.63 192.168.50.0 0.0.0.31 log
 deny ip 192.168.60.0 0.0.0.63 192.168.90.0 0.0.0.31 log
 deny ip 192.168.60.0 0.0.0.63 192.168.0.0 0.0.255.255 log
 permit ip 192.168.60.0 0.0.0.63 any
!
ip access-list extended PFT_V90_FUNC_IN
 remark Gestion, AD y excepciones QDevice/PG
 permit udp any eq bootpc any eq bootps
 permit udp 192.168.90.0 0.0.0.31 host 192.168.50.12 eq domain
 permit udp 192.168.90.0 0.0.0.31 host 192.168.50.13 eq domain
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.12 eq domain
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.13 eq domain
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.12 eq 88
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.13 eq 88
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.12 eq 135
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.13 eq 135
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.12 eq 389
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.13 eq 389
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.12 eq 445
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.13 eq 445
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.12 eq 464
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.13 eq 464
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.12 eq 636
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.13 eq 636
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.12 eq 3268
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.13 eq 3268
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.12 eq 3269
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.13 eq 3269
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.12 range 49152 65535
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.13 range 49152 65535
 permit udp 192.168.90.0 0.0.0.31 host 192.168.50.12 eq 88
 permit udp 192.168.90.0 0.0.0.31 host 192.168.50.13 eq 88
 permit udp 192.168.90.0 0.0.0.31 host 192.168.50.12 eq 123
 permit udp 192.168.90.0 0.0.0.31 host 192.168.50.13 eq 123
 permit udp 192.168.90.0 0.0.0.31 host 192.168.50.12 eq 389
 permit udp 192.168.90.0 0.0.0.31 host 192.168.50.13 eq 389
 permit udp 192.168.90.0 0.0.0.31 host 192.168.50.12 eq 464
 permit udp 192.168.90.0 0.0.0.31 host 192.168.50.13 eq 464
 permit tcp 192.168.90.0 0.0.0.31 host <IP_WEB_DMZ> eq 80
 permit tcp 192.168.90.0 0.0.0.31 host <IP_WEB_DMZ> eq 443
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.10 eq 22
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.10 eq 8006
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.11 eq 22
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.11 eq 8006
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.14 eq 5432
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.15 eq 5432
 permit tcp 192.168.90.0 0.0.0.31 host 192.168.50.16 eq 5432
 permit tcp host 192.168.90.28 host 192.168.50.14 eq 2379
 permit tcp host 192.168.90.28 host 192.168.50.14 eq 2380
 permit tcp host 192.168.90.28 host 192.168.50.15 eq 2379
 permit tcp host 192.168.90.28 host 192.168.50.15 eq 2380
 deny ip 192.168.90.0 0.0.0.31 192.168.0.0 0.0.255.255 log
 permit ip 192.168.90.0 0.0.0.31 any
!
ip access-list extended PFT_V100_FUNC_IN
 remark WebUbuntuServer-1 unico en DMZ: DNS y PostgreSQL HA exclusivamente
 permit udp host <IP_WEB_DMZ> host 192.168.50.12 eq domain
 permit udp host <IP_WEB_DMZ> host 192.168.50.13 eq domain
 permit tcp host <IP_WEB_DMZ> host 192.168.50.12 eq domain
 permit tcp host <IP_WEB_DMZ> host 192.168.50.13 eq domain
 permit tcp host <IP_WEB_DMZ> host 192.168.50.16 eq 5432
 permit tcp host <IP_WEB_DMZ> 192.168.10.0 0.0.0.31 established
 permit tcp host <IP_WEB_DMZ> 192.168.20.0 0.0.0.63 established
 permit tcp host <IP_WEB_DMZ> 192.168.30.0 0.0.0.63 established
 permit tcp host <IP_WEB_DMZ> 192.168.40.0 0.0.0.63 established
 permit tcp host <IP_WEB_DMZ> 192.168.90.0 0.0.0.31 established
 deny ip 192.168.100.0 0.0.0.7 192.168.50.0 0.0.0.31 log
 deny ip 192.168.100.0 0.0.0.7 192.168.90.0 0.0.0.31 log
 deny ip 192.168.100.0 0.0.0.7 192.168.0.0 0.0.255.255 log
 permit ip 192.168.100.0 0.0.0.7 any
end
```

Antes de adjuntar, reemplazar `<IP_WEB_DMZ>` por la IP estática real de `WebUbuntuServer-1` y cada `<IP_MGMT_EQUIPO_n>` por la IP de gestión confirmada del inventario. Obtenerlas sin inferencias con `show ip interface brief`, `show running-config | include ^interface Vlan|ip address|snmp-server`, `show cdp neighbors detail` y `show lldp neighbors detail` en cada Core, distribución, acceso, Border e ISP. No pegar una línea que conserve un marcador.

Para cada interfaz de gestión ubicada detrás de una SVI con `PFT_Vxx_FUNC_IN`, añadir antes de su `deny ip ... 192.168.0.0` estas dos líneas con la IP inventariada; son el retorno del sondeo y el trap opcional hacia Zabbix:

```cisco
permit udp host <IP_MGMT_EQUIPO> eq snmp host 192.168.50.17
permit udp host <IP_MGMT_EQUIPO> host 192.168.50.17 eq snmptrap
```

La ACL `PFT_V20/30/40` aplica el mismo conjunto AD/DNS/Web de mínimo privilegio que VLAN 10; sólo cambia la red de origen.

## 5. Sustitución segura, verificación y rollback

1. Hacer respaldo en **ambos** Core: `copy running-config startup-config`, `show run | section ...` y guardar el resultado fuera de los routers. Verificar quién es Active por VLAN con `show standby brief`.
2. Confirmar que VLAN 50 ya es `/27`, OSPF anuncia `/27` y `NAT_INSIDE` en ambos Border usa sólo `permit 192.168.50.0 0.0.0.31`. No editar `NAT_INSIDE` como parte de la sustitución de ACL funcional.
3. Cargar las nuevas ACL sin adjuntarlas. Revisar sintaxis, contadores cero y nombres: `show access-lists PFT_V10_FUNC_IN` (y todas las demás).
4. Desde consola local o una sesión SSH permitida, reemplazar sólo la referencia de **un Core a la vez**. Quitar primero las dos referencias viejas de VLAN 100 para evitar el doble filtro y después adjuntar la nueva ACL. Para cada SVI, no queda más de una ACL IP por dirección.

```cisco
conf t
interface Vlan10
 no ip access-group VLAN_10_IN in
 ip access-group PFT_V10_FUNC_IN in
interface Vlan20
 no ip access-group VLAN_20_IN in
 ip access-group PFT_V20_FUNC_IN in
interface Vlan30
 no ip access-group VLAN_30_IN in
 ip access-group PFT_V30_FUNC_IN in
interface Vlan40
 no ip access-group VLAN_40_IN in
 ip access-group PFT_V40_FUNC_IN in
interface Vlan50
 no ip access-group VLAN_50_IN in
 ip access-group PFT_V50_FUNC_IN in
interface Vlan60
 no ip access-group VLAN_60_IN in
 ip access-group PFT_V60_FUNC_IN in
interface Vlan90
 no ip access-group VLAN_90_IN in
 ip access-group PFT_V90_FUNC_IN in
interface Vlan100
 no ip access-group FILTRO_DMZ in
 no ip access-group VLAN_100_IN in
 ip access-group PFT_V100_FUNC_IN in
end
show ip interface vlan 10 | include access list
show ip interface vlan 100 | include access list
```

5. Ejecutar pruebas de la sección siguiente y revisar contadores antes de `write memory`. Repetir en el segundo Core. Forzar un failover HSRP controlado o al menos probar contra el Core que quede activo; las ACL deben estar presentes en ambos.

**Rollback:** antes de `write memory`, quitar `PFT_*` y reponer exactamente los adjuntos que muestre el backup. En CorevIOS-1 se repone `VLAN_x_IN` en VLAN 10–100 y además `FILTRO_DMZ` en VLAN 100; en CorevIOS-2 el archivo disponible sólo evidencia `FILTRO_DMZ` en VLAN100, pero se restaura el resultado real capturado en el paso 1. No borrar las ACL `PFT_*` hasta que el rollback funcione y esté guardado.

## 6. Validación verificable

### En Cisco

```cisco
show ip interface vlan 10
show ip interface vlan 50
show ip interface vlan 60
show ip interface vlan 90
show ip interface vlan 100
show access-lists PFT_V10_FUNC_IN
show access-lists PFT_V50_FUNC_IN
show access-lists PFT_V60_FUNC_IN
show access-lists PFT_V90_FUNC_IN
show access-lists PFT_V100_FUNC_IN
show standby brief
show ip nat translations
```

Se aceptan incrementos en `permit` para pruebas positivas y en los `deny ... log` para negativas. Un contador no incrementado puede significar tráfico same-VLAN, no ausencia de control en una ACL SVI.

### Positivas

| Origen | Prueba | Resultado |
|---|---|---|
| Windows VLAN 90 | `Resolve-DnsName _ldap._tcp.dc._msdcs.pft.test -Type SRV`; `Test-NetConnection 192.168.50.12 -Port 445`; unir/actualizar GPO | DNS/AD correcto |
| Windows VLAN 90 | `Test-NetConnection 192.168.50.10 -Port 22`; `Test-NetConnection 192.168.50.10 -Port 8006` y repetir `.11` | PVE accesible sólo desde gestión |
| Windows VLAN 90 | `Test-NetConnection 192.168.50.16 -Port 5432` con cuenta `db_admins` | Administración DB permitida |
| WebUbuntuServer-1 DMZ `<IP_WEB_DMZ>` | `psql 'host=postgres.pft.test dbname=appdb user=app_user sslmode=disable'` | Cliente de prueba llega a VIP `.16`; contador de `PFT_V100_FUNC_IN` aumenta. TLS/certificados están fuera de alcance del laboratorio. |
| PG-1/PG-2/QDevice | `etcdctl --endpoints=http://192.168.50.14:2379,http://192.168.50.15:2379,http://192.168.90.28:2379 endpoint status -w table` | etcd sano |
| PG-1/PG-2 | `sudo keepalived --config-test`; `ip address show dev ens3`; `patronictl ... list` | un líder y VIP única |
| Zabbix `.17` | `snmpwalk -v3 ... <IP_MGMT_EQUIPO>` para cada Core, distribución, acceso, Border e ISP | Sólo infraestructura de red; no end hosts |

### Negativas

| Origen | Prueba | Resultado esperado |
|---|---|---|
| Guest VLAN 60 | `Test-NetConnection 192.168.50.10 -Port 8006`; `Test-NetConnection 192.168.90.28 -Port 22` | Falla; contador `PFT_V60_FUNC_IN` deny aumenta |
| `WebUbuntuServer-1` DMZ `<IP_WEB_DMZ>` | `nc -vz 192.168.90.28 2379` | Falla; contador `PFT_V100_FUNC_IN` deny aumenta |
| VLAN 10/20/30/40 representativa | `Test-NetConnection 192.168.50.10 -Port 22` y `-Port 8006` | Falla; deny de su ACL aumenta |
| DMZ distinto de `<IP_WEB_DMZ>` | `nc -vz 192.168.50.16 5432` | Falla; deny de `PFT_V100_FUNC_IN` aumenta |
| Cualquier end host | No agregarlo al inventario de Zabbix ni ejecutar sondeo SNMP | Fuera de alcance de monitoreo |

## 7. Bloqueadores que requieren confirmación

- La topología exportada y los `.txt` no son una consola viva. Confirmar con los `show` de la sección 1, especialmente CorevIOS-2, antes de cualquier `no ip access-group`.
- `WebUbuntuServer-1` es el único servidor web y está en VLAN 100. Falta su IP real: reemplazar `<IP_WEB_DMZ>` usando `show ip interface brief` del Core y `ip -br address` en el servidor antes de cargar la ACL.
- SNMPv3 no está configurado en la infraestructura. P7.2 debe configurar SNMPv3, inventariar las IP de gestión y habilitar los permisos ACL/Zabbix sólo para Core, distribución, acceso, Border, ISP y red intermedia que corresponda; los end hosts se excluyen.
- Confirmar que los DC realmente usen el rango RPC dinámico por defecto; si se endurece, fijar y documentar el rango en Windows antes de reducir la ACL.
- Los requisitos de exclusividad entre hosts de VLAN 50 no pueden verificarse con una ACL aplicada a la SVI; quedan fuera de esta fase hasta decidir el mecanismo L2 compatible con la imagen vIOS.
