# EVIDENCIA 14: EVALUACIÓN INTEGRAL DE RIESGOS DE PRIVACIDAD

* **Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
* **Unidad:** II. Seguridad, privacidad y control de acceso  
* **Tema:** 2.5 Privacidad, cumplimiento y gobierno de los datos  
* **Motor:** PostgreSQL 16  
* **Estudiante:** Genaro Isaac Cárdenas Soto (@darksitoV)  
* **Organización / Escenario:** Comercializadora Norte S.A. de C.V.  

---

## 1. Objetivo
Realizar una auditoría técnica y de gobierno de datos exhaustiva sobre el escenario global de *Comercializadora Norte S.A. de C.V.* (base de datos con 50,000 clientes activos e históricos), identificando como mínimo diez problemas críticos de privacidad, relacionándolos con los principios normativos vulnerados (LFPDPPP / RGPD), evaluando el riesgo operativo e institucional resultante y proponiendo controles técnicos y administrativos de remediación inmediata en PostgreSQL.

---

## 2. Descripción del Escenario Auditado
La auditoría de seguridad reveló las siguientes prácticas operativas vigentes en la empresa:
1. La base de datos alberga **50,000 registros de clientes** con: `nombre`, `correo`, `telefono`, `rfc`, `edad`, `ciudad` y `codigo_postal`.
2. Todos los empleados del departamento de analítica poseen permisos directos de lectura (`SELECT`) sobre la tabla de producción `clientes`.
3. El área de analítica únicamente utiliza los datos para compilar estadísticas globales mensuales.
4. Los datos de clientes se conservan en la base activa desde hace **12 años**.
5. No existe ninguna política documentada ni automatizada de retención y purga.
6. Los desarrolladores reciben semanalmente volcados completos (`pg_dump`) de la base de datos de producción con datos reales para hacer pruebas en sus laptops y servidores de pruebas.
7. El área de mercadotecnia extrae los correos electrónicos directamente para enviar campañas comerciales y promocionales masivas.
8. No existe documentación ni catálogo que vincule qué finalidad corresponde a cada campo almacenado.

---

## 3. Resultado Obtenido: Matriz de Evaluación Integral de Riesgos

A continuación se detallan **10 problemas críticos** detectados, su principio vulnerado, su impacto y el control de remediación propuesto:

| # | Problema Detectado | Principio Afectado | Riesgo Operativo y Legal | Control Propuesto (Técnico / Administrativo) |
| :- | :--- | :--- | :--- | :--- |
| **1** | Analistas consultan directamente la tabla `clientes` en producción con PII completa. | **Minimización de Datos y Mínimo Privilegio.** | Filtración accidental o intencionada de nombres, RFCs y teléfonos; impacto en el rendimiento de producción por consultas analíticas no optimizadas. | **Técnico:** Crear la vista disociada `v_analitica_clientes` (sin nombres ni RFCs), otorgar `GRANT SELECT` únicamente a la vista y revocar el acceso a la tabla base mediante el rol `analista`. |
| **2** | Desarrolladores reciben copias completas de la BD productiva con datos reales para pruebas. | **Confidencialidad, Integridad y Proporcionalidad.** | Fuga masiva de la base de datos ante robo o extravío de laptops de desarrollo; malware en entornos locales; infracción grave a la LFPDPPP. | **Técnico/Administrativo:** Prohibir volcados de producción en desarrollo. Implementar un pipeline automatizado de **enmascaramiento irreversible / datos sintéticos** (`pg_dump` con ofuscación). |
| **3** | Retención indiscriminada de registros durante 12 años sin política documentada. | **Temporalidad / Limitación del Almacenamiento.** | Acumulación de pasivos legales; sanciones del INAI por conservación indebida; multas por custodia de datos obsoletos; sobrecostos de almacenamiento. | **Administrativo/Técnico:** Elaborar la *Política de Retención* (máximo 5 años para datos fiscales por CFF Art. 30). Implementar particionamiento y borrado de registros caducos mediante tareas programadas. |
| **4** | Mercadotecnia utiliza correos electrónicos para promociones sin consentimiento informado. | **Limitación de la Finalidad y Consentimiento.** | Spam ilícito; denuncias ante PROFECO e INAI por tratamiento para finalidades secundarias no autorizadas; daño reputacional a la marca. | **Técnico/Administrativo:** Agregar columna `consentimiento_marketing BOOLEAN DEFAULT FALSE`. Exigir consentimiento expreso (*opt-in*) en el Aviso de Privacidad y crear vista filtrada de marketing. |
| **5** | Ausencia total de documentación sobre la finalidad de cada campo almacenado. | **Responsabilidad Proactiva (*Accountability*) y Licitud.** | Imposibilidad de justificar la tenencia de los datos ante auditorías del órgano garante; tratamiento arbitrario por parte de los desarrolladores. | **Administrativo:** Publicar el **Catálogo y Matriz de Gobierno de Datos**, definiendo Propietarios de Datos (*Data Owners*) y finalidades para cada columna. |
| **6** | No existe segregación de ambientes ni aislamiento entre producción y analítica. | **Segregación de Entornos y Disponibilidad.** | Consultas analíticas pesadas (`GROUP BY`, escaneos secuenciales masivos) bloquean transacciones del sistema de ventas en línea; colapso del servicio. | **Técnico:** Separar físicamente la carga de trabajo analítica mediante **Streaming Replication** en un nodo de solo lectura (*read-only replica*) o volcado a Data Warehouse. |
| **7** | Almacenamiento de identificadores fiscales (RFC) en texto claro sin protección criptográfica. | **Seguridad y Confidencialidad.** | Exposición de identificadores fiscales ante lecturas no autorizadas o inyecciones SQL; usurpación de identidad tributaria ante el SAT. | **Técnico:** Migrar la columna `rfc` a formato binario cifrado (`BYTEA`) utilizando `pgcrypto` con algoritmos robustos (AES/PGP) restringiendo la clave al rol de facturación. |
| **8** | Inexistencia de bitácoras de auditoría de consultas sobre datos personales. | **Trazabilidad y Responsabilidad Proactiva.** | Incapacidad de detectar exfiltraciones internas de empleados o saber qué usuario consultó qué cliente en caso de un incidente de seguridad. | **Técnico:** Implementar la extensión oficial de auditoría **`pgaudit`** para registrar consultas `SELECT` que involucren tablas con información personal sensible. |
| **9** | Carencia de un procedimiento técnico y formal para la atención de Derechos ARCO. | **Atención de Derechos de los Titulares.** | Vencimiento del plazo legal de 20 días para responder solicitudes ARCO (LFPDPPP Art. 32); quejas directas ante el INAI y multas económicas. | **Administrativo/Técnico:** Diseñar un protocolo documentado de respuesta ARCO y procedimientos almacenados parametrizados para Acceso, Rectificación y Bloqueo. |
| **10** | Ambigüedad en la toma de decisiones: El DBA asume funciones de negocio sin directrices. | **Gobierno Corporativo de Datos.** | Decisiones discrecionales sobre compartir o borrar datos sin respaldo jurídico; vulnerabilidad legal para la empresa y para el administrador. | **Administrativo:** Establecer formalmente el Comité de Privacidad y Gobierno de Datos donde Dirección General, Jurídico y TI dicten las políticas que el DBA ejecutará técnicamente. |

---

## 4. Análisis de Impacto Global
El escenario evaluado describe una organización con un **nivel de madurez de privacidad nulo o inicial**. Aunque el motor PostgreSQL opere con alta disponibilidad y estabilidad técnica, la empresa enfrenta un riesgo crítico de multas regulatorias que pueden ascender a decenas de millones de pesos conforme a la LFPDPPP, sumado a la pérdida de confianza de los clientes en caso de una filtración pública derivada de las copias en desarrollo o el abuso de mercadotecnia.

---

## 5. Conclusión
La evaluación del escenario evidencia que los riesgos de privacidad no se limitan a posibles ataques externos, sino a prácticas internas inadecuadas como el uso de datos productivos en pruebas, la falta de políticas de retención y la ausencia de controles en consultas analíticas. La implementación de controles técnicos (vistas, particiones y roles) y administrativos (políticas documentadas) permite mitigar estos riesgos de forma estructurada.

