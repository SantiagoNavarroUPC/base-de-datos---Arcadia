-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: db
-- Tiempo de generación: 28-10-2024 a las 14:47:04
-- Versión del servidor: 9.0.1
-- Versión de PHP: 8.2.8

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `acreditacion_arcadia`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `autoevaluaciones`
--

CREATE TABLE `autoevaluaciones` (
  `autoevaluacion_id` int NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `programa_id` int NOT NULL,
  `modelo_id` int NOT NULL,
  `user_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_final` date NOT NULL,
  `estado` enum('activo','inactivo') DEFAULT 'activo' COMMENT 'Estado de la tabla: activo o inactivo',
  `fecha_modificacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Fecha de la última modificación',
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `autoevaluaciones`
--

INSERT INTO `autoevaluaciones` (`autoevaluacion_id`, `nombre`, `programa_id`, `modelo_id`, `user_id`, `fecha_inicio`, `fecha_final`, `estado`, `fecha_modificacion`, `fecha_creacion`) VALUES
(1, 'Autoevaluación Programa Administración', 1, 1, 'admin123', '2024-01-01', '2024-06-01', 'activo', '2024-10-28 14:34:50', '2024-09-20 18:42:36');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calificacion_caracteristica`
--

CREATE TABLE `calificacion_caracteristica` (
  `calificacion_caracteristica_id` int NOT NULL,
  `caracteristica_id` int NOT NULL,
  `justificacion` text,
  `resultado` decimal(5,2) DEFAULT NULL,
  `ponderacion` float DEFAULT NULL,
  `calificacion_factor_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `calificacion_caracteristica`
--

INSERT INTO `calificacion_caracteristica` (`calificacion_caracteristica_id`, `caracteristica_id`, `justificacion`, `resultado`, `ponderacion`, `calificacion_factor_id`) VALUES
(1, 1, 'Cumple parcialmente con los requisitos', 3.00, 20, 1),
(2, 2, 'Satisface las expectativas', 3.67, 30, 1),
(3, 3, 'Proyecto educativo del programa e identidad institucional', 3.00, 5, 2),
(4, 4, 'Relevancia académica y pertinencia social del programa académico', 3.00, 10, 2),
(5, 5, 'Participación en actividades de formación integral', 4.00, 2, 2),
(6, 6, 'Orientación y seguimiento a estudiantes', 3.00, 25, 2),
(7, 7, 'Capacidad de trabajo autónomo', 3.50, 8, 2);

--
-- Disparadores `calificacion_caracteristica`
--
DELIMITER $$
CREATE TRIGGER `actualizar_resultado_factor_insert` AFTER INSERT ON `calificacion_caracteristica` FOR EACH ROW BEGIN
    DECLARE resultado_total DECIMAL(5, 2);
    SET resultado_total = (
        SELECT SUM(c.resultado * c.ponderacion) / SUM(c.ponderacion)
        FROM calificacion_caracteristica c
        WHERE c.calificacion_factor_id = NEW.calificacion_factor_id
    );
    UPDATE calificacion_factor
    SET resultado = resultado_total
    WHERE calificacion_factor_id = NEW.calificacion_factor_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `actualizar_resultado_factor_update` AFTER UPDATE ON `calificacion_caracteristica` FOR EACH ROW BEGIN
    DECLARE resultado_total DECIMAL(5, 2);
    SET resultado_total = (
        SELECT SUM(c.resultado * c.ponderacion) / SUM(c.ponderacion)
        FROM calificacion_caracteristica c
        WHERE c.calificacion_factor_id = NEW.calificacion_factor_id
    );
    UPDATE calificacion_factor
    SET resultado = resultado_total
    WHERE calificacion_factor_id = NEW.calificacion_factor_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `validar_ponderacion_caracteristica_insert` BEFORE INSERT ON `calificacion_caracteristica` FOR EACH ROW BEGIN
    DECLARE ponderacion_total DECIMAL(5, 2);
    SELECT ponderacion INTO ponderacion_total
    FROM calificacion_factor
    WHERE calificacion_factor_id = NEW.calificacion_factor_id;
    IF (SELECT COALESCE(SUM(ponderacion), 0) 
        FROM calificacion_caracteristica 
        WHERE calificacion_factor_id = NEW.calificacion_factor_id) + NEW.ponderacion > ponderacion_total THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La suma de las ponderaciones de las características no puede exceder la ponderación del factor.';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `validar_ponderacion_caracteristica_update` BEFORE UPDATE ON `calificacion_caracteristica` FOR EACH ROW BEGIN
    DECLARE ponderacion_total DECIMAL(5, 2);
    SELECT ponderacion INTO ponderacion_total
    FROM calificacion_factor
    WHERE calificacion_factor_id = NEW.calificacion_factor_id;
    IF (SELECT COALESCE(SUM(ponderacion), 0)
        FROM calificacion_caracteristica 
        WHERE calificacion_factor_id = NEW.calificacion_factor_id) + NEW.ponderacion - OLD.ponderacion > ponderacion_total THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La suma de las ponderaciones de las características no puede exceder la ponderación del factor.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calificacion_factor`
--

CREATE TABLE `calificacion_factor` (
  `calificacion_factor_id` int NOT NULL,
  `factor_id` int NOT NULL,
  `ponderacion` float NOT NULL,
  `resultado` decimal(5,2) DEFAULT NULL,
  `autoevaluacion_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `calificacion_factor`
--

INSERT INTO `calificacion_factor` (`calificacion_factor_id`, `factor_id`, `ponderacion`, `resultado`, `autoevaluacion_id`) VALUES
(1, 1, 50, 3.40, 1),
(2, 2, 50, 3.12, 1);

--
-- Disparadores `calificacion_factor`
--
DELIMITER $$
CREATE TRIGGER `validar_ponderacion_factor` BEFORE INSERT ON `calificacion_factor` FOR EACH ROW BEGIN
    DECLARE suma_ponderaciones DECIMAL(5, 2);
    SELECT COALESCE(SUM(ponderacion), 0) INTO suma_ponderaciones
    FROM calificacion_factor
    WHERE autoevaluacion_id = NEW.autoevaluacion_id;
    IF suma_ponderaciones + NEW.ponderacion > 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La suma de las ponderaciones de los factores no puede exceder el 100%.';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `validar_ponderacion_factor_update` BEFORE UPDATE ON `calificacion_factor` FOR EACH ROW BEGIN
    DECLARE suma_ponderaciones DECIMAL(5, 2);
    SELECT COALESCE(SUM(ponderacion), 0) INTO suma_ponderaciones
    FROM calificacion_factor
    WHERE autoevaluacion_id = NEW.autoevaluacion_id AND factor_id != OLD.factor_id;
    IF suma_ponderaciones + NEW.ponderacion > 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La suma de las ponderaciones de los factores no puede exceder el 100%.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calificacion_indicador`
--

CREATE TABLE `calificacion_indicador` (
  `calificacion_indicador_id` int NOT NULL,
  `indicador_id` int NOT NULL,
  `escala_id` int DEFAULT NULL,
  `calificacion_caracteristica_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `calificacion_indicador`
--

INSERT INTO `calificacion_indicador` (`calificacion_indicador_id`, `indicador_id`, `escala_id`, `calificacion_caracteristica_id`) VALUES
(1, 1, 4, 1),
(2, 2, 4, 2),
(3, 3, 4, 2),
(4, 4, 3, 2),
(5, 5, 3, 3),
(6, 6, 3, 3),
(7, 7, 3, 3),
(8, 8, 3, 3),
(9, 9, 3, 4),
(10, 10, 4, 5),
(11, 11, 3, 6),
(12, 12, 3, 6),
(13, 13, 4, 7),
(14, 14, 3, 7);

--
-- Disparadores `calificacion_indicador`
--
DELIMITER $$
CREATE TRIGGER `actualizar_resultado_caracteristica_insert` AFTER INSERT ON `calificacion_indicador` FOR EACH ROW BEGIN
    DECLARE promedio DECIMAL(5, 2);
    SELECT AVG(e.escala_numerica) INTO promedio
    FROM calificacion_indicador ci
    JOIN escalas e ON ci.escala_id = e.escala_id
    WHERE ci.calificacion_caracteristica_id = NEW.calificacion_caracteristica_id;
    UPDATE calificacion_caracteristica
    SET resultado = promedio
    WHERE calificacion_caracteristica_id = NEW.calificacion_caracteristica_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `actualizar_resultado_caracteristica_update` AFTER UPDATE ON `calificacion_indicador` FOR EACH ROW BEGIN
    DECLARE promedio DECIMAL(5, 2);
    SELECT AVG(e.escala_numerica) INTO promedio
    FROM calificacion_indicador ci
    JOIN escalas e ON ci.escala_id = e.escala_id
    WHERE ci.calificacion_caracteristica_id = NEW.calificacion_caracteristica_id;
    UPDATE calificacion_caracteristica
    SET resultado = promedio
    WHERE calificacion_caracteristica_id = NEW.calificacion_caracteristica_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `caracteristicas`
--

CREATE TABLE `caracteristicas` (
  `caracteristica_id` int NOT NULL,
  `codigo` varchar(50) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `factor_id` int DEFAULT NULL,
  `estado` tinyint(1) NOT NULL,
  `fecha_modificacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `caracteristicas`
--

INSERT INTO `caracteristicas` (`caracteristica_id`, `codigo`, `nombre`, `descripcion`, `factor_id`, `estado`, `fecha_modificacion`) VALUES
(1, 'F1C1', 'Característica 1', '1. Proyecto educativo del programa e identidad institucional', 1, 1, '2024-09-14 22:12:22'),
(2, 'F1C2', 'Característica 2', '2. Relevancia académica y pertinencia social del programa académico', 1, 1, '2024-09-14 22:12:22'),
(3, 'F2C3', 'Característica 3', 'Participación en actividades de formación integral', 2, 1, '2024-09-14 22:12:22'),
(4, 'F2C4', 'Característica 4', 'Orientación y seguimiento a estudiantes', 2, 1, '2024-09-14 22:12:22'),
(5, 'F2C5', 'Característica 5', 'Capacidad de trabajo autónomo', 2, 1, '2024-09-14 22:12:22'),
(6, 'F2C6', 'Característica 6', 'Reglamento estudiantil y política académica', 2, 1, '2024-09-14 22:12:22'),
(7, 'F2C7', 'Característica 7', 'Estímulos y apoyos para estudiantes', 2, 1, '2024-09-14 22:12:22'),
(8, 'F3C8', 'Característica 8', 'Selección, vinculación y permanencia', 3, 1, '2024-09-14 22:12:22'),
(9, 'F3C9', 'Característica 9', 'Estatuto profesoral', 3, 1, '2024-09-14 22:12:22'),
(10, 'F3C10', 'Característica 10', 'Número, dedicación, nivel de formación y experiencia', 3, 1, '2024-09-14 22:12:22'),
(11, 'F3C11', 'Característica 11', 'Desarrollo profesoral', 3, 1, '2024-09-14 22:12:22'),
(12, 'F3C12', 'Característica 12', 'Estímulos a la trayectoria profesoral', 3, 1, '2024-09-14 22:12:22'),
(13, 'F3C13', 'Característica 13', 'Producción, pertinencia, utilización e impacto de material docente', 3, 1, '2024-09-14 22:12:22'),
(14, 'F3C14', 'Característica 14', 'Remuneración por méritos', 3, 1, '2024-09-14 22:12:22'),
(15, 'F3C15', 'Característica 15', 'Evaluación de profesores', 3, 1, '2024-09-14 22:12:22'),
(16, 'F4C16', 'Característica 16', 'Seguimiento de los egresados', 4, 1, '2024-09-14 22:12:22'),
(17, 'F4C17', 'Característica 17', 'Impacto de los egresados en el medio social y académico', 4, 1, '2024-09-14 22:12:22'),
(18, 'F5C18', 'Característica 18', 'Integralidad de los aspectos curriculares', 5, 1, '2024-09-14 22:12:22'),
(19, 'F5C19', 'Característica 19', 'Flexibilidad de los aspectos curriculares', 5, 1, '2024-09-14 22:12:22'),
(20, 'F5C20', 'Característica 20', 'Interdisciplinariedad', 5, 1, '2024-09-14 22:12:22'),
(21, 'F5C21', 'Característica 21', 'Estrategias pedagógicas', 5, 1, '2024-09-14 22:12:22'),
(22, 'F5C22', 'Característica 22', 'Sistema de evaluación de estudiantes', 5, 1, '2024-09-14 22:12:22'),
(23, 'F5C23', 'Característica 23', 'Resultados de aprendizaje', 5, 1, '2024-09-14 22:12:22'),
(24, 'F5C24', 'Característica 24', 'Competencias', 5, 1, '2024-09-14 22:12:22'),
(25, 'F5C25', 'Característica 25', 'Evaluación y autorregulación del programa académico', 5, 1, '2024-09-14 22:12:22'),
(26, 'F5C26', 'Característica 26', 'Vinculación e interacción social', 5, 1, '2024-09-14 22:12:22'),
(27, 'F6C27', 'Característica 27', 'Políticas, estrategias y estructura para la permanencia y la graduación', 6, 1, '2024-09-14 22:12:22'),
(28, 'F6C28', 'Característica 28', 'Caracterización de estudiantes y sistema de alertas tempranas', 6, 1, '2024-09-14 22:12:22'),
(29, 'F6C29', 'Característica 29', 'Ajustes a los aspectos curriculares', 6, 1, '2024-09-14 22:12:22'),
(30, 'F6C30', 'Característica 30', 'Mecanismos de selección', 6, 1, '2024-09-14 22:12:22'),
(31, 'F7C31', 'Característica 31', 'Inserción del programa en contextos académicos nacionales e internacionales', 7, 1, '2024-09-14 22:12:22'),
(32, 'F7C32', 'Característica 32', 'Relaciones externas de profesores y estudiantes', 7, 1, '2024-09-14 22:12:22'),
(33, 'F7C33', 'Característica 33', 'Habilidades comunicativas en una segunda lengua', 7, 1, '2024-09-14 22:12:22'),
(34, 'F8C34', 'Característica 34', 'Formación para la investigación, desarrollo tecnológico, la innovación y la creación', 8, 1, '2024-09-14 22:12:22'),
(35, 'F8C35', 'Característica 35', 'Compromiso con la investigación, desarrollo tecnológico, la innovación y la creación', 8, 1, '2024-09-14 22:12:22'),
(36, 'F9C36', 'Característica 36', 'Programas y servicios', 9, 1, '2024-09-14 22:12:22'),
(37, 'F9C37', 'Característica 37', 'Participación y seguimiento', 9, 1, '2024-09-14 22:12:22'),
(38, 'F10C38', 'Característica 38', 'Estrategias y recursos de apoyo a profesores', 10, 1, '2024-09-14 22:12:22'),
(39, 'F10C39', 'Característica 39', 'Estrategias y recursos de apoyo a estudiantes', 10, 1, '2024-09-14 22:12:22'),
(40, 'F10C40', 'Característica 40', 'Recursos bibliográficos y de información', 10, 1, '2024-09-14 22:12:22'),
(41, 'F11C41', 'Característica 41', 'Organización y administración', 11, 1, '2024-09-14 22:12:22'),
(42, 'F11C42', 'Característica 42', 'Dirección y gestión', 11, 1, '2024-09-14 22:12:22'),
(43, 'F11C43', 'Característica 43', 'Sistemas de comunicación e información', 11, 1, '2024-09-14 22:12:22'),
(44, 'F11C44', 'Característica 44', 'Estudiantes y capacidad institucional', 11, 1, '2024-09-14 22:12:22'),
(45, 'F11C45', 'Característica 45', 'Financiación del programa académico', 11, 1, '2024-09-14 22:12:22'),
(46, 'F11C46', 'Característica 46', 'Aseguramiento de la alta calidad y mejora continua', 11, 1, '2024-09-14 22:12:22'),
(47, 'F12C47', 'Característica 47', 'Recursos de infraestructura física y tecnológica', 12, 1, '2024-09-14 22:12:22'),
(48, 'F12C48', 'Característica 48', 'Recursos informáticos y de comunicación', 12, 1, '2024-09-14 22:12:22');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escalas`
--

CREATE TABLE `escalas` (
  `escala_id` int NOT NULL,
  `escala_cualitativa` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `escala_numerica` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `escalas`
--

INSERT INTO `escalas` (`escala_id`, `escala_cualitativa`, `escala_numerica`) VALUES
(1, 'no cumple', 1),
(2, 'cumple insuficientemente', 2),
(3, 'cumple aceptablemente', 3),
(4, 'cumple en alto grado', 4),
(5, 'cumple plenamente', 5);

--
-- Disparadores `escalas`
--
DELIMITER $$
CREATE TRIGGER `insertar_escala_cualitativa` BEFORE INSERT ON `escalas` FOR EACH ROW BEGIN
    CASE NEW.escala_numerica
        WHEN 0 THEN SET NEW.escala_cualitativa = 'no cumple';
        WHEN 1 THEN SET NEW.escala_cualitativa = 'no cumple';
        WHEN 2 THEN SET NEW.escala_cualitativa = 'cumple insuficientemente';
        WHEN 3 THEN SET NEW.escala_cualitativa = 'cumple aceptablemente';
        WHEN 4 THEN SET NEW.escala_cualitativa = 'cumple en alto grado';
        WHEN 5 THEN SET NEW.escala_cualitativa = 'cumple plenamente';
        ELSE SET NEW.escala_cualitativa = NULL; -- Opcional: Manejo para valores no válidos
    END CASE;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `insertar_escala_numerica` BEFORE INSERT ON `escalas` FOR EACH ROW BEGIN
    CASE NEW.escala_cualitativa
        WHEN 'no cumple' THEN SET NEW.escala_numerica = 1;
        WHEN 'cumple insuficientemente' THEN SET NEW.escala_numerica = 2;
        WHEN 'cumple aceptablemente' THEN SET NEW.escala_numerica = 3;
        WHEN 'cumple en alto grado' THEN SET NEW.escala_numerica = 4;
        WHEN 'cumple_plenamente' THEN SET NEW.escala_numerica = 5;
        ELSE SET NEW.escala_numerica = NULL;
    END CASE;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `factores`
--

CREATE TABLE `factores` (
  `factor_id` int NOT NULL,
  `codigo` varchar(50) NOT NULL,
  `nombre` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `estado` tinyint(1) NOT NULL,
  `fecha_modificacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modelo_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `factores`
--

INSERT INTO `factores` (`factor_id`, `codigo`, `nombre`, `estado`, `fecha_modificacion`, `modelo_id`) VALUES
(1, 'F1', 'Proyecto educativo del programa e identidad institucional', 1, '2024-09-14 22:00:51', 1),
(2, 'F2', 'Estudiantes', 1, '2024-09-14 22:01:00', 1),
(3, 'F3', 'Profesores', 1, '2024-09-14 22:01:09', 1),
(4, 'F4', 'Egresados', 1, '2024-09-14 22:01:18', 1),
(5, 'F5', 'Aspectos académicos y resultados de aprendizaje', 1, '2024-09-14 22:01:27', 1),
(6, 'F6', 'Permanencia y graduación', 1, '2024-09-14 22:01:44', 1),
(7, 'F7', 'Interacción con el entorno nacional e internacional', 1, '2024-09-14 22:01:52', 1),
(8, 'F8', 'Aportes de la investigación, la innovación, el desarrollo tecnológico y la creación, asociados al programa académico', 1, '2024-09-14 22:02:02', 1),
(9, 'F9', 'Bienestar de la comunidad académica del programa', 1, '2024-09-14 22:02:10', 1),
(10, 'F10', 'Medios educativos y ambientes de aprendizaje', 1, '2024-09-14 22:02:19', 1),
(11, 'F11', 'Organización, administración y financiación del programa académico', 1, '2024-09-14 22:02:26', 1),
(12, 'F12', 'Recursos físicos y tecnológicos', 1, '2024-09-14 22:02:38', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `facultades`
--

CREATE TABLE `facultades` (
  `facultad_id` int NOT NULL,
  `nombre` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `facultades`
--

INSERT INTO `facultades` (`facultad_id`, `nombre`) VALUES
(1, 'Facultad ciencias administrativas contables y economicas'),
(2, 'Facultad de bellas artes'),
(3, 'Facultad de derecho, ciencias políticas y sociales'),
(4, 'Facultad de ciencias básicas'),
(5, 'Facultad de ingenierías y tecnologías'),
(6, 'Facultad ciencias de la salud'),
(7, 'Facultad de la educacion');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `fuentes`
--

CREATE TABLE `fuentes` (
  `fuente_id` int NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `soporte` varchar(255) DEFAULT NULL,
  `tipo` enum('encuesta','documentos','ambos') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `fuentes`
--

INSERT INTO `fuentes` (`fuente_id`, `nombre`, `soporte`, `tipo`) VALUES
(1, 'Encuesta a estudiantes', 'https://formulariodegoogle.com', 'encuesta'),
(2, 'Encuesta a profesores', 'https://formulariodegoogle.com', 'encuesta'),
(3, 'Encuesta a egresados', 'https://formulariodegoogle.com', 'encuesta'),
(4, 'Encuesta a directivos', 'https://formulariodegoogle.com', 'encuesta'),
(5, 'Documentos', 'https://documentodegoogle.com', 'documentos'),
(6, 'Encuesta Administrativos', 'https://formulariodegoogle.com', 'encuesta'),
(7, 'Encuesta Profesores y estudiantes', 'https://formulariodegoogle.com', 'encuesta'),
(8, 'Encuesta Profesores, estudiantes y directivos', 'https://formulariodegoogle.com', 'encuesta'),
(9, 'Encuesta Empleadores', 'https://formulariodegoogle.com', 'encuesta');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `indicadores`
--

CREATE TABLE `indicadores` (
  `indicador_id` int NOT NULL,
  `codigo` varchar(50) NOT NULL,
  `nombre` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `estado` tinyint(1) NOT NULL,
  `fecha_modificacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `caracteristica_id` int DEFAULT NULL,
  `fuente_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `indicadores`
--

INSERT INTO `indicadores` (`indicador_id`, `codigo`, `nombre`, `estado`, `fecha_modificacion`, `caracteristica_id`, `fuente_id`) VALUES
(1, 'F1C1I1', 'Demostrar coherencia del Proyecto Educativo del Programa (PEP) o el que haga sus veces, con los lineamientos y políticas institucionales, así como en la definición de objetivos de formación y resultados de aprendizaje y la manera cómo el PEP ha ido mejorando, como resultado de los procesos de aseguramiento de la calidad, la consolidación de la identidad institucional y la relación que mantiene con la comunidad y sus grupos de interés.', 1, '2024-09-15 19:11:01', 1, 5),
(2, 'F1C2I1', 'Análisis sobre las tendencias, necesidades y líneas de desarrollo de la disciplina o profesión, en el contexto regional, nacional e internacional.', 1, '2024-09-15 19:11:16', 2, 5),
(3, 'F1C2I2', 'Estudio de la pertinencia social del programa desde la perspectiva de la comunidad académica y de sus grupos de interés con el fin de identificar necesidades y requerimientos del entorno local, regional o nacional en términos productivos y de competitividad, tecnológicos, culturales, científicos y de talento humano.', 1, '2024-09-15 19:11:26', 2, 5),
(4, 'F1C2I3', 'Evidencia de las transformaciones sociales pertinentes para el contexto y el territorio en el que se ofrece el programa académico, y del entorno tanto nacional como internacional.', 1, '2024-09-15 19:11:37', 2, 5),
(5, 'F2C3I1', 'Apreciación de los estudiantes en relación con su participación en las actividades de investigación, desarrollo tecnológico, creación artística, culturales, deportivas y de extensión, que contribuyen a su formación integral, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:11:57', 3, 1),
(6, 'F2C3I2', 'Resultados del análisis de la participación y principales logros de los estudiantes en actividades de investigación, desarrollo tecnológico, innovación, creación artística, culturales y deportivas.', 1, '2024-09-15 19:12:12', 3, 5),
(7, 'F2C3I3', 'Resultados del análisis de la participación y principales logros de los estudiantes en proyectos de desarrollo empresarial, relacionamiento nacional e internacional.', 1, '2024-09-15 19:12:26', 3, 5),
(8, 'F2C3I4', 'Resultados del análisis de la participación y principales logros de los estudiantes en otras acciones de formación complementaria, que promuevan la comprensión de la realidad social, la empatía, la ética, habilidades blandas, así como el relacionamiento con otras culturas y lenguas, de acuerdo con el nivel de formación y la modalidad del programa.', 1, '2024-09-15 19:13:08', 3, 4),
(9, 'F2C4I1', 'Evidencia de los efectos en la formación de los estudiantes, a partir de los procesos de orientación y seguimiento de los estudiantes, teniendo como referencia sus características de ingreso.', 1, '2024-09-15 19:14:04', 4, 5),
(10, 'F2C5I1', 'Evidencia de los resultados de las estrategias de seguimiento y evaluación de los resultados de aprendizaje en el desarrollo de capacidades para el trabajo autónomo del estudiante.', 1, '2024-09-15 19:14:18', 5, 5),
(11, 'F2C6I1', 'Apreciación de estudiantes y profesores del programa sobre la pertinencia, vigencia y aplicación del reglamento estudiantil y las políticas académicas y, sobre las estrategias de divulgación de dicha reglamentación, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:18:06', 6, 7),
(12, 'F2C6I2', 'Evidencia de los mecanismos para la aplicación, actualización y divulgación del reglamento estudiantil.', 1, '2024-09-15 19:18:48', 6, 5),
(13, 'F2C7I2', 'Evidencia de aplicación de procesos de selección, vinculación y permanencia de docentes.', 1, '2024-09-15 19:19:33', 7, 5),
(14, 'F2C7I3', 'Apreciación de los estudiantes del programa frente a la aplicación de los estímulos académicos y apoyos socioeconómicos, y el cumplimiento institucional de estas medidas, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:19:57', 7, 1),
(15, 'F3C8I1', 'Evidencia de la aplicación de los procesos de selección, vinculación y permanencia de los profesores, en coherencia con el nivel de formación, modalidad del programa académico y lugar de desarrollo.', 1, '2024-09-15 19:20:30', 8, 5),
(16, 'F3C8I2', 'Apreciación de los profesores sobre la aplicación, pertinencia y vigencia de las políticas, normas y criterios académicos establecidos por la institución para su selección, vinculación y permanencia, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:20:45', 8, 2),
(17, 'F3C9I1', 'Evidencia que demuestren los resultados de la aplicación del estatuto profesoral, o el que haga sus veces, sobre la trayectoria profesoral, la inclusión, el reconocimiento de méritos y el ascenso en el escalafón, de acuerdo con el nivel de formación y la modalidad del programa.', 1, '2024-09-15 19:21:04', 9, 5),
(18, 'F3C9I2', 'Resultados en el mejoramiento de la calidad del programa, a partir de la aplicación de un estatuto que promueve la trayectoria profesoral, la inclusión, el reconocimiento de los méritos y el ascenso en el escalafón.', 1, '2024-09-15 19:21:18', 9, 5),
(19, 'F3C9I3', 'Apreciación de los profesores sobre la aplicación y pertinencia del estatuto profesoral y de las políticas que establecen distinciones, estímulos que promueven la trayectoria profesoral, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:21:31', 9, 2),
(20, 'F3C10I1', 'Evidencia de la coherencia entre el número, dedicación, nivel de formación y experiencia de los profesores de tiempo completo, con el número de estudiantes, nivel de formación y modalidad del programa académico.', 1, '2024-09-15 19:21:56', 10, 5),
(21, 'F3C10I2', 'Evidencia de la existencia de un núcleo básico de profesores de tiempo completo, preferiblemente con contratación a término indefinido, y su relación con la formación de la comunidad académica del programa y el cumplimiento con alta calidad de las funciones esenciales del programa.', 1, '2024-09-15 19:22:21', 10, 5),
(22, 'F3C10I3', 'Evidencia de la vinculación de una planta profesoral pertinente con el área disciplinar del programa con título de especialistas, magísteres y/o doctores con experiencia o formación pedagógica y profesional certificada, que garantice el logro de los resultados de aprendizaje de los estudiantes y el cumplimiento de las funciones asignadas en condiciones de calidad, atendiendo a estándares internacionales, en coherencia con el nivel de formación y modalidad del programa.', 1, '2024-09-15 19:22:41', 10, 5),
(23, 'F3C11I1', 'Análisis de los resultados de la aplicación de políticas y estrategias institucionales en materia de desarrollo integral del profesorado, que incluya la capacitación y la actualización en los aspectos académicos, profesionales y pedagógicos relacionados con la naturaleza, nivel de formación y modalidad del programa.', 1, '2024-09-15 19:23:09', 11, 5),
(24, 'F3C11I2', 'Evidencia de cómo el desarrollo profesoral atiende a la diversidad de los estudiantes, a las modalidades de la docencia y a los requerimientos de internacionalización y de inter y multiculturalidad de profesores y estudiantes.', 1, '2024-09-15 19:23:26', 11, 5),
(25, 'F3C11I3', 'Apreciación de directivos del programa sobre los resultados que han tenido las acciones orientadas al desarrollo integral de los profesores, en el mejoramiento de las competencias pedagógicas, científicas y sociales para el sostenimiento de las funciones misionales, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:24:36', 11, 4),
(26, 'F3C11I3', 'Apreciación de los profesores del programa sobre los resultados que han tenido las acciones orientadas al desarrollo integral de los profesores, en el mejoramiento de las competencias pedagógicas, científicas y sociales para el sostenimiento de las funciones misionales, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:25:22', 11, 2),
(27, 'F3C12I1', 'Evidencia de los efectos generados en el desempeño de las labores de docencia, investigación y extensión con el otorgamiento de estímulos a los profesores.', 1, '2024-09-15 19:25:46', 12, 5),
(28, 'F3C12I2', 'Apreciación de directivos del programa, sobre el efecto que ha tenido el régimen de estímulos al profesorado en el ejercicio cualificado de la docencia, la investigación, la innovación, la creación artística y cultural, la extensión o proyección social, en los aportes al desarrollo técnico y tecnológico y la cooperación internacional, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:26:25', 12, 4),
(29, 'F3C12I2', 'Apreciación de profesores del programa, sobre el efecto que ha tenido el régimen de estímulos al profesorado en el ejercicio cualificado de la docencia, la investigación, la innovación, la creación artística y cultural, la extensión o proyección social, en los aportes al desarrollo técnico y tecnológico y la cooperación internacional, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:26:51', 12, 2),
(30, 'F3C13I1', 'Evidencia de la efectividad de los criterios de evaluación del material producido por los profesores en la calidad de los aprendizajes de los estudiantes, de acuerdo con el nivel de formación y modalidad del programa académico.', 1, '2024-09-15 19:27:09', 13, 5),
(31, 'F3C13I2', 'Presentación de los resultados de evaluación de los materiales académicos producidos por los profesores para el desarrollo de las diversas actividades académicas, que soportan los ambientes de aprendizaje, de acuerdo con el nivel de formación y modalidad.', 1, '2024-09-15 19:35:05', 13, 5),
(32, 'F3C13I3', 'Apreciación de los estudiantes del programa sobre la pertinencia y calidad del material académico producido, de acuerdo con el nivel de formación y la modalidad del programa, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:35:27', 13, 1),
(33, 'F3C13I3', 'Apreciación de los directivos del programa sobre la pertinencia y calidad del material académico producido, de acuerdo con el nivel de formación y la modalidad del programa, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:35:43', 13, 4),
(34, 'F3C14I1', 'Apreciación de los profesores del programa con respecto a la correspondencia entre la remuneración recibida y los méritos académicos, pedagógicos y profesionales, derivados de su actividad docente, investigativa, tecnológica, innovación, creación artística o cultural y proyección social, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:36:04', 14, 2),
(35, 'F3C15I1', 'Apreciación de los profesores, directivos y estudiantes sobre los criterios y mecanismos para la evaluación de los profesores; su transparencia, equidad y eficacia y; su coherencia con la naturaleza de la institución, el nivel de formación y la modalidad del programa, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:37:54', 15, 8),
(36, 'F3C15I2', 'Demostración del mejoramiento continuo del programa, a partir de las evaluaciones permanentes realizadas a los profesores, en coherencia con el nivel de formación y modalidad.', 1, '2024-09-15 19:38:08', 15, 5),
(37, 'F3C16I1', 'Resultado de los estudios sistémicos aplicados sobre el desarrollo profesional y laboral de los egresados, el alcance de las competencias adquiridas, la correspondencia entre el desempeño de los egresados y el perfil de egreso o resultados de aprendizaje del programa.', 1, '2024-09-15 19:38:34', 16, 5),
(38, 'F3C16I2', 'Apreciación de los egresados en relación con el perfil de formación, las competencias adquiridas y las posibilidades que les ha ofrecido su formación para su desarrollo profesional y laboral, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:38:47', 16, 3),
(39, 'F3C17I1', 'Evidencia del impacto de los egresados en el medio social y académico, científico y cultural, como un mecanismo para establecer los aportes del programa a la solución de problemas de la sociedad y/o la creación e innovación de conocimiento.', 1, '2024-09-15 19:40:07', 17, 5),
(40, 'F3C17I2', 'Apreciación de empleadores sobre el desempeño destacado de los egresados y su aporte en la solución de los problemas académicos, ambientales, tecnológicos, sociales y culturales, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:41:34', 17, 9),
(41, 'F5C18I1', 'Resultados de la aplicación de ejercicios continuos de evaluación de la integralidad del currículo que conduzcan a la realización de ajustes y mejoras que impactan a la formación en valores, actitudes, aptitudes, conocimientos, métodos, capacidades y habilidades, de acuerdo con el estado del arte y con el ejercicio de la disciplina, profesión, ocupación u oficio, y que busca la formación integral del estudiante en coherencia con la misión institucional y los objetivos propios del programa académico.', 1, '2024-09-15 19:41:52', 18, 5),
(42, 'F5C18I2', 'Evaluación de las estrategias y acciones del programa para el mejoramiento de las competencias definidas por el programa.', 1, '2024-09-15 19:42:03', 18, 5),
(43, 'F5C19I1', 'Evidencia de procesos de flexibilización como, doble titulación; articulación pregrado-posgrado; reconocimiento de créditos, homologación y oferta de cursos electivos en distintas modalidades y lugares de desarrollo entre otros, que permiten al estudiante interactuar con otros programas a nivel institucional, nacional e internacional.', 1, '2024-09-15 19:42:17', 19, 5),
(44, 'F5C19I2', 'Apreciación de estudiantes sobre las rutas de formación alternativas y adoptadas por los estudiantes a partir de sus necesidades e intereses, derivadas de las estrategias de flexibilidad curricular definidas por la institución, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:42:38', 19, 1),
(45, 'F5C19I2', 'Apreciación de profesores sobre las rutas de formación alternativas y adoptadas por los estudiantes a partir de sus necesidades e intereses, derivadas de las estrategias de flexibilidad curricular definidas por la institución, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:43:09', 19, 2),
(46, 'F5C19I2', 'Apreciación de egresados sobre las rutas de formación alternativas y adoptadas por los estudiantes a partir de sus necesidades e intereses, derivadas de las estrategias de flexibilidad curricular definidas por la institución, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:43:27', 19, 3),
(47, 'F5C20I1', 'Evidencia de la implementación de las estrategias que promueven y estimulan la interdisciplinariedad curricular del programa, y el resultado de su aplicación en las diferentes rutas formativas seguidas por los estudiantes.', 1, '2024-09-15 19:43:41', 20, 5),
(48, 'F5C20I2', 'Apreciación de los estudiantes frente a los mecanismos y criterios dispuestos por la institución para la interdisciplinariedad curricular del programa, los resultados de su análisis y la evidencia de los logros en el mejoramiento en la calidad del programa.', 1, '2024-09-15 19:43:53', 20, 1),
(49, 'F5C20I2', 'Apreciación de los profesores frente a los mecanismos y criterios dispuestos por la institución para la interdisciplinariedad curricular del programa, los resultados de su análisis y la evidencia de los logros en el mejoramiento en la calidad del programa.', 1, '2024-09-15 19:44:12', 20, 2),
(50, 'F5C21I1', 'Apreciación de profesores y estudiantes sobre la coherencia de las estrategias pedagógicas utilizadas que facilitan el logro de los resultados de aprendizaje esperados, incluyendo los escenarios de práctica para los programas que lo requieren, valorando la calidad, la pertinencia, el acompañamiento y el cumplimiento de la normatividad específica para su desarrollo, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:44:28', 21, 7),
(51, 'F5C21I2', 'Evidencia de la evaluación y el mejoramiento de las estrategias y prácticas pedagógicas, a partir de los aportes de la investigación pedagógica y de los procesos de actualización de los profesores.', 1, '2024-09-15 19:44:56', 21, 5),
(52, 'F5C21I3', 'En el caso de programas académicos del área de la salud, presentar análisis de la incidencia de las actividades desarrolladas en el marco de los convenios de docencia servicio con los distintos escenarios de práctica (con énfasis en el escenario principal, cuando aplique) en los procesos de formación. Los análisis se deben realizar entre las partes que participan en el convenio.', 1, '2024-09-15 19:45:28', 21, 5),
(53, 'F5C22I1', 'Apreciación de profesores y estudiantes sobre los sistemas de evaluación de los resultados de aprendizaje que desarrolla o implementa el programa, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:47:08', 22, 7),
(54, 'F5C22I2', 'Evidencia de los resultados obtenidos a partir de la implementación de los sistemas de evaluación de estudiantes basado en políticas y normas claras, universales y transparentes.', 1, '2024-09-15 19:47:19', 22, 5),
(55, 'F5C22I3', 'Evidencia de los mecanismos y estrategias utilizadas para la evaluación de los resultados de aprendizaje, sus aportes y recomendaciones.', 1, '2024-09-15 19:47:33', 22, 5),
(56, 'F5C23I1', 'Evidencia de la aplicación de una política institucional que establezca parámetros para la formulación, evaluación y mejora continua de los resultados de aprendizaje establecidos en el programa, en alineación con el perfil de formación y acorde con el nivel y la modalidad de formación.', 1, '2024-09-15 19:47:45', 23, 5),
(57, 'F5C23I2', 'Evidencia del proceso de mejoramiento continuo relacionado con la evaluación entre los resultados de aprendizaje esperados y los alcanzados por los estudiantes, el sistema de evaluación de estudiantes y las acciones de ajuste de los aspectos curriculares y las metodologías de enseñanza - aprendizaje derivadas de dicha evaluación.', 1, '2024-09-15 19:47:56', 23, 5),
(58, 'F5C24I1', 'Evidencia del resultado de la aplicación de estrategias para el desarrollo de las competencias previstas acordes con el perfil de formación del programa.', 1, '2024-09-15 19:48:23', 24, 5),
(59, 'F5C25I1', 'Evidencia del cumplimiento de planes de mejoramiento y de innovación producto del proceso de autoevaluación del programa.', 1, '2024-09-15 19:49:47', 25, 5),
(60, 'F5C25I2', 'Apreciación de los profesores y estudiantes sobre la calidad y pertinencia del proceso de evaluación y autorregulación del programa, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:50:07', 25, 7),
(61, 'F5C26I1', 'Evidencia de la participación de los profesores y estudiantes en la proyección social del programa.', 1, '2024-09-15 19:50:32', 26, 5),
(62, 'F5C26I2', 'Evidencia del efecto de las estrategias y acciones de proyección social como un mecanismo para establecer los aportes del programa a la solución de problemas de la sociedad y a las mejoras de los aspectos curriculares.', 1, '2024-09-15 19:50:46', 26, 5),
(63, 'F6C27I1', 'Análisis del efecto de las políticas, estrategias y acciones orientadas al mejoramiento de la permanencia y la graduación en el programa, que incluyan el comportamiento en los últimos seis años o en la vigencia de la acreditación si se trata de una renovación, de la tasa de deserción interanual, tasa de deserción por cohorte y la tasa de graduación acumulada del programa.', 1, '2024-09-15 19:51:14', 27, 5),
(64, 'F6C28I1', 'Evidencia de la existencia e implementación de un sistema de alertas tempranas que permita reconocer las particularidades de los estudiantes según su contexto sociocultural y la puesta en marcha de acciones que faciliten su proceso formativo, de acuerdo, al menos, con las normas nacionales vigentes en materia de inclusión y diversidad.', 1, '2024-09-15 19:51:41', 28, 5),
(65, 'F6C28I2', 'Apreciación de estudiantes y profesores sobre la contribución de las estrategias del sistema de alertas tempranas en su permanencia y graduación, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:51:56', 28, 7),
(66, 'F6C28I3', 'Presentación del análisis de los resultados derivados del sistema de alertas tempranas y su impacto en el currículo, para mejorar el desempeño académico de los estudiantes, su permanencia y graduación.', 1, '2024-09-15 19:52:09', 28, 5),
(67, 'F6C29I1', 'Evidencia de la evaluación y el mejoramiento de los aspectos curriculares derivados de los análisis del desempeño académico de los estudiantes, la permanencia y la graduación.', 1, '2024-09-15 19:52:27', 29, 5),
(68, 'F6C30I1', 'Evidencia y análisis de la evolución de la matrícula total de estudiantes del programa y de la relación entre aspirantes inscritos, admitidos y matriculados en cada periodo, a fin de establecer la tasa de selectividad y/o absorción del programa.', 1, '2024-09-15 19:52:39', 30, 5),
(69, 'F6C30I2', 'Análisis de la correlación entre los mecanismos de selección, de desempeño académico, permanencia y graduación que resulte en ajustes a los procesos de selección del programa.', 1, '2024-09-15 19:52:51', 30, 5),
(70, 'F7C31I1', 'Evidencia del efecto de la aplicación de políticas y estrategias de cooperación con comunidades, nacionales e internacionales, en el desarrollo de labores formativas, académicas, docentes, científicas, culturales, deportivas y de extensión, así como en aspectos curriculares y en la revisión de tendencias y referentes nacionales e internacionales que contribuyan al mejoramiento continuo del programa.', 1, '2024-09-15 19:54:23', 31, 5),
(71, 'F7C32I1', 'Evidencia y análisis de los resultados de la cooperación académica y científica del programa, mediante convenios, proyectos conjuntos, intercambios de profesores, estudiantes y la participación en redes científicas, culturales y de extensión.', 1, '2024-09-15 19:54:38', 32, 5),
(72, 'F7C32I2', 'Apreciación de profesores sobre los resultados de la cooperación académica y científica derivados de la aplicación de políticas y estrategias que favorezcan la interacción de profesores y estudiantes con sus homólogos, a nivel nacional e internacional, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:54:57', 32, 2),
(73, 'F7C32I2', 'Apreciación de estudiantes sobre los resultados de la cooperación académica y científica derivados de la aplicación de políticas y estrategias que favorezcan la interacción de profesores y estudiantes con sus homólogos, a nivel nacional e internacional, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:55:11', 32, 1),
(74, 'F7C32I2', 'Apreciación de egresados sobre los resultados de la cooperación académica y científica derivados de la aplicación de políticas y estrategias que favorezcan la interacción de profesores y estudiantes con sus homólogos, a nivel nacional e internacional, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:57:58', 32, 3),
(75, 'F7C33I1', 'Evidencia de la incidencia de las estrategias empleadas para el desarrollo de las competencias comunicativas en una segunda lengua y las interacciones de profesores y estudiantes con otras comunidades no hispanohablantes de acuerdo con el nivel de formación y modalidad del programa.', 1, '2024-09-15 19:58:18', 33, 5),
(76, 'F8C34I1', 'Evidencia de las estrategias implementadas para el desarrollo de las competencias investigativas, de innovación o creación artística y cultural de los estudiantes, en coherencia con la naturaleza, nivel de formación y la modalidad de oferta del programa.', 1, '2024-09-15 19:58:42', 34, 5),
(77, 'F8C34I2', 'Apreciación de los estudiantes acerca de la formación para la investigación, el desarrollo de un pensamiento crítico, creativo e innovador, así como el desarrollo tecnológico, la innovación y la creación promovida en el programa, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 19:58:55', 34, 1),
(78, 'F8C35I1', 'Evidencia de la existencia de un reglamento de propiedad intelectual, de grupos de investigación categorizados y de profesores investigadores reconocidos en las convocatorias de medición de Minciencias, acorde con el Proyecto Educativo del Programa, el nivel de formación y la modalidad del programa.', 1, '2024-09-15 19:59:09', 35, 5),
(79, 'F8C35I2', 'Evidencia de resultados de investigación, desarrollo tecnológico, innovación o creación de los profesores del programa, que contribuyan al fortalecimiento de los aspectos curriculares, la formación de los estudiantes y a la generación de nuevo conocimiento o a la solución de problemas de la sociedad, en coherencia con el Proyecto Educativo del Programa, el nivel de formación y la modalidad del programa.', 1, '2024-09-15 19:59:21', 35, 5),
(80, 'F9C36I1', 'Análisis sistemáticos de la participación de estudiantes y profesores en las actividades de bienestar en cada uno de los escenarios de práctica.', 1, '2024-09-15 19:59:35', 36, 5),
(81, 'F9C36I2', 'Apreciación de los estudiantes sobre la incidencia de la implementación de políticas, programas y servicios de bienestar, en coherencia con las condiciones y necesidades de la comunidad en cada uno de los lugares y escenarios de práctica donde desarrolla sus labores, en correspondencia con el nivel de formación y la modalidad del programa, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 20:00:02', 36, 1),
(82, 'F9C36I3', 'Apreciación de los profesores sobre la incidencia de la implementación de políticas, programas y servicios de bienestar, en coherencia con las condiciones y necesidades de la comunidad en cada uno de los lugares y escenarios de práctica donde desarrolla sus labores, en correspondencia con el nivel de formación y la modalidad del programa, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 20:00:17', 36, 2),
(83, 'F9C36I4', 'Apreciación del personal administrativo sobre la incidencia de la implementación de políticas, programas y servicios de bienestar, en coherencia con las condiciones y necesidades de la comunidad en cada uno de los lugares y escenarios de práctica donde desarrolla sus labores, en correspondencia con el nivel de formación y la modalidad del programa, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 20:02:13', 36, 6),
(84, 'F9C37I1', 'Análisis sistemáticos de la participación de la comunidad del programa en los planes y las actividades de bienestar, de acuerdo con las particularidades de la población estudiantil, académica y administrativa.', 1, '2024-09-15 20:02:28', 37, 5),
(85, 'F9C37I2', 'Evaluación de la calidad y pertinencia de la infraestructura, espacios y servicios de bienestar por parte de la comunidad del programa, junto con las acciones emprendidas como resultado de dicha evaluación.', 1, '2024-09-15 20:02:39', 37, 5),
(86, 'F10C38I1', 'Demostración de los resultados y la incidencia de la implementación de las estrategias y recursos de apoyo (pedagógico-didáctico) en los contextos de actuación de los profesores para el mejoramiento de sus prácticas de enseñanza-aprendizaje teniendo en cuenta la diversidad y la inclusión.', 1, '2024-09-15 20:02:52', 38, 5),
(87, 'F10C38I2', 'Apreciación de los profesores en relación con las estrategias pedagógicas, tecnológicas y de acompañamiento dispuestas por el programa para el desarrollo de las habilidades comunicativas y de interacción de los profesores con los estudiantes, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 20:03:27', 38, 2),
(88, 'F10C38I3', 'Apreciación de los estudiantes en relación con las estrategias pedagógicas, tecnológicas y de acompañamiento dispuestas por el programa para el desarrollo de las habilidades comunicativas y de interacción de los profesores con los estudiantes, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 20:03:38', 38, 1),
(89, 'F10C38I4', 'En el caso de programas académicos del área de la salud, análisis de las acciones que realizan conjuntamente el programa con los escenarios de práctica, en sus procesos de certificación, acreditación, reconocimiento como hospital universitario y acciones de mejora.', 1, '2024-09-15 20:04:12', 38, 5),
(90, 'F10C39I1', 'Evidencia de la disponibilidad y capacidad de talleres, laboratorios, equipos, medios audiovisuales, sitios de práctica, estaciones y granjas experimentales, escenarios de simulación virtual, entre otros, para el adecuado desarrollo de la actividad docente, investigativa y de extensión, según requerimientos del programa.', 1, '2024-09-15 20:04:34', 39, 5),
(91, 'F10C39I2', 'Apreciación de los estudiantes sobre la utilidad y pertinencia de las estrategias y recursos de apoyo brindados por la institución para el desarrollo de su proceso formativo en diferentes contextos, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 20:05:37', 39, 1),
(92, 'F10C39I3', 'En el caso de los programas académicos del área de la salud, evidencia de la disponibilidad de laboratorios especializados y/o de simulación en los distintos lugares de desarrollo y los escenarios de práctica, y análisis del nivel de uso por parte de profesores y estudiantes.', 1, '2024-09-15 20:06:09', 39, 5),
(93, 'F10C40I1', 'Análisis de la correspondencia entre la inversión en recursos bibliográficos y de información, su utilización por parte de la comunidad del programa, demostrando la suficiencia y pertinencia para el desarrollo de actividades de docencia, investigación y extensión, de acuerdo con el nivel de formación y modalidad del programa.', 1, '2024-09-15 20:06:34', 40, 5),
(94, 'F10C40I2', 'Apreciación de estudiantes y profesores acerca de la pertinencia, actualización y suficiencia del material bibliográfico con que cuenta el programa, para apoyar el desarrollo de las distintas actividades académicas, de acuerdo con su nivel de formación y modalidad, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 20:07:30', 40, 5),
(95, 'F10C40I3', 'Apreciación de estudiantes acerca de la pertinencia, actualización y suficiencia del material bibliográfico con que cuenta el programa, para apoyar el desarrollo de las distintas actividades académicas, de acuerdo con su nivel de formación y modalidad, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 20:07:53', 40, 1),
(96, 'F10C40I3', 'Apreciación de profesores acerca de la pertinencia, actualización y suficiencia del material bibliográfico con que cuenta el programa, para apoyar el desarrollo de las distintas actividades académicas, de acuerdo con su nivel de formación y modalidad, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 20:08:14', 40, 2),
(97, 'F11C41I1', 'Evidencia de la participación de representantes de la comunidad académica, a través de estructuras organizacionales definidas por la institución, y de su contribución, en el desarrollo y mejoramiento del programa.', 1, '2024-09-15 20:09:16', 41, 5),
(98, 'F11C41I2', 'Apreciación de estudiantes sobre su participación en cuerpos colegiados, y en decisiones orientadas al mejoramiento del programa, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 20:09:28', 41, 1),
(99, 'F11C41I2', 'Apreciación de profesores sobre su participación en cuerpos colegiados, y en decisiones orientadas al mejoramiento del programa, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 20:09:55', 41, 2),
(100, 'F11C41I2', 'Apreciación de egresados sobre su participación en cuerpos colegiados, y en decisiones orientadas al mejoramiento del programa, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 20:10:14', 41, 3),
(101, 'F11C42I1', 'Evidencia de los mecanismos existentes para la dirección y gestión del programa que contribuyen al mejoramiento de las dinámicas administrativas y académicas y al relacionamiento con los grupos de interés.', 1, '2024-09-15 20:10:42', 42, 5),
(102, 'F11C42I2', 'Apreciación de profesores sobre la eficiencia, eficacia y orientación de los procesos administrativos hacia el desarrollo de las labores formativas, académicas, docentes, científicas, culturales y de extensión, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 20:10:59', 42, 2),
(103, 'F11C42I2', 'Apreciación de estudiantes sobre la eficiencia, eficacia y orientación de los procesos administrativos hacia el desarrollo de las labores formativas, académicas, docentes, científicas, culturales y de extensión, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 20:11:20', 42, 1),
(104, 'F11C43I1', 'Presentación de estudios de satisfacción de profesores y estudiantes del programa acerca de la suficiencia y calidad de los recursos y sistemas de comunicación e información.', 1, '2024-09-15 20:11:52', 43, 5),
(105, 'F11C43I2', 'Presentación de estadísticas y análisis del uso de los sistemas de comunicación e información, y de la implementación de estrategias que garanticen la conectividad a los miembros de la comunidad académica del programa.', 1, '2024-09-15 20:12:06', 43, 5),
(106, 'F11C43I3', 'Evidencia de la aplicación de mecanismos de gestión documental, organización, actualización y seguridad de los registros y archivos académicos de estudiantes, profesores, personal directivo y administrativo.', 1, '2024-09-15 20:12:52', 43, 5),
(107, 'F11C44I1', 'Presentación de estadísticas y análisis de las capacidades institucionales en materia de recursos humanos (planta docente y personal administrativo), técnicos, tecnológicos y financieros, que favorecen la permanencia, el desarrollo académico y la graduación de los estudiantes.', 1, '2024-09-15 20:13:11', 44, 5),
(108, 'F11C44I2', 'Apreciación de profesores del programa con respecto a la correspondencia entre las capacidades institucionales en materia de sus recursos humanos, técnicos, tecnológicos y financieros, y el número de estudiantes matriculados, en cumplimiento del Proyecto Educativo del Programa, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 20:13:25', 44, 2),
(109, 'F11C44I2', 'Apreciación de estudiantes del programa con respecto a la correspondencia entre las capacidades institucionales en materia de sus recursos humanos, técnicos, tecnológicos y financieros, y el número de estudiantes matriculados, en cumplimiento del Proyecto Educativo del Programa, junto con las acciones emprendidas como resultado de dichas apreciaciones.', 1, '2024-09-15 20:19:40', 44, 1),
(110, 'F11C45I1', 'Demostración de la consistencia entre la asignación y distribución presupuestal del programa, y el desarrollo de las actividades de docencia, investigación, creación artística y cultural, deportiva, proyección social, bienestar institucional e internacionalización, y la implementación de los planes de mejoramiento.', 1, '2024-09-15 20:19:48', 45, 5),
(111, 'F11C45I2', 'Presentación de la proyección y la ejecución del presupuesto de inversión y de funcionamiento del programa y los mecanismos de seguimiento y control.', 1, '2024-09-15 20:19:57', 45, 5),
(112, 'F11C45I3', 'Evidencia de la consolidación de un Sistema Interno de Aseguramiento de la Calidad que permita verificar, mediante unos procesos periódicos y participativos de autoevaluación, la alta calidad en cada uno de los factores y características del modelo del Consejo Nacional de Acreditación, en el programa.', 1, '2024-09-15 20:20:16', 45, 5),
(113, 'F11C46I1', 'En el caso de los programas académicos del área de la salud, evidencia de los procesos de autoevaluación sobre el funcionamiento del convenio docencia servicio en cada uno de los escenarios de práctica y su incidencia en los procesos de mejoramiento.', 1, '2024-09-15 20:20:45', 46, 5),
(114, 'F12C47I1', 'Demostración de la existencia de aulas, laboratorios, talleres, centros de simulación, plataformas tecnológicas, biblioteca y salas de estudio, para el cumplimiento de las labores formativas, académicas, docentes, científicas, culturales y de extensión, en coherencia con el nivel de formación y la modalidad de oferta del programa.', 1, '2024-09-15 20:22:17', 47, 5),
(115, 'F12C47I2', 'Evidencia de planes y proyectos realizados o en ejecución, para la conservación, expansión, mejoras y mantenimiento de la planta física para el programa, de acuerdo con las normas técnicas respectivas y con el nivel de formación y la modalidad de oferta del programa.', 1, '2024-09-15 20:22:07', 47, 5),
(116, 'F12C48I1', 'Evidencia de la coherencia entre los recursos informáticos y de comunicación con las necesidades para el desarrollo y cumplimiento de las labores formativas, académicas, docentes, científicas, culturales del programa en el lugar de desarrollo y en los escenarios de práctica.', 1, '2024-09-15 20:22:32', 48, 5),
(117, 'F12C48I2', 'Apreciación de directivos del programa sobre la pertinencia, correspondencia y suficiencia de los recursos informáticos y de comunicación con que cuenta el programa.', 1, '2024-09-15 20:24:15', 48, 4),
(118, 'F12C48I2', 'Apreciación de los profesores del programa sobre la pertinencia, correspondencia y suficiencia de los recursos informáticos y de comunicación con que cuenta el programa.', 1, '2024-09-15 20:25:17', 48, 2),
(119, 'F12C48I2', 'Apreciación de los estudiantes del programa sobre la pertinencia, correspondencia y suficiencia de los recursos informáticos y de comunicación con que cuenta el programa.', 1, '2024-09-15 20:25:32', 48, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `modelo_acreditacion`
--

CREATE TABLE `modelo_acreditacion` (
  `modelo_id` int NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `user_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `modelo_acreditacion`
--

INSERT INTO `modelo_acreditacion` (`modelo_id`, `nombre`, `user_id`) VALUES
(1, 'Modelo CNA', 'admin123');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `programas`
--

CREATE TABLE `programas` (
  `programa_id` int NOT NULL,
  `nombre` varchar(255) DEFAULT NULL,
  `facultad_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `programas`
--

INSERT INTO `programas` (`programa_id`, `nombre`, `facultad_id`) VALUES
(1, 'Administracion de Empresas', 1),
(2, 'Administracion de Empresas Turisticas y Hoteleras', 1),
(3, 'Comercio Internacional', 1),
(4, 'Contaduria Publica', 1),
(5, 'Economia', 1),
(6, 'Licenciatura en Artes', 2),
(7, 'Licenciatura en Musica', 2),
(8, 'Derecho', 3),
(9, 'Sociologia', 3),
(10, 'Psicologia', 3),
(11, 'Microbiologia', 4),
(12, 'Ingenieria Agroindustrial', 5),
(13, 'Ingenieria Ambiental y Sanitaria', 5),
(14, 'Ingenieria de Sistemas', 5),
(15, 'Ingenieria Electronica', 5),
(16, 'Enfermeria', 6),
(17, 'Instrumentacion Quirurgica', 6),
(18, 'Licenciatura en Naturales y Educacion Ambiental', 7),
(19, 'Licenciatura en Literatura y Lengua Castellana', 7),
(20, 'Licenciatura en Matematicas', 7),
(21, 'Licenciatura en Español e Ingles', 7),
(22, 'Licenciatura en Educacion Fisica, Recreacion y Deporte', 7);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `roles`
--

CREATE TABLE `roles` (
  `role_name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `role_description` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `roles`
--

INSERT INTO `roles` (`role_name`, `role_description`) VALUES
('Admin', 'Admin role'),
('user', 'Default role for newly created record role');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `users`
--

CREATE TABLE `users` (
  `username` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `user_first_name` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `user_last_name` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `user_password` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `verification_token` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `verified` bit(1) NOT NULL,
  `reset_token` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `reset_token_expiry` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `users`
--

INSERT INTO `users` (`username`, `user_first_name`, `user_last_name`, `user_password`, `verification_token`, `verified`, `reset_token`, `reset_token_expiry`) VALUES
('admin123', 'admin', 'admin', '$2a$10$MHZFKA6zgG.b87qw.N8Zw.G/MKhvqQ8Pei/YmGeVcwNo4xtdWODYa', NULL, b'1', NULL, NULL),
('admin123@gmail.com', 'Admin', 'Admin', '$2a$10$3a3vj36oEWh7lS0VomsF8.nGaisKknC977BiZtJJE23EeMhVcNrsi', NULL, b'1', NULL, NULL),
('andresf@gmail.com', 'Andres', 'Arroyo', '$2a$10$PNml2jmTmQGFyz2bLOC1r.7e2xTprNSmjCcIA3LKw7LqtrOIVPEC2', NULL, b'1', NULL, NULL),
('fabianr@gmail.com', 'Fabian', 'Rua', '$2a$10$M9mX8.qPf4U9ou5BhJb9l.vfOCO/p5Jp4Y.vO6o5KYGxAjDQ90T1S', NULL, b'1', NULL, NULL),
('jdavid@gmail.com', 'Jesus David', 'Dela', '$2a$10$XyU0iqD7EW4J0JxLPsbJBusI4D.TNVc04E5NAS.zoKEj.KwJvUB1a', NULL, b'1', NULL, NULL),
('pruebaarcadia382@gmail.com', 'Fabian', 'Fuente', '$2a$10$vvhiHeTy4tlXn/9ohWX/QOqS4XRMpanzGPMGmkUnQyXw2BPMebOoy', '2b6e7729-084a-4057-a18b-1f3e85c36e24', b'1', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `user_roles`
--

CREATE TABLE `user_roles` (
  `user_id` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `role_id` varchar(255) COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `user_roles`
--

INSERT INTO `user_roles` (`user_id`, `role_id`) VALUES
('admin123', 'Admin'),
('admin123@gmail.com', 'Admin'),
('jdavid@gmail.com', 'Admin'),
('andresf@gmail.com', 'user'),
('fabianr@gmail.com', 'user'),
('pruebaarcadia382@gmail.com', 'user');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `autoevaluaciones`
--
ALTER TABLE `autoevaluaciones`
  ADD PRIMARY KEY (`autoevaluacion_id`),
  ADD KEY `fk_programa_id` (`programa_id`),
  ADD KEY `fk_modelo_id` (`modelo_id`),
  ADD KEY `fk_autoevaluaciones_user` (`user_id`);

--
-- Indices de la tabla `calificacion_caracteristica`
--
ALTER TABLE `calificacion_caracteristica`
  ADD PRIMARY KEY (`calificacion_caracteristica_id`),
  ADD KEY `factor_id` (`calificacion_factor_id`),
  ADD KEY `fk_crud_caracteristica_id` (`caracteristica_id`);

--
-- Indices de la tabla `calificacion_factor`
--
ALTER TABLE `calificacion_factor`
  ADD PRIMARY KEY (`calificacion_factor_id`),
  ADD KEY `fk_crud_factor_id` (`factor_id`),
  ADD KEY `fk_autoevaluacion` (`autoevaluacion_id`);

--
-- Indices de la tabla `calificacion_indicador`
--
ALTER TABLE `calificacion_indicador`
  ADD PRIMARY KEY (`calificacion_indicador_id`),
  ADD KEY `escala_id` (`escala_id`),
  ADD KEY `caracteristica_id` (`calificacion_caracteristica_id`),
  ADD KEY `fk_indicador_id` (`indicador_id`);

--
-- Indices de la tabla `caracteristicas`
--
ALTER TABLE `caracteristicas`
  ADD PRIMARY KEY (`caracteristica_id`),
  ADD KEY `factor_id` (`factor_id`);

--
-- Indices de la tabla `escalas`
--
ALTER TABLE `escalas`
  ADD PRIMARY KEY (`escala_id`);

--
-- Indices de la tabla `factores`
--
ALTER TABLE `factores`
  ADD PRIMARY KEY (`factor_id`),
  ADD KEY `modelo_id` (`modelo_id`);

--
-- Indices de la tabla `facultades`
--
ALTER TABLE `facultades`
  ADD PRIMARY KEY (`facultad_id`);

--
-- Indices de la tabla `fuentes`
--
ALTER TABLE `fuentes`
  ADD PRIMARY KEY (`fuente_id`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `indicadores`
--
ALTER TABLE `indicadores`
  ADD PRIMARY KEY (`indicador_id`),
  ADD KEY `caracteristica_id` (`caracteristica_id`),
  ADD KEY `fk_fuente_id` (`fuente_id`);

--
-- Indices de la tabla `modelo_acreditacion`
--
ALTER TABLE `modelo_acreditacion`
  ADD PRIMARY KEY (`modelo_id`),
  ADD KEY `fk_modelo_user` (`user_id`);

--
-- Indices de la tabla `programas`
--
ALTER TABLE `programas`
  ADD PRIMARY KEY (`programa_id`),
  ADD KEY `facultad_id` (`facultad_id`);

--
-- Indices de la tabla `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`role_name`);

--
-- Indices de la tabla `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`username`);

--
-- Indices de la tabla `user_roles`
--
ALTER TABLE `user_roles`
  ADD PRIMARY KEY (`user_id`,`role_id`),
  ADD KEY `FKa68196081fvovjhkek5m97n3y` (`role_id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `autoevaluaciones`
--
ALTER TABLE `autoevaluaciones`
  MODIFY `autoevaluacion_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `calificacion_caracteristica`
--
ALTER TABLE `calificacion_caracteristica`
  MODIFY `calificacion_caracteristica_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `calificacion_factor`
--
ALTER TABLE `calificacion_factor`
  MODIFY `calificacion_factor_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `calificacion_indicador`
--
ALTER TABLE `calificacion_indicador`
  MODIFY `calificacion_indicador_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT de la tabla `caracteristicas`
--
ALTER TABLE `caracteristicas`
  MODIFY `caracteristica_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=49;

--
-- AUTO_INCREMENT de la tabla `escalas`
--
ALTER TABLE `escalas`
  MODIFY `escala_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `factores`
--
ALTER TABLE `factores`
  MODIFY `factor_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT de la tabla `facultades`
--
ALTER TABLE `facultades`
  MODIFY `facultad_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `fuentes`
--
ALTER TABLE `fuentes`
  MODIFY `fuente_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `indicadores`
--
ALTER TABLE `indicadores`
  MODIFY `indicador_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=150;

--
-- AUTO_INCREMENT de la tabla `modelo_acreditacion`
--
ALTER TABLE `modelo_acreditacion`
  MODIFY `modelo_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `programas`
--
ALTER TABLE `programas`
  MODIFY `programa_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `autoevaluaciones`
--
ALTER TABLE `autoevaluaciones`
  ADD CONSTRAINT `fk_autoevaluaciones_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`username`),
  ADD CONSTRAINT `fk_modelo_id` FOREIGN KEY (`modelo_id`) REFERENCES `modelo_acreditacion` (`modelo_id`),
  ADD CONSTRAINT `fk_programa_id` FOREIGN KEY (`programa_id`) REFERENCES `programas` (`programa_id`);

--
-- Filtros para la tabla `calificacion_caracteristica`
--
ALTER TABLE `calificacion_caracteristica`
  ADD CONSTRAINT `calificacion_caracteristica_ibfk_1` FOREIGN KEY (`calificacion_factor_id`) REFERENCES `calificacion_factor` (`calificacion_factor_id`),
  ADD CONSTRAINT `fk_crud_caracteristica_id` FOREIGN KEY (`caracteristica_id`) REFERENCES `caracteristicas` (`caracteristica_id`);

--
-- Filtros para la tabla `calificacion_factor`
--
ALTER TABLE `calificacion_factor`
  ADD CONSTRAINT `fk_autoevaluacion` FOREIGN KEY (`autoevaluacion_id`) REFERENCES `autoevaluaciones` (`autoevaluacion_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_crud_factor_id` FOREIGN KEY (`factor_id`) REFERENCES `factores` (`factor_id`);

--
-- Filtros para la tabla `calificacion_indicador`
--
ALTER TABLE `calificacion_indicador`
  ADD CONSTRAINT `calificacion_indicador_ibfk_2` FOREIGN KEY (`escala_id`) REFERENCES `escalas` (`escala_id`),
  ADD CONSTRAINT `calificacion_indicador_ibfk_3` FOREIGN KEY (`calificacion_caracteristica_id`) REFERENCES `calificacion_caracteristica` (`calificacion_caracteristica_id`),
  ADD CONSTRAINT `fk_indicador_id` FOREIGN KEY (`indicador_id`) REFERENCES `indicadores` (`indicador_id`);

--
-- Filtros para la tabla `caracteristicas`
--
ALTER TABLE `caracteristicas`
  ADD CONSTRAINT `caracteristicas_ibfk_1` FOREIGN KEY (`factor_id`) REFERENCES `factores` (`factor_id`);

--
-- Filtros para la tabla `factores`
--
ALTER TABLE `factores`
  ADD CONSTRAINT `factores_ibfk_1` FOREIGN KEY (`modelo_id`) REFERENCES `modelo_acreditacion` (`modelo_id`);

--
-- Filtros para la tabla `indicadores`
--
ALTER TABLE `indicadores`
  ADD CONSTRAINT `fk_fuente_id` FOREIGN KEY (`fuente_id`) REFERENCES `fuentes` (`fuente_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `indicadores_ibfk_1` FOREIGN KEY (`caracteristica_id`) REFERENCES `caracteristicas` (`caracteristica_id`);

--
-- Filtros para la tabla `modelo_acreditacion`
--
ALTER TABLE `modelo_acreditacion`
  ADD CONSTRAINT `fk_modelo_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`username`);

--
-- Filtros para la tabla `programas`
--
ALTER TABLE `programas`
  ADD CONSTRAINT `programas_ibfk_1` FOREIGN KEY (`facultad_id`) REFERENCES `facultades` (`facultad_id`);

--
-- Filtros para la tabla `user_roles`
--
ALTER TABLE `user_roles`
  ADD CONSTRAINT `FK859n2jvi8ivhui0rl0esws6o` FOREIGN KEY (`user_id`) REFERENCES `users` (`username`),
  ADD CONSTRAINT `FKa68196081fvovjhkek5m97n3y` FOREIGN KEY (`role_id`) REFERENCES `roles` (`role_name`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
