-- ===================== PRUEBAS =====================
SET SERVEROUTPUT ON;

EXEC pkg_gatoteca.sp_registrar_prestamo(1, 1, 1);
EXEC pkg_gatoteca.sp_devolucion_ejemplar(1);
EXEC pkg_gatoteca.sp_registrar_alimentacion(1, 1, 1, 1, 3);
EXEC pkg_gatoteca.sp_registrar_alimentacion(1, 1, 1, 1, 7);  -- debe tirar ORA-20001 (Evidencia 3)