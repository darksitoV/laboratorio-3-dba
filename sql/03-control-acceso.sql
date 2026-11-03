-- =============================================================================
-- LAB-03: Privacidad, cumplimiento y gobierno de los datos
-- Script 03: Control de Acceso Relacionado con la Finalidad (RBAC + Vistas)
-- Motor: PostgreSQL 16
-- Estudiante: Genaro Isaac Cárdenas Soto (@darksitoV)
-- Organización: Comercializadora Norte S.A. de C.V.
-- =============================================================================

-- Contexto:
-- Para garantizar técnicamente que los analistas únicamente tengan acceso a datos
-- compatibles con su finalidad funcional (Principio de Limitación de la Finalidad y
-- Mínimo Privilegio), se crea una vista analítica y se restringe el acceso directo
-- a la tabla principal con datos personales (clientes).

-- 1. Creación del rol funcional si no existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'analista') THEN
        CREATE ROLE analista NOLOGIN;
    END IF;
END $$;

-- 2. Creación de la vista analítica disociada (sin PII directa)
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

COMMENT ON VIEW v_analitica_clientes IS 'Vista disociada para analistas sin identificadores directos ni fiscales';

-- 3. Otorgamiento de privilegios mínimos sobre el esquema y la vista
GRANT USAGE ON SCHEMA public TO analista;
GRANT SELECT ON v_analitica_clientes TO analista;

-- 4. Revocación estricta de privilegios directos sobre la tabla de clientes
REVOKE SELECT ON clientes FROM analista;

-- 5. Verificación de los privilegios asignados al rol en el catálogo
SELECT 
    grantee,
    table_schema,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'analista' AND table_schema = 'public';

-- 6. Demostración técnica de cumplimiento (simulación de sesión)
-- Prueba de consulta exitosa a la vista:
SET ROLE analista;
SELECT * FROM v_analitica_clientes LIMIT 5;

-- Prueba de denegación de consulta directa (PostgreSQL arrojará permission denied):
-- SELECT * FROM clientes; -- Descomentar para comprobar el bloqueo: ERROR: permission denied for table clientes

RESET ROLE;

