-- =====================================================
--  BASE DE DATOS GATOTECA (3FN) - ORACLE
-- =====================================================

-- -----------------------------------------------------
-- 0. LIMPIEZA (permite ejecutar el script varias veces)
-- -----------------------------------------------------
BEGIN
  FOR t IN (SELECT table_name FROM user_tables
            WHERE table_name IN ('ALIMENTACION','ALIMENTO','GATO','RAZA','MULTA','PRESTAMO','EJEMPLAR','LIBRO_AUTOR','LIBRO',
                                 'SOCIO','EMPLEADO','AUTOR','CATEGORIA','EDITORIAL')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
  END LOOP;
END;
/

-- -----------------------------------------------------
-- 1. TABLAS
-- -----------------------------------------------------
CREATE TABLE editorial (
  id_editorial  NUMBER(5)     CONSTRAINT pk_editorial PRIMARY KEY,
  nombre        VARCHAR2(80)  NOT NULL,
  pais          VARCHAR2(50)  NOT NULL,
  CONSTRAINT uq_editorial_nombre UNIQUE (nombre)
);

CREATE TABLE categoria (
  id_categoria  NUMBER(5)     CONSTRAINT pk_categoria PRIMARY KEY,
  nombre        VARCHAR2(50)  NOT NULL,
  CONSTRAINT uq_categoria_nombre UNIQUE (nombre)
);

CREATE TABLE autor (
  id_autor      NUMBER(5)     CONSTRAINT pk_autor PRIMARY KEY,
  nombre        VARCHAR2(50)  NOT NULL,
  apellido      VARCHAR2(50)  NOT NULL,
  nacionalidad  VARCHAR2(50)
);

CREATE TABLE libro (
  id_libro          NUMBER(6)     CONSTRAINT pk_libro PRIMARY KEY,
  isbn              VARCHAR2(13)  NOT NULL,
  titulo            VARCHAR2(150) NOT NULL,
  anio_publicacion  NUMBER(4),
  id_editorial      NUMBER(5)     NOT NULL,
  id_categoria      NUMBER(5)     NOT NULL,
  CONSTRAINT fk_libro_editorial FOREIGN KEY (id_editorial) REFERENCES editorial(id_editorial),
  CONSTRAINT fk_libro_categoria FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria),
  CONSTRAINT uq_libro_isbn UNIQUE (isbn),
  CONSTRAINT ck_libro_anio CHECK (anio_publicacion BETWEEN 1450 AND 2100)
);

CREATE TABLE libro_autor (
  id_libro_autor  NUMBER(6)  CONSTRAINT pk_libro_autor PRIMARY KEY,
  id_libro        NUMBER(6)  NOT NULL,
  id_autor        NUMBER(5)  NOT NULL,
  CONSTRAINT fk_la_libro FOREIGN KEY (id_libro) REFERENCES libro(id_libro),
  CONSTRAINT fk_la_autor FOREIGN KEY (id_autor) REFERENCES autor(id_autor),
  CONSTRAINT uq_libro_autor UNIQUE (id_libro, id_autor)
);

CREATE TABLE ejemplar (
  id_ejemplar  NUMBER(6)     CONSTRAINT pk_ejemplar PRIMARY KEY,
  id_libro     NUMBER(6)     NOT NULL,
  estado       VARCHAR2(12)  DEFAULT 'DISPONIBLE' NOT NULL,
  ubicacion    VARCHAR2(20),
  CONSTRAINT fk_ejemplar_libro FOREIGN KEY (id_libro) REFERENCES libro(id_libro),
  CONSTRAINT ck_ejemplar_estado CHECK (estado IN ('DISPONIBLE','PRESTADO','DANADO','PERDIDO'))
);

CREATE TABLE socio (
  id_socio   NUMBER(6)     CONSTRAINT pk_socio PRIMARY KEY,
  rut        VARCHAR2(12)  NOT NULL,
  nombre     VARCHAR2(50)  NOT NULL,
  apellido   VARCHAR2(50)  NOT NULL,
  email      VARCHAR2(100),
  telefono   VARCHAR2(15),
  direccion  VARCHAR2(120),
  CONSTRAINT uq_socio_rut UNIQUE (rut)
);

CREATE TABLE empleado (
  id_empleado  NUMBER(5)     CONSTRAINT pk_empleado PRIMARY KEY,
  rut          VARCHAR2(12)  NOT NULL,
  nombre       VARCHAR2(50)  NOT NULL,
  apellido     VARCHAR2(50)  NOT NULL,
  cargo        VARCHAR2(40)  NOT NULL,
  CONSTRAINT uq_empleado_rut UNIQUE (rut)
);

CREATE TABLE prestamo (
  id_prestamo                NUMBER(8)  CONSTRAINT pk_prestamo PRIMARY KEY,
  id_socio                   NUMBER(6)  NOT NULL,
  id_ejemplar                NUMBER(6)  NOT NULL,
  id_empleado                NUMBER(5)  NOT NULL,
  fecha_prestamo             DATE       DEFAULT SYSDATE NOT NULL,
  fecha_devolucion_estimada  DATE       NOT NULL,
  fecha_devolucion_real      DATE,
  CONSTRAINT fk_prestamo_socio    FOREIGN KEY (id_socio)    REFERENCES socio(id_socio),
  CONSTRAINT fk_prestamo_ejemplar FOREIGN KEY (id_ejemplar) REFERENCES ejemplar(id_ejemplar),
  CONSTRAINT fk_prestamo_empleado FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado),
  CONSTRAINT ck_prestamo_fechas CHECK (fecha_devolucion_estimada > fecha_prestamo)
);

CREATE TABLE multa (
  id_multa     NUMBER(8)  CONSTRAINT pk_multa PRIMARY KEY,
  id_prestamo  NUMBER(8)  NOT NULL,
  monto        NUMBER(8)  NOT NULL,
  pagada       CHAR(1)    DEFAULT 'N' NOT NULL,
  CONSTRAINT fk_multa_prestamo FOREIGN KEY (id_prestamo) REFERENCES prestamo(id_prestamo),
  CONSTRAINT uq_multa_prestamo UNIQUE (id_prestamo),
  CONSTRAINT ck_multa_monto  CHECK (monto > 0),
  CONSTRAINT ck_multa_pagada CHECK (pagada IN ('S','N'))
);


-- ---------- GATOS ----------
CREATE TABLE raza (
  id_raza  NUMBER(3)     CONSTRAINT pk_raza PRIMARY KEY,
  nombre   VARCHAR2(50)  NOT NULL,
  CONSTRAINT uq_raza_nombre UNIQUE (nombre)
);

CREATE TABLE gato (
  id_gato           NUMBER(5)     CONSTRAINT pk_gato PRIMARY KEY,
  nombre            VARCHAR2(40)  NOT NULL,
  sexo              CHAR(1)       NOT NULL,
  color             VARCHAR2(40),
  fecha_nacimiento  DATE,
  fecha_llegada     DATE          NOT NULL,
  id_raza           NUMBER(3)     NOT NULL,
  CONSTRAINT fk_gato_raza FOREIGN KEY (id_raza) REFERENCES raza(id_raza),
  CONSTRAINT ck_gato_sexo CHECK (sexo IN ('M','H'))
);

-- Tipos de comida que vende la Gatoteca
CREATE TABLE alimento (
  id_alimento  NUMBER(4)     CONSTRAINT pk_alimento PRIMARY KEY,
  nombre       VARCHAR2(60)  NOT NULL,
  tipo         VARCHAR2(10)  NOT NULL,
  precio       NUMBER(6)     NOT NULL,
  CONSTRAINT uq_alimento_nombre UNIQUE (nombre),
  CONSTRAINT ck_alimento_tipo   CHECK (tipo IN ('SECO','HUMEDO','SNACK')),
  CONSTRAINT ck_alimento_precio CHECK (precio > 0)
);

-- Cada vez que un socio paga por darle comida a un gato
CREATE TABLE alimentacion (
  id_alimentacion  NUMBER(8)  CONSTRAINT pk_alimentacion PRIMARY KEY,
  id_socio         NUMBER(6)  NOT NULL,
  id_gato          NUMBER(5)  NOT NULL,
  id_alimento      NUMBER(4)  NOT NULL,
  id_empleado      NUMBER(5)  NOT NULL,
  fecha            DATE       DEFAULT SYSDATE NOT NULL,
  cantidad         NUMBER(2)  NOT NULL,
  CONSTRAINT fk_alim_socio    FOREIGN KEY (id_socio)    REFERENCES socio(id_socio),
  CONSTRAINT fk_alim_gato     FOREIGN KEY (id_gato)     REFERENCES gato(id_gato),
  CONSTRAINT fk_alim_alimento FOREIGN KEY (id_alimento) REFERENCES alimento(id_alimento),
  CONSTRAINT fk_alim_empleado FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado),
  CONSTRAINT ck_alim_cantidad CHECK (cantidad BETWEEN 1 AND 5)
);

-- -----------------------------------------------------
-- 2. DATOS DE PRUEBA (minimo 10 por tabla)
-- -----------------------------------------------------

-- EDITORIAL (ids 1..10)
INSERT INTO editorial VALUES (1, 'Sudamericana', 'Argentina');
INSERT INTO editorial VALUES (2, 'Penguin Random House', 'Estados Unidos');
INSERT INTO editorial VALUES (3, 'Editorial Universitaria', 'Chile');
INSERT INTO editorial VALUES (4, 'Planeta', 'Espana');
INSERT INTO editorial VALUES (5, 'Alfaguara', 'Espana');
INSERT INTO editorial VALUES (6, 'Anagrama', 'Espana');
INSERT INTO editorial VALUES (7, 'Zig-Zag', 'Chile');
INSERT INTO editorial VALUES (8, 'LOM Ediciones', 'Chile');
INSERT INTO editorial VALUES (9, 'Pearson', 'Reino Unido');
INSERT INTO editorial VALUES (10, 'O''Reilly Media', 'Estados Unidos');

-- CATEGORIA (ids 1..10)
INSERT INTO categoria VALUES (1, 'Novela');
INSERT INTO categoria VALUES (2, 'Poesia');
INSERT INTO categoria VALUES (3, 'Ciencia Ficcion');
INSERT INTO categoria VALUES (4, 'Informatica');
INSERT INTO categoria VALUES (5, 'Historia');
INSERT INTO categoria VALUES (6, 'Fantasia');
INSERT INTO categoria VALUES (7, 'Cuento');
INSERT INTO categoria VALUES (8, 'Ensayo');
INSERT INTO categoria VALUES (9, 'Terror');
INSERT INTO categoria VALUES (10, 'Infantil');

-- AUTOR (ids 1..13)
INSERT INTO autor VALUES (1, 'Gabriel', 'Garcia Marquez', 'Colombiana');
INSERT INTO autor VALUES (2, 'Isabel', 'Allende', 'Chilena');
INSERT INTO autor VALUES (3, 'Pablo', 'Neruda', 'Chilena');
INSERT INTO autor VALUES (4, 'Isaac', 'Asimov', 'Estadounidense');
INSERT INTO autor VALUES (5, 'Robert', 'Martin', 'Estadounidense');
INSERT INTO autor VALUES (6, 'Micah', 'Martin', 'Estadounidense');
INSERT INTO autor VALUES (7, 'Gabriela', 'Mistral', 'Chilena');
INSERT INTO autor VALUES (8, 'Julio', 'Cortazar', 'Argentina');
INSERT INTO autor VALUES (9, 'Stephen', 'King', 'Estadounidense');
INSERT INTO autor VALUES (10, 'J.R.R.', 'Tolkien', 'Britanica');
INSERT INTO autor VALUES (11, 'Jorge Luis', 'Borges', 'Argentina');
INSERT INTO autor VALUES (12, 'Antoine', 'de Saint-Exupery', 'Francesa');
INSERT INTO autor VALUES (13, 'Yuval Noah', 'Harari', 'Israeli');

-- LIBRO (13 libros)
INSERT INTO libro VALUES (1, '9780307474728', 'Cien anos de soledad',     1967, 1, 1);
INSERT INTO libro VALUES (2, '9780525433477', 'La casa de los espiritus', 1982, 2, 1);
INSERT INTO libro VALUES (3, '9789561119270', 'Veinte poemas de amor',    1924, 3, 2);
INSERT INTO libro VALUES (4, '9780553293357', 'Fundacion',                1951, 2, 3);
INSERT INTO libro VALUES (5, '9780131857254', 'Agile Principles in C#',   2006, 9, 4);
INSERT INTO libro VALUES (6, '9789561124571', 'Desolacion',               1922, 7, 2);
INSERT INTO libro VALUES (7, '9788420437484', 'Rayuela',                  1963, 5, 1);
INSERT INTO libro VALUES (8, '9788497593793', 'It',                       1986, 2, 9);
INSERT INTO libro VALUES (9, '9788445000663', 'El Senor de los Anillos',  1954, 4, 6);
INSERT INTO libro VALUES (10, '9788499089515', 'Ficciones',                1944, 1, 7);
INSERT INTO libro VALUES (11, '9788498381498', 'El Principito',            1943, 7, 10);
INSERT INTO libro VALUES (12, '9788499926223', 'Sapiens',                  2011, 4, 5);
INSERT INTO libro VALUES (13, '9780132350884', 'Clean Code',               2008, 9, 4);

-- LIBRO_AUTOR (14 filas; 'Agile Principles' tiene 2 autores y Robert Martin tiene 2 libros -> N:M)
INSERT INTO libro_autor VALUES (1, 1, 1);
INSERT INTO libro_autor VALUES (2, 2, 2);
INSERT INTO libro_autor VALUES (3, 3, 3);
INSERT INTO libro_autor VALUES (4, 4, 4);
INSERT INTO libro_autor VALUES (5, 5, 5);
INSERT INTO libro_autor VALUES (6, 5, 6);
INSERT INTO libro_autor VALUES (7, 6, 7);
INSERT INTO libro_autor VALUES (8, 7, 8);
INSERT INTO libro_autor VALUES (9, 8, 9);
INSERT INTO libro_autor VALUES (10, 9, 10);
INSERT INTO libro_autor VALUES (11, 10, 11);
INSERT INTO libro_autor VALUES (12, 11, 12);
INSERT INTO libro_autor VALUES (13, 12, 13);
INSERT INTO libro_autor VALUES (14, 13, 5);

-- EJEMPLAR (ids 1..20). Los PRESTADO coinciden con los prestamos activos (12 a 15)
INSERT INTO ejemplar VALUES (1, 1, 'PRESTADO',   'A-01');
INSERT INTO ejemplar VALUES (2, 1, 'DISPONIBLE', 'A-01');
INSERT INTO ejemplar VALUES (3, 2, 'PRESTADO',   'A-02');
INSERT INTO ejemplar VALUES (4, 3, 'DISPONIBLE', 'B-01');
INSERT INTO ejemplar VALUES (5, 4, 'DISPONIBLE', 'C-01');
INSERT INTO ejemplar VALUES (6, 4, 'DANADO',     'C-01');
INSERT INTO ejemplar VALUES (7, 5, 'DISPONIBLE', 'D-01');
INSERT INTO ejemplar VALUES (8, 6, 'DISPONIBLE', 'B-02');
INSERT INTO ejemplar VALUES (9, 7, 'DISPONIBLE', 'A-03');
INSERT INTO ejemplar VALUES (10, 8, 'DISPONIBLE', 'E-01');
INSERT INTO ejemplar VALUES (11, 9, 'PRESTADO',   'F-01');
INSERT INTO ejemplar VALUES (12, 9, 'DISPONIBLE', 'F-01');
INSERT INTO ejemplar VALUES (13, 10, 'DISPONIBLE', 'G-01');
INSERT INTO ejemplar VALUES (14, 11, 'DISPONIBLE', 'H-01');
INSERT INTO ejemplar VALUES (15, 12, 'DISPONIBLE', 'I-01');
INSERT INTO ejemplar VALUES (16, 13, 'PRESTADO',   'D-02');
INSERT INTO ejemplar VALUES (17, 13, 'DISPONIBLE', 'D-02');
INSERT INTO ejemplar VALUES (18, 2, 'PERDIDO',    'A-02');
INSERT INTO ejemplar VALUES (19, 7, 'DISPONIBLE', 'A-03');
INSERT INTO ejemplar VALUES (20, 11, 'DISPONIBLE', 'H-01');

-- SOCIO (ids 1..12)
INSERT INTO socio VALUES (1, '12345678-9', 'Camila',    'Rojas',     'camila.rojas@mail.com',    '912345678', 'Av. Principal 123');
INSERT INTO socio VALUES (2, '15678901-2', 'Diego',     'Soto',      'diego.soto@mail.com',      '923456789', 'Los Aromos 456');
INSERT INTO socio VALUES (3, '18901234-5', 'Valentina', 'Munoz',     'vale.munoz@mail.com',      '934567890', 'Pasaje Sur 78');
INSERT INTO socio VALUES (4, '20123456-7', 'Matias',    'Perez',     'matias.perez@mail.com',    '945678901', 'Calle Norte 910');
INSERT INTO socio VALUES (5, '16234567-8', 'Fernanda',  'Gonzalez',  'fer.gonzalez@mail.com',    '956789012', 'Los Olmos 234');
INSERT INTO socio VALUES (6, '17345678-K', 'Benjamin',  'Silva',     'benja.silva@mail.com',     '967890123', 'Av. Libertad 1500');
INSERT INTO socio VALUES (7, '19456789-1', 'Antonia',   'Contreras', 'anto.contreras@mail.com',  '978901234', 'Las Rosas 67');
INSERT INTO socio VALUES (8, '14567890-3', 'Tomas',     'Vargas',    'tomas.vargas@mail.com',    '989012345', 'Pje. Los Pinos 12');
INSERT INTO socio VALUES (9, '21678901-4', 'Josefa',    'Fuentes',   'josefa.fuentes@mail.com',  '990123456', 'Av. Central 880');
INSERT INTO socio VALUES (10, '13789012-6', 'Sebastian', 'Reyes',     'seba.reyes@mail.com',      '901234567', 'El Roble 345');
INSERT INTO socio VALUES (11, '22890123-5', 'Martina',   'Castro',    'martina.castro@mail.com',  '913579246', 'Los Canelos 91');
INSERT INTO socio VALUES (12, '11901234-7', 'Nicolas',   'Herrera',   'nico.herrera@mail.com',    '924681357', 'Av. Estacion 202');

-- EMPLEADO (ids 1..10)
INSERT INTO empleado VALUES (1, '11222333-4', 'Carolina', 'Diaz',     'Bibliotecaria Jefa');
INSERT INTO empleado VALUES (2, '13444555-6', 'Felipe',   'Lopez',    'Asistente');
INSERT INTO empleado VALUES (3, '14555666-7', 'Paula',    'Morales',  'Bibliotecaria');
INSERT INTO empleado VALUES (4, '15666777-8', 'Ignacio',  'Torres',   'Asistente');
INSERT INTO empleado VALUES (5, '16777888-9', 'Daniela',  'Araya',    'Bibliotecaria');
INSERT INTO empleado VALUES (6, '17888999-0', 'Cristobal','Navarro',  'Asistente');
INSERT INTO empleado VALUES (7, '18999000-1', 'Javiera',  'Espinoza', 'Encargada de Catalogo');
INSERT INTO empleado VALUES (8, '12111222-3', 'Rodrigo',  'Sepulveda','Asistente');
INSERT INTO empleado VALUES (9, '19222333-K', 'Catalina', 'Pizarro',  'Bibliotecaria');
INSERT INTO empleado VALUES (10, '20333444-5', 'Joaquin',  'Carrasco', 'Asistente');

-- PRESTAMO (ids 1..15). Todos los prestamos son por 7 dias.
-- 1: devuelto a tiempo
INSERT INTO prestamo VALUES (1, 1,  4,  1, SYSDATE-30, SYSDATE-23, SYSDATE-25);
-- 2 a 11: devueltos con atraso (cada uno tiene multa)
INSERT INTO prestamo VALUES (2, 2,  5,  2, SYSDATE-60, SYSDATE-53, SYSDATE-48); -- 5 dias
INSERT INTO prestamo VALUES (3, 3,  7,  3, SYSDATE-58, SYSDATE-51, SYSDATE-49); -- 2 dias
INSERT INTO prestamo VALUES (4, 4,  9,  1, SYSDATE-55, SYSDATE-48, SYSDATE-40); -- 8 dias
INSERT INTO prestamo VALUES (5, 5,  10, 4, SYSDATE-50, SYSDATE-43, SYSDATE-42); -- 1 dia
INSERT INTO prestamo VALUES (6, 6,  13, 5, SYSDATE-47, SYSDATE-40, SYSDATE-30); -- 10 dias
INSERT INTO prestamo VALUES (7, 7,  14, 2, SYSDATE-45, SYSDATE-38, SYSDATE-35); -- 3 dias
INSERT INTO prestamo VALUES (8, 8,  15, 6, SYSDATE-40, SYSDATE-33, SYSDATE-27); -- 6 dias
INSERT INTO prestamo VALUES (9, 9,  8,  7, SYSDATE-35, SYSDATE-28, SYSDATE-24); -- 4 dias
INSERT INTO prestamo VALUES (10, 10, 12, 8, SYSDATE-30, SYSDATE-23, SYSDATE-16); -- 7 dias
INSERT INTO prestamo VALUES (11, 11, 19, 9, SYSDATE-25, SYSDATE-18, SYSDATE-16); -- 2 dias
-- 12 y 13: activos y atrasados (sin multa todavia -> para calcularla con PL/SQL)
INSERT INTO prestamo VALUES (12, 12, 1,  10, SYSDATE-15, SYSDATE-8, NULL);
INSERT INTO prestamo VALUES (13, 3,  11, 1,  SYSDATE-12, SYSDATE-5, NULL);
-- 14 y 15: activos y al dia
INSERT INTO prestamo VALUES (14, 1,  3,  2, SYSDATE-3, SYSDATE+4, NULL);
INSERT INTO prestamo VALUES (15, 5,  16, 3, SYSDATE-1, SYSDATE+6, NULL);

-- MULTA (ids 1..10). Regla: $500 por dia de atraso
INSERT INTO multa VALUES (1, 2,  2500, 'S');
INSERT INTO multa VALUES (2, 3,  1000, 'S');
INSERT INTO multa VALUES (3, 4,  4000, 'N');
INSERT INTO multa VALUES (4, 5,  500,  'S');
INSERT INTO multa VALUES (5, 6,  5000, 'N');
INSERT INTO multa VALUES (6, 7,  1500, 'S');
INSERT INTO multa VALUES (7, 8,  3000, 'N');
INSERT INTO multa VALUES (8, 9,  2000, 'S');
INSERT INTO multa VALUES (9, 10, 3500, 'N');
INSERT INTO multa VALUES (10, 11, 1000, 'N');

-- RAZA (ids 1..10)
INSERT INTO raza VALUES (1,  'Mestizo');
INSERT INTO raza VALUES (2,  'Siames');
INSERT INTO raza VALUES (3,  'Persa');
INSERT INTO raza VALUES (4,  'Maine Coon');
INSERT INTO raza VALUES (5,  'Angora');
INSERT INTO raza VALUES (6,  'Bengali');
INSERT INTO raza VALUES (7,  'Ragdoll');
INSERT INTO raza VALUES (8,  'Azul Ruso');
INSERT INTO raza VALUES (9,  'British Shorthair');
INSERT INTO raza VALUES (10, 'Sphynx');

-- GATO (ids 1..12)
INSERT INTO gato VALUES (1,  'Nana',        'H', 'Atigrado Blanco',  DATE '2019-03-12', DATE '2021-05-01', 1);
INSERT INTO gato VALUES (2,  'Trex',        'M', 'Blanco',           DATE '2020-07-22', DATE '2021-05-01', 5);
INSERT INTO gato VALUES (3,  'Amira',       'H', 'Negro con Blanco', DATE '2018-11-02', DATE '2021-08-15', 1);
INSERT INTO gato VALUES (4,  'Pandora',     'H', 'Carey Negro',      DATE '2021-01-30', DATE '2022-02-10', 1);
INSERT INTO gato VALUES (5,  'Naruto',      'M', 'Blanco',           DATE '2020-04-18', DATE '2022-06-20', 8);
INSERT INTO gato VALUES (6,  'Huachimingo', 'M', 'Negro',            DATE '2022-09-05', DATE '2023-01-12', 1);
INSERT INTO gato VALUES (7,  'Molly',       'H', 'Americano',        DATE '2021-06-14', DATE '2023-03-03', 1);
INSERT INTO gato VALUES (8,  'Canela',      'H', 'Tricolor',         DATE '2022-02-27', DATE '2023-07-19', 2);
INSERT INTO gato VALUES (9,  'Morocha',     'H', 'Azul Ruso',        DATE '2019-12-01', DATE '2023-10-08', 4);
INSERT INTO gato VALUES (10, 'Maki',        'H', 'Carey Gris',       DATE '2023-04-10', DATE '2024-01-25', 3);
INSERT INTO gato VALUES (11, 'Cortazar',    'M', 'Blanco y negro',   DATE '2022-08-19', DATE '2024-05-30', 9);
INSERT INTO gato VALUES (12, 'Jaspeao',     'H', 'Naranjo atigrado', DATE '2024-02-14', DATE '2025-03-01', 6);

-- ALIMENTO (precio por porcion)
INSERT INTO alimento VALUES (1,  'Croquetas Adulto',    'SECO',   1000);
INSERT INTO alimento VALUES (2,  'Croquetas Gatito',    'SECO',   1200);
INSERT INTO alimento VALUES (3,  'Croquetas Light',     'SECO',   1100);
INSERT INTO alimento VALUES (4,  'Pate de Pollo',       'HUMEDO', 1500);
INSERT INTO alimento VALUES (5,  'Pate de Atun',        'HUMEDO', 1600);
INSERT INTO alimento VALUES (6,  'Sobre de Salmon',     'HUMEDO', 1800);
INSERT INTO alimento VALUES (7,  'Sobre de Pavo',       'HUMEDO', 1700);
INSERT INTO alimento VALUES (8,  'Snack de Atun',       'SNACK',  800);
INSERT INTO alimento VALUES (9,  'Barrita Cremosa',     'SNACK',  900);
INSERT INTO alimento VALUES (10, 'Galletas de Pescado', 'SNACK',  700);

-- ALIMENTACION (socio, gato, alimento, empleado, fecha, cantidad)
INSERT INTO alimentacion VALUES (1,  1,  1,  4,  1,  SYSDATE-20, 1);
INSERT INTO alimentacion VALUES (2,  2,  1,  8,  2,  SYSDATE-19, 2);
INSERT INTO alimentacion VALUES (3,  3,  2,  5,  3,  SYSDATE-18, 1);
INSERT INTO alimentacion VALUES (4,  4,  3,  1,  4,  SYSDATE-16, 1);
INSERT INTO alimentacion VALUES (5,  5,  4,  9,  5,  SYSDATE-15, 3);
INSERT INTO alimentacion VALUES (6,  6,  5,  6,  6,  SYSDATE-13, 1);
INSERT INTO alimentacion VALUES (7,  7,  6,  10, 7,  SYSDATE-12, 2);
INSERT INTO alimentacion VALUES (8,  8,  8,  2,  8,  SYSDATE-10, 1);
INSERT INTO alimentacion VALUES (9,  9,  9,  7,  9,  SYSDATE-9,  2);
INSERT INTO alimentacion VALUES (10, 10, 10, 8,  10, SYSDATE-7,  1);
INSERT INTO alimentacion VALUES (11, 11, 11, 3,  1,  SYSDATE-5,  1);
INSERT INTO alimentacion VALUES (12, 12, 12, 2,  2,  SYSDATE-4,  2);
INSERT INTO alimentacion VALUES (13, 1,  12, 5,  3,  SYSDATE-3,  1);
INSERT INTO alimentacion VALUES (14, 3,  7,  9,  4,  SYSDATE-2,  2);
INSERT INTO alimentacion VALUES (15, 1,  1,  6,  5,  SYSDATE-1,  1);

COMMIT;
