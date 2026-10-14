-- =====================================================================
-- GatoTeca - PKG_GATOTECA
-- Taller de Base de Datos - Sección 004D
-- Package principal: préstamos, devoluciones y alimentación de gatos
-- =====================================================================

-- ===================== ESPECIFICACIÓN =====================
CREATE OR REPLACE PACKAGE pkg_gatoteca AS

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

END pkg_gatoteca;
/

-- ===================== CUERPO =====================
CREATE OR REPLACE PACKAGE BODY pkg_gatoteca AS

    -- ===== Constantes privadas (reglas de negocio) =====
    c_dias_prestamo     CONSTANT NUMBER       := 7;
    c_min_porciones     CONSTANT NUMBER       := 1;
    c_max_porciones     CONSTANT NUMBER       := 5;
    c_estado_disponible CONSTANT VARCHAR2(20) := 'DISPONIBLE';

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

    -- Devuelve el estado del ejemplar, o NULL si no existe
    FUNCTION estado_ejemplar (p_id NUMBER) RETURN VARCHAR2 IS
        v_estado ejemplar.estado%TYPE;
    BEGIN
        SELECT estado INTO v_estado FROM ejemplar WHERE id_ejemplar = p_id;
        RETURN v_estado;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END estado_ejemplar;

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

        INSERT INTO prestamo (id_prestamo, id_socio, id_ejemplar, id_empleado,
                              fecha_prestamo, fecha_devolucion_estimada, fecha_devolucion_real)
        VALUES (seq_prestamo.NEXTVAL, p_id_socio, p_id_ejemplar, p_id_empleado,
                TRUNC(SYSDATE), TRUNC(SYSDATE) + c_dias_prestamo, NULL)
        RETURNING id_prestamo INTO v_id_prestamo;

        -- El trigger TRG_VALIDAR_DISPONIBILIDAD cambia el estado del ejemplar a PRESTADO

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Préstamo ' || v_id_prestamo || ' registrado. Devolver antes del '
                             || TO_CHAR(TRUNC(SYSDATE) + c_dias_prestamo, 'DD/MM/YYYY'));
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END sp_registrar_prestamo;

    -- ===== Devolución =====
    PROCEDURE sp_devolucion_ejemplar (
        p_id_prestamo  IN prestamo.id_prestamo%TYPE
    ) IS
        v_id_ejemplar   prestamo.id_ejemplar%TYPE;
        v_fecha_real    prestamo.fecha_devolucion_real%TYPE;
        v_dias_atraso   NUMBER;
        v_monto_multa   multa.monto%TYPE;
    BEGIN
        BEGIN
            SELECT id_ejemplar, fecha_devolucion_real
              INTO v_id_ejemplar, v_fecha_real
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

        UPDATE prestamo
           SET fecha_devolucion_real = TRUNC(SYSDATE)
         WHERE id_prestamo = p_id_prestamo;

        UPDATE ejemplar
           SET estado = c_estado_disponible
         WHERE id_ejemplar = v_id_ejemplar;

        v_dias_atraso := fn_dias_atraso(p_id_prestamo);

        IF v_dias_atraso > 0 THEN
            v_monto_multa := fn_calcular_multa(p_id_prestamo);

            -- Si SP_GENERAR_MULTAS_MASIVO ya la creó, se actualiza; si no, se inserta
            UPDATE multa
               SET monto = v_monto_multa
             WHERE id_prestamo = p_id_prestamo
               AND pagada = 'N';

            IF SQL%ROWCOUNT = 0 THEN
                INSERT INTO multa (id_multa, id_prestamo, monto, pagada)
                VALUES (seq_multa.NEXTVAL, p_id_prestamo, v_monto_multa, 'N');
            END IF;

            DBMS_OUTPUT.PUT_LINE('Devolución con ' || v_dias_atraso || ' días de atraso. Multa: $' || v_monto_multa);
        ELSE
            DBMS_OUTPUT.PUT_LINE('Devolución registrada a tiempo, sin multa.');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
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
        IF p_cantidad_porciones > c_max_porciones THEN
            RAISE_APPLICATION_ERROR(-20001, 'La cantidad de porciones excede el límite permitido por visita (Máx: '
                                            || c_max_porciones || ')');
        ELSIF p_cantidad_porciones IS NULL OR p_cantidad_porciones < c_min_porciones THEN
            RAISE_APPLICATION_ERROR(-20002, 'Debe comprar al menos ' || c_min_porciones || ' porción.');
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

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Alimentación ' || v_id_alimentacion || ' registrada. Total a pagar: $' || v_monto);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END sp_registrar_alimentacion;

END pkg_gatoteca;
/