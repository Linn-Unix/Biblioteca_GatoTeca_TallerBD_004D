-- =====================================================================
-- GatoTeca - TRIGGERS
-- Taller de Base de Datos - Sección 004D

-- 1) trg_prestamo_bir            FILA      BEFORE INSERT       prestamo
-- 2) trg_prestamo_estado_ejemplar FILA      AFTER INSERT/UPDATE prestamo
-- 3) trg_multa_aud_stmt          SENTENCIA AFTER INSERT/UPDATE/DELETE multa

CREATE OR REPLACE TRIGGER trg_prestamo_bir
BEFORE INSERT ON prestamo
FOR EACH ROW
DECLARE
    v_estado ejemplar.estado%TYPE;
BEGIN
    SELECT estado INTO v_estado
      FROM ejemplar
     WHERE id_ejemplar = :NEW.id_ejemplar;

    IF UPPER(v_estado) <> 'DISPONIBLE' THEN
        RAISE_APPLICATION_ERROR(-20030,
            'Trigger: el ejemplar ' || :NEW.id_ejemplar || ' no está disponible (estado: ' || v_estado || ').');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20032,
            'Trigger: el ejemplar ' || :NEW.id_ejemplar || ' no existe.');
END trg_prestamo_bir;
/

-- ---------- 2) FILA: mantener el estado del ejemplar ----------
-- Insert de préstamo      -> ejemplar PRESTADO
-- Se registra devolución  -> ejemplar DISPONIBLE
-- Solo modifica ejemplar (no consulta prestamo): no hay tabla mutante.
CREATE OR REPLACE TRIGGER trg_prestamo_estado_ejemplar
AFTER INSERT OR UPDATE OF fecha_devolucion_real ON prestamo
FOR EACH ROW
BEGIN
    IF INSERTING AND :NEW.fecha_devolucion_real IS NULL THEN
        UPDATE ejemplar
           SET estado = 'PRESTADO'
         WHERE id_ejemplar = :NEW.id_ejemplar;

    ELSIF UPDATING
          AND :OLD.fecha_devolucion_real IS NULL
          AND :NEW.fecha_devolucion_real IS NOT NULL THEN
        UPDATE ejemplar
           SET estado = 'DISPONIBLE'
         WHERE id_ejemplar = :NEW.id_ejemplar;
    END IF;
END trg_prestamo_estado_ejemplar;
/

-- ---------- 3) SENTENCIA: auditoría de multas ----------
-- Se ejecuta UNA vez por sentencia DML, sin importar cuántas filas
-- afecte (un UPDATE de 10 multas genera 1 registro, no 10).
CREATE OR REPLACE TRIGGER trg_multa_aud_stmt
AFTER INSERT OR UPDATE OR DELETE ON multa
DECLARE
    v_operacion VARCHAR2(10);
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
    ELSE
        v_operacion := 'DELETE';
    END IF;

    INSERT INTO aud_gatoteca (tabla, operacion)
    VALUES ('MULTA', v_operacion);
END trg_multa_aud_stmt;
/

SHOW ERRORS