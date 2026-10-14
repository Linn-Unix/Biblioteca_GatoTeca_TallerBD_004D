# 

# 

# 

# 

# **GatoTeca**

## Proyecto de soluciones con SQL y PL/SQL para biblioteca.

Asignatura: Taller de Base de Datos  
Sección: 004D  
Docente: Carlos Orellana  
Integrantes: Aolani Caiguan, Felipe Barra, Isidora Diaz, Renata Orellana

[**1\.  Análisis del contexto	3**](#1.-análisis-del-contexto)

[1.1 Descripción del proyecto	3](#1.1-descripción-del-proyecto)

[1.2 Alcance	3](#1.2-alcance)

[1.3 Tecnologías utilizadas	4](#1.3-tecnologías-utilizadas)

[1.4 Datos a Procesar e información relevante	4](#1.4-datos-a-procesar-e-información-relevante)

[1.4.1 Datos transaccionales	4](#1.4.1-datos-transaccionales)

[1.4.2 Datos de referencia	5](#1.4.2-datos-de-referencia)

[1.5 Información relevante a generar	5](#1.5-información-relevante-a-generar)

[1.6 Reglas de Negocio	6](#1.6-reglas-de-negocio)

[**2\. Desarrollo de procedimientos y funciones	7**](#2.-desarrollo-de-procedimientos-y-funciones)

[2.1 Definición y características	7](#2.1-definición-y-características)

[2.2 Ventajas y desventajas de cada uno	7](#2.2-ventajas-y-desventajas-de-cada-uno)

[2.2.1 Ventajas	7](#2.2.1-ventajas)

[2.2.2 Desventajas	7](#2.2.2-desventajas)

[2.3 Propósito de procedimientos y funciones en el contexto del proyecto	8](#2.3-propósito-de-procedimientos-y-funciones-en-el-contexto-del-proyecto)

[2.4 Utilidad de procedimientos y funciones en el contexto del proyecto	8](#2.4-utilidad-de-procedimientos-y-funciones-en-el-contexto-del-proyecto)

[**3\. Desarrollo de Packages	9**](#3.-desarrollo-de-packages)

[3.1 Definición y características	9](#3.1-definición-y-características)

[3.2 Ventajas y desventajas al momento de utilizar Triggers	9](#3.2-ventajas-y-desventajas-al-momento-de-utilizar-triggers)

[3.2.1 Ventajas	9](#3.2.1-ventajas)

[3.2.2 Desventajas	9](#3.2.2-desventajas)

[3.3 Cómo ayudan a organizar el código en el proyecto	9](#3.3-cómo-ayudan-a-organizar-el-código-en-el-proyecto)

[3.4 Cómo se relacionan con los procedimientos y funciones	10](#3.4-cómo-se-relacionan-con-los-procedimientos-y-funciones)

[3.5 Cómo se utilizaron los packages en el proyecto	10](#3.5-cómo-se-utilizaron-los-packages-en-el-proyecto)

[**4\. Desarrollo de Triggers	11**](#4.-desarrollo-de-triggers)

[4.1 Definición y características	11](#4.1-definición-y-características)

[4.2 Ventajas y desventajas en la utilización de triggers	11](#4.2-ventajas-y-desventajas-en-la-utilización-de-triggers)

[4.3 Propósito de los triggers en el contexto del proyecto	11](#4.3-propósito-de-los-triggers-en-el-contexto-del-proyecto)

[4.4 Utilidad los triggers en el contexto del proyecto semestral	11](#4.4-utilidad-los-triggers-en-el-contexto-del-proyecto-semestral)

[**5\. Conclusión	11**](#5.-conclusión)

[5.1 Resumen	11](#5.1-resumen)

[5.2 Impacto en el proyecto	12](#5.2-impacto-en-el-proyecto)

[5.3 Recomendaciones	12](#5.3-recomendaciones)

[**6\. Anexos	12**](#6.-anexos)

[6.1 Código completo	12](#6.1-código-completo)

[6.2 Diagramas y modelos	12](#6.2-diagramas-y-modelos)

# 

# 1\.  Análisis del contexto {#1.-análisis-del-contexto}

## 1.1 Descripción del proyecto {#1.1-descripción-del-proyecto}

Gatoteca es una biblioteca que combina el préstamo de libros con la convivencia de gatos que residen en el establecimiento. Además de libros prestados, los socios pueden alimentar a los gatos, procedimiento que es supervisado por los empleados.

El objetivo del proyecto es automatizar los procesos de la biblioteca como el control de préstamos y devoluciones, el cálculo de las multas por atraso, el registro de la alimentación de los gatos y la generación de reportes de gestión. Para lograrlo, se desarrolló una base de datos en Oracle normalizada en tercera forma normal y objetos de PL/SQL. Se utilizaron funciones para los cálculo del negocio (días de atraso, multas, montos, etc), procedimientos para procesar información de forma masiva y generar reportes, packages que agrupan las operaciones de préstamos de libros y la alimentación de gatos, y los triggers garantizan que las reglas de negocio se cumplan siempre.

## 1.2 Alcance {#1.2-alcance}

Con nuestros programas PL/SQL se buscará mejorar los componentes del negocio que tienen directa relación con la gestión de préstamos y los gatos.

1. Gestión de préstamos: Automatiza el registro de préstamos y devoluciones, validando que el ejemplar esté disponible antes de prestarlo y actualizando su estado en cada movimiento.  
2. Control de multas: Automatiza el cálculo y registro de multas por atraso, sin intervención manual, tanto en la revisión diaria de préstamos como al momento de la devolución   
3. Servicio de alimentación: Automatiza el registro de cada alimentación, validando que la cantidad de porciones esté dentro de lo permitido y calculando el monto a pagar  
4. Reportes de gestión: Automatiza la generación de reportes por periodo, para que la información esté disponible al instante sin tener que hacerlo a mano.  
     
     
     
     
     
   

## 1.3 Tecnologías utilizadas {#1.3-tecnologías-utilizadas}

1. Oracle Database: Es el motor de base de datos donde creamos tanto las tablas como los objetos en PL/SQL.  
2. SQL: Lenguaje utilizado para la creación de tablas, límites del programa, DML, y consultas.  
3. Visual Studio Code con la extensión de Oracle SQL: Editor desde el que se conecta la base de datos, ejecución de scripts y pruebas de código.  
4. Git: Control de versiones de los scripts y documentación, facilitando el trabajo colaborativo.

## 1.4 Datos a Procesar e información relevante {#1.4-datos-a-procesar-e-información-relevante}

El sistema procesa datos de 14 tablas distintas, que se dividen en dos grupos según cómo se procesan.

### 1.4.1 Datos transaccionales {#1.4.1-datos-transaccionales}

Son datos que se originan en las tareas del día a día del establecimiento. Crecen diariamente y se recorren por bloques para calcular deudas, atrasos y recaudaciones.

| Entidad | Atributos |
| :---- | :---- |
| PRESTAMO | id\_prestamo (PK), id\_socio (FK), id\_ejemplar (FK), id\_empleado (FK), fecha\_prestamo, fecha\_devolucion\_estimada, fecha\_devolucion\_real |
| MULTA | id\_multa (PK), id\_prestamo (FK), monto, pagada |
| ALIMENTACION | id\_alimentacion (PK), id\_socio (FK), id\_gato (FK), id\_alimento (FK), id\_empleado (FK), fecha, cantidad |
| EJEMPLAR | id\_ejemplar (PK), id\_libro (FK), estado, ubicacion |

### 1.4.2 Datos de referencia {#1.4.2-datos-de-referencia}

Cambian con poca frecuencia y se cruzan con los datos transaccionales para darle el contexto en cálculos y reportes.

| Entidad | Atributos |
| :---- | :---- |
| LIBRO | id\_libro (PK), isbn, titulo, anio\_publicacion, id\_editorial (FK), id\_categoria (FK) |
| AUTOR | id\_autor (PK), nombre, apellido, nacionalidad |
| LIBRO\_AUTOR | id\_libro\_autor (PK), id\_libro (FK), id\_autor (FK) |
| EDITORIAL | id\_editorial (PK), nombre, pais |
| CATEGORIA | id\_categoria (PK), nombre |
| SOCIO | id\_socio (PK), rut, nombre, apellido, email, telefono, direccion |
| EMPLEADO | id\_empleado (PK), rut, nombre, apellido, cargo |
| GATO | id\_gato (PK), nombre, sexo, color, fecha\_nacimiento, fecha\_llegada, id\_raza (FK) |
| RAZA  | id\_raza (PK), nombre |
| ALIMENTO | id\_alimento (PK), nombre, tipo, precio |

## 1.5 Información relevante a generar {#1.5-información-relevante-a-generar}

El sistema, después de la implementación de código PL/SQL, podrá generar la siguiente información: 

1. Listado de préstamos vencidos, con el socio, el libro y los días de atraso.  
2. Monto de la multa de cada préstamo atrasado  
3. Ejemplares disponibles, prestados, dañados o perdidos  
4. Monto a pagar por cada alimentación y recaudación total por periodos

## 1.6 Reglas de Negocio  {#1.6-reglas-de-negocio}

1. Los préstamos de los libros duran 7 días y corresponden solo a un ejemplar específico.  
2. Un ejemplar prestado, dañado o perdido no se puede volver a prestar.  
3. Si un socio se atrasa en la devolución de un libro, se genera una multa de \$500 por día de atraso.  
4. En cada visita, el socio puede comprar de 1 a 5 porciones. El monto a pagar se obtiene multiplicando las porciones por el precio del alimento elegido.

# 2\. Desarrollo de procedimientos y funciones {#2.-desarrollo-de-procedimientos-y-funciones}

## 2.1 Definición y características {#2.1-definición-y-características}

1. Procedimiento almacenado: Es un bloque PL/SQL con nombre, este se guarda en la base de datos y ejecuta una serie de acciones como consulta, inserción, actualización o muestra de datos. No devuelven un valor directamente a pesar de tener opcionalmente los parámetros.  
2. Función almacenada: Es un bloque PL/SQL que ejecuta un cálculo y siempre devuelve un valor, en caso de no modificar datos se puede usar dentro de sentencias SQL y también desde otros programas PL/SQL.

## 2.2 Ventajas y desventajas de cada uno {#2.2-ventajas-y-desventajas-de-cada-uno}

### 2.2.1 Ventajas {#2.2.1-ventajas}

1. Procedimientos: Centralizan procesos del negocio de forma completa, procesando grandes volúmenes de datos permitiendo manejar los errores con mensajes claros.  
2. Funciones: Permiten reutilizar una misma ejecución de código en muchas partes del sistema, entonces se evita guardar los datos calculados, respetando la tercera forma normal, entonces las modificaciones se mantienen solo donde ocurre el cambio y no salen de ahí.

### 2.2.2 Desventajas {#2.2.2-desventajas}

3. Procedimientos: No se pueden usar dentro de una sentencia SQL y en caso de tener mucha lógica puede ser difícil en cuanto a testeo y mantención.  
4. Funciones: Usadas sobre muchas filas en una consulta pueden volverla más lenta, no se deben modificar los datos si se quieren usar en sentencias SQL.  
 


## 

## 

## 

## 2.3 Propósito de procedimientos y funciones en el contexto del proyecto {#2.3-propósito-de-procedimientos-y-funciones-en-el-contexto-del-proyecto}

5. `FN_DIAS_ATRASO`: Permite saber cuantos dias lleva atrasado cada préstamo, tanto si está devuelto como no.  
6. `FN_CALCULAR_MULTA`: Asegura que la multa de \$500 por día se calcule siempre igual, sin errores a la hora de cobrar.  
7. `FN_TOTAL_ALIMENTACION:` Entrega el monto que debe pagar el socio según las porciones y el precio del alimento para los gatitos.  
8. `FN_TOTAL_MULTAS_PENDIENTES`: Informa a la administración cuánto dinero se le debe a la biblioteca en total, sin revisar cada multa por separado.  
9. `SP_GENERAR_MULTAS_MASIVO`: Recorre todos los préstamos atrasados y crea o actualiza sus multas de forma masiva.  
10. `SP_REPORTE_GESTION`: Entrega en un solo paso los préstamos vencidos, socios con deudas, recaudación por gato y libros más pedidos de un periodo.

## 2.4 Utilidad de procedimientos y funciones en el contexto del proyecto {#2.4-utilidad-de-procedimientos-y-funciones-en-el-contexto-del-proyecto}

1. Las funciones se implementan para ser usadas en sentencias SQL, como realizar un `SELECT` en `id_prestamo, fn_dias_atraso(id_prestamo)` para calcular atrasos de préstamos activos o consultar la deuda total desde la tabla.  
2. Los procedimientos se ejecutan (ej. `EXEC sp_generar_multas_masivo`) para actualizar las multas pendientes en el sistema o generar reportes parametrizados (ej. `EXEC sp_reporte_gestion(SYSDATE - 60, SYSDATE)`).

# 3\. Desarrollo de Packages {#3.-desarrollo-de-packages}

## 3.1 Definición y características {#3.1-definición-y-características}

1. Un package es un objeto que agrupa los procedimientos, funciones, variables y constantes relacionadas bajo una misma expresión.  
2. Posee una especificación, es decir, declara los elementos públicos utilizables desde afuera y un cuerpo que contiene el código y los elementos privados de uso interno.

## 3.2 Ventajas y desventajas al momento de utilizar Triggers {#3.2-ventajas-y-desventajas-al-momento-de-utilizar-triggers}

### 3.2.1 Ventajas {#3.2.1-ventajas}

Ordena el código por área del negocio, protege la lógica interna y mejora el rendimiento porque se carga por completo en la memoria la primera vez que se usa, de este modo impidiendo que los datos se llamen desde afuera debido a su condición de “privado”.

### 3.2.2 Desventajas {#3.2.2-desventajas}

Si se cambia la especificación, hay que compilar los objetos que dependen de él, y un package muy grande puede volverse difícil en cuanto a la mantención.

## 3.3 Cómo ayudan a organizar el código en el proyecto {#3.3-cómo-ayudan-a-organizar-el-código-en-el-proyecto}

1. Se crearon dos packages por área de negocio: `PKG_PRESTAMOS` para la gestión de préstamos como registros y devoluciones, por otro lado los `PKG_GATOS` para el servicio de alimentación.  
2. Las validaciones como `existe_negocio` o `existe_gat`o y constantes como los días de préstamo o límites de porciones que se dejaron como privadas para proteger las reglas de negocio y evitar un mal uso externo.

## 

## 

## 

## 3.4 Cómo se relacionan con los procedimientos y funciones {#3.4-cómo-se-relacionan-con-los-procedimientos-y-funciones}

Los packages no repiten los cálculos sino que consumen las funciones almacenadas previamente creadas, por ejemplo:

- `PKG_PRESTAMOS.registrar_devolucion` usa `FN_DIAS_ATRASO`  
- `PKG_GATOS.registrar_alimentacion` utiliza `FN_TOTAL_ALIMENTACION` para calcular los montos finales 

## 3.5 Cómo se utilizaron los packages en el proyecto {#3.5-cómo-se-utilizaron-los-packages-en-el-proyecto}

`1.PKG_PRESTAMOS`: Se implementó para unificar los subprogramas `SP_REGISTRAR_PRESTAMO` y `SP_DEVOLUCION_EJEMPLAR`, junto con las funciones `FN_DIAS_ATRASO` y `FN_CALCULAR_MULTA`. De esta forma, cualquier acción relacionada con un ejemplar se llama estructuradamente por ejemplo: `PKG_PRESTAMOS.SP_REGISTRAR_PRESTAMO.`

2.PKG\_GATOS: Se utilizó para agrupar el procedimiento de registro  
SP\_REGISTRAR\_ALIMENTACIÓN y la función FN\_TOTAL\_ALIMENTACIÓN. Además, dentro del cuerpo de este package se definieron como constantes privadas los límites de porciones (mínimo 1, máximo 5\) para que no puedan ser alteradas desde el exterior.

# 4\. Desarrollo de Triggers {#4.-desarrollo-de-triggers}

## 4.1 Definición y características {#4.1-definición-y-características}

1. Un trigger es un bloque PL/SQL asociado a una tabla que se ejecuta automáticamente cuando ocurre un evento sobre ella (INSERT, UPDATE o DELETE), ya sea antes (BEFORE) o después (AFTER) del evento.  
2. Trigger de sentencia: se ejecuta una sola vez por cada instrucción, sin importar cuántas filas afecte.  
3. Trigger de fila (FOR EACH ROW): se ejecuta una vez por cada fila afectada y puede leer los valores anteriores (:OLD) y nuevos (:NEW) de esa fila.

## 4.2 Ventajas y desventajas en la utilización de triggers {#4.2-ventajas-y-desventajas-en-la-utilización-de-triggers}

1. Ventajas: garantizan que las reglas del negocio se cumplan siempre, aunque los datos se modifiquen sin pasar por los procedimientos, y automatizan tareas como actualizar estados o registrar multas.  
2. Desventajas: actúan de forma "invisible", lo que puede dificultar encontrar errores. Además, no reaccionan al paso del tiempo, y un trigger de fila no puede consultar la misma tabla que lo dispara (error de tabla mutante, ORA-04091).

## 4.3 Propósito de los triggers en el contexto del proyecto {#4.3-propósito-de-los-triggers-en-el-contexto-del-proyecto}

En GatoTeca hay reglas que no pueden saltarse nunca: no prestar ejemplares no disponibles y cobrar siempre las devoluciones atrasadas. Los vencimientos de plazo se controlan en dos momentos: al devolver el libro (trigger) y en la revisión diaria de préstamos activos (procedimiento `SP_GENERAR_MULTAS_MASIVO`). 

## 4.4 Utilidad los triggers en el contexto del proyecto semestral {#4.4-utilidad-los-triggers-en-el-contexto-del-proyecto-semestral}

1. Al ejecutar `EXEC pkg_prestamos.registrar_prestamo(...)`, el trigger cambia el estado del objeto automáticamente sin intervención manual.  
2. Si se intenta ejecutar fuera del horario, el trigger a nivel de sentencia rechaza la inserción arrojando un error personalizado.

# 5\. Conclusión {#5.-conclusión}

## 5.1 Resumen {#5.1-resumen}

Se desarrolló una base de datos normalizada (3FN), con 14 tablas para poder gestionar de forma ordenada el catálogo de libros y el servicio de alimentación de gatos. De otro modo se integró PL/SQL creando funciones para cálculos, procedimientos para tareas masivas, packages para agrupar lógica de negocio, y triggers para asegurar integridad.

## 5.2 Impacto en el proyecto {#5.2-impacto-en-el-proyecto}

La biblioteca reduce de forma significativa el error humano, ahorra tiempo en tareas rutinarias como la generación de multas diarias o reportes, contando con información íntegra y confiable para la toma de decisiones al no guardar datos calculados redundantes.

## 5.3 Recomendaciones {#5.3-recomendaciones}

Como posibles mejoras o cómo se podría extender el uso de pl/sql

# 6\. Anexos {#6.-anexos}

## 6.1 Código completo {#6.1-código-completo}

## 6.2 Diagramas y modelos {#6.2-diagramas-y-modelos}