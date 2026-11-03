# EVIDENCIA 12: PRIVACIDAD POR DISEÑO Y POR DEFECTO

* **Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
* **Unidad:** II. Seguridad, privacidad y control de acceso  
* **Tema:** 2.5 Privacidad, cumplimiento y gobierno de los datos  
* **Motor:** PostgreSQL 16  
* **Estudiante:** Genaro Isaac Cárdenas Soto (@darksitoV)  
* **Organización / Escenario:** Comercializadora Norte S.A. de C.V.  

---

## 1. Objetivo
Evaluar críticamente una propuesta de diseño de base de datos para una nueva aplicación de registro de clientes bajo la perspectiva de los principios fundamentales de **Privacidad por Diseño (*Privacy by Design*)** y **Privacidad por Defecto (*Privacy by Default*)**, identificando anomalías de recolección excesiva, datos sensibles no justificados y formulando una propuesta de esquema normalizado y minimizado para PostgreSQL 16.

---

## 2. Procedimiento Realizado
1. Se analizó la propuesta preliminar planteada por el equipo de desarrollo:
   ```sql
   CREATE TABLE clientes (
       id BIGSERIAL,
       nombre TEXT,
       correo TEXT,
       telefono TEXT,
       rfc TEXT,
       edad INTEGER,
       direccion TEXT,
       ciudad TEXT,
       codigo_postal TEXT,
       fecha_nacimiento DATE,
       ocupacion TEXT,
       salario NUMERIC,
       estado_civil TEXT,
       ...
   );
   ```
   Acompañada de la justificación: *“Es mejor guardar todos los datos por si posteriormente necesitamos alguno.”*
2. Se analizó la propuesta conforme a los principios de privacidad por diseño, minimización y proporcionalidad de la LFPDPPP y el RGPD.
3. Se respondieron las 6 preguntas de la actividad.
4. Se diseñó el esquema DDL refactorizado y normalizado.

---

## 3. Resultado Obtenido: Respuestas y Evaluación Técnica

### 3.1 Pregunta 1: ¿Qué problemas identificas en el diseño propuesto?
1. **Recolección excesiva de datos:** Se solicitan datos socioeconómicos y personales (`salario`, `estado_civil`, `ocupacion`) sin una necesidad funcional clara para el proceso de compra y venta.
2. **Redundancia:** Se solicita simultáneamente `edad` (entero) y `fecha_nacimiento` (fecha). La edad puede calcularse a partir de la fecha de nacimiento cuando sea necesario.
3. **Tipos de datos poco estrictos:** El uso exclusivo de `TEXT` sin restricciones de formato o longitud no aprovecha los mecanismos de validación de PostgreSQL.
4. **Mayor riesgo de exposición:** Almacenar datos personales innecesarios incrementa la severidad de un posible incidente de seguridad.

---

### 3.2 Pregunta 2: ¿Qué principio de privacidad se está ignorando abiertamente?
Se ignoran simultáneamente:
* **Principio de Minimización de Datos:** Los datos recabados deben ser los mínimos estrictamente necesarios para cumplir el objetivo del servicio.
* **Principio de Proporcionalidad y Necesidad:** El responsable sólo debe solicitar los datos pertinentes y guardar equilibrio entre el servicio ofrecido y la invasión a la esfera privada del titular.
* **Principio de Privacidad por Defecto:** Los sistemas deben nacer configurados de fábrica para proteger al usuario, sin que este tenga que solicitar no ser espiado o sobre-perfilado.

---

### 3.3 Pregunta 3: ¿Qué preguntas realizarías antes de aprobar el diseño?
Como DBA senior y custodio de la base de datos, antes de ejecutar el DDL exigiría:
1. *¿Cuál es el modelo de negocio o flujo funcional específico que requiere conocer el salario y el estado civil del comprador?*
2. *¿El Aviso de Privacidad actual contiene expresamente el tratamiento de datos patrimoniales o financieros (salario)? Si es así, ¿se recaba la firma o consentimiento expreso por escrito según exige el Art. 8 de la LFPDPPP?*
3. *¿Por qué se solicita la dirección física completa en el registro inicial si el cliente únicamente está creando una cuenta para ver un catálogo digital y aún no ha realizado una compra?*
4. *¿Existe una Evaluación de Impacto a la Privacidad (PIA / DPIA) que respalde la captura de estos campos?*

---

### 3.4 Pregunta 4: ¿Qué datos eliminarías inmediatamente?
Se deben eliminar de la tabla de clientes:
* **`salario`:** No es necesario para compras de comercio electrónico o atención al cliente.
* **`estado_civil`:** No guarda relación con la finalidad comercial.
* **`ocupacion`:** No se requiere para operar pedidos ni facturación.
* **`edad`:** Debe eliminarse porque es un valor redundante con la fecha de nacimiento.

---

### 3.5 Pregunta 5: ¿Qué datos requerirían una justificación adicional?
* **`rfc`:** No debe solicitarse en el registro obligatorio; solo debe capturarse si el cliente solicita comprobante fiscal (CFDI).
* **`direccion`:** No debe pedirse al abrir la cuenta, sino únicamente al procesar un pedido con entrega a domicilio.
* **`telefono`:** Debe solicitarse solo si se utiliza para contacto operativo de entregas o soporte.

---

### 3.6 Pregunta 6: ¿Cómo aplicarías Privacidad por Defecto (*Privacy by Default*)?
La privacidad por defecto se traduce en las siguientes medidas concretas:
1. **Campos Opcionales Desmarcados:** Casillas de suscripción a boletines publicitarios sin marcar por omisión.
2. **Captura Progresiva (*Progressive Profiling*):** Solo pedir correo y contraseña robusta para crear la cuenta. Los demás datos se solicitan conforme el usuario los requiera.
3. **Cifrado en Reposo Automático:** Configurar que los campos fiscales que se agreguen en el futuro se almacenen en columnas cifradas (`BYTEA` vía `pgcrypto`).
4. **Vistas Segregadas de Fábrica:** El rol de la aplicación web nunca debe acceder a la tabla sin filtros; debe acceder a través de una API o vista que aplique enmascaramiento dinámico.

---

## 4. Propuesta de Esquema Refactorizado Bajo Privacy by Design

```sql
-- Esquema minimizado y proporcional para PostgreSQL 16
DROP TABLE IF EXISTS clientes_v2 CASCADE;

CREATE TABLE clientes_v2 (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    fecha_nacimiento DATE NOT NULL,
    ciudad VARCHAR(80),
    codigo_postal VARCHAR(10),
    consentimiento_marketing BOOLEAN DEFAULT FALSE,
    fecha_alta TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_mayoria_edad CHECK (fecha_nacimiento <= CURRENT_DATE - INTERVAL '18 years')
);

COMMENT ON TABLE clientes_v2 IS 'Tabla de clientes optimizada bajo el principio de minimización y privacidad por diseño';
```

---

## 5. Conclusión
El análisis del diseño propuesto demuestra que almacenar datos innecesarios "por si acaso" perjudica el diseño de la base de datos y aumenta la exposición de los titulares. Aplicar privacidad por diseño permite definir esquemas más limpios y eficientes, donde únicamente se almacena lo necesario para la operación y se facilita el cumplimiento de los principios de minimización y proporcionalidad.

