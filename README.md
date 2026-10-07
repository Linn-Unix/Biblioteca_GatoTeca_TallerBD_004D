# GatoTeca - Sistema de Gestion de Biblioteca y Cafe de Gatos

Este repositorio contiene la implementacion en Oracle SQL y PL/SQL para la base de datos de GatoTeca, un sistema de gestion para un establecimiento que combina el prestamo de libros con un espacio de convivencia y alimentacion de gatos.

El sistema esta modelado en 3FN y cuenta con objetos procedurales encargados de la logica transaccional, automatizacion de multas, validacion de horarios y generacion de reportes.

---

## Informacion del Proyecto

* **Asignatura:** Taller de Base de Datos (BDY1103)
* **Seccion:** 004D
* **Docente:** Carlos Orellana
* **Integrantes:**
  * Aolani Caiguan
  * Felipe Barra
  * Renata Orellana

---

## Tecnologias Utilizadas

* Oracle Database 19c / 21c
* SQL / PL/SQL
* Oracle SQL Developer
* Git

---

## Estructura de la Base de Datos

La base de datos consta de 14 tablas divididas entre entidades transaccionales y de referencia:

* **Transaccionales:** PRESTAMO, MULTA, ALIMENTACION, EJEMPLAR.
* **Referenciales:** LIBRO, AUTOR, LIBRO_AUTOR, EDITORIAL, CATEGORIA, SOCIO, EMPLEADO, GATO, RAZA, ALIMENTO.

---

## Componentes PL/SQL Implementados

### 1. Funciones (`FN_`)
* `fn_dias_atraso(p_id_prestamo)`: Calcula los dias transcurridos respecto a la fecha estimada de devolucion.
* `fn_calcular_multa(p_id_prestamo)`: Retorna el monto a cobrar por atraso ($500 por dia).
* `fn_total_alimentacion(p_id_alimentacion)`: Calcula el costo total de la compra de alimento segun la cantidad de porciones y tarifa.
* `fn_total_multas_pendientes()`: Retorna la suma global de multas impagas registradas en el sistema.

### 2. Procedimientos (`SP_`)
* `sp_generar_multas_masivo`: Proceso diario que evalua los prestamos activos con retraso y registra o actualiza sus multas de forma masiva.
* `sp_reporte_gestion(p_fecha_inicio, p_fecha_fin)`: Genera en consola de salida informes sobre prestamos vencidos, morosidad por socio, recaudacion por gato y libros mas prestados.

### 3. Paquetes (`PKG_`)
* `pkg_prestamos`:
  * `registrar_prestamo`: Valida existencia de entidades y registra la salida del libro.
  * `registrar_devolucion`: Cierra el prestamo, calcula dias de mora y actualiza el estado del ejemplar.
  * `prestamos_activos_socio`: Consulta el total de libros en posesion de un socio.
* `pkg_gatos`:
  * `registrar_alimentacion`: Valida cantidad permitida (1 a 5 porciones) y registra el evento.
  * `recaudacion_gato`: Retorna el monto total reunido por las alimentaciones de un gato especifico.

### 4. Triggers (`TRG_`)
* `trg_horario_prestamo` (BEFORE INSERT - Sentencia): Impide el registro de prestamos fuera del horario comercial (Lunes a Sabado, 09:00 a 20:00).
* `trg_valida_ejemplar_disponible` (BEFORE INSERT - Fila): Verifica que el ejemplar solicitado este en estado `DISPONIBLE`.
* `trg_estado_ejemplar` (AFTER INSERT/UPDATE - Fila): Actualiza automaticamente el estado del ejemplar a `PRESTADO` o `DISPONIBLE`.
* `trg_multa_devolucion` (AFTER UPDATE - Fila): Genera o recalcula la multa al momento de entregar un libro con atraso sin incurrir en error de tabla mutante (ORA-04091).

---

## Reglas de Negocio Clave

1. La duracion estandar de un prestamo es de 7 dias corridos.
2. Un ejemplar en estado `PRESTADO`, `DANADO` o `PERDIDO` no puede ser asignado a un nuevo prestamo.
3. La multa fija por atraso es de $500 diarios.
4. Las compras de alimento para gatos deben estar entre 1 y 5 porciones por registro y siempre son supervisadas por un empleado.
5. Los registros de prestamos estan bloqueados los domingos y fuera del rango de 09:00 a 20:00 hrs.

---

## Guia de Instalacion y Ejecucion

1. **Creacion de Esquema:**
   Ejecutar el script DDL de creacion de tablas e insercion de datos de prueba (`Anexo A` del informe).

2. **Compilacion de Objetos:**
   Ejecutar el script PL/SQL (`Anexo B`) en el siguiente orden para evitar conflictos de dependencia:
   * Funciones
   * Procedimientos
   * Especificaciones de Packages
   * Cuerpos de Packages (Package Bodies)
   * Triggers

3. **Pruebas de Funcionamiento:**

```sql
SET SERVEROUTPUT ON;

-- Registrar un prestamo
EXEC pkg_prestamos.registrar_prestamo(p_id_socio => 2, p_id_ejemplar => 2, p_id_empleado => 3);

-- Proceso masivo de revision de multas
EXEC sp_generar_multas_masivo;

-- Registrar devolucion de un prestamo
EXEC pkg_prestamos.registrar_devolucion(p_id_prestamo => 12);

-- Registrar alimentacion de un gato
EXEC pkg_gatos.registrar_alimentacion(p_id_socio => 4, p_id_gato => 6, p_id_alimento => 5, p_id_empleado => 2, p_cantidad => 2);

-- Generar reporte de gestion entre fechas
EXEC sp_reporte_gestion(SYSDATE - 60, SYSDATE);
```

---

## Consideraciones Adicionales

* Si requiere ejecutar pruebas de insercion fuera del horario de atencion permitido por la regla de negocio, desactive temporalmente el trigger de horario:
  ```sql
  ALTER TRIGGER trg_horario_prestamo DISABLE;
