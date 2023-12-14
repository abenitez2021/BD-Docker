-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 25-10-2023 a las 14:50:29
-- Versión del servidor: 10.4.28-MariaDB
-- Versión de PHP: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `enter`
--

DELIMITER ;;
--
-- Procedimientos
--
CREATE DEFINER=`root`@`%.%.%.%` PROCEDURE `sp_dashboard_cabecera_list` ()   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);

	SELECT
	-- (SELECT COUNT(id) FROM visitas WHERE entrada is not null AND salida is null AND CAST(entrada AS DATE) = CURDATE()) AS visitasPermanecen,
	-- (SELECT COUNT(id) FROM visitas WHERE CAST(entrada AS DATE) = CURDATE()) AS ingresosDia,
	-- (SELECT COUNT(id) FROM visitas) AS ingresosMes,
	(SELECT COUNT(id) FROM usuarios_marcacion WHERE entrada is not null AND salida is null AND CAST(entrada AS DATE) = CURDATE()) AS guardiasActivos,

	(SELECT COUNT(id) FROM visitas WHERE CAST(entrada AS DATE) = CURDATE() AND entrada is not null AND salida is null) AS visitasPermanecen,
	(SELECT COUNT(id) FROM visitas WHERE CAST(entrada AS DATE) = CURDATE() AND entrada is not null AND salida is not null) AS salidasDia,
	(SELECT COUNT(id) FROM visitas WHERE CAST(entrada AS DATE) = CURDATE() ) AS ingresosDia;
END;;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_dashboard_dependencia` (IN `v_user` INT, IN `v_marcacion` VARCHAR(50))   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);

	SELECT COUNT(t1.id) AS cantidad,
	t2.nombre AS name,
	t2.color
	FROM visitas t1
		LEFT JOIN dependencias t2 ON t1.id_dependencia = t2.id
	WHERE CAST(t1.entrada AS DATE) = CURDATE() 
		AND IFNULL(v_marcacion,'ALL') like 
			CASE WHEN v_marcacion = 'Entrada' THEN 'Entrada'
			WHEN v_marcacion = 'Salida' AND t1.entrada IS NOT NULL AND t1.salida IS NOT NULL THEN 'Salida'
			WHEN v_marcacion = 'Permanecen' AND t1.entrada IS NOT NULL AND t1.salida IS NULL THEN 'Permanecen'
			ELSE 'ALL' END
	GROUP BY t2.nombre, t2.color;
END;;

CREATE DEFINER=`root`@`%.%.%.%` PROCEDURE `sp_dashboard_visita_list` ()   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);
	
	SELECT 
	t1.id AS idVisita,
	t1.nombre,
	t1.apellido,
	t1.nro_documento AS documento,
	t1.tipo_documento AS tipoDocumento,
	t1.foto,
	t1.imagen_frente AS fotoCedulaFrente,
	t1.imagen_dorso AS fotoCedulaDorso,
	-- t1.foto_documento AS fotoDocumento,
	t1.nacionalidad,
	DATE_FORMAT(t1.entrada, '%d-%m-%Y %h:%i:%s') AS entrada,
	DATE_FORMAT(t1.salida, '%d-%m-%Y %h:%i:%s') AS salida,
	CASE WHEN t1.entrada IS NOT NULL AND t1.salida IS NULL THEN 'Entrada' 
		WHEN t1.entrada IS NOT NULL AND t1.salida IS NOT NULL THEN 'Salida' 
		WHEN t1.entrada IS NULL AND t1.salida IS NULL THEN 'Sin Marcacion'
		ELSE 'Sin Entrada' END AS marcacion
	FROM visitas t1
	ORDER BY  t1.entrada DESC LIMIT 10;
	
END;;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_dependencias_inactive` (IN `v_idUser` INT, IN `v_id` INT)   BEGIN
			
	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);	

	IF NOT EXISTS (SELECT id FROM usuarios WHERE id = v_idUser) THEN 
	SET errmsg = 'El usuario no existe';
	SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = errno, MESSAGE_TEXT = errmsg;
	
		ELSE
		UPDATE dependencias
		SET 
		estado = 'INACTIVO'
		WHERE id = v_id;
	
	END IF;
END;;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_dependencias_insert` (IN `v_idUser` INT, IN `v_nombre` VARCHAR(100), IN `v_color` VARCHAR(100))   BEGIN
			
	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);	

	IF NOT EXISTS (SELECT id FROM usuarios WHERE id = v_idUser) THEN 
	SET errmsg = 'El usuario no existe';
	SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = errno, MESSAGE_TEXT = errmsg;
	
		ELSE
		INSERT INTO dependencias
		(nombre, color)
		VALUES
		(v_nombre, v_color);
	
		SELECT LAST_INSERT_ID() AS idDepndencia; 
	
	END IF;
END;;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_dependencias_list` (IN `v_idUser` INT)   BEGIN
			
	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);	

	IF NOT EXISTS (SELECT id FROM usuarios WHERE id = v_idUser) THEN 
	SET errmsg = 'El usuario no existe';
	SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = errno, MESSAGE_TEXT = errmsg;
	
		ELSE
		SELECT 
		id AS idDependencia,
		nombre, color
		FROM dependencias
		WHERE estado = 'ACTIVO';

	
	END IF;
END;;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_dependencias_update` (IN `v_idUser` INT, IN `v_id` INT, IN `v_nombre` VARCHAR(255), IN `v_color` VARCHAR(100))   BEGIN
			
	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);	

	IF NOT EXISTS (SELECT id FROM usuarios WHERE id = v_idUser) THEN 
	SET errmsg = 'El usuario no existe';
	SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = errno, MESSAGE_TEXT = errmsg;
	
		ELSE
		UPDATE dependencias
		SET 
		nombre = v_nombre,
		color = v_color
		WHERE id = v_id;
	
	END IF;
END;;

CREATE DEFINER=`ab9251_enter`@`%` PROCEDURE `sp_grafica_semana_listar` ()   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);
	
		SELECT 
			'Luneas' AS dia,
			'22' AS entradas,
			'22' AS salidas
	UNION ALL
		SELECT 
			'Martes' AS dia,
			'30' AS entradas,
			'25' AS salidas
	UNION ALL
		SELECT 
			'Miercoles' AS dia,
			'29' AS entradas,
			'29' AS salidas
	UNION ALL
		SELECT 
			'Jueves' AS dia,
			'25' AS entradas,
			'25' AS salidas
	UNION ALL
		SELECT 
			'Viernes' AS dia,
			'20' AS entradas,
			'5' AS salidas
	UNION ALL
		SELECT 
			'Sabado' AS dia,
			'0' AS entradas,
			'0' AS salidas
	UNION ALL
		SELECT 
			'Domingo' AS dia,
			'0' AS entradas,
			'0' AS salidas;
	
END;;

CREATE DEFINER=`root`@`%.%.%.%` PROCEDURE `sp_marcacion_insert` (IN `v_user` INT, IN `v_idDependencia` INT)   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);
	DECLARE p_id INT;

	IF NOT EXISTS(SELECT id FROM usuarios WHERE id = v_user) THEN
	SET errmsg = 'El usuario no esta registrado';
	SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = errno, MESSAGE_TEXT = errmsg;

	
	ELSEIF NOT EXISTS(SELECT t1.id FROM usuarios_marcacion t1 JOIN (SELECT MAX(id) AS id FROM usuarios_marcacion WHERE id_usuario = v_user) t2 ON t1.id = t2.id
				WHERE entrada IS NOT NULL AND salida IS NULL) THEN
				
		INSERT INTO usuarios_marcacion
		(id_usuario, entrada, id_dependencia)
		VALUES 
		(v_user, now(), v_idDependencia);
		
		SELECT LAST_INSERT_ID() AS idMarcacion; 
	

	
	ELSEIF EXISTS(SELECT t1.id FROM usuarios_marcacion t1 JOIN (SELECT MAX(id) AS id FROM usuarios_marcacion WHERE id_usuario = v_user) t2 ON t1.id = t2.id
				WHERE entrada IS NOT NULL AND salida IS NULL) THEN
				
		SET p_id = (SELECT t1.id FROM usuarios_marcacion t1 JOIN (SELECT MAX(id) AS id FROM usuarios_marcacion WHERE id_usuario = v_user) t2 ON t1.id = t2.id
				WHERE entrada IS NOT NULL AND salida IS NULL);
				
		UPDATE usuarios_marcacion
		SET 
		salida = now()
		WHERE id = p_id;
		
		SELECT p_id AS idMarcacion;
	
	END IF;
END;;

CREATE DEFINER=`root`@`%.%.%.%` PROCEDURE `sp_marcacion_list` (IN `v_idRol` INT, IN `v_fechaDesde` DATE, IN `v_fechaHasta` DATE, IN `v_marcacion` VARCHAR(100), IN `v_idDependencia` INT)   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);
	
	SELECT 
	t2.id AS idMarcacion,
	t1.id AS idUsuario,
	t1.nombre,
	t1.apellido,
	t1.documento AS documento,
	t1.foto,
	t1.tipo_documento AS tipoDocumento,
	t1.correo,
	t1.nro_celular AS celular,
	t1.nro_telefono AS telefono,
	t3.id AS idRol,
	t3.nombre AS rol,
	DATE_FORMAT(t2.entrada, '%d-%m-%Y %h:%i:%s') AS entrada,
	DATE_FORMAT(t2.salida, '%d-%m-%Y %h:%i:%s') AS salida,
	CASE WHEN t2.entrada IS NOT NULL AND t2.salida IS NULL THEN 'Entrada' 
		WHEN t2.entrada IS NOT NULL AND t2.salida IS NOT NULL THEN 'Salida' 
		WHEN t2.entrada IS NULL AND t2.salida IS NULL THEN 'Sin Marcacion'
		ELSE 'Sin Entrada' END AS marcacion,
	t4.id AS idDependencia,
	t4.nombre AS dependencia
	FROM usuarios t1
		JOIN usuarios_marcacion t2 ON t1.id = t2.id_usuario
		LEFT JOIN roles t3 ON t1.id_rol = t3.id
		LEFT JOIN dependencias t4 ON t2.id_dependencia = t4.id
	WHERE t1.id_rol like CASE WHEN v_idRol IS NOT NULL THEN v_idRol ELSE '%%' end
		-- AND t2.id_dependencia like CASE WHEN v_idDependencia IS NOT NULL THEN v_idDependencia ELSE '%%' END
	order by t2.id desc;
	
END;;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_puestos_inactive` (IN `v_id` INT)   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);
	
	UPDATE puestos 
	SET
	estado = 'INACTIVO'
	WHERE id = v_id;

END;;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_puestos_insert` (IN `v_descripcion` VARCHAR(100), IN `v_nombre` VARCHAR(100), IN `v_ip` VARCHAR(25), IN `v_puerto` VARCHAR(25), IN `v_url` VARCHAR(255), IN `v_subcarpeta` VARCHAR(100), IN `v_servidor` BOOL, IN `v_tipo` VARCHAR(100), IN `v_ubicacionServidor` VARCHAR(100))   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);
	
	INSERT INTO puestos 
	(descripcion,
	nombre,
	ip,
	puerto,
	ubicacion,
	subcarpeta,
	servidor,
	tipo,
	ubicacion_servidor)
	VALUES
	(v_descripcion,
	v_nombre,
	v_ip,
	v_puerto,
	v_url,
	v_subcarpeta,
	IFNULL(v_servidor,false),
	v_tipo,
	v_ubicacionServidor);

	SELECT LAST_INSERT_ID() AS idPuesto; 
END;;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_puestos_list` (IN `v_id` INT)   BEGIN 
	
	SELECT 
	t1.id AS idPuesto,
	t1.descripcion,
	t1.nombre,
	t1.ip AS ipPuesto,
	t1.puerto,
	t1.ubicacion AS ubicacionCarpeta,
	t1.servidor,
	t1.tipo,
	t1.ubicacion_servidor AS ubicacionServidor,
	t1.subcarpeta,
	t1.sistema_operativo,
	t2.id AS idImpresora,
	t2.archivo_principal AS archivoPrincipal,
	t2.archivo_secundario AS archivoSecundario,
	t2.foto,
	t2.imagen_frente AS imagenFrente,
	t2.imagen_dorso AS imagenDorso,
	t2.subcarpeta AS subcarpetaImpresora,
	t1.ubicacion_servidor AS urlServidor
	
	FROM puestos t1
		LEFT JOIN impresoras t2 ON t1.id_impresora = t2.id
	WHERE t1.id like CASE WHEN v_id IS NULL THEN '%%'  ELSE v_id END;
	
END;;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_puestos_update` (IN `v_id` INT, IN `v_descripcion` VARCHAR(100), IN `v_nombre` VARCHAR(100), IN `v_ip` VARCHAR(25), IN `v_puerto` VARCHAR(25), IN `v_url` VARCHAR(255), IN `v_subcarpeta` VARCHAR(100), IN `v_servidor` BOOL, IN `v_tipo` VARCHAR(100), IN `v_ubicacionServidor` VARCHAR(100))   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);
	
	UPDATE puestos 
	SET
	descripcion = v_descripcion,
	nombre = v_nombre,
	ip = v_ip,
	puerto = v_puerto,
	ubicacion = v_url,
	subcarpeta = v_subcarpeta,
	servidor = IFNULL(v_servidor, false),
	tipo = v_tipo,
	ubicacion_servidor = v_ubicacionServidor
	WHERE id = v_id;

END;;

CREATE DEFINER=`root`@`%.%.%.%` PROCEDURE `sp_rol_list` ()   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);

	SELECT id AS idRol, nombre
	FROM roles
	WHERE estado = 'ACTIVO';

END;;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_tipo_documento_list` ()   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);
	
	SELECT 
	id AS idTipoDocumento,
	nombre AS descripcion,
	codigo
	FROM tipo_documento
	WHERE estado = 'ACTIVO';
END;;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_user_documentos_update` (IN `v_id` INT, IN `v_foto` VARCHAR(255), IN `v_frente` VARCHAR(255), IN `v_dorso` VARCHAR(255))   BEGIN
			
	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);	

	IF NOT EXISTS (SELECT id FROM usuarios WHERE id = v_id) THEN 
	SET errmsg = 'El usuario no existe';
	SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = errno, MESSAGE_TEXT = errmsg;
	
		ELSE
		UPDATE usuarios 
		SET
		foto = v_foto,
		imagen_frente = v_frente,
		imagen_dorso  = v_dorso
		WHERE id = v_id;
	
	END IF;
END;;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_user_list` (IN `v_idRol` INT, IN `v_estado` VARCHAR(50))   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);
	DECLARE urlEndpoint VARCHAR(255) DEFAULT (SELECT 'usuarios/ver-archivo/nro/');
	
	SELECT 
	t1.id AS idUsuario,
	t1.nombre,
	t1.apellido,
	t1.documento AS documento,
	-- t1.foto,
	t1.tipo_documento AS tipoDocumento,
	t1.correo,
	t1.nro_celular AS celular,
	t1.nro_telefono AS telefono,
	t3.id AS idRol,
	t3.nombre AS rol,
	CONCAT(t4.url_api,urlEndpoint,t1.documento,'/archivo/',t1.foto) AS foto,
	CONCAT(t4.url_api,urlEndpoint,t1.documento,'/archivo/',t1.foto) AS urlFoto,
	t4.url_api, urlEndpoint, t1.documento as doc,  t1.foto as fot
	
	FROM usuarios t1
		LEFT JOIN roles t3 ON t1.id_rol = t3.id
		LEFT JOIN puestos t4 ON t4.id =(select id from puestos where servidor = true
										and estado = 'ACTIVO'
										order by id limit 1)
	WHERE t1.id_rol like CASE WHEN v_idRol IS NOT NULL THEN v_idRol ELSE '%%' END
		AND t1.estado like CASE WHEN v_estado IS NOT NULL THEN v_estado ELSE '%%' END;
	
END;;

CREATE DEFINER=`root`@`%.%.%.%` PROCEDURE `sp_user_login` (IN `v_user` INT)   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);

	IF NOT EXISTS(SELECT id FROM usuarios WHERE id = v_user) THEN
	SET errmsg = 'El usuario no esta registrado';
	SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = errno, MESSAGE_TEXT = errmsg;

	ELSE	
	SELECT 
	t1.id,
	t1.nombre,
	t1.apellido,
	t1.correo,
	t1.documento AS documento,
	t1.tipo_documento AS tipoDocumento,
	t3.id AS idRol,
	t3.nombre AS rol,
	t1.nro_celular AS celular,
	t1.nro_telefono AS telefono,
	DATE_FORMAT(t2.entrada, '%d-%m-%Y %h:%i:%s') AS entrada,
	DATE_FORMAT(t2.salida, '%d-%m-%Y %h:%i:%s') AS salida,
	CASE WHEN t2.entrada IS NOT NULL AND t2.salida IS NULL THEN 'Entrada' 
		WHEN t2.entrada IS NOT NULL AND t2.salida IS NOT NULL THEN 'Salida' 
		WHEN t2.entrada IS NULL AND t2.salida IS NULL THEN 'Sin Marcacion'
		ELSE 'Sin Entrada' END AS marcacion,
	t2.id_dependencia AS idDependencia,
	t4.nombre AS dependencia,
	CASE WHEN t1.id_rol = 1 THEN true ELSE false END AS visitasDia,
	CASE WHEN t1.id_rol = 1 THEN true ELSE false END AS movimientos,
	CASE WHEN t1.id_rol = 1 THEN true ELSE false END AS gestion,
	CASE WHEN t1.id_rol = 1 THEN true ELSE false END AS sistema
	FROM usuarios t1
		LEFT JOIN (SELECT MAX(id) AS id, id_usuario FROM usuarios_marcacion GROUP BY id_usuario) t5 ON t1.id = t5.id_usuario
		LEFT JOIN usuarios_marcacion t2 ON t1.id = t2.id_usuario AND t5.id = t2.id
		LEFT JOIN roles t3 ON t1.id_rol = t3.id
		LEFT JOIN dependencias t4 ON t2.id_dependencia = t4.id 
	WHERE t1.id = v_user;
	
	END IF;
END;;

CREATE DEFINER=`root`@`%.%.%.%` PROCEDURE `sp_user_registro_insert` (IN `v_documento` VARCHAR(100), IN `v_contrasena` VARCHAR(255), IN `v_nombre` VARCHAR(100), IN `v_apellido` VARCHAR(100), IN `v_idRol` INT, IN `v_idTipoDocumento` INT, IN `v_tipoDocumento` VARCHAR(100), IN `v_correo` VARCHAR(255), IN `v_nroCelular` VARCHAR(50), IN `v_nroTelefono` VARCHAR(50), IN `v_codNacionalidad` VARCHAR(25), IN `v_nacionalidad` VARCHAR(100), IN `v_fechaNacimiento` VARCHAR(25), IN `v_fechaExpiracion` VARCHAR(25), IN `v_fechaEmision` VARCHAR(25), IN `v_sexo` VARCHAR(3), IN `v_estadoCivil` VARCHAR(100), IN `v_user` INT)   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);

	INSERT INTO usuarios 
	(
	documento,  contrasena, nombre, apellido, 
	id_rol, id_tipo_documento, tipo_documento, 
	correo, nro_celular, nro_telefono,
	cod_nacionalidad, nacionalidad, 
	fecha_nacimiento, fecha_expiracion, fecha_emision,
	cod_sexo, sexo, estado_civil
	)
	VALUES
	(
	v_documento, v_contrasena, v_nombre, v_apellido, 
	v_idRol, v_idTipoDocumento, v_tipoDocumento,
	v_correo, v_nroCelular, v_nroTelefono,
	v_codNacionalidad, v_nacionalidad,
	v_fechaNacimiento, v_fechaExpiracion, v_fechaEmision,
	v_sexo, CASE WHEN v_sexo = 'M' THEN 'MASCULINO' WHEN v_sexo = 'F' THEN 'FEMENINO' ELSE 'OTROS' END, v_estadoCivil
	);

	SELECT LAST_INSERT_ID() AS idUsuario; 

END;;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_visitas_buscar_list` (IN `v_documento` VARCHAR(50))   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);
	DECLARE urlApi VARCHAR(255) DEFAULT (SELECT 'http://localhost:7001/api/visitas/ver-archivo/nro/');
	DECLARE urlServidor VARCHAR(255) DEFAULT (SELECT '/Applications/XAMPP/xamppfiles/htdocs/enter/servidor/documentos/');
	
	SELECT 
	t1.nombre,
	t1.apellido,
	t1.nro_documento AS documento,
	t1.tipo_documento AS tipoDocumento,
	t1.tipo_documento AS codTipoDocumento, 
	-- fotos,
	t1.foto,
	t1.imagen_frente AS imagenFrente,
	t1.imagen_dorso AS imagenDorso,
	-- t1.foto  AS urlFoto,
	CONCAT(urlApi,t1.nro_documento,'/archivo/',foto) AS urlFoto,
	CONCAT(urlApi,t1.nro_documento,'/archivo/',t1.imagen_frente) AS urlImagenFrente,
	CONCAT(urlApi,t1.nro_documento,'/archivo/',t1.imagen_frente) AS urlImagenDorso,
	t1.cod_nacionalidad AS codNacionalidad, 
	t1.nacionalidad,
	t1.fecha_nacimiento AS fechaNacimiento,
	t1.fecha_expiracion AS fechaExpiracionDocumento,
	t1.fecha_emision AS fechaEmision,
	t1.sexo,
	t1.estado_civil AS estadoCivil,
	CONCAT(urlServidor,t1.nro_documento,'/',t1.id,'/') AS url
	FROM visitas t1
	WHERE t1.nro_documento like CASE WHEN v_documento IS NOT NULL THEN v_documento ELSE '%%' END
	ORDER BY t1.id DESC LIMIT 1;
	
end;;

CREATE DEFINER=`ab9251_enter`@`%` PROCEDURE `sp_visitas_dashboard` ()   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);

	SELECT
	'10' AS entradasHoy,
	'5' AS salidasHoy,
	'15' AS totalPersonas;
	
END;;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_visitas_documentos_update` (IN `v_id` INT, IN `v_foto` VARCHAR(255), IN `v_frente` VARCHAR(255), IN `v_dorso` VARCHAR(255))   BEGIN
			
	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);	

	IF NOT EXISTS (SELECT id FROM visitas WHERE id = v_id) THEN 
	SET errmsg = 'LA visita no existe';
	SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = errno, MESSAGE_TEXT = errmsg;
	
		ELSE
		UPDATE visitas 
		SET
		foto = v_foto,
		imagen_frente = v_frente,
		imagen_dorso  = v_dorso
		WHERE id = v_id;
	
	END IF;
END;;

CREATE DEFINER=`root`@`%.%.%.%` PROCEDURE `sp_visitas_entrada` (IN `v_nombre` VARCHAR(100), IN `v_apellido` VARCHAR(100), IN `v_nroDocumento` VARCHAR(100), IN `v_idTipoDocumento` INT, IN `v_tipoDocumento` VARCHAR(100), IN `v_codNacionalidad` VARCHAR(25), IN `v_nacionalidad` VARCHAR(100), IN `v_fechaNacimiento` VARCHAR(25), IN `v_fechaExpiracion` VARCHAR(25), IN `v_fechaEmision` VARCHAR(25), IN `v_sexo` VARCHAR(3), IN `v_estadoCivil` VARCHAR(100), IN `v_identityCardNumber` VARCHAR(255), IN `v_idDependencia` INT, IN `v_idPuesto` INT, IN `v_codigoTarjeta` VARCHAR(100), IN `v_user` INT, IN `TransactionID` VARCHAR(100), IN `ComputerName` VARCHAR(100), IN `UserName` VARCHAR(100), IN `SDKVersion` VARCHAR(100), IN `FileVersion` VARCHAR(100), IN `DeviceType` VARCHAR(100), IN `DeviceNumber` VARCHAR(100), IN `DeviceLabelNumber` VARCHAR(100))   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);
	DECLARE p_idVisita INT;

	INSERT INTO visitas  
	(nombre, apellido, nro_documento, id_tipo_documento, tipo_documento,
	cod_nacionalidad, nacionalidad, 
	fecha_nacimiento, fecha_expiracion, fecha_emision,
	cod_sexo, sexo, 
	estado_civil, identity_card_number,
	id_dependencia, id_puesto, codigo_tarjeta, id_usuario, entrada)
	SELECT
	v_nombre, v_apellido, v_nroDocumento, v_idTipoDocumento, v_tipoDocumento,
	v_codNacionalidad, v_nacionalidad,
	v_fechaNacimiento, v_fechaExpiracion, v_fechaEmision,
	v_sexo, CASE WHEN v_sexo = 'M' THEN 'MASCULINO' WHEN v_sexo = 'F' THEN 'FEMENINO' ELSE 'OTROS' END, 
	v_estadoCivil, v_identityCardNumber,
	v_idDependencia, v_idPuesto, v_codigoTarjeta, v_user, now();

	SET p_idVisita = (SELECT LAST_INSERT_ID());

	INSERT INTO visitas_datos_puesto
	(id_visita, transaction_id, computer_name, user_name, sdk_version, file_version, device_type, device_number, device_abel_number)
	VALUES
	(p_idVisita, TransactionID, ComputerName, UserName, SDKVersion, FileVersion, DeviceType, DeviceNumber, DeviceLabelNumber);
	
	SELECT p_idVisita AS idVisita;

END;;

CREATE DEFINER=`root`@`%.%.%.%` PROCEDURE `sp_visitas_list` (IN `v_idPuesto` INT, IN `v_idVisita` INT, IN `v_desde` DATE, IN `v_hasta` DATE, IN `v_marcacion` VARCHAR(50), IN `v_documento` VARCHAR(50), IN `v_idDpendencia` INT, IN `v_user` INT)   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);
	DECLARE urlEndpoint VARCHAR(255) DEFAULT (SELECT 'visitas/ver-archivo/nro/');
	
	SELECT 
	t1.id AS idVisita,
	t1.nombre,
	t1.apellido,
	DATE_FORMAT(t1.entrada, '%d-%m-%Y %H:%i:%s') AS entrada,
	DATE_FORMAT(t1.salida, '%d-%m-%Y %H:%i:%s') AS salida,
	CASE WHEN t1.entrada IS NOT NULL AND t1.salida IS NULL THEN 'Entrada' 
		WHEN t1.entrada IS NOT NULL AND t1.salida IS NOT NULL THEN 'Salida' 
		WHEN t1.entrada IS NULL AND t1.salida IS NULL THEN 'Sin Marcacion'
		ELSE 'Sin Entrada' END AS marcacion,
	t1.nro_documento AS documento,
	t1.tipo_documento AS tipoDocumento,
	t1.tipo_documento AS codTipoDocumento, 
	-- fotos,
	t1.foto,
	t1.imagen_frente AS imagenFrente,
	t1.imagen_dorso AS imagenDorso,
	
	CONCAT(t4.url_api,urlEndpoint,t1.nro_documento,'/archivo/',t1.foto) AS urlFoto,
	CONCAT(t4.url_api,urlEndpoint,t1.nro_documento,'/archivo/',t1.imagen_frente) AS urlImagenFrente,
	CONCAT(t4.url_api,urlEndpoint,t1.nro_documento,'/archivo/',t1.imagen_dorso) AS urlImagenDorso,
	-- ----
	-- CONCAT(urlServidor,t1.nro_documento,'/',t1.id,'/',t1.foto) AS urlFoto,
	-- CONCAT(urlServidor,t1.nro_documento,'/',t1.id,'/',t1.imagen_frente) AS urlImagenFrente,
	-- CONCAT(urlServidor,t1.nro_documento,'/',t1.id,'/',t1.imagen_dorso) AS urlImagenDorso,
	-- ---
	
	t1.cod_nacionalidad AS codNacionalidad,
	t1.nacionalidad,
	t1.fecha_nacimiento AS fechaNacimiento,
	t1.fecha_expiracion AS fechaExpiracionDocumento,
	t1.fecha_emision AS fechaEmision,
	t1.sexo,
	t1.estado_civil AS esstadoCivil,
	t1.id_dependencia AS idDependencia,
	t2.nombre AS dependencia,
	t1.id_puesto AS idPuesto,
	t3.descripcion AS puesto
	FROM visitas t1
		JOIN dependencias t2 ON t1.id_dependencia = t2.id
		LEFT JOIN puestos t3 ON t1.id_puesto = t3.id
		LEFT JOIN puestos t4 ON t4.id =(select id from puestos where id like CASE WHEN v_idPuesto IS NULL THEN '%%'  ELSE v_idPuesto end
										and estado like case when v_idPuesto is null then 'ACTIVO' else '%%' end 
										order by t1.id limit 1)
	WHERE t1.id like CASE WHEN v_idVisita IS NOT NULL THEN v_idVisita ELSE '%%' END 
		 AND CAST(t1.entrada AS DATE) BETWEEN (CASE WHEN v_desde IS NOT NULL THEN v_desde ELSE CURDATE() END) 
		 						AND (CASE WHEN v_hasta IS NOT NULL THEN v_hasta ELSE CURDATE() END) 
		AND t1.nro_documento like CASE WHEN v_documento IS NOT NULL THEN v_documento ELSE '%%' END 
		AND t1.id_dependencia  like CASE WHEN v_idDpendencia IS NOT NULL THEN v_idDpendencia ELSE '%%' END
		AND IFNULL(v_marcacion,'ALL') like 
			CASE WHEN v_marcacion = 'Entrada' THEN 'Entrada'
			WHEN v_marcacion = 'Salida' AND t1.entrada IS NOT NULL AND t1.salida IS NOT NULL THEN 'Salida'
			WHEN v_marcacion = 'Permanecen' AND t1.entrada IS NOT NULL AND t1.salida IS NULL THEN 'Permanecen'
			ELSE 'ALL' END
			
	ORDER BY  t1.entrada DESC;
	
END;;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_visitas_list_group` (IN `v_idVisita` INT, IN `v_desde` DATE, IN `v_hasta` DATE, IN `v_marcacion` VARCHAR(50), IN `v_documento` VARCHAR(50), IN `v_idDpendencia` INT, IN `v_user` INT)   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);
	DECLARE urlEndpoint VARCHAR(255) DEFAULT (SELECT 'visitas/ver-archivo/nro/');

	
	SELECT t2.idVisita AS idVisita,
		t1.nombre, t1.apellido, 
		t1.nro_documento AS documento,
		t1.tipo_documento AS tipoDocumento,
		t1.foto, t1.imagen_frente AS fotoCedulaFrente, t1.imagen_dorso AS fotoCedulaDorso,
		t1.nacionalidad,
		DATE_FORMAT(t1.entrada, '%d-%m-%Y %h:%i:%s') AS ultimaVisita, t2.cantidad,
		CONCAT(t4.url_api,urlEndpoint,t1.nro_documento,'/archivo/',t1.foto) AS foto,
		CONCAT(t4.url_api,urlEndpoint,t1.nro_documento,'/archivo/',t1.foto) AS urlFoto
	FROM (SELECT MAX(id) AS idVisita, COUNT(id) AS cantidad, nro_documento FROM visitas GROUP BY nro_documento) t2
	join visitas t1 ON t2.idVisita = t1.id
	LEFT JOIN puestos t4 ON t4.id =(select id from puestos where servidor = true
										and estado = 'ACTIVO'
										order by id limit 1)
	
		WHERE t1.id like CASE WHEN v_idVisita IS NOT NULL THEN v_idVisita ELSE '%%' END 
			 -- AND CAST(t1.entrada AS DATE) BETWEEN (CASE WHEN v_desde IS NOT NULL THEN v_desde ELSE '%%' END) 
		 						-- AND (CASE WHEN v_hasta IS NOT NULL THEN v_hasta ELSE '%%' END) 
		-- AND t1.nro_documento like CASE WHEN v_documento IS NOT NULL THEN v_documento ELSE '%%' END 
		-- AND t1.id_dependencia  like CASE WHEN v_idDpendencia IS NOT NULL THEN v_idDpendencia ELSE '%%' END
		/*AND IFNULL(v_marcacion,'ALL') like 
			CASE WHEN v_marcacion = 'Entrada' THEN 'Entrada'
			WHEN v_marcacion = 'Salida' AND t1.entrada IS NOT NULL AND t1.salida IS NOT NULL THEN 'Salida'
			WHEN v_marcacion = 'Permanecen' AND t1.entrada IS NOT NULL AND t1.salida IS NULL THEN 'Permanecen'
			ELSE 'ALL' END*/
			
	ORDER BY  t1.entrada DESC
	;
	
END;;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_visitas_puestos_list` (IN `v_id` INT)   BEGIN 
	
	SELECT 
	t1.id AS idPuesto,
	t1.descripcion,
	t1.nombre,
	t1.ip AS ipPuesto,
	t1.puerto,
	t1.ubicacion AS ubicacionCarpeta,
	t1.servidor,
	t1.tipo,
	t1.ubicacion_servidor AS ubicacionServidor,
	-- t1.subcarpeta,
	t1.sistema_operativo,
	t2.id AS idImpresora,
	t2.archivo_principal AS archivoPrincipal,
	t2.archivo_secundario AS archivoSecundario,
	t2.foto,
	t2.imagen_frente AS imagenFrente,
	t2.imagen_dorso AS imagenDorso,
	t2.subcarpeta AS subcarpetaImpresora,
	t1.ubicacion_servidor AS urlServidor
	
	FROM puestos t1
		LEFT JOIN impresoras t2 ON t1.id_impresora = t2.id
	WHERE t1.id like CASE WHEN v_id IS NULL THEN '%%'  ELSE v_id end
	and t1.estado like case when v_id is null then 'ACTIVO' else '%%' end 
	order by t1.id limit 1; 
	
END;;

CREATE DEFINER=`ab9251_enter`@`%` PROCEDURE `sp_visitas_salida` (IN `v_idVisita` INT)   BEGIN

	DECLARE errno SMALLINT UNSIGNED DEFAULT 31001;
	DECLARE errmsg VARCHAR(100);
	
	IF NOT EXISTS(SELECT id FROM visitas WHERE id = v_idVisita) THEN
	SET errmsg = 'La visita no esta registrado';
	SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = errno, MESSAGE_TEXT = errmsg;

	ELSEIF NOT EXISTS(SELECT id FROM visitas WHERE id = v_idVisita AND salida IS NULL) THEN
	SET errmsg = 'La visita ya realizo la salida';
	SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = errno, MESSAGE_TEXT = errmsg;

	ELSE
	UPDATE visitas
	SET 
	salida = now()
	WHERE id = v_idVisita
		AND salida IS NULL;
	
	END IF;

END;;

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `dependencias`
--

CREATE TABLE `dependencias` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `color` varchar(100) DEFAULT NULL,
  `estado` enum('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `dependencias`
--

INSERT INTO `dependencias` (`id`, `nombre`, `descripcion`, `color`, `estado`) VALUES
(1, 'Mesa de Entrada', '1', '#0088FE', 'ACTIVO'),
(2, 'Primer Piso', '1', '#00C49F', 'ACTIVO'),
(3, 'Porteria', '1', '#7E8E9E', 'ACTIVO');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `impresoras`
--

CREATE TABLE `impresoras` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(100) NOT NULL,
  `tipo` varchar(100) NOT NULL,
  `archivo_principal` varchar(100) NOT NULL,
  `archivo_secundario` varchar(100) DEFAULT NULL,
  `foto` varchar(100) DEFAULT NULL,
  `imagen_frente` varchar(100) DEFAULT NULL,
  `imagen_dorso` varchar(100) DEFAULT NULL,
  `subcarpeta` varchar(100) DEFAULT NULL,
  `texto_codigo` varchar(100) DEFAULT NULL,
  `texto_valor` varchar(100) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `estado` enum('ACTIVO','INACTIVO') DEFAULT 'ACTIVO'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `impresoras`
--

INSERT INTO `impresoras` (`id`, `descripcion`, `tipo`, `archivo_principal`, `archivo_secundario`, `foto`, `imagen_frente`, `imagen_dorso`, `subcarpeta`, `texto_codigo`, `texto_valor`, `created_at`, `estado`) VALUES
(1, 'Impresora Tostadora', 'TOSTADORA', 'MRZ_DATA.json', 'Text_Data.json', 'Photo.png', 'WHITE.png', 'WHITE.png', 'Page1/', 'fieldType', 'value', '2023-09-26 00:41:57', 'ACTIVO'),
(2, 'Impresora SCANNER', 'SCANNER', 'MRZ_DATA.json', 'Text_Data.json', 'Photo.png', 'WHITE.png', 'WHITE.png', 'Page1/', 'fieldType', 'value', '2023-09-26 00:41:57', 'ACTIVO');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pantallas`
--

CREATE TABLE `pantallas` (
  `id` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `fecha_create` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_inactive` datetime DEFAULT NULL,
  `estado` enum('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `pantallas`
--

INSERT INTO `pantallas` (`id`, `nombre`, `fecha_create`, `fecha_inactive`, `estado`) VALUES
(5, 'VisitasDia', '2023-09-26 00:44:05', NULL, 'ACTIVO'),
(6, 'Movimientos', '2023-09-26 00:44:05', NULL, 'ACTIVO'),
(7, 'Gestion', '2023-09-26 00:44:05', NULL, 'ACTIVO'),
(8, 'Sistema', '2023-09-26 00:44:05', NULL, 'ACTIVO');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `puestos`
--

CREATE TABLE `puestos` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(100) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `ip` varchar(25) DEFAULT NULL,
  `puerto` int(11) DEFAULT NULL,
  `ubicacion` varchar(255) NOT NULL,
  `servidor` tinyint(1) DEFAULT NULL,
  `tipo` enum('XAMPP','LOCAL') DEFAULT NULL,
  `ubicacion_servidor` varchar(255) DEFAULT NULL,
  `ubicacion_servidor_xampp` varchar(255) DEFAULT NULL,
  `url_api` varchar(255) DEFAULT NULL,
  `sistema_operativo` enum('WINDOWS','MACOS') DEFAULT 'WINDOWS',
  `id_impresora` int(11) DEFAULT NULL,
  `estado` enum('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `puestos`
--

INSERT INTO `puestos` (`id`, `descripcion`, `nombre`, `ip`, `puerto`, `ubicacion`, `servidor`, `tipo`, `ubicacion_servidor`, `ubicacion_servidor_xampp`, `url_api`, `sistema_operativo`, `id_impresora`, `estado`, `created_at`) VALUES
(1, 'PC WIN', 'PCWIN', '127.0.0.1', 80, 'C:/enter/sdk/', 1, 'LOCAL', 'C:/enter/servidor/documentos/', NULL, 'http://127.0.0.1:7001/api/', 'WINDOWS', 1, 'INACTIVO', '2023-09-26 00:48:38'),
(2, 'PC MAC', 'PCMAC', '127.0.0.1', 80, '/Applications/XAMPP/xamppfiles/htdocs/enter/sdk/', 1, 'LOCAL', '/Applications/XAMPP/xamppfiles/htdocs/enter/servidor/documentos', NULL, 'http://127.0.0.1:7001/api/', 'MACOS', 1, 'ACTIVO', '2023-09-26 00:47:00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `roles`
--

CREATE TABLE `roles` (
  `id` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `fecha_create` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_inactive` datetime DEFAULT NULL,
  `estado` enum('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `roles`
--

INSERT INTO `roles` (`id`, `nombre`, `fecha_create`, `fecha_inactive`, `estado`) VALUES
(1, 'Administrador', '2023-07-27 13:49:15', NULL, 'ACTIVO'),
(2, 'Guardia', '2023-07-27 13:49:24', NULL, 'ACTIVO');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `roles_pantallas`
--

CREATE TABLE `roles_pantallas` (
  `id` int(11) NOT NULL,
  `id_rol` int(11) NOT NULL,
  `id_pantalla` int(11) NOT NULL,
  `fecha_create` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_inactive` datetime DEFAULT NULL,
  `estado` enum('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_documento`
--

CREATE TABLE `tipo_documento` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` varchar(100) NOT NULL,
  `codigo` varchar(10) DEFAULT NULL,
  `estado` enum('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido` varchar(100) NOT NULL,
  `documento` varchar(50) NOT NULL,
  `contrasena` varchar(255) NOT NULL,
  `id_rol` int(11) NOT NULL,
  `foto` varchar(100) DEFAULT NULL,
  `imagen_frente` varchar(100) DEFAULT NULL,
  `imagen_dorso` varchar(100) DEFAULT NULL,
  `id_tipo_documento` int(11) DEFAULT NULL,
  `tipo_documento` varchar(50) NOT NULL,
  `correo` varchar(255) DEFAULT NULL,
  `nro_celular` varchar(25) DEFAULT NULL,
  `nro_telefono` varchar(25) DEFAULT NULL,
  `cod_nacionalidad` varchar(100) DEFAULT NULL,
  `nacionalidad` varchar(100) DEFAULT NULL,
  `fecha_nacimiento` varchar(100) DEFAULT NULL,
  `fecha_emision` varchar(100) DEFAULT NULL,
  `fecha_expiracion` varchar(100) DEFAULT NULL,
  `cod_sexo` varchar(100) DEFAULT NULL,
  `sexo` varchar(100) DEFAULT NULL,
  `estado_civil` varchar(100) DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 0,
  `fecha_create` datetime NOT NULL DEFAULT current_timestamp(),
  `estado` enum('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id`, `nombre`, `apellido`, `documento`, `contrasena`, `id_rol`, `foto`, `imagen_frente`, `imagen_dorso`, `id_tipo_documento`, `tipo_documento`, `correo`, `nro_celular`, `nro_telefono`, `cod_nacionalidad`, `nacionalidad`, `fecha_nacimiento`, `fecha_emision`, `fecha_expiracion`, `cod_sexo`, `sexo`, `estado_civil`, `activo`, `fecha_create`, `estado`) VALUES
(1, 'Francisco', 'Medina', '4422359', '$2a$10$gruS.j1LtB3fRbq8Iz5U8.z/7oaukIIDWqyL51Nv/RANc/D08SQ82', 2, NULL, NULL, NULL, NULL, 'C.I.N.', 'fram.medinax@gmail.com', '0981300200', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2023-07-27 13:54:52', 'ACTIVO'),
(2, 'Juan', 'Acuna', '111111', '$2a$10$7zdlSY8SW5mziZc0bgV7vOH/cM8q/DzoOBrG/euQGjYijgipl0Y2u', 2, NULL, NULL, NULL, NULL, 'Cedula de Identidad', 'juan@correo.com', '0981300200', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2023-07-28 13:20:13', 'ACTIVO'),
(6, 'Admin', 'Web', '123456', '$2a$10$14kWg7kr5Pgq1NGux3QkkevO70gG80ANQmvgvBv080TJM2npeVEb2', 1, 'foto.png', 'frente.png', 'dorso.png', 1, 'ID', 'admin@correo.com', '0981300200', NULL, 'PRY', 'PARAGUAYA', '911201', '19-06-2015', '250619', 'M', 'MASCULINO', 'SOLTERO', 0, '2023-09-26 03:27:32', 'ACTIVO');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios_marcacion`
--

CREATE TABLE `usuarios_marcacion` (
  `id` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `id_dependencia` int(11) DEFAULT NULL,
  `entrada` datetime NOT NULL DEFAULT current_timestamp(),
  `salida` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios_marcacion`
--

INSERT INTO `usuarios_marcacion` (`id`, `id_usuario`, `id_dependencia`, `entrada`, `salida`) VALUES
(4, 1, 1, '2023-09-26 01:23:58', '2023-09-26 01:28:40'),
(6, 1, 1, '2023-09-26 01:28:58', '2023-09-26 01:29:03'),
(7, 1, NULL, '2023-09-26 01:30:11', '2023-09-26 01:30:32'),
(8, 1, NULL, '2023-09-27 18:48:34', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `visitas`
--

CREATE TABLE `visitas` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido` varchar(100) NOT NULL,
  `nro_documento` varchar(50) NOT NULL,
  `id_tipo_documento` int(11) DEFAULT NULL,
  `tipo_documento` varchar(50) NOT NULL,
  `foto` varchar(255) DEFAULT NULL,
  `imagen_frente` varchar(255) DEFAULT NULL,
  `imagen_dorso` varchar(255) DEFAULT NULL,
  `cod_nacionalidad` varchar(25) DEFAULT NULL,
  `nacionalidad` varchar(255) DEFAULT NULL,
  `fecha_nacimiento` varchar(100) DEFAULT NULL,
  `fecha_expiracion` varchar(100) DEFAULT NULL,
  `fecha_emision` varchar(100) DEFAULT NULL,
  `cod_sexo` varchar(1) DEFAULT NULL,
  `sexo` varchar(25) DEFAULT NULL,
  `estado_civil` varchar(100) DEFAULT NULL,
  `identity_card_number` varchar(255) DEFAULT NULL,
  `entrada` datetime DEFAULT NULL,
  `salida` datetime DEFAULT NULL,
  `id_dependencia` int(11) DEFAULT NULL,
  `id_puesto` int(11) DEFAULT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  `codigo_tarjeta` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `visitas`
--

INSERT INTO `visitas` (`id`, `nombre`, `apellido`, `nro_documento`, `id_tipo_documento`, `tipo_documento`, `foto`, `imagen_frente`, `imagen_dorso`, `cod_nacionalidad`, `nacionalidad`, `fecha_nacimiento`, `fecha_expiracion`, `fecha_emision`, `cod_sexo`, `sexo`, `estado_civil`, `identity_card_number`, `entrada`, `salida`, `id_dependencia`, `id_puesto`, `id_usuario`, `codigo_tarjeta`) VALUES
(81, 'ARNALDO ALBE', 'RIQUELME RIVEROS', '4994624', NULL, 'ID', 'foto.png', 'frente.png', 'dorso.png', 'PRY', 'Paraguay', '1/12/1991', '19/6/2025', NULL, 'M', 'MASCULINO', NULL, NULL, '2023-09-26 01:43:48', NULL, 1, NULL, 1, NULL),
(82, 'ARNALDO ALBE', 'RIQUELME RIVEROS', '4994624', NULL, 'ID', 'foto.png', 'frente.png', 'dorso.png', NULL, 'PRY', 'Paraguay', '1/12/1991', '19/6/2025', NULL, 'OTROS', 'M', NULL, '2023-09-26 02:35:36', NULL, NULL, 1, NULL, NULL),
(83, 'ARNALDO ALBE', 'RIQUELME RIVEROS', '4994624', NULL, 'ID', 'foto.png', 'frente.png', 'dorso.png', NULL, 'PRY', 'Paraguay', '1/12/1991', '19/6/2025', NULL, 'OTROS', 'M', NULL, '2023-09-26 04:10:37', NULL, NULL, 2, NULL, NULL),
(84, 'ARNALDO ALBE', 'RIQUELME RIVEROS', '4994624', NULL, 'ID', 'foto.png', 'frente.png', 'dorso.png', NULL, 'PRY', 'Paraguay', '1/12/1991', '19/6/2025', NULL, 'OTROS', 'M', NULL, '2023-09-26 04:12:00', NULL, NULL, 1, NULL, NULL),
(85, 'ARNALDO ALBE', 'RIQUELME RIVEROS', '4994624', NULL, 'ID', 'foto.png', 'frente.png', 'dorso.png', 'PRY', 'Paraguay', '1/12/1991', '19/6/2025', NULL, 'M', 'MASCULINO', NULL, NULL, '2023-09-26 04:25:35', NULL, 3, NULL, 1, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `visitas_datos_puesto`
--

CREATE TABLE `visitas_datos_puesto` (
  `id` int(11) NOT NULL,
  `id_visita` int(11) NOT NULL,
  `transaction_id` varchar(100) DEFAULT NULL,
  `computer_name` varchar(100) DEFAULT NULL,
  `user_name` varchar(100) DEFAULT NULL,
  `sdk_version` varchar(100) DEFAULT NULL,
  `file_version` varchar(100) DEFAULT NULL,
  `device_type` varchar(100) DEFAULT NULL,
  `device_number` varchar(100) DEFAULT NULL,
  `device_abel_number` varchar(100) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `visitas_datos_puesto`
--

INSERT INTO `visitas_datos_puesto` (`id`, `id_visita`, `transaction_id`, `computer_name`, `user_name`, `sdk_version`, `file_version`, `device_type`, `device_number`, `device_abel_number`, `created_at`) VALUES
(49, 81, '24202f7b-f031-4e1c-8c19-8c0266dcc163', 'DESKTOP-LDCO92T', 'JOSUE', '6.8.0.6084', '6.8', '7027 (OV 5Mp)', '0x089FC582', '338J2283', '2023-09-26 01:43:48'),
(50, 82, '1', '24202f7b-f031-4e1c-8c19-8c0266dcc163', 'DESKTOP-LDCO92T', 'JOSUE', '6.8.0.6084', '6.8', '7027 (OV 5Mp)', '0x089FC582', '2023-09-26 02:35:36'),
(51, 83, '1', '24202f7b-f031-4e1c-8c19-8c0266dcc163', 'DESKTOP-LDCO92T', 'JOSUE', '6.8.0.6084', '6.8', '7027 (OV 5Mp)', '0x089FC582', '2023-09-26 04:10:37'),
(52, 84, '1', '24202f7b-f031-4e1c-8c19-8c0266dcc163', 'DESKTOP-LDCO92T', 'JOSUE', '6.8.0.6084', '6.8', '7027 (OV 5Mp)', '0x089FC582', '2023-09-26 04:12:00'),
(53, 85, '24202f7b-f031-4e1c-8c19-8c0266dcc163', 'DESKTOP-LDCO92T', 'JOSUE', '6.8.0.6084', '6.8', '7027 (OV 5Mp)', '0x089FC582', '338J2283', '2023-09-26 04:25:35');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `dependencias`
--
ALTER TABLE `dependencias`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `impresoras`
--
ALTER TABLE `impresoras`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `pantallas`
--
ALTER TABLE `pantallas`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `puestos`
--
ALTER TABLE `puestos`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `roles_pantallas`
--
ALTER TABLE `roles_pantallas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_rol` (`id_rol`),
  ADD KEY `id_pantalla` (`id_pantalla`);

--
-- Indices de la tabla `tipo_documento`
--
ALTER TABLE `tipo_documento`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD KEY `roles_usuarios_fk` (`id_rol`);

--
-- Indices de la tabla `usuarios_marcacion`
--
ALTER TABLE `usuarios_marcacion`
  ADD PRIMARY KEY (`id`,`id_usuario`),
  ADD KEY `usuarios_usuarios_marcacion_fk` (`id_usuario`);

--
-- Indices de la tabla `visitas`
--
ALTER TABLE `visitas`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `visitas_datos_puesto`
--
ALTER TABLE `visitas_datos_puesto`
  ADD PRIMARY KEY (`id`,`id_visita`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `dependencias`
--
ALTER TABLE `dependencias`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `impresoras`
--
ALTER TABLE `impresoras`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `pantallas`
--
ALTER TABLE `pantallas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `puestos`
--
ALTER TABLE `puestos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `roles`
--
ALTER TABLE `roles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `roles_pantallas`
--
ALTER TABLE `roles_pantallas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `tipo_documento`
--
ALTER TABLE `tipo_documento`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `usuarios_marcacion`
--
ALTER TABLE `usuarios_marcacion`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `visitas`
--
ALTER TABLE `visitas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=86;

--
-- AUTO_INCREMENT de la tabla `visitas_datos_puesto`
--
ALTER TABLE `visitas_datos_puesto`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=54;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `roles_pantallas`
--
ALTER TABLE `roles_pantallas`
  ADD CONSTRAINT `roles_pantallas_ibfk_1` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id`),
  ADD CONSTRAINT `roles_pantallas_ibfk_2` FOREIGN KEY (`id_pantalla`) REFERENCES `pantallas` (`id`);

--
-- Filtros para la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD CONSTRAINT `roles_usuarios_fk` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `usuarios_marcacion`
--
ALTER TABLE `usuarios_marcacion`
  ADD CONSTRAINT `usuarios_usuarios_marcacion_fk` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
