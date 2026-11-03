# INFORME TÉCNICO: LABORATORIO 03 — PRIVACIDAD, CUMPLIMIENTO Y GOBIERNO DE DATOS

* **Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
* **Unidad:** II. Seguridad, privacidad y control de acceso  
* **Tema:** 2.5 Privacidad, cumplimiento y gobierno de los datos  
* **Motor:** PostgreSQL 16 (Desplegado en Contenedores Podman / Alpine)  
* **Estudiante:** Genaro Isaac Cárdenas Soto (@darksitoV)  
* **Organización / Escenario:** Comercializadora Norte S.A. de C.V.  

---

## 1. INTRODUCCIÓN Y CONTEXTO OPERATIVO

En los laboratorios previos se implementaron medidas de protección técnica como clasificación, enmascaramiento, seudonimización y cifrado. Sin embargo, antes de la implementación técnica existe una pregunta fundamental: ¿la organización realmente debe recopilar y conservar ese dato? Una base de datos puede estar técnicamente asegurada y aun así presentar problemas de privacidad o cumplimiento si se recopila información innecesaria, se utiliza para fines no informados o se retiene más tiempo del debido.

En este Laboratorio 03 se analizan y aplican los principios básicos de privacidad, minimización, limitación de finalidad, retención y atención de derechos ARCO para la empresa Comercializadora Norte S.A. de C.V. en PostgreSQL 16, relacionando los requerimientos de la LFPDPPP con controles técnicos como vistas, roles RBAC y estructuras mínimas.

---

## 2. INVENTARIO Y CLASIFICACIÓN DE DATOS PERSONALES

Se catalogaron los 9 atributos presentes en la entidad principal `clientes`, identificando la naturaleza jurídica de cada dato:

1. **`id` (Bigint):** Llave primaria técnica. En sí misma es un dato pseudoidentificador que al vincularse con la tabla individualiza a una persona identificable.
2. **`nombre` (Varchar):** Dato personal directo indispensable para formalizar la relación comercial y trato al cliente.
3. **`correo` (Varchar):** Dato personal de contacto directo y localización digital.
4. **`telefono` (Varchar):** Dato personal de contacto para notificaciones urgentes y autenticación 2FA.
5. **`rfc` (Varchar):** Identificador tributario oficial regulado por la autoridad fiscal (SAT). Constituye un dato sensible de alta trascendencia fiscal y patrimonial.
6. **`edad` (Integer):** Dato indirecto y sociodemográfico. Debe eliminarse o derivarse dinámicamente de la fecha de nacimiento.
7. **`ciudad` (Varchar):** Dato de localización geográfica indirecto, necesario para logística de envíos.
8. **`codigo_postal` (Varchar):** Dato de ubicación domiciliaria y validación de comprobantes fiscales (CFDI 4.0).
9. **`fecha_alta` (Date):** Metadato operativo y de trazabilidad cronológica.

---

## 3. SEPARACIÓN Y LIMITACIÓN POR FINALIDAD

El principio de **limitación de la finalidad** (Art. 12 LFPDPPP) exige que los datos se utilicen exclusivamente para las finalidades informadas en el Aviso de Privacidad original. Se establecieron las fronteras operativas para los cuatro roles de la organización:

* **Atención al Cliente (Soporte):** Su finalidad es resolver problemas técnicos y pedidos. Requiere consultar: `id`, `nombre`, `correo` y `telefono`. No requiere conocer identificadores fiscales (`rfc`) ni fecha de alta.
* **Facturación:** Su finalidad es emitir comprobantes fiscales digitales y cumplir obligaciones contables. Requiere consultar: `nombre`, `rfc`, y `codigo_postal`. No requiere acceder a grabaciones ni correos de soporte.
* **Analítica:** Su finalidad es medir tendencias demográficas y de ventas. **No requiere identificar individualmente a ningún titular**. Requiere datos agregados (distribución por ciudad y rangos etarios).
* **DBA:** Su función es custodiar la plataforma tecnológica, asegurar respaldos y optimizar el rendimiento. No debe utilizar su acceso de superusuario para extraer o compartir datos personales para finalidades no autorizadas.

---

## 4. PRINCIPIO DE MINIMIZACIÓN DE DATOS (IMPLEMENTACIÓN SQL)

Frente a la solicitud del área de soporte de clonar la tabla entera con RFCs, edades y códigos postales, se aplicó el principio de minimización diseñando la tabla `clientes_soporte` (`sql/01-minimizacion.sql`), la cual almacena estrictamente lo necesario:

```sql
DROP TABLE IF EXISTS clientes_soporte CASCADE;
CREATE TABLE clientes_soporte (
    id BIGINT PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    correo VARCHAR(150) NOT NULL,
    telefono VARCHAR(20)
);

INSERT INTO clientes_soporte (id, nombre, correo, telefono)
SELECT id, nombre, correo, telefono FROM clientes;
```

### 4.1 Resolución de Preguntas de la Actividad 2
1. **¿Todos los campos son necesarios para atención al cliente?**  
   **No.** Soporte técnico únicamente requiere individualizar al usuario y comunicarse con él (`id`, `nombre`, `correo` y `telefono`). Campos como `rfc`, `edad`, `ciudad`, `codigo_postal` y `fecha_alta` son totalmente prescindibles para la atención postventa habitual.
2. **¿Por qué soporte necesitaría conocer el RFC?**  
   **No lo necesita.** El RFC es un identificador de naturaleza tributaria y fiscal requerido exclusivamente para facturación y declaraciones ante el SAT. Entregarlo a soporte aumentaría injustificadamente el riesgo de fraude o suplantación fiscal.
3. **¿Necesita conocer la edad?**  
   **No.** Para resolver un ticket de servicio no se requiere la edad del titular. La validación de capacidad legal de ejercicio se verifica al crear la cuenta, no en cada interacción de soporte.
4. **¿Necesita conocer el código postal?**  
   **No** para la atención técnica estándar. Solamente paquetería y logística lo requerirían en caso de envíos físicos.
5. **¿Qué principio de privacidad está relacionado con esta decisión?**  
   El **Principio de Minimización de Datos** (Art. 6 LFPDPPP y Art. 5.1c RGPD), complementado por los principios de necesidad y proporcionalidad.

---

## 5. CONTROL DE ACCESO BASADO EN ROLES Y VISTAS AGREGADAS

Para atender las necesidades del área de analítica sin vulnerar el principio de finalidad ni entregar la base de clientes en claro, se diseñaron consultas de agregación y k-anonimato (`sql/02-finalidad.sql`) y se implementó una vista disociada con segregación de roles (`sql/03-control-acceso.sql`):

```sql
-- Creación de la vista de analítica sin identificadores directos
CREATE OR REPLACE VIEW v_analitica_clientes AS
SELECT 
    ciudad,
    CASE
        WHEN edad < 18 THEN 'Menor de 18'
        WHEN edad BETWEEN 18 AND 29 THEN '18-29'
        WHEN edad BETWEEN 30 AND 44 THEN '30-44'
        WHEN edad BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60 o más'
    END AS rango_edad
FROM clientes;

-- Segregación de permisos en PostgreSQL
GRANT USAGE ON SCHEMA public TO analista;
GRANT SELECT ON v_analitica_clientes TO analista;
REVOKE SELECT ON clientes FROM analista;
```

**Validación Técnica de Bloqueo:**  
Al iniciar sesión bajo el rol `analista`, el motor autoriza la consulta sobre `v_analitica_clientes`, pero al intentar ejecutar `SELECT * FROM clientes;`, PostgreSQL detiene la instrucción emitiendo:  
`ERROR: permission denied for table clientes`.

### 5.1 Resolución de Preguntas de las Actividades 3 y 4
* **Pregunta Actividad 3: ¿Por qué esta información puede ser más apropiada para analítica que entregar directamente la tabla completa de clientes?**  
  Porque analítica busca inferir patrones de consumo, dimensionamiento de mercado y distribución geográfica, para lo cual los datos agregados (`COUNT(*) GROUP BY ciudad`, rangos etarios) son 100% suficientes. Entregar la tabla en claro violaría el principio de finalidad, expondría datos personales directos (PII) innecesariamente y crearía riesgos masivos de filtración.
* **Preguntas Actividad 4:**
  1. **¿Qué información puede consultar el rol `analista`?**  
     Únicamente la columna `ciudad` y la clasificación agregada `rango_edad` expuestas por la vista `v_analitica_clientes`.
  2. **¿Puede consultar directamente `clientes`?**  
     **No.** El permiso `SELECT` sobre `clientes` ha sido revocado expresamente; el gestor emite `ERROR: permission denied for table clientes`.
  3. **¿Puede obtener nombre, correo y RFC?**  
     **No.** Dichas columnas no forman parte de la vista y el rol carece de privilegios sobre cualquier tabla que las contenga.
  4. **¿Qué principio de privacidad estás aplicando?**  
     Los principios de **Limitación de la Finalidad** y **Minimización de Datos**.
  5. **¿Qué principio de seguridad estás aplicando?**  
     El principio de **Mínimo Privilegio (*Least Privilege*)** y **Control de Acceso Basado en Roles (*RBAC*)**.

---

## 6. IMPLICACIONES TÉCNICAS DE LOS DERECHOS ARCO

La atención de los derechos de los titulares tiene repercusiones directas sobre el Administrador de Bases de Datos:

1. **Acceso:** Búsqueda exhaustiva mediante identificadores confiables (`SELECT ... WHERE correo = '...'`). Exige generar extractos comprensibles para el usuario sin exponer llaves internas del sistema ni datos de terceros.
   * *Pregunta Actividad 6:* **¿Qué información adicional debería proporcionar la organización además del resultado de esta consulta?**  
     Conforme a la LFPDPPP (Art. 23) y el RGPD (Art. 15), debe informar: finalidades del tratamiento, categorías de datos tratados, transferencias realizadas o previstas (terceros receptores), plazo de conservación estipulado y la vía formal para ejercer rectificación, cancelación u oposición.
2. **Rectificación:** Modificación atómica (`UPDATE ... WHERE id = ...`) que exige comprobación de identidad previa y registro obligatorio en bitácoras de auditoría para prevenir la suplantación de identidad.
   * *Preguntas Actividad 7:*
     1. **¿Cómo podría comprobarse que el cambio fue autorizado?** Mediante folio formal de solicitud ARCO, validación de identidad del titular y confirmación de doble factor enviada al medio de contacto previo.
     2. **¿Debería registrarse quién realizó el cambio?** Sí, en una bitácora inmutable de auditoría indicando usuario operador, IP, timestamp y valor modificado.
     3. **¿Por qué la trazabilidad será importante?** Para auditar cualquier alteración indebida, deslindar responsabilidades legales y soportar revisiones del órgano garante (INAI).
3. **Cancelación:** La eliminación física inmediata (`DELETE`) suele ser ilegal si subsisten obligaciones de conservación fiscal (CFF Art. 30). Por ende, el DBA debe aplicar un **Periodo de Bloqueo** (*Soft Delete* mediante un atributo booleano de bloqueo), aislando el dato de las operaciones cotidianas hasta su depuración definitiva tras 5 años.
4. **Oposición:** Desactivación de finalidades secundarias (ej. `consentimiento_marketing = FALSE`), permitiendo que el cliente continúe operando sus servicios primarios sin recibir comunicaciones no deseadas.
   * *Preguntas Actividad 9:*
     1. **¿Qué información podría necesitar mantenerse?** Datos indispensables para facturación y ejecución de la relación comercial principal (nombre, RFC, historial contable).
     2. **¿Qué información podría dejar de utilizarse?** Canales de contacto para campañas publicitarias, perfilamiento y llamadas promocionales.
     3. **¿Qué mecanismos técnicos podrían separar finalidades?** Banderas booleanas en BD (`opt_in_marketing = FALSE`), vistas filtradas para los roles comerciales y listas de supresión.
     4. **¿Por qué la decisión final no debe ser tomada únicamente por el DBA?** Porque involucra interpretar derechos legales y excepciones normativas frente a obligaciones fiscales y mercantiles, labor que compete al área Jurídica y al Oficial de Privacidad.

---

## 7. POLÍTICA DE RETENCIÓN Y CICLO DE VIDA DE LOS DATOS

La propuesta de almacenar datos indefinidamente fue evaluada como un grave riesgo legal y operacional. El ciclo de vida de los datos personales debe contemplar:
* **Fase Activa:** Vigencia de la relación comercial.
* **Fase de Bloqueo:** Periodo de conservación legal de **5 años** para fines tributarios y contables ante el SAT.
* **Fase de Disposición:** Purga automatizada mediante particionamiento temporal y tareas programadas (`pg_cron`), o anonimización irreversible para series estadísticas históricas.

---

## 8. MATRIZ DE GOBIERNO Y SEPARACIÓN DE FUNCIONES (SoD)

Se consolidó la asignación formal de responsabilidades:
* **Data Owner (Propietarios de Negocio):** Directores Comercial y de Finanzas, facultados para determinar quién accede a qué dato y con qué finalidad.
* **Data Custodian (Custodio Técnico / DBA):** Responsable de instrumentar los esquemas DDL, privilegios RBAC, cifrado de columnas y planes de respaldo.
* **Data Protection Officer (Oficial de Privacidad):** Supervisa el cumplimiento de la LFPDPPP y coordina las solicitudes ARCO.

---

## 9. EVALUACIÓN INTEGRAL DE RIESGOS

Se identificaron 10 vulnerabilidades operacionales críticas en el escenario de 50,000 clientes:
1. Acceso analítico irrestricto a datos personales.
2. Volcados reales entregados a desarrolladores para pruebas.
3. Retención indiscriminada durante 12 años.
4. Envíos promocionales de mercadotecnia sin consentimiento informado.
5. Inexistencia de catálogo y finalidades documentadas.
6. Falta de segregación entre entornos de producción y analítica.
7. RFC en texto claro sin cifrado en reposo.
8. Ausencia de auditoría de lecturas (`pgaudit`).
9. Carencia de protocolo técnico para derechos ARCO.
10. Ambigüedad en la gobernanza de datos y decisiones unilaterales.

---

## 10. CLASIFICACIÓN DE CONTROLES TÉCNICOS Y ADMINISTRATIVOS (ACTIVIDAD 13)

Conforme a la Sección 19 del manual oficial, se clasifican y justifican las medidas de seguridad y privacidad:

| Medida | Técnico | Administrativo | Justificación Técnica y Operativa |
| :--- | :---: | :---: | :--- |
| **Crear roles de PostgreSQL** | **X** | | Medida puramente técnica implementada en el motor mediante sentencias DDL (`CREATE ROLE`, `GRANT`, `REVOKE`) que gobiernan privilegios en el catálogo del sistema. |
| **Política de retención** | | **X** | Documento normativo corporativo emitido por la dirección institucional que estipula formalmente los plazos legales y operativos de conservación de la información. |
| **Cifrado de datos** | **X** | | Algoritmo matemático computacional (ej. `pgcrypto`, AES-256, PGP) que transforma texto claro en bloques ilegibles en disco o red. |
| **Procedimiento para solicitudes ARCO** | | **X** | Protocolo organizacional, plazos, formatos y flujos de trabajo interdepartamentales para recibir, validar y dictaminar las solicitudes de los titulares. |
| **Vista con información limitada** | **X** | | Objeto estructurado de base de datos (`CREATE VIEW`) que restringe a nivel de consulta las columnas y registros expuestos a un rol determinado. |
| **Clasificación de información** | **X** | **X** | **Ambos:** Es **administrativo** al definir la taxonomía corporativa (Público, Confidencial, Secreto); y es **técnico** al etiquetar esquemas, aplicar políticas de seguridad a nivel de fila (RLS) y catálogos de metadatos. |
| **Registro de auditoría** | **X** | **X** | **Ambos:** Es **técnico** por la captura de eventos en el motor (`pgaudit`, `pg_wal`); y es **administrativo** por la política de revisión periódica, cadena de custodia e inspección por el comité de cumplimiento. |
| **Política de control de acceso** | | **X** | Documento institucional que estipula las directrices de mínimo privilegio, segregación de funciones (SoD) y perfiles autorizados. *(Su aplicación en PostgreSQL mediante GRANT/REVOKE constituye el control técnico).* |

---

## 11. RESPUESTAS A LAS PREGUNTAS DE REFLEXIÓN (SECCIÓN 27)

A continuación se responden detalladamente las diez preguntas de reflexión formuladas en el manual oficial del laboratorio:

### Pregunta 1: ¿Una base de datos técnicamente segura necesariamente cumple con todos los requisitos de privacidad?
**No.**  
La seguridad de la información protege la confidencialidad, integridad y disponibilidad (tríada CIA) contra accesos no autorizados, ataques e intrusiones técnicas. La **privacidad**, en cambio, evalúa si la recolección, el tratamiento, la finalidad, el tiempo de conservación y la legitimidad del uso de esos datos respetan los derechos del titular.  
Una base de datos puede tener cifrado de disco militar, contraseñas robustas y firewall de última generación (100% segura técnicamente) y, simultáneamente, violar las leyes de privacidad si recopila datos excesivos sin consentimiento o los comercializa para finalidades ilegítimas.

### Pregunta 2: ¿Por qué el principio de mínimo privilegio también contribuye a la privacidad?
Porque al limitar los permisos de cada usuario, rol o aplicación estrictamente a los recursos que necesitan para ejecutar su labor (*Need-to-Know*), se reduce la cantidad de personas y procesos expuestos a datos personales sensibles. Si un rol de soporte o analítica solo puede ver datos agregados o seudonimizados, una vulnerabilidad en sus credenciales o una conducta maliciosa no resultará en la exfiltración masiva de información confidencial.

### Pregunta 3: ¿Por qué el DBA no debería decidir por sí solo la finalidad del tratamiento de los datos?
Porque el DBA es el **Custodio Técnico (*Data Custodian*)**, no el **Propietario (*Data Owner*)** ni el asesor legal de la organización. Las finalidades del tratamiento involucran compromisos contractuales, consentimientos legales expresados en el Aviso de Privacidad y regulaciones federales (LFPDPPP). Si el DBA decide por cuenta propia entregar datos a mercadotecnia o compartirlos con terceros, compromete civil, administrativa y penalmente a toda la empresa.

### Pregunta 4: ¿Por qué los desarrolladores no deberían recibir automáticamente copias completas de bases de datos productivas?
Porque los entornos de desarrollo y pruebas carecen de las defensas perimétricas, auditorías y controles de acceso que protegen a producción. Las laptops de los ingenieros, servidores de QA y repositorios locales son altamente susceptibles a extravíos, malware, accesos compartidos y filtraciones accidentales. Exponer la base real de 50,000 clientes en una máquina de desarrollo multiplica la superficie de ataque y viola el deber de confidencialidad.

### Pregunta 5: ¿Por qué una copia utilizada para desarrollo también puede representar un riesgo de privacidad?
Porque un dato personal sigue siendo dato personal sin importar en qué servidor o archivo resida. Si una copia de desarrollo que contiene RFCs, correos o teléfonos reales es sustraída o expuesta en internet, el daño moral y patrimonial a los titulares es exactamente el mismo que si la brecha hubiera ocurrido en el servidor central de producción, acarreando las mismas sanciones regulatorias por parte del INAI.

### Pregunta 6: ¿Por qué la retención debe formar parte del ciclo de vida de los datos?
Porque los datos tienen un ciclo vital: nacen (recolección), se utilizan (operación), maduran (archivo legal) y deben morir (supresión segura). Si la retención no se gestiona como parte intrínseca de este ciclo, las bases de datos se convierten en vertederos de información obsoleta y tóxica (*data hoard*), donde cada registro caduco representa un pasivo legal latente, un costo innecesario de almacenamiento y un blanco potencial para los atacantes.

### Pregunta 7: ¿Qué relación existe entre privacidad por diseño y diseño de bases de datos?
La Privacidad por Diseño (*Privacy by Design*) exige que los principios de protección al titular se incorporen desde el primer boceto del modelo entidad-relación y el script DDL. Al diseñar una base de datos, esto se traduce en elegir los tipos de datos más acotados, no solicitar atributos superfluos (salarios o estado civil), configurar restricciones `CHECK`, implementar columnas cifradas (`BYTEA`) para datos sensibles y definir vistas de agregación de forma nativa antes de que el sistema entre a producción.

### Pregunta 8: ¿Qué controles técnicos implementarías para reducir el riesgo de exposición de datos personales?
1. **Control de Acceso basado en Roles (RBAC):** Otorgar permisos granulares de esquema y tabla vinculados a necesidades funcionales.
2. **Vistas Segregadas y Enmascaramiento Dinámico:** Ocultar PII directa mediante vistas parametrizadas para perfiles operativos y de soporte.
3. **Cifrado en Reposo a Nivel de Columna (`pgcrypto`):** Proteger identificadores fiscales y datos financieros con AES/PGP.
4. **Cifrado en Tránsito Estricto (TLS 1.3):** Impedir la interceptación de datos en la red mediante certificados validados (`verify-full`).
5. **Auditoría Estructurada (`pgaudit`):** Bitácoras inmutables de consultas `SELECT` sobre tablas que alberguen datos personales.

### Pregunta 9: ¿Qué información debería conocer un DBA para responder técnicamente a una solicitud ARCO?
El DBA debe conocer:
1. El identificador unívoco verificado del titular solicitante (RFC, correo o ID).
2. El catálogo completo de tablas, vistas, réplicas, respaldos y particiones donde reside la información del titular.
3. Las dependencias de integridad referencial (llaves foráneas en cascada) para evaluar el impacto de una actualización o bloqueo.
4. Las directrices del área jurídica sobre si procede la eliminación física inmediata o si debe aplicarse el periodo de bloqueo preventivo por disposiciones fiscales.

### Pregunta 10: ¿Qué responsabilidades deberían corresponder al DBA, al responsable de privacidad, al área jurídica y al propietario de los datos?
* **Responsable de Privacidad (DPO) / Área Jurídica:** Redactar el Aviso de Privacidad, interpretar la legislación (LFPDPPP/RGPD), fijar los periodos legales de retención, gestionar los plazos formales ante el titular y resolver las solicitudes ARCO.
* **Propietario de los Datos (*Data Owner*):** Definir los requerimientos de negocio, clasificar la criticidad funcional de la información y autorizar qué departamentos tienen necesidad legítima de uso (*Need-to-Know*).
* **Administrador de Bases de Datos (*Data Custodian* / DBA):** Traducir las políticas corporativas en configuraciones del motor PostgreSQL (DDL, vistas, RBAC, cifrado, backups y tareas programadas de purga), garantizando la disponibilidad, integridad y trazabilidad técnica de los activos de información.

---

## 12. CONCLUSIONES GENERALES

En este laboratorio se analizó cómo los principios de privacidad y cumplimiento se traducen en decisiones concretas de diseño y administración en PostgreSQL 16. Se comprobó que el control de acceso y la seguridad técnica deben complementarse con la minimización de campos, la delimitación de finalidades y políticas claras de retención.

Asimismo, se identificó la importancia de delimitar las funciones del DBA como custodio técnico frente a los propietarios de los datos y el área legal, garantizando que los usuarios reciban únicamente la información necesaria para sus labores y se cuente con mecanismos técnicos para atender derechos ARCO.

