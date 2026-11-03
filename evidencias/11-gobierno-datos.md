# EVIDENCIA 11: MATRIZ DE GOBIERNO DE DATOS

* **Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
* **Unidad:** II. Seguridad, privacidad y control de acceso  
* **Tema:** 2.5 Privacidad, cumplimiento y gobierno de los datos  
* **Motor:** PostgreSQL 16  
* **Estudiante:** Genaro Isaac Cárdenas Soto (@darksitoV)  
* **Organización / Escenario:** Comercializadora Norte S.A. de C.V.  

---

## 1. Objetivo
Diseñar una matriz integral de gobierno y administración de datos para los campos representativos de la tabla `clientes`, estableciendo formalmente las responsabilidades organizacionales (Data Owner, Data Custodian, Data User), las finalidades primarias de negocio, los controles de protección criptográfica y lógica, y los protocolos de retención y disposición final, bajo el principio de separación funcional de responsabilidades (Segregation of Duties - SoD).

---

## 2. Procedimiento Realizado
1. Se mapearon los roles organizacionales clave:
   * **Dirección Comercial / Ventas:** Propietario de la relación con el cliente y datos de contacto.
   * **Dirección de Finanzas / Contabilidad:** Propietario de la información fiscal y de facturación.
   * **DBA / Infraestructura TI:** Custodio técnico encargado de implementar los controles y salvaguardar la disponibilidad e integridad.
   * **Oficial de Privacidad (DPO / Jurídico):** Garante del cumplimiento normativo y atención de derechos ARCO.
   * **Atención al Cliente / Facturación / Analítica:** Usuarios funcionales autorizados con necesidades acotadas.
2. Se estructuró la matriz asignando a cada atributo su propietario, usuarios con necesidad legítima de acceso, medidas de protección técnica y destino al concluir la vigencia.

---

## 3. Resultado Obtenido: Matriz de Gobierno de Datos

| Dato | Finalidad Primaria | Responsable (Data Owner) | Usuarios Autorizados | Mecanismo de Protección Técnica | Retención Estipulada | Acción al Finalizar |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **nombre** | Individualización contractual y trato al cliente. | Dirección Comercial | Atención al Cliente, Facturación, Logística. | RBAC, TLS en tránsito, vista con enmascaramiento parcial para soporte de primer nivel. | Relación contractual activa + 5 años de prescripción mercantil. | Supresión física en BD principal y desvinculación en sistemas de soporte. |
| **correo** | Canal primario de comunicación digital y notificaciones. | Dirección Comercial | Atención al Cliente, Plataforma de notificaciones automáticas. | RBAC, TLS en tránsito, columna booleana para consentimiento de mercadotecnia. | Relación contractual activa o revocación inmediata por oposición. | Bloqueo en listas de envío y eliminación física tras vencimiento. |
| **telefono** | Contacto urgente para entregas y validación de doble factor (2FA). | Dirección de Operaciones | Atención al Cliente, Logística / Envíos. | RBAC, acceso restringido mediante aplicación web (sin acceso directo a BD). | Vigencia de la cuenta o entrega del pedido en curso. | Purgado de logs de llamadas y borrado de la base activa. |
| **rfc** | Facturación electrónica (CFDI) y cumplimiento con el SAT. | Dirección de Finanzas | Facturación / Contabilidad exclusivamente. | **Cifrado simétrico en reposo a nivel de columna (`pgcrypto`)**, RBAC estricto, revocación a soporte y analistas. | **5 años obligatorios** conforme al Art. 30 del Código Fiscal de la Federación. | Destrucción criptográfica (borrado de la llave o purga segura de registros fiscales caducos). |
| **edad** | Verificación de capacidad jurídica de ejercicio. | Dirección Jurídica | Registro de usuarios (validación en frontend). | Disociación; transformación a rango etario mediante vistas en PostgreSQL (`CASE`). | Vigencia del contrato de usuario. | Anonimización irreversible / Agrupación estadística k-anónima. |
| **ciudad** | Logística de paquetería y cálculo de envíos. | Dirección de Operaciones | Logística, Atención a Clientes, Analítica. | Vistas de agregación (`COUNT(*) GROUP BY ciudad`), RBAC. | Indefinido mientras la cuenta esté activa; permanente a nivel estadístico agregado. | Conservación disociada exclusivamente para series históricas de analítica. |
| **codigo_postal**| Enrutamiento geográfico y validación de domicilio fiscal (CFDI 4.0). | Dirección de Finanzas / Operaciones | Facturación, Logística, Analítica (truncado a primeros 2 dígitos). | RBAC, truncamiento dinámico para reportería general. | 5 años vinculado al comprobante fiscal digital emitido. | Desvinculación del cliente; conservación únicamente del código postal para analítica regional. |

---

## 4. Análisis de Gobierno y Separación de Funciones (Segregation of Duties)

1. **El DBA como Custodio y no como Dueño del Dato:**
   Un principio angular del gobierno de datos establece que el **DBA es un Custodio Técnico (*Data Custodian*)**, no el Propietario (*Data Owner*). El DBA posee el acceso de superusuario (`postgres`) para optimizar índices, configurar respaldos y afinar el motor, pero no tiene legitimidad para decidir qué departamentos pueden consultar el RFC o si los correos pueden ser utilizados para campañas comerciales. Esas directrices emanan de los Propietarios de Negocio (Directores de Finanzas y Comercial) junto con el Oficial de Privacidad.
2. **Acceso Vinculado a Necesidad Funcional (*Need-to-Know*):**
   Como se plasma en la matriz, ningún rol funcional tiene acceso irrestricto a todos los campos. Al personal de Atención a Clientes se le niega el RFC para evitar fraudes de suplantación fiscal; a Facturación se le niegan los datos de navegación o soporte técnico; y a los analistas se les otorgan únicamente vistas agregadas sin identificadores.
3. **Protección Proporcional al Riesgo:**
   Los identificadores fiscales (RFC) y bancarios reciben controles de máxima seguridad (cifrado simétrico con `pgcrypto` evaluado en LAB-02), mientras que datos de menor sensibilidad como la ciudad se resguardan mediante segregación lógica de vistas y RBAC.

---

## 5. Conclusión
La matriz de gobierno de datos permite organizar formalmente qué áreas tienen acceso a cada dato y quién es el responsable de autorizarlo. Para el DBA, delimitar el rol de custodio técnico frente al propietario del dato evita que se tomen decisiones arbitrarias sobre la información y garantiza que los permisos en PostgreSQL reflejen las necesidades operativas de la organización.

