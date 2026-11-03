# EVIDENCIA 05: ANÁLISIS DE UNA FINALIDAD SECUNDARIA

* **Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
* **Unidad:** II. Seguridad, privacidad y control de acceso  
* **Tema:** 2.5 Privacidad, cumplimiento y gobierno de los datos  
* **Motor:** PostgreSQL 16  
* **Estudiante:** Genaro Isaac Cárdenas Soto (@darksitoV)  
* **Organización / Escenario:** Comercializadora Norte S.A. de C.V.  

---

## 1. Objetivo
Analizar los riesgos jurídicos, éticos y técnicos inherentes a la incorporación de un nuevo tratamiento no contemplado originalmente sobre los datos de clientes: *"Enviar promociones personalizadas basadas en la edad, ciudad y comportamiento de compra"*, evaluando el principio de limitación de la finalidad, la necesidad de consentimiento expreso, la segregación de accesos funcionales y los controles técnicos aplicables en PostgreSQL.

---

## 2. Procedimiento Realizado
1. Se evaluó la solicitud planteada por la dirección comercial de *Comercializadora Norte S.A. de C.V.*
2. Se contrastó la propuesta contra los artículos 6, 8, 12, 13 y 14 de la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP) y los estándares del Reglamento General de Protección de Datos (RGPD / GDPR).
3. Se formularon respuestas fundamentadas a las 5 preguntas críticas de evaluación técnica y de cumplimiento.
4. Se diseñó una estrategia técnica de implementación basada en listas disociadas y consentimiento verificable mediante esquemas y vistas en PostgreSQL.

---

## 3. Resultado Obtenido: Respuestas y Análisis de la Solicitud

### 3.1 Pregunta 1: ¿El hecho de que la organización ya tenga los datos significa automáticamente que puede utilizarlos para cualquier finalidad?
**Respuesta:**  
**No.** El hecho de que una organización tenga almacenada la información no le otorga autorización automática para utilizarla en cualquier fin.  
El principio de **limitación de la finalidad** (Art. 12 de la LFPDPPP y Art. 5.1(b) del RGPD) establece que los datos personales únicamente pueden ser tratados para las finalidades que fueron informadas en el Aviso de Privacidad. El almacenamiento para operaciones de compra o soporte no permite utilizarlos posteriormente para mercadotecnia o elaboración de perfiles comerciales sin una base legítima independiente y el consentimiento del titular.

---

### 3.2 Pregunta 2: ¿Qué preguntas debería realizar la organización antes de implementar este tratamiento?
Antes de habilitar cualquier consulta, pipeline o vista hacia marketing, el comité de privacidad, el área jurídica y el DBA deben responder:
1. **¿Está contemplada en el Aviso de Privacidad vigente?** Si las finalidades secundarias mercadotécnicas no estaban descritas con claridad, se debe actualizar el aviso y notificar a los titulares antes de proceder.
2. **¿Existe consentimiento válido?** ¿Se recabó el consentimiento previo para finalidades secundarias? (Debe existir opción clara tipo *opt-in* o *opt-out* sin condicionar la venta del producto).
3. **¿Existe un mecanismo técnico para gestionar la negativa/oposición?** Si un cliente revoca su consentimiento para promociones, ¿cómo se entera la base de datos de manera inmediata?
4. **¿Cuál es la base de datos de destino?** ¿Se pretende enviar los correos mediante plataformas externas (ej. Mailchimp, SendGrid)? Si es así, ¿existe un contrato de transmisión de datos (Data Processing Agreement) con el proveedor?
5. **¿Qué impacto tiene el perfilamiento?** ¿La combinación de edad, ciudad y patrones de compra puede inferir datos sensibles del titular (ej. nivel socioeconómico, salud o preferencias personales)?

---

### 3.3 Pregunta 3: ¿Qué datos serían realmente necesarios?
Bajo el principio de **minimización de datos** (proporcionalidad y necesidad):
* **Datos estrictamente necesarios:**
  * Identificador seudonimizado o token del cliente (para no exponer el ID real de producción).
  * Segmento demográfico general (ej. rango de edad `30-44` en lugar de edad exacta; ciudad o región postal).
  * Indicador de interés o categoría de compra agregada (ej. `categoría: electrónica`).
  * Canal de comunicación autorizado (correo electrónico exclusivamente de aquellos clientes con `opt_in_marketing = TRUE`).
* **Datos totalmente innecesarios (que deben ser bloqueados):**
  * **RFC:** No tiene relación alguna con la publicidad y constituye un dato fiscal sensible.
  * **Nombre completo:** No es necesario para segmentar campañas; las herramientas de envío pueden usar saludos parametrizados o nombres de pila sin apellidos.
  * **Teléfono:** No debe entregarse a menos que exista consentimiento específico para telemercadeo o SMS.
  * **Fecha de alta o historial transaccional completo en texto claro.**

---

### 3.4 Pregunta 4: ¿Necesitaría el área de marketing acceso directo a la tabla `clientes`?
**Respuesta:**  
**No.**  
El personal de mercadotecnia jamás debe poseer privilegios de lectura directa (`SELECT`) sobre la tabla de producción `clientes`.  
Conceder acceso directo generaría graves riesgos:
* Exposición innecesaria de PII de clientes que rechazaron la publicidad.
* Riesgo de consultas sin filtro (*full table scans*) que degraden el rendimiento operativo de la base de datos en producción.
* Pérdida de trazabilidad sobre qué contactos autorizaron recibir promociones.

El área de marketing debe interactuar exclusivamente mediante una **vista disociada**, una tabla de suscriptores o una cola de mensajes que contenga únicamente los destinatarios que cuenten con consentimiento afirmativo vigente.

---

### 3.5 Pregunta 5: ¿Qué controles técnicos podrían limitar la información entregada?
Para blindar el tratamiento de la finalidad secundaria, se proponen los siguientes 5 controles en PostgreSQL:

1. **Columna de Consentimiento Explícito en la BD:**
   ```sql
   ALTER TABLE clientes ADD COLUMN consentimiento_marketing BOOLEAN DEFAULT FALSE;
   ```
2. **Vista Segregada por Finalidad (Marketing View):**
   ```sql
   CREATE OR REPLACE VIEW v_destinatarios_marketing AS
   SELECT 
       correo,
       ciudad,
       CASE 
           WHEN edad BETWEEN 18 AND 29 THEN '18-29'
           WHEN edad BETWEEN 30 AND 44 THEN '30-44'
           ELSE '45+'
       END AS segmento_edad
   FROM clientes
   WHERE consentimiento_marketing = TRUE;
   ```
3. **Control de Acceso basado en Roles (RBAC):**
   ```sql
   CREATE ROLE rol_marketing NOLOGIN;
   GRANT SELECT ON v_destinatarios_marketing TO rol_marketing;
   REVOKE ALL ON clientes FROM rol_marketing;
   ```
4. **Mecanismo de Desuscripción Automático (Unsubscribe Hook):**
   Un procedimiento almacenado o API que actualice `consentimiento_marketing = FALSE` en cuanto el titular presione el enlace de baja en el correo, surtiendo efecto inmediato.
5. **Enmascaramiento Dinámico para Perfilamiento Interno:**
   Ocultar los correos electrónicos si el análisis de mercadotecnia solo busca medir tamaños de audiencia (`COUNT(*)`) y no despachar el mensaje directamente.

---

## 4. Conclusión
El análisis de finalidades secundarias muestra que el uso de los datos debe estar respaldado por el consentimiento del titular y el aviso de privacidad. Para el DBA, esto implica que no se debe dar acceso directo a tablas operativas a áreas como mercadotecnia, sino implementar filtros técnicos como vistas y banderas de consentimiento para asegurar que solo se procesen los datos autorizados.

