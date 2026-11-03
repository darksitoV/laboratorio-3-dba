-- =============================================================================
-- LAB-03: Privacidad, cumplimiento y gobierno de los datos
-- Script 01: Principio de Minimización de Datos
-- Motor: PostgreSQL 16
-- Estudiante: Genaro Isaac Cárdenas Soto (@darksitoV)
-- Organización: Comercializadora Norte S.A. de C.V.
-- =============================================================================

-- Contexto:
-- El área de atención al cliente necesita consultar información para interactuar con los
-- titulares (nombre, correo, teléfono). No requiere conocer identificadores fiscales (RFC),
-- edad, ni código postal completo. En cumplimiento con el principio de minimización
-- (LFPDPPP Art. 6 y GDPR Art. 5.1c), se crea una estructura mínima para este propósito.

-- 1. Eliminación y creación de la tabla minimizada para atención al cliente
DROP TABLE IF EXISTS clientes_soporte CASCADE;

CREATE TABLE clientes_soporte (
    id BIGINT PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    correo VARCHAR(150) NOT NULL,
    telefono VARCHAR(20)
);

-- Comentario descriptivo del objeto en el catálogo de PostgreSQL
COMMENT ON TABLE clientes_soporte IS 'Estructura minimizada para atención al cliente y soporte operativo';
COMMENT ON COLUMN clientes_soporte.id IS 'Identificador foráneo del cliente';
COMMENT ON COLUMN clientes_soporte.nombre IS 'Nombre completo para trato al cliente';
COMMENT ON COLUMN clientes_soporte.correo IS 'Canal digital primario de contacto';
COMMENT ON COLUMN clientes_soporte.telefono IS 'Canal telefónico de atención y resolución';

-- 2. Carga controlada de información únicamente con los campos necesarios
INSERT INTO clientes_soporte (id, nombre, correo, telefono)
SELECT id, nombre, correo, telefono
FROM clientes;

-- 3. Verificación de los registros cargados bajo principio de necesidad
SELECT id, nombre, correo, telefono
FROM clientes_soporte
ORDER BY id;

