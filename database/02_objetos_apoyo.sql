-- =====================================================================
-- 02_objetos_apoyo.sql
-- Crea secuencias y tablas de auditoría necesarias para el Package y Triggers
-- =====================================================================

-- Secuencias para los PKs automáticos
CREATE SEQUENCE seq_prestamo START WITH 100 INCREMENT BY 1;
CREATE SEQUENCE seq_multa START WITH 100 INCREMENT BY 1;
CREATE SEQUENCE seq_alimentacion START WITH 100 INCREMENT BY 1;

-- Tabla de auditoría para el Trigger a nivel de sentencia
CREATE TABLE aud_gatoteca (
    id_aud NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tabla VARCHAR2(30),
    operacion VARCHAR2(10),
    usuario VARCHAR2(30) DEFAULT USER,
    fecha DATE DEFAULT SYSDATE
);