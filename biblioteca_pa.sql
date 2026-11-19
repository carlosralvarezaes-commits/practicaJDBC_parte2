-- =====================================================================
-- UD2 · Ejercicios guiados de procedimientos almacenados
-- Base de datos: biblioteca_pa (MySQL 8)
-- Ejecuta este script ANTES DE CADA EJERCICIO para partir siempre
-- del mismo estado inicial.
-- Las fechas se calculan a partir de hoy (CURDATE()), así que el
-- resultado es el mismo sea cual sea el día en que se ejecute.
-- =====================================================================

DROP DATABASE IF EXISTS biblioteca_pa;
CREATE DATABASE biblioteca_pa CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;
USE biblioteca_pa;

-- ---------------------------------------------------------------------
-- Tablas
-- ---------------------------------------------------------------------
CREATE TABLE socio (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    nombre     VARCHAR(80)  NOT NULL,
    email      VARCHAR(100) NOT NULL UNIQUE,
    bloqueado  BOOLEAN      NOT NULL DEFAULT FALSE
);

CREATE TABLE libro (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    titulo                  VARCHAR(100) NOT NULL,
    autor                   VARCHAR(80)  NOT NULL,
    ejemplares_disponibles  INT          NOT NULL,
    CONSTRAINT ck_libro_disponibles CHECK (ejemplares_disponibles >= 0)
);

CREATE TABLE prestamo (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    id_socio          INT  NOT NULL,
    id_libro          INT  NOT NULL,
    fecha_prestamo    DATE NOT NULL,
    fecha_limite      DATE NOT NULL,
    fecha_devolucion  DATE NULL,            -- NULL = todavía no devuelto
    renovaciones      INT  NOT NULL DEFAULT 0,
    CONSTRAINT fk_prestamo_socio FOREIGN KEY (id_socio) REFERENCES socio(id),
    CONSTRAINT fk_prestamo_libro FOREIGN KEY (id_libro) REFERENCES libro(id)
);

CREATE TABLE aviso (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    id_prestamo  INT  NOT NULL,
    fecha_aviso  DATE NOT NULL,
    CONSTRAINT fk_aviso_prestamo FOREIGN KEY (id_prestamo) REFERENCES prestamo(id)
);

-- ---------------------------------------------------------------------
-- Datos iniciales
-- ---------------------------------------------------------------------
INSERT INTO socio (nombre, email, bloqueado) VALUES
    ('Antía Varela',    'antia@biblioteca.gal',  FALSE),
    ('Bruno Lema',      'bruno@biblioteca.gal',  FALSE),
    ('Celia Mouriño',   'celia@biblioteca.gal',  FALSE),
    ('Damián Ferro',    'damian@biblioteca.gal', TRUE);    -- ya bloqueado

INSERT INTO libro (titulo, autor, ejemplares_disponibles) VALUES
    ('Memorias dun neno labrego', 'Xosé Neira Vilas',    0),
    ('La sombra del viento',      'Carlos Ruiz Zafón',   0),
    ('Don Quijote de la Mancha',  'Miguel de Cervantes', 1),
    ('Follas novas',              'Rosalía de Castro',   0);

INSERT INTO prestamo (id_socio, id_libro, fecha_prestamo, fecha_limite, fecha_devolucion, renovaciones) VALUES
    -- 1: Antía, en plazo, sin renovar
    (1, 1, CURDATE() - INTERVAL 10 DAY, CURDATE() + INTERVAL 5 DAY,  NULL, 0),
    -- 2: Bruno, VENCIDO hace 5 días
    (2, 2, CURDATE() - INTERVAL 25 DAY, CURDATE() - INTERVAL 5 DAY,  NULL, 0),
    -- 3: Celia, ya devuelto
    (3, 3, CURDATE() - INTERVAL 40 DAY, CURDATE() - INTERVAL 25 DAY, CURDATE() - INTERVAL 26 DAY, 0),
    -- 4: Celia, VENCIDO hace 2 días
    (3, 4, CURDATE() - INTERVAL 20 DAY, CURDATE() - INTERVAL 2 DAY,  NULL, 0),
    -- 5: Damián (bloqueado), VENCIDO hace 15 días
    (4, 3, CURDATE() - INTERVAL 30 DAY, CURDATE() - INTERVAL 15 DAY, NULL, 1),
    -- 6: Antía, en plazo, ya renovado 2 veces (máximo)
    (1, 3, CURDATE() - INTERVAL 5 DAY,  CURDATE() + INTERVAL 10 DAY, NULL, 2),
    -- 7: Celia, en plazo, sin renovar
    (3, 1, CURDATE() - INTERVAL 3 DAY,  CURDATE() + INTERVAL 12 DAY, NULL, 0);

-- ---------------------------------------------------------------------
-- Procedimientos almacenados
-- ---------------------------------------------------------------------
DELIMITER //

-- Ejercicio 1 · Solo parámetro de SALIDA
-- Bloquea a los socios no bloqueados que tengan algún préstamo vencido
-- sin devolver. Devuelve en p_bloqueados cuántos socios ha bloqueado.
CREATE PROCEDURE bloquear_morosos(OUT p_bloqueados INT)
BEGIN
    UPDATE socio
       SET bloqueado = TRUE
     WHERE bloqueado = FALSE
       AND id IN (SELECT id_socio
                    FROM prestamo
                   WHERE fecha_devolucion IS NULL
                     AND fecha_limite < CURDATE());
    SET p_bloqueados = ROW_COUNT();
END //

-- Ejercicio 2 · Un parámetro de ENTRADA y uno de SALIDA
-- Registra la devolución del préstamo p_id_prestamo: pone la fecha de
-- devolución a hoy y suma un ejemplar disponible al libro.
-- Devuelve en p_dias_retraso los días de retraso (0 si se devuelve en
-- plazo) o -1 si el préstamo no existe o ya estaba devuelto.
CREATE PROCEDURE devolver_libro(IN p_id_prestamo INT, OUT p_dias_retraso INT)
BEGIN
    DECLARE v_id_libro INT;
    DECLARE v_limite DATE;

    SET v_id_libro = (SELECT id_libro FROM prestamo
                       WHERE id = p_id_prestamo AND fecha_devolucion IS NULL);
    SET v_limite   = (SELECT fecha_limite FROM prestamo
                       WHERE id = p_id_prestamo AND fecha_devolucion IS NULL);

    IF v_id_libro IS NULL THEN
        SET p_dias_retraso = -1;
    ELSE
        UPDATE prestamo SET fecha_devolucion = CURDATE() WHERE id = p_id_prestamo;
        UPDATE libro SET ejemplares_disponibles = ejemplares_disponibles + 1
         WHERE id = v_id_libro;
        SET p_dias_retraso = GREATEST(DATEDIFF(CURDATE(), v_limite), 0);
    END IF;
END //

-- Ejercicio 3 · Parámetros de ENTRADA, ENTRADA/SALIDA y SALIDA
-- Renueva el préstamo p_id_prestamo.
--   p_dias (INOUT): entra con los días solicitados y sale con los días
--                   concedidos (máximo 15; 0 si se deniega).
--   p_nueva_fecha (OUT): fecha límite tras la renovación (si se deniega,
--                   la fecha límite actual; NULL si el préstamo no existe
--                   o ya está devuelto).
-- Se deniega si: el préstamo no existe o está devuelto, ya está vencido,
-- ya se ha renovado 2 veces, el socio está bloqueado o se piden 0 días.
CREATE PROCEDURE renovar_prestamo(IN p_id_prestamo INT,
                                  INOUT p_dias INT,
                                  OUT p_nueva_fecha DATE)
BEGIN
    DECLARE v_limite DATE;
    DECLARE v_renovaciones INT;
    DECLARE v_bloqueado BOOLEAN;

    SET v_limite = (SELECT fecha_limite FROM prestamo
                     WHERE id = p_id_prestamo AND fecha_devolucion IS NULL);
    SET v_renovaciones = (SELECT renovaciones FROM prestamo
                           WHERE id = p_id_prestamo);
    SET v_bloqueado = (SELECT s.bloqueado FROM socio s
                         JOIN prestamo p ON p.id_socio = s.id
                        WHERE p.id = p_id_prestamo);

    IF v_limite IS NULL
       OR v_limite < CURDATE()
       OR v_renovaciones >= 2
       OR v_bloqueado
       OR IFNULL(p_dias, 0) <= 0 THEN
        SET p_dias = 0;
        SET p_nueva_fecha = v_limite;
    ELSE
        SET p_dias = LEAST(p_dias, 15);
        SET p_nueva_fecha = v_limite + INTERVAL p_dias DAY;
        UPDATE prestamo
           SET fecha_limite = p_nueva_fecha,
               renovaciones = renovaciones + 1
         WHERE id = p_id_prestamo;
    END IF;
END //

-- Ejercicio 4 · Parámetros IN, INOUT y OUT + devuelve FILAS (ResultSet)
-- Avisa al socio p_id_socio de sus préstamos sin devolver que vencen en
-- los próximos p_dias días (o que ya están vencidos):
--   p_dias (INOUT): entra con la ventana de días pedida y sale con la
--                   aplicada (si es NULL o < 1 se usan 7; como máximo 30).
--   p_vencidos (OUT): préstamos del socio ya vencidos sin devolver
--                   (-1 si el socio no existe).
-- Registra un aviso en la tabla aviso por cada préstamo de la lista y
-- termina con un SELECT que devuelve esa lista, ordenada por fecha límite.
CREATE PROCEDURE avisar_vencimientos(IN p_id_socio INT,
                                     INOUT p_dias INT,
                                     OUT p_vencidos INT)
BEGIN
    IF p_dias IS NULL OR p_dias < 1 THEN
        SET p_dias = 7;
    ELSEIF p_dias > 30 THEN
        SET p_dias = 30;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM socio WHERE id = p_id_socio) THEN
        SET p_vencidos = -1;
    ELSE
        INSERT INTO aviso (id_prestamo, fecha_aviso)
        SELECT id, CURDATE()
          FROM prestamo
         WHERE id_socio = p_id_socio
           AND fecha_devolucion IS NULL
           AND fecha_limite <= CURDATE() + INTERVAL p_dias DAY;

        SET p_vencidos = (SELECT COUNT(*) FROM prestamo
                           WHERE id_socio = p_id_socio
                             AND fecha_devolucion IS NULL
                             AND fecha_limite < CURDATE());
    END IF;

    SELECT p.id, l.titulo, p.fecha_limite,
           DATEDIFF(p.fecha_limite, CURDATE()) AS dias_restantes
      FROM prestamo p
      JOIN libro l ON l.id = p.id_libro
     WHERE p.id_socio = p_id_socio
       AND p.fecha_devolucion IS NULL
       AND p.fecha_limite <= CURDATE() + INTERVAL p_dias DAY
     ORDER BY p.fecha_limite;
END //

DELIMITER ;

-- ---------------------------------------------------------------------
-- Pruebas rápidas desde MySQL Workbench (opcional)
-- ---------------------------------------------------------------------
-- CALL bloquear_morosos(@n);            SELECT @n;
-- CALL devolver_libro(2, @r);           SELECT @r;
-- SET @d = 7; CALL renovar_prestamo(1, @d, @f); SELECT @d, @f;
-- SET @v = 10; CALL avisar_vencimientos(1, @v, @x); SELECT @v, @x;
