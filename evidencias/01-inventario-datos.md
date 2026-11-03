# EVIDENCIA 01: INVENTARIO Y FINALIDAD DE LOS DATOS

* **Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
* **Unidad:** II. Seguridad, privacidad y control de acceso  
* **Tema:** 2.5 Privacidad, cumplimiento y gobierno de los datos  
* **Motor:** PostgreSQL 16  
* **Estudiante:** Genaro Isaac Cárdenas Soto (@darksitoV)  
* **Organización / Escenario:** Comercializadora Norte S.A. de C.V.  

---

## 1. Objetivo
Identificar, catalogar y clasificar exhaustivamente cada uno de los atributos almacenados en la tabla principal de `clientes` de *Comercializadora Norte S.A. de C.V.*, vinculando cada dato personal con una base jurídica legítima, su finalidad operativa primaria, la justificación de necesidad funcional, el nivel de acceso granular correspondiente y su periodo estipulado de retención conforme a la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP) y estándares internacionales como el RGPD.

---

## 2. Procedimiento Realizado
1. Se inspeccionó la estructura DDL de la entidad `clientes` en la base de datos `lab01_db` sobre PostgreSQL 16.
2. Se analizaron los procesos funcionales de la organización:
   * **Atención al Cliente:** Contacto directo y resolución de incidencias.
   * **Facturación:** Cumplimiento de obligaciones fiscales y timbrado de CFDI.
   * **Analítica:** Estudios estadísticos agregados sin identificación individual.
   * **DBA:** Mantenimiento técnico, seguridad, disponibilidad e integridad de la infraestructura.
3. Se construyó una matriz integral de gobierno e inventario de datos personales asociando cada campo con su ciclo de vida y justificación legal.

---

## 3. Resultado Obtenido: Matriz de Inventario y Finalidad

| Campo | ¿Es dato personal? | Finalidad Primaria | ¿Es necesario? | Nivel de Acceso Autorizado | Periodo de Retención |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **id** | No (en sí mismo); Sí (vinculado a un titular). | Llave primaria técnica para integridad referencial e indexación. | Sí, estrictamente indispensable para el RDBMS. | Interno / Técnico (DBA, Soporte, Facturación). | Mientras exista el registro del cliente; depuración en cascada. |
| **nombre** | **Sí** (Dato personal directo / identificador). | Identificación del cliente para formalización contractual y trato personalizado. | Sí, requerido para individualizar la relación comercial y facturar. | Soporte / Atención a Clientes, Facturación, DBA (bajo cifrado/rol). | Vigencia de la relación contractual + 5 años de prescripción mercantil. |
| **correo** | **Sí** (Dato personal de contacto y localización digital). | Envío de notificaciones transaccionales, confirmaciones de compra y soporte. | Sí, canal indispensable de comunicación digital contractual. | Soporte / Atención a Clientes, Notificaciones automáticas. | Vigencia de la cuenta activa; revocable ante solicitud de cancelación. |
| **telefono** | **Sí** (Dato personal directo de contacto). | Soporte técnico urgente, validación de entrega y autenticación en 2 factores. | Sí, para validaciones de seguridad y seguimiento logístico. | Soporte / Atención a Clientes, Logística. | Vigencia del contrato de servicio o hasta oposición expresa. |
| **rfc** | **Sí** (Dato personal identificador fiscal regulado). | Facturación electrónica (CFDI) y cumplimiento de obligaciones tributarias (SAT). | Sí, obligatorio por ley tributaria mexicana (CFF Art. 29-A). | Facturación / Contabilidad exclusivamente. | **5 años** obligatorios por disposición del Código Fiscal de la Federación. |
| **edad** | **Sí** (Dato personal indirecto / sociodemográfico). | Verificación de mayoría de edad para capacidad de ejercicio contractual. | Sí, para verificar capacidad legal; innecesario como entero estático. | Registro de usuario / Validación legal inicial. | Duración de la relación contractual o sustituible por fecha de nacimiento. |
| **ciudad** | **Sí** (Dato personal geográfico indirecto). | Logística de envíos, asignación de centros de distribución y cálculo de impuestos. | Sí, requerido para la entrega física de pedidos. | Logística, Facturación, Analítica (únicamente de forma agregada). | Vigencia de la relación contractual; analítica agregada indefinida. |
| **codigo_postal**| **Sí** (Dato personal de localización geográfica). | Validación tributaria domiciliaria (CFDI 4.0) y enrutamiento logístico. | Sí, requerido por disposiciones fiscales y paquetería. | Facturación, Logística, Analítica (agrupado por región). | 5 años vinculado a facturas fiscales; disociado para analítica. |
| **fecha_alta** | No (Metadato operativo); Sí (vinculado al cliente). | Auditoría interna, trazabilidad temporal y cálculo de antigüedad. | Sí, indispensable para control de versiones y auditoría. | DBA, Auditoría, Atención a Clientes, Facturación. | Permanente mientras subsista el registro contable o de auditoría. |

---

## 4. Análisis y Justificación Detallada por Decisión

1. **Principio de Licitud y Finalidad Determinada:**
   Cada dato recolectado debe responder a una finalidad explícita informada en el Aviso de Privacidad. Por ejemplo, el `rfc` únicamente está justificado para la emisión de comprobantes fiscales digitales ante el Servicio de Administración Tributaria (SAT). Usarlo para prospección comercial o entregarlo al personal de soporte técnico constituiría un desvío de finalidad penado por el Art. 63 de la LFPDPPP.
2. **Principio de Proporcionalidad y Necesidad:**
   Campos como `edad` en formato entero estático representan un mal diseño de base de datos y una recopilación innecesaria: la edad cambia anualmente requiriendo actualizaciones constantes o queda desactualizada. Si el negocio requiere validar mayoría de edad legal para contratación, basta con un indicador booleano (`es_mayor_edad BOOLEAN`) verificado al momento del registro.
3. **Nivel de Acceso Segregado (Principio de Mínimo Privilegio):**
   No existe ningún proceso operativo donde un único rol requiera el 100% de los datos en claro. Facturación requiere `rfc`, `nombre` y `codigo_postal`, pero no requiere consultar el historial de conversaciones o llamadas de soporte. A su vez, el área de soporte no requiere consultar el `rfc` para solucionar un problema técnico en la plataforma.
4. **Temporalidad y Retención:**
   El principio de calidad de la información exige que los datos se supriman una vez que hayan dejado de ser necesarios para las finalidades que motivaron su tratamiento. No obstante, la retención debe conciliarse con los plazos legales de conservación de la documentación contable y fiscal (5 años conforme al Art. 30 del Código Fiscal de la Federación en México).

---

## 5. Conclusión
Elaborar un inventario de datos permite identificar con precisión qué información personal se almacena y qué justificación tiene cada campo. Para el DBA, este análisis facilita definir qué tablas o vistas deben crearse, qué campos pueden descartarse y qué permisos deben asignarse a cada rol, asegurando que la base de datos cumpla con los principios de finalidad y minimización.

