-- =====================================================================
-- GatoTeca - PKG_GATOTECA
-- Taller de Base de Datos - Sección 004D
-- Package principal: préstamos, devoluciones, alimentación y multas
-- Orden de ejecución: 01_gatoteca_init.sql -> 02_objetos_apoyo.sql
--                     -> pkg_gatoteca.sql -> trg_gatoteca.sql

-- ===================== ESPECIFICACIÓN =====================
CREATE OR REPLACE PACKAGE pkg_gatoteca AS

    -- Procedimientos CON parámetros
    PROCEDURE sp_registrar_prestamo (
        p_id_socio     IN prestamo.id_socio%TYPE,
        p_id_ejemplar  IN prestamo.id_ejemplar%TYPE,
        p_id_empleado  IN prestamo.id_empleado%TYPE
    );

    PROCEDURE sp_devolucion_ejemplar (
        p_id_prestamo  IN prestamo.id_prestamo%TYPE
    );

    PROCEDURE sp_registrar_alimentacion (
        p_id_socio            IN alimentacion.id_socio%TYPE,
        p_id_gato             IN alimentacion.id_gato%TYPE,
        p_id_alimento         IN alimentacion.id_alimento%TYPE,
        p_id_empleado         IN alimentacion.id_empleado%TYPE,
        p_cantidad_porciones  IN alimentacion.cantidad%TYPE
    );

    -- Función SIN parámetros
    FUNCTION fn_total_gatos_activos RETURN NUMBER;

    -- Función CON parámetros (usable desde SQL: solo lee, no modifica)
    FUNCTION fn_calcular_multa (
        p_id_prestamo IN prestamo.id_prestamo%TYPE
    ) RETURN NUMBER;

    -- Procedimiento SIN parámetros (procesamiento masivo)
    PROCEDURE sp_generar_multas_masivo;

END pkg_gatoteca;
/

-- ===================== CUERPO =====================
CREATE OR REPLACE PACKAGE BODY pkg_gatoteca AS

    -- ===== Constantes privadas =====
    c_dias_prestamo     CONSTANT NUMBER       := 7;
    c_min_porciones     CONSTANT NUMBER       := 1;
    c_max_porciones     CONSTANT NUMBER       := 5;
    c_multa_por_dia     CONSTANT NUMBER       := 500;
    c_estado_disponible CONSTANT VARCHAR2(20) := 'DISPONIBLE';

    -- Declaraciones anticipadas para las funciones usadas por varios
    -- procedimientos del cuerpo.
    FUNCTION fn_dias_atraso (p_id_prestamo NUMBER) RETURN NUMBER;
    FUNCTION fn_total_alimentacion (p_id_alimentacion NUMBER) RETURN NUMBER;

    -- ===== Validaciones privadas =====
    FUNCTION existe_socio (p_id NUMBER) RETURN BOOLEAN IS
        v_cant NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cant FROM socio WHERE id_socio = p_id;
        RETURN v_cant > 0;
    END existe_socio;

    FUNCTION existe_empleado (p_id NUMBER) RETURN BOOLEAN IS
        v_cant NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cant FROM empleado WHERE id_empleado = p_id;
        RETURN v_cant > 0;
    END existe_empleado;

    FUNCTION existe_gato (p_id NUMBER) RETURN BOOLEAN IS
        v_cant NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cant FROM gato WHERE id_gato = p_id;
        RETURN v_cant > 0;
    END existe_gato;

    FUNCTION existe_alimento (p_id NUMBER) RETURN BOOLEAN IS
        v_cant NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cant FROM alimento WHERE id_alimento = p_id;
        RETURN v_cant > 0;
    END existe_alimento;

    -- Devuelve el estado del ejemplar (NULL si no existe).
    -- Bloquea la fila para evitar que dos usuarios presten el mismo ejemplar.
    FUNCTION estado_ejemplar (p_id NUMBER) RETURN VARCHAR2 IS
        v_estado ejemplar.estado%TYPE;
    BEGIN
        SELECT estado INTO v_estado
          FROM ejemplar
         WHERE id_ejemplar = p_id
           FOR UPDATE;
        RETURN v_estado;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END estado_ejemplar;

    -- Días de atraso (negativo o 0 = a tiempo). Si no se ha devuelto, usa hoy.
    FUNCTION fn_dias_atraso (p_id_prestamo NUMBER) RETURN NUMBER IS
        v_dias NUMBER;
    BEGIN
        SELECT NVL(TRUNC(fecha_devolucion_real), TRUNC(SYSDATE))
               - TRUNC(fecha_devolucion_estimada)
          INTO v_dias
          FROM prestamo
         WHERE id_prestamo = p_id_prestamo;
        RETURN v_dias;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END fn_dias_atraso;

    -- Total a pagar por una alimentación (precio x porciones)
    FUNCTION fn_total_alimentacion (p_id_alimentacion NUMBER) RETURN NUMBER IS
        v_total NUMBER;
    BEGIN
        SELECT ali.precio * ag.cantidad
          INTO v_total
          FROM alimentacion ag
          JOIN alimento ali ON ag.id_alimento = ali.id_alimento
         WHERE ag.id_alimentacion = p_id_alimentacion;
        RETURN v_total;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END fn_total_alimentacion;

    -- Crea la multa del préstamo o actualiza su monto si sigue sin pagar.
    -- Si ya está pagada no la toca (multa tiene UNIQUE por préstamo, así
    -- que insertar otra provocaría ORA-00001). Usada por devolución y masivo.
    PROCEDURE registrar_multa (p_id_prestamo NUMBER, p_monto NUMBER) IS
        v_pagada multa.pagada%TYPE;
    BEGIN
        IF p_monto IS NULL OR p_monto <= 0 THEN
            RETURN;
        END IF;

        SELECT pagada INTO v_pagada
          FROM multa
         WHERE id_prestamo = p_id_prestamo;

        IF v_pagada = 'N' THEN
            UPDATE multa
               SET monto = p_monto
             WHERE id_prestamo = p_id_prestamo;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO multa (id_multa, id_prestamo, monto, pagada)
            VALUES (seq_multa.NEXTVAL, p_id_prestamo, p_monto, 'N');
    END registrar_multa;

    -- ===== Funciones públicas =====
    FUNCTION fn_total_gatos_activos RETURN NUMBER IS
        v_total NUMBER;
    BEGIN
        -- gato no tiene columna de estado: se cuentan todos los gatos
        SELECT COUNT(*) INTO v_total FROM gato;
        RETURN v_total;
    END fn_total_gatos_activos;

    FUNCTION fn_calcular_multa (
        p_id_prestamo IN prestamo.id_prestamo%TYPE
    ) RETURN NUMBER IS
    BEGIN
        IF p_id_prestamo IS NULL THEN
            RETURN 0;
        END IF;
        RETURN GREATEST(0, fn_dias_atraso(p_id_prestamo)) * c_multa_por_dia;
    END fn_calcular_multa;

    -- ===== Préstamo =====
    PROCEDURE sp_registrar_prestamo (
        p_id_socio     IN prestamo.id_socio%TYPE,
        p_id_ejemplar  IN prestamo.id_ejemplar%TYPE,
        p_id_empleado  IN prestamo.id_empleado%TYPE
    ) IS
        v_estado      ejemplar.estado%TYPE;
        v_id_prestamo prestamo.id_prestamo%TYPE;
    BEGIN
        IF NOT existe_socio(p_id_socio) THEN
            RAISE_APPLICATION_ERROR(-20010, 'El socio ' || p_id_socio || ' no existe.');
        END IF;

        IF NOT existe_empleado(p_id_empleado) THEN
            RAISE_APPLICATION_ERROR(-20011, 'El empleado ' || p_id_empleado || ' no existe.');
        END IF;

        v_estado := estado_ejemplar(p_id_ejemplar);

        IF v_estado IS NULL THEN
            RAISE_APPLICATION_ERROR(-20012, 'El ejemplar ' || p_id_ejemplar || ' no existe.');
        ELSIF UPPER(v_estado) <> c_estado_disponible THEN
            RAISE_APPLICATION_ERROR(-20013, 'El ejemplar no está disponible (estado: ' || v_estado || ').');
        END IF;

        -- El trigger trg_prestamo_estado_ejemplar marca el ejemplar como PRESTADO
        INSERT INTO prestamo (id_prestamo, id_socio, id_ejemplar, id_empleado,
                              fecha_prestamo, fecha_devolucion_estimada, fecha_devolucion_real)
        VALUES (seq_prestamo.NEXTVAL, p_id_socio, p_id_ejemplar, p_id_empleado,
                TRUNC(SYSDATE), TRUNC(SYSDATE) + c_dias_prestamo, NULL)
        RETURNING id_prestamo INTO v_id_prestamo;

        DBMS_OUTPUT.PUT_LINE('Préstamo ' || v_id_prestamo || ' registrado. Devolver antes del '
                             || TO_CHAR(TRUNC(SYSDATE) + c_dias_prestamo, 'DD/MM/YYYY'));
    END sp_registrar_prestamo;

    -- ===== Devolución =====
    PROCEDURE sp_devolucion_ejemplar (
        p_id_prestamo  IN prestamo.id_prestamo%TYPE
    ) IS
        v_fecha_real    prestamo.fecha_devolucion_real%TYPE;
        v_dias_atraso   NUMBER;
        v_monto_multa   multa.monto%TYPE;
    BEGIN
        BEGIN
            SELECT fecha_devolucion_real
              INTO v_fecha_real
              FROM prestamo
             WHERE id_prestamo = p_id_prestamo
               FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20020, 'El préstamo ' || p_id_prestamo || ' no existe.');
        END;

        IF v_fecha_real IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20021, 'Este préstamo ya fue devuelto.');
        END IF;

        -- El trigger trg_prestamo_estado_ejemplar deja el ejemplar DISPONIBLE
        UPDATE prestamo
           SET fecha_devolucion_real = TRUNC(SYSDATE)
         WHERE id_prestamo = p_id_prestamo;

        v_dias_atraso := fn_dias_atraso(p_id_prestamo);

        IF v_dias_atraso > 0 THEN
            v_monto_multa := fn_calcular_multa(p_id_prestamo);
            registrar_multa(p_id_prestamo, v_monto_multa);

            DBMS_OUTPUT.PUT_LINE('Devolución con ' || v_dias_atraso || ' días de atraso. Multa: $' || v_monto_multa);
        ELSE
            DBMS_OUTPUT.PUT_LINE('Devolución registrada a tiempo, sin multa.');
        END IF;
    END sp_devolucion_ejemplar;

    -- ===== Alimentación =====
    PROCEDURE sp_registrar_alimentacion (
        p_id_socio            IN alimentacion.id_socio%TYPE,
        p_id_gato             IN alimentacion.id_gato%TYPE,
        p_id_alimento         IN alimentacion.id_alimento%TYPE,
        p_id_empleado         IN alimentacion.id_empleado%TYPE,
        p_cantidad_porciones  IN alimentacion.cantidad%TYPE
    ) IS
        v_id_alimentacion alimentacion.id_alimentacion%TYPE;
        v_monto           NUMBER;
    BEGIN
        IF p_cantidad_porciones IS NULL OR p_cantidad_porciones < c_min_porciones THEN
            RAISE_APPLICATION_ERROR(-20002, 'Debe comprar al menos ' || c_min_porciones || ' porción.');
        ELSIF p_cantidad_porciones > c_max_porciones THEN
            RAISE_APPLICATION_ERROR(-20001, 'La cantidad de porciones excede el límite permitido por visita (Máx: ' || c_max_porciones || ')');
        END IF;

        IF NOT existe_socio(p_id_socio) THEN
            RAISE_APPLICATION_ERROR(-20003, 'El socio ' || p_id_socio || ' no existe.');
        END IF;

        IF NOT existe_gato(p_id_gato) THEN
            RAISE_APPLICATION_ERROR(-20004, 'El gato ' || p_id_gato || ' no existe.');
        END IF;

        IF NOT existe_alimento(p_id_alimento) THEN
            RAISE_APPLICATION_ERROR(-20005, 'El alimento ' || p_id_alimento || ' no existe.');
        END IF;

        IF NOT existe_empleado(p_id_empleado) THEN
            RAISE_APPLICATION_ERROR(-20006, 'El empleado ' || p_id_empleado || ' no existe.');
        END IF;

        INSERT INTO alimentacion (id_alimentacion, id_socio, id_gato, id_alimento,
                                  id_empleado, fecha, cantidad)
        VALUES (seq_alimentacion.NEXTVAL, p_id_socio, p_id_gato, p_id_alimento,
                p_id_empleado, SYSDATE, p_cantidad_porciones)
        RETURNING id_alimentacion INTO v_id_alimentacion;

        v_monto := fn_total_alimentacion(v_id_alimentacion);

        DBMS_OUTPUT.PUT_LINE('Alimentación ' || v_id_alimentacion || ' registrada. Total: $' || v_monto);
    END sp_registrar_alimentacion;

    -- ===== Procesamiento masivo: multas de préstamos vencidos sin devolver =====
    PROCEDURE sp_generar_multas_masivo IS
        v_monto       multa.monto%TYPE;
        v_procesados  NUMBER := 0;
    BEGIN
        FOR r IN (SELECT id_prestamo
                    FROM prestamo
                   WHERE fecha_devolucion_real IS NULL
                     AND TRUNC(fecha_devolucion_estimada) < TRUNC(SYSDATE)) LOOP

            v_monto := fn_calcular_multa(r.id_prestamo);
            registrar_multa(r.id_prestamo, v_monto);

            v_procesados := v_procesados + 1;
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('Multas generadas/actualizadas: ' || v_procesados);
    END sp_generar_multas_masivo;

END pkg_gatoteca;
/

SHOW ERRORS PACKAGE BODY pkg_gatoteca