# EVIDENCIA 10: POLÍTICA DE RETENCIÓN DE DATOS

* **Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
* **Unidad:** II. Seguridad, privacidad y control de acceso  
* **Tema:** 2.5 Privacidad, cumplimiento y gobierno de los datos  
* **Motor:** PostgreSQL 16  
* **Estudiante:** Genaro Isaac Cárdenas Soto (@darksitoV)  
* **Organización / Escenario:** Comercializadora Norte S.A. de C.V.  

---

## 1. Objetivo
Evaluar críticamente la propuesta operativa de *“Conservar todos los datos de clientes indefinidamente porque podrían ser útiles en el futuro”*, demostrando por qué la retención perpetua constituye un antipatrón arquitectónico y una violación directa a los principios de minimización temporal y proporcionalidad, y formular un marco metodológico para definir periodos de retención legal y operativamente sustentables.

---

## 2. Procedimiento Realizado
1. Se sometió a análisis la postura de acumulación indefinida frente a los ordenamientos legales aplicables (LFPDPPP, Código Fiscal de la Federación, Código de Comercio y RGPD).
2. Se analizaron las implicaciones financieras, técnicas y de ciberseguridad asociadas al almacenamiento desmedido en motores PostgreSQL.
3. Se respondieron de manera estructurada las 4 preguntas planteadas en la práctica.
4. Se diseñó un calendario tipo de retención y una estrategia técnica para implementar la purga automatizada en bases de datos.

---

## 3. Resultado Obtenido: Análisis de las Preguntas Clave

### 3.1 Pregunta 1: ¿Es compatible con el principio de minimización?
**Respuesta:**  
**No es compatible.**  
El principio de **minimización de datos** abarca tanto la cantidad de datos que se recaban como el **tiempo de conservación** (limitación del plazo de almacenamiento, Art. 11 LFPDPPP y Art. 5.1(e) del RGPD). Conservar datos de manera indefinida por si pudieran ser útiles en el futuro viola los criterios de necesidad y proporcionalidad. Los datos deben cancelarse o eliminarse cuando dejen de ser necesarios para las finalidades informadas y hayan prescrito los plazos legales aplicables.

---

### 3.2 Pregunta 2: ¿Qué riesgos genera conservar información innecesaria?
Conservar datos indefinidamente genera riesgos operativos y legales:
1. **Mayor superficie de exposición:** Ante un incidente de seguridad (filtración de respaldos o accesos no autorizados), se compromete información de un volumen mucho mayor de personas, incluyendo clientes de años anteriores.
2. **Incumplimiento normativo:** La legislación mexicana (LFPDPPP) sanciona la retención injustificada de datos personales cuando ya no existe finalidad que la sustente.
3. **Costos y degradación de rendimiento:** Almacenar tablas innecesariamente grandes incrementa el tiempo de respaldos (`pg_dump`), el consumo de almacenamiento y ralentiza índices.
4. **Datos obsoletos:** La información pierde exactitud con el tiempo (cambios de teléfono, domicilio o correo), lo cual afecta la calidad del servicio.

---

### 3.3 Pregunta 3: ¿Qué debería determinar la organización antes de establecer un periodo de retención?
Para definir plazos racionales, la organización debe conformar un comité multidisciplinario (Jurídico, Cumplimiento, Finanzas y DBA) para determinar:
1. **Obligaciones Legales y Plazos de Prescripción Tributaria:**
   * Código Fiscal de la Federación (Art. 30 CFF): Plazo de **5 años** para conservación de registros contables y fiscales.
   * Código de Comercio (Art. 46 CCom): Plazo de **10 años** para contratos mercantiles y correspondencia comercial.
   * Ley Federal del Trabajo o IMSS (si aplicara a expedientes laborales): Plazos de 5 a 10 años.
2. **Ciclo de Vida del Negocio:** Tiempo promedio en que un cliente repite una compra o permanece activo en la plataforma.
3. **Plazos de Garantía y Responsabilidad de Producto:** Periodos en los que un cliente puede formular reclamaciones de servicio o devoluciones.
4. **Eventos de Disparo de la Retención (*Trigger Events*):** Momento exacto en que inicia la cuenta regresiva (ej. fecha de terminación del contrato, fecha de última compra, fecha de cancelación voluntaria de la cuenta).

---

### 3.4 Pregunta 4: ¿Qué información debería documentarse para justificar el periodo seleccionado?
En la **Política Institucional de Retención y Disposición de Información**, debe documentarse:
* **Catálogo de Tipologías de Datos:** Listado de entidades (`clientes`, `facturas`, `logs_soporte`).
* **Base Legal de Conservación:** Cita explícita del artículo de ley que fundamenta el plazo (ej. "Retención de 5 años fundamentada en el Art. 30 CFF").
* **Regla de Disposición Final:** Qué se hará con el dato al expirar el plazo (Destrucción física / Borrado criptográfico / Anonimización irreversible para fines analíticos).
* **Mecanismo Técnico de Ejecución:** Descripción del procedimiento automatizado (particionado mensual, vistas de exclusión o jobs con `pg_cron`).
* **Firma de Aprobación:** Aprobación formal por parte del Responsable de Privacidad (*Data Privacy Officer*), la Dirección Jurídica y la Dirección General.

---

## 4. Propuesta Técnica de Implementación en PostgreSQL

Para garantizar el cumplimiento sin intervención manual susceptible a errores humanos, el DBA debe estructurar:

1. **Particionamiento por Rango de Fechas (Table Partitioning):**
   ```sql
   CREATE TABLE registro_ventas (
       id BIGSERIAL,
       cliente_id BIGINT,
       monto NUMERIC(10,2),
       fecha_venta DATE NOT NULL
   ) PARTITION BY RANGE (fecha_venta);
   ```
   Permite eliminar particiones completas que hayan superado el plazo legal mediante un rápido `DROP TABLE registro_ventas_2018;`, evitando costosos bloqueos de tabla por `DELETE`.
2. **Tareas Programadas de Depuración y Anonimización (`pg_cron`):**
   Un job que marque para bloqueo las cuentas inactivas por más de 3 años y desvincule identificadores personales (sustituyendo nombres y correos por hashes irreversibles) dejando únicamente registros numéricos agregados para analítica.

---

## 5. Conclusión
Definir periodos de retención es fundamental tanto para el cumplimiento de la ley como para el rendimiento de la base de datos. Guardar datos indefinidamente incrementa los riesgos ante brechas de seguridad y satura el almacenamiento. Contar con plazos documentados y mecanismos de depuración periódica permite al DBA mantener la base de datos optimizada y alineada a las obligaciones legales.

