# EVIDENCIA 15: PROPUESTA DE ARQUITECTURA DE DATOS PROTEGIDOS

* **Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
* **Unidad:** II. Seguridad, privacidad y control de acceso  
* **Tema:** 2.5 Privacidad, cumplimiento y gobierno de los datos  
* **Motor:** PostgreSQL 16  
* **Estudiante:** Genaro Isaac Cárdenas Soto (@darksitoV)  
* **Organización / Escenario:** Comercializadora Norte S.A. de C.V.  

---

## 1. Objetivo
Diseñar una propuesta arquitectónica conceptual y técnica integral para la segregación, protección y gobierno de la información en *Comercializadora Norte S.A. de C.V.*, desacoplando los flujos operativos, analíticos y de auditoría, e incorporando controles técnicos nativos en PostgreSQL 16 para control de acceso, minimización, cifrado de información sensible, retención temporal, trazabilidad inmutable y atención de derechos ARCO.

---

## 2. Procedimiento Realizado
1. Se analizaron las deficiencias del modelo monolítico actual donde las cargas de analítica, desarrollo, mercadotecnia y operación confluyen sobre una única tabla de clientes.
2. Se estructuró un modelo arquitectónico de tres planos: **Plano Operacional (OLTP)**, **Plano Analítico (OLAP / Data Mart)** y **Plano de Auditoría y Trazabilidad**.
3. Se integraron los 7 controles transversales exigidos por la práctica (acceso, minimización, protección criptográfica, retención, trazabilidad, eliminación/bloqueo y derechos de los titulares).
4. Se generó el diagrama arquitectónico conceptual y se especificaron las implementaciones técnicas en PostgreSQL 16.

---

## 3. Resultado Obtenido: Arquitectura de Datos Protegidos

### 3.1 Diagrama Arquitectónico Conceptual

```text
                        BASE DE DATOS (PostgreSQL 16)
                                      │
                ┌─────────────────────┼─────────────────────┐
                │                     │                     │
                ▼                     ▼                     ▼
            Operación             Analítica             Auditoría
           (OLTP / RW)          (Standby / RO)       (Logs y Trazas)
                │                     │                     │
                ▼                     ▼                     ▼
         Datos necesarios      Datos agregados         Registros de
          para operación      (vistas/métricas)        transacciones
```

---

## 4. Controles Transversales por Capa

Conforme a los requerimientos de la actividad, se especifican los controles técnicos correspondientes:

### 1. Acceso
* **Capa Operativa:** Control de acceso basado en roles (RBAC). El rol `rol_soporte` solo accede a datos de atención al cliente y `rol_facturacion` accede a datos fiscales.
* **Capa Analítica:** El rol `analista` tiene permisos exclusivamente sobre vistas agregadas (`v_analitica_clientes`) y no sobre tablas base.
* **Capa de Auditoría:** Solo el usuario administrador o de seguridad puede consultar registros de auditoría.

### 2. Minimización
* Las tablas operativas se separan para evitar que un proceso acceda a datos innecesarios (por ejemplo, `clientes_soporte` solo contiene nombre, correo y teléfono).
* En analítica se entregan conteos agrupados por ciudad y rangos de edad, eliminando identificadores personales.

### 3. Protección de Información Sensible
* Cifrado a nivel de columna con la extensión `pgcrypto` para identificadores fiscales como el RFC en reposo.
* Conexiones de red cifradas mediante TLS (modo `verify-full`).

### 4. Retención
* Particionamiento de tablas transaccionales y de facturación por rango de fecha para facilitar la depuración histórica.
* Definición de plazos de retención basados en obligaciones legales (5 años para datos fiscales por Código Fiscal de la Federación).

### 5. Trazabilidad
* Registro de operaciones de modificación (`INSERT`, `UPDATE`, `DELETE`) en bitácoras de auditoría.
* Registro de accesos a datos personales sensibles mediante la extensión `pgaudit`.

### 6. Eliminación
* Procedimiento de eliminación controlada al vencer los periodos de retención.
* Aplicación de borrado en cascada en tablas puente o disociadas cuando proceda la supresión de un titular.

### 7. Atención de Solicitudes (Derechos ARCO)
* **Acceso:** Consultas filtradas por identificador único del titular.
* **Rectificación:** Procedimiento controlado para actualizar datos inexactos con registro del cambio en auditoría.
* **Cancelación y Oposición:** Implementación de un estado de bloqueo (*Soft Delete*) que excluye al cliente de procesos comerciales y de soporte, preservando el dato aislado únicamente durante el plazo que la ley exija antes de su eliminación definitiva.

---

## 5. Conclusión
La separación conceptual de la base de datos en capas de operación, analítica y auditoría permite aplicar los controles necesarios para cada finalidad sin afectar el desempeño. Mediante el uso de réplicas de lectura, vistas agregadas, cifrado y políticas de retención, es posible proteger la información personal y mantener una operación eficiente en PostgreSQL.

