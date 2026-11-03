-- =============================================================================
-- LAB-03: Privacidad, cumplimiento y gobierno de los datos
-- Script 02: Separación por Finalidad (Analítica vs Operación)
-- Motor: PostgreSQL 16
-- Estudiante: Genaro Isaac Cárdenas Soto (@darksitoV)
-- Organización: Comercializadora Norte S.A. de C.V.
-- =============================================================================

-- Contexto:
-- El área de analítica requiere información estadística agregada (por ciudad y por rangos
-- de edad) para estudios de mercado y planificación de inventarios. No requiere en lo absoluto
-- conocer datos directamente identificables (nombre, correo, teléfono, RFC).
-- Entregar la tabla completa de clientes violaría el principio de finalidad y expondría PII.

-- 1. Consulta analítica agregada por ciudad (sin datos individuales)
SELECT 
    ciudad, 
    COUNT(*) AS cantidad_clientes
FROM clientes
GROUP BY ciudad
ORDER BY cantidad_clientes DESC;

-- 2. Consulta analítica agrupada por rangos etarios (k-anonimato / disociación)
SELECT 
    CASE
        WHEN edad < 18 THEN 'Menor de 18'
        WHEN edad BETWEEN 18 AND 29 THEN '18-29'
        WHEN edad BETWEEN 30 AND 44 THEN '30-44'
        WHEN edad BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60 o más'
    END AS rango_edad,
    COUNT(*) AS cantidad
FROM clientes
GROUP BY 
    CASE
        WHEN edad < 18 THEN 'Menor de 18'
        WHEN edad BETWEEN 18 AND 29 THEN '18-29'
        WHEN edad BETWEEN 30 AND 44 THEN '30-44'
        WHEN edad BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60 o más'
    END
ORDER BY rango_edad;

-- 3. Consulta de distribución cruzada (Ciudad y Rango Etario) para soporte de toma de decisiones
SELECT 
    ciudad,
    CASE
        WHEN edad < 18 THEN 'Menor de 18'
        WHEN edad BETWEEN 18 AND 29 THEN '18-29'
        WHEN edad BETWEEN 30 AND 44 THEN '30-44'
        WHEN edad BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60 o más'
    END AS rango_edad,
    COUNT(*) AS total_clientes
FROM clientes
GROUP BY ciudad, rango_edad
ORDER BY ciudad, rango_edad;

