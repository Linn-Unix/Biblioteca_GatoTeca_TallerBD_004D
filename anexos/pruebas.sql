-- =====================================================================
-- Pruebas de package + triggers con los datos de 01_gatoteca_init.sql
-- Ejecutar completo, en orden, justo después de recrear la BD.
-- Cada prueba indica ESPERADO; compara con lo OBTENIDO.
-- Termina con ROLLBACK para no ensuciar los datos.
-- =====================================================================
SET SERVEROUTPUT ON

-- ---- P1: préstamo normal -> el trigger deja el ejemplar PRESTADO ----
-- ESPERADO: ejemplar 2 pasa de DISPONIBLE a PRESTADO
SELECT id_ejemplar, estado FROM ejemplar WHERE id_ejemplar = 2;
EXEC pkg_gatoteca.sp_registrar_prestamo(1, 2, 1);
SELECT id_ejemplar, estado FROM ejemplar WHERE id_ejemplar = 2;

-- ---- P2: prestar un ejemplar ya prestado ----
-- ESPERADO: ORA-20013 (package) y, por INSERT directo, ORA-20030 (trigger)
EXEC pkg_gatoteca.sp_registrar_prestamo(2, 2, 1);
INSERT INTO prestamo (id_prestamo, id_socio, id_ejemplar, id_empleado,
                      fecha_prestamo, fecha_devolucion_estimada)
VALUES (999, 2, 2, 1, SYSDATE, SYSDATE + 7);

-- ---- P3: funciones desde SQL ----
-- ESPERADO: 12 gatos; multa del préstamo 12 = 4000 (8 días) y del 13 = 2500 (5 días)
SELECT pkg_gatoteca.fn_total_gatos_activos AS total_gatos FROM dual;
SELECT id_prestamo, pkg_gatoteca.fn_calcular_multa(id_prestamo) AS multa_calculada
  FROM prestamo
 WHERE id_prestamo IN (12, 13);

-- ---- P4: la función reproduce las multas ya existentes ----
-- ESPERADO: 0 filas (la multa calculada coincide con multa.monto en los préstamos 2 a 11)
SELECT m.id_prestamo, m.monto, pkg_gatoteca.fn_calcular_multa(m.id_prestamo) AS calculada
  FROM multa m
 WHERE m.monto <> pkg_gatoteca.fn_calcular_multa(m.id_prestamo);

-- ---- P5: procedimiento masivo sin parámetros (y repetido) ----
-- ESPERADO: "Multas generadas/actualizadas: 2" las dos veces; en multa quedan
-- solo 2 filas nuevas (préstamos 12 y 13), sin duplicados (idempotente)
EXEC pkg_gatoteca.sp_generar_multas_masivo;
EXEC pkg_gatoteca.sp_generar_multas_masivo;
SELECT id_multa, id_prestamo, monto, pagada FROM multa WHERE id_prestamo IN (12, 13);

-- ---- P6: devolución con atraso -> libera el ejemplar ----
-- ESPERADO: "8 días de atraso. Multa: $4000"; ejemplar 1 pasa a DISPONIBLE;
-- la multa del préstamo 12 sigue siendo una sola fila
EXEC pkg_gatoteca.sp_devolucion_ejemplar(12);
SELECT id_ejemplar, estado FROM ejemplar WHERE id_ejemplar = 1;
SELECT COUNT(*) AS multas_prestamo_12 FROM multa WHERE id_prestamo = 12;

-- ---- P7: devolver dos veces ----
-- ESPERADO: ORA-20021
EXEC pkg_gatoteca.sp_devolucion_ejemplar(12);

-- ---- P8: trigger de sentencia vs filas afectadas ----
-- ESPERADO: aud_gatoteca sube en 1 aunque el UPDATE afecte varias multas
SELECT COUNT(*) AS aud_antes FROM aud_gatoteca;
UPDATE multa SET pagada = pagada WHERE pagada = 'N';
SELECT COUNT(*) AS aud_despues FROM aud_gatoteca;
SELECT tabla, operacion, usuario, fecha FROM aud_gatoteca ORDER BY id_aud;

-- ---- P9: alimentación, límites y caso normal ----
-- ESPERADO: ORA-20002 (0), ORA-20001 (6), ORA-20003 (socio 99999);
-- y la última: "Total: $2000"
EXEC pkg_gatoteca.sp_registrar_alimentacion(1, 1, 1, 1, 0);
EXEC pkg_gatoteca.sp_registrar_alimentacion(1, 1, 1, 1, 6);
EXEC pkg_gatoteca.sp_registrar_alimentacion(99999, 1, 1, 1, 2);
EXEC pkg_gatoteca.sp_registrar_alimentacion(1, 1, 1, 1, 2);

ROLLBACK;