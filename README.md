# LAB-03 — Privacidad, cumplimiento y gobierno de los datos

* **Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
* **Unidad:** II. Seguridad, privacidad y control de acceso  
* **Tema:** 2.5 Privacidad, cumplimiento y gobierno de los datos  
* **Motor:** PostgreSQL 16 (Contenedor Podman)  
* **Estudiante:** Genaro Isaac Cárdenas Soto (@darksitoV)  
* **Organización Evaluada:** Comercializadora Norte S.A. de C.V.  
* **Repositorio Oficial:** [laboratorio-3-dba (GitHub)](https://github.com/darksitoV/laboratorio-3-dba.git)  

---

## 1. Descripción de la Práctica y Estructura del Repositorio

Este repositorio contiene la entrega integral del **Laboratorio 03: Privacidad, cumplimiento y gobierno de los datos** para la empresa *Comercializadora Norte S.A. de C.V.*, ejecutado sobre **PostgreSQL 16**.

El propósito fundamental de la práctica consiste en traducir los principios éticos, jurídicos y de gobierno de la información (LFPDPPP y RGPD) en **decisiones arquitectónicas y controles técnicos concretos en PostgreSQL**:
1. **Minimización de Datos:** Creación de esquemas acotados a la necesidad funcional estricta (mesa de ayuda y soporte).
2. **Separación por Finalidad:** Generación de información estadística agregada (k-anonimato) sin identificadores personales.
3. **Control de Acceso (RBAC):** Restricción de permisos mediante vistas y denegación explícita sobre tablas con PII.
4. **Ciclo de Vida y Derechos ARCO:** Análisis técnico de dispersión en respaldos, réplicas y políticas de bloqueo.
5. **Gobernanza Corporativa:** Matriz de asignación de responsabilidades (*Data Owner* vs *Data Custodian*).

---

### Estructura de Archivos del Laboratorio

```text
laboratorio-3-dba/
├── .gitignore                          # Protección contra logs, respaldos y secretos
├── README.md                           # Informe final ejecutivo (Sección 26 del manual)
├── informe.md                          # Informe técnico integral y respuestas de reflexión (Sección 27)
├── sql/                                # Scripts SQL para PostgreSQL 16
│   ├── 01-minimizacion.sql             # Tabla clientes_soporte y principio de necesidad
│   ├── 02-finalidad.sql                # Agregaciones analíticas por ciudad y rangos de edad
│   └── 03-control-acceso.sql           # Rol analista, vista v_analitica_clientes y permisos
└── evidencias/                         # Documentación técnica con comandos, resultados y conclusiones
    ├── img/                            # Capturas de terminal en alta resolución
    ├── 01-inventario-datos.md          # Matriz de inventario, finalidad y clasificación de campos
    ├── 05-finalidad-secundaria.md      # Análisis sobre mercadotecnia, perfilamiento y consentimiento
    ├── 08-ciclo-vida.md                # Mapa de propagación, persistencia en backups y derechos ARCO
    ├── 10-retencion.md                 # Política de conservación, riesgos de acumulación y plazos legales
    ├── 11-gobierno-datos.md            # Matriz institucional de gobierno y separación de funciones (SoD)
    ├── 12-privacidad-diseno.md         # Evaluación de nueva app, data hoarding y esquema minimizado
    ├── 14-evaluacion-integral.md       # Auditoría de 10 problemas críticos en escenario de 50,000 clientes
    └── 15-arquitectura.md              # Propuesta conceptual de arquitectura de datos protegidos
```

---

## 2. INFORME FINAL (SECCIÓN 26 DEL MANUAL OFICIAL)

### 2.1 Introducción: El Problema de Privacidad Abordado
En la administración de bases de datos, la seguridad técnica suele centrarse en evitar accesos no autorizados. Sin embargo, una base de datos puede estar protegida contra intrusos y aun así presentar problemas de privacidad o cumplimiento normativo si recopila datos que no son necesarios, si se utilizan para fines distintos a los informados al cliente o si se conservan por tiempo indefinido. En esta práctica se analiza cómo traducir los principios de privacidad, minimización y finalidad en configuraciones técnicas dentro de PostgreSQL 16.

### 2.2 Inventario de Datos
Se analizó la tabla `clientes` de *Comercializadora Norte S.A. de C.V.*, clasificando sus 9 atributos entre identificadores directos (`nombre`, `correo`, `telefono`), identificadores fiscales sensibles (`rfc`), datos indirectos/demográficos (`edad`, `ciudad`, `codigo_postal`) y metadatos técnicos (`id`, `fecha_alta`). Cada atributo fue asociado con una finalidad operativa indispensable y su respectivo nivel de confidencialidad.  
*(Detalle completo en [`evidencias/01-inventario-datos.md`](evidencias/01-inventario-datos.md))*

### 2.3 Finalidades
Se establecieron las fronteras legítimas de tratamiento:
* **Atención al Cliente:** Interacción directa para solución de incidencias y confirmación de pedidos.
* **Facturación:** Emisión de comprobantes fiscales CFDI 4.0 ante el SAT.
* **Analítica:** Inteligencia de negocios y dimensionamiento de mercado a nivel agregado.
* **DBA:** Mantenimiento, rendimiento y seguridad de la infraestructura tecnológica.  
Se determinó que la tenencia legítima de los datos no habilita a la organización a utilizarlos para finalidades secundarias (como mercadotecnia) sin consentimiento previo y expreso del titular.  
*(Detalle completo en [`evidencias/05-finalidad-secundaria.md`](evidencias/05-finalidad-secundaria.md))*

### 2.4 Minimización
Se demostró que solicitar y conservar datos en exceso incrementa exponencialmente el impacto de cualquier incidente de seguridad. Se refactorizó la solicitud del área de soporte técnico creando la estructura `clientes_soporte` (`sql/01-minimizacion.sql`), restringida estrictamente a `id`, `nombre`, `correo` y `telefono`, eliminando el acceso al `rfc` y reduciendo la exposición innecesaria de PII.

### 2.5 Control de Acceso
Se implementó el principio de mínimo privilegio en PostgreSQL mediante el rol `analista` y la vista disociada `v_analitica_clientes` (`sql/03-control-acceso.sql`). Al rol se le otorgó acceso exclusivo a métricas por ciudad y rangos de edad, mientras que se le revocó el acceso directo a la tabla `clientes`. Las pruebas demostraron que cuando el analista intenta consultar la tabla principal, el motor responde con: `ERROR: permission denied for table clientes`.

### 2.6 Derechos ARCO
Se analizaron las implicaciones técnicas de las solicitudes ARCO:
* **Acceso:** Consultas parametrizadas de localización (`SELECT ... WHERE correo = ...`).
* **Rectificación:** Modificaciones puntuales (`UPDATE`) con registro obligatorio en bitácoras para trazabilidad.
* **Cancelación:** Se demostró por qué un `DELETE` en la tabla viva no elimina el dato de respaldos ni satisface las leyes fiscales (SAT CFF Art. 30). Se formuló la implementación técnica del **Periodo de Bloqueo** (*Soft Delete*).
* **Oposición:** Desactivación de finalidades secundarias mediante banderas booleanas.  
*(Detalle completo en [`evidencias/08-ciclo-vida.md`](evidencias/08-ciclo-vida.md))*

### 2.7 Retención
Se evaluó críticamente la postura de conservar datos indefinidamente. Se sustentó la necesidad de fijar plazos legales de conservación (5 años en materia fiscal) y se propusieron mecanismos técnicos automatizados en PostgreSQL: particionamiento temporal de tablas y tareas programadas de depuración y anonimización mediante `pg_cron`.  
*(Detalle completo en [`evidencias/10-retencion.md`](evidencias/10-retencion.md))*

### 2.8 Gobierno de Datos
Se definió la matriz institucional de asignación de roles distinguiendo con claridad entre el **Propietario del Dato (*Data Owner*)** —quien decide la finalidad del negocio— y el **Custodio Técnico (*Data Custodian* / DBA)** —quien aplica los controles criptográficos y privilegios en la base de datos—.  
*(Detalle completo en [`evidencias/11-gobierno-datos.md`](evidencias/11-gobierno-datos.md))*

### 2.9 Evaluación Integral de Riesgos
Se auditaron 10 vulnerabilidades críticas en el escenario corporativo de 50,000 clientes (uso de datos reales en pruebas de desarrollo, retención de 12 años sin política, marketing no consentido, ausencia de cifrado de RFC y falta de auditoría), formulando controles de mitigación inmediatos para cada hallazgo.  
*(Detalle completo en [`evidencias/14-evaluacion-integral.md`](evidencias/14-evaluacion-integral.md))*

### 2.10 Conclusiones
La práctica permitió comprender que la administración de bases de datos debe considerar la privacidad y el cumplimiento legal desde el diseño de las tablas y permisos. Mediante el uso de vistas, delimitación de roles y esquemas mínimos, el DBA puede asegurar que cada área consulte únicamente la información necesaria para sus tareas operativas, evitando la sobreexposición de datos personales y facilitando la atención de los derechos de los titulares.

---

## 3. Preguntas de Reflexión (Sección 27)
Las respuestas completas, detalladas y fundamentadas a las 10 preguntas de reflexión se encuentran documentadas en el archivo técnico complementario [`informe.md`](informe.md).

---

## 4. Consulta del Informe Completo y Evidencias

Para consultar el desarrollo exhaustivo de cada actividad, las justificaciones técnicas formales y las respuestas completas a las 10 preguntas de reflexión de la Sección 27, diríjase a:
* **[informe.md](informe.md)**
* **Carpeta de Evidencias:** [evidencias/](evidencias/)
