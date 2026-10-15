CREATE SCHEMA IF NOT EXISTS proyecto;
SET search_path TO proyecto, public;


-- Entrega 2 autorizacion: estado de cuenta + tokens JWT
CREATE TYPE estado_usuario AS ENUM ('pending', 'active');
CREATE TYPE tipo_token AS ENUM ('ACCESS', 'VERIFY', 'CHANGE_PASSWORD');

CREATE TABLE roles (
    id_rol          SERIAL PRIMARY KEY,
    nombre          VARCHAR(20) UNIQUE NOT NULL,
    nivel           INT NOT NULL DEFAULT 1,
    eliminado       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE permisos (
    id_permiso      SERIAL PRIMARY KEY,
    recurso         VARCHAR(30) NOT NULL,
    accion          VARCHAR(30) NOT NULL,
    eliminado       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_permisos UNIQUE (recurso, accion)
);

CREATE TABLE roles_permisos (
    id              SERIAL PRIMARY KEY,
    id_rol          INT NOT NULL,
    id_permiso      INT NOT NULL,
    eliminado       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_permisos_roles_rol FOREIGN KEY (id_rol) REFERENCES roles (id_rol),
    CONSTRAINT fk_permisos_roles_permiso FOREIGN KEY (id_permiso) REFERENCES permisos (id_permiso)
);

CREATE TABLE carreras (
    id_carrera      SERIAL PRIMARY KEY,
    nombre          VARCHAR(100) UNIQUE NOT NULL,
    sede            VARCHAR(20) NOT NULL,
    eliminado       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE grupos (
    id_grupo        SERIAL PRIMARY KEY,
    nombre          VARCHAR(20) NOT NULL,
    sede            VARCHAR(20) NOT NULL,
    id_carrera      INT NOT NULL,
    eliminado       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_grupos_nombre_carrera UNIQUE (nombre, id_carrera),
    CONSTRAINT fk_grupos_carreras FOREIGN KEY (id_carrera)
        REFERENCES carreras (id_carrera)
);

CREATE TABLE usuarios (
    id_usuario          SERIAL PRIMARY KEY,
    cedula              VARCHAR(12) UNIQUE NOT NULL,
    nombre              VARCHAR(20) NOT NULL,
    apellido            VARCHAR(20) NOT NULL,
    correo              VARCHAR(100) UNIQUE NOT NULL,
    contrasenia         TEXT NOT NULL,
    sede                VARCHAR(20) NOT NULL,
    id_rol              INT NOT NULL,
    estado              estado_usuario NOT NULL DEFAULT 'pending',
    eliminado           BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_nacimiento    DATE NOT NULL,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_usuarios_roles FOREIGN KEY (id_rol)
        REFERENCES roles (id_rol)
);

ALTER TABLE proyecto.usuarios
ADD CONSTRAINT check_usuario_correo
    CHECK (
        correo ~* '^[A-Za-z0-9.%+-]+@(estudiantes\.)?utec\.edu\.uy$'
    );

CREATE TABLE usuarios_roles (
    id              SERIAL PRIMARY KEY,
    id_rol          INT NOT NULL,
    id_usuario      INT NOT NULL,
    eliminado       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_usuario_rol_rol FOREIGN KEY (id_rol) REFERENCES roles (id_rol),
    CONSTRAINT fk_usuario_rol_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
);

CREATE TABLE estudiantes (
    id_usuario          INT PRIMARY KEY,
    mot_registro        VARCHAR(200) NOT NULL,
    calle               VARCHAR(50) NOT NULL,
    nro_puerta          SMALLINT NOT NULL,
    ciudad              VARCHAR(30) NOT NULL,
    sis_salud           VARCHAR(50) NOT NULL,
    id_grupo            INT,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_estudiantes_usuarios FOREIGN KEY (id_usuario)
        REFERENCES usuarios (id_usuario),
    CONSTRAINT fk_estudiantes_grupos FOREIGN KEY (id_grupo)
        REFERENCES grupos (id_grupo)
);

CREATE TABLE funcionarios (
    id_usuario          INT PRIMARY KEY,
    num_funcionario     VARCHAR(6) UNIQUE NOT NULL,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_funcionarios_usuarios FOREIGN KEY (id_usuario)
        REFERENCES usuarios (id_usuario)
);

CREATE TABLE telefonos_estudiante (
    id              SERIAL PRIMARY KEY,
    id_estudiante   INT NOT NULL,
    telefono        VARCHAR(9) NOT NULL,
    eliminado       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_telefonos_estudiante UNIQUE (id_estudiante, telefono),
    CONSTRAINT fk_telefonos_estudiante FOREIGN KEY (id_estudiante)
        REFERENCES estudiantes (id_usuario)
);

CREATE TABLE estado_salud (
    id_estado_salud             SERIAL PRIMARY KEY,
    medicacion                  VARCHAR(30) NOT NULL,
    id_estudiante               INT NOT NULL,
    descripcion                 VARCHAR(150) NOT NULL,
    enfermedades                VARCHAR(150) NOT NULL,
    tratamientos                VARCHAR(150) NOT NULL,
    discapacidades_dificultades VARCHAR(150) NOT NULL,
    categoria                   VARCHAR(30) NOT NULL,
    eliminado                   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at                  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_estado_salud_estudiantes FOREIGN KEY (id_estudiante)
        REFERENCES estudiantes (id_usuario)
);

CREATE TABLE archivos (
    id_archivo      SERIAL PRIMARY KEY,
    nombre          VARCHAR(30) NOT NULL,
    id_usuario      INT NOT NULL,
    extension       VARCHAR(6) NOT NULL,
    eliminado       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_archivos_usuarios FOREIGN KEY (id_usuario)
        REFERENCES usuarios (id_usuario)
);

CREATE TABLE certificados (
    id_certificado          SERIAL PRIMARY KEY,
    nombre                  VARCHAR(30) NOT NULL,
    id_estudiante           INT NOT NULL,
    id_estado_salud         INT NOT NULL,
    id_archivo              INT NOT NULL,
    eliminado               BOOLEAN NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_certificados_estudiantes FOREIGN KEY (id_estudiante)
        REFERENCES estudiantes (id_usuario),
    CONSTRAINT fk_certificados_estado_salud FOREIGN KEY (id_estado_salud)
        REFERENCES estado_salud (id_estado_salud),
    CONSTRAINT fk_certificados_archivos FOREIGN KEY (id_archivo)
        REFERENCES archivos (id_archivo)
);

CREATE TABLE cate_instancias (
    id_categoria        SERIAL PRIMARY KEY,
    nombre              VARCHAR(30) UNIQUE NOT NULL,
    eliminado           BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Para que no se pueda borrar la categoría de incidencia

CREATE RULE no_borrar_categoria_incidencia AS
    ON DELETE TO proyecto.cate_instancias
    WHERE OLD.nombre = 'Incidencia'
    DO INSTEAD NOTHING;

CREATE RULE no_modificar_categoria_incidencia AS
    ON UPDATE TO proyecto.cate_instancias
       WHERE OLD.nombre = 'Incidencia'
           DO INSTEAD NOTHING;

CREATE TABLE instancias (
    id_instancia        SERIAL PRIMARY KEY,
    id_categoria        INT NOT NULL,
    codigo              VARCHAR(16) UNIQUE NOT NULL,
    tipo                VARCHAR(10) NOT NULL DEFAULT 'COMUN' CHECK (tipo IN ('COMUN', 'INCIDENCIA')),
    motivo              VARCHAR(150) NOT NULL,
    estado              VARCHAR(30) NOT NULL DEFAULT 'ACTIVA',
    id_estudiante       INT NOT NULL,
    id_funcionario      INT NOT NULL,
    lugar               VARCHAR(50),
    eliminado           BOOLEAN NOT NULL DEFAULT FALSE,
    fecha               TIMESTAMP NOT NULL,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_instancias_categorias FOREIGN KEY (id_categoria)
        REFERENCES cate_instancias (id_categoria),
    CONSTRAINT fk_instancias_estudiantes FOREIGN KEY (id_estudiante)
        REFERENCES estudiantes (id_usuario),
    CONSTRAINT fk_instancias_funcionarios FOREIGN KEY (id_funcionario)
        REFERENCES funcionarios (id_usuario)
);

CREATE TABLE involucrados_instancia (
    id_instancia INT NOT NULL,
    involucrado VARCHAR(50) NOT NULL,
    eliminado BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_involucrados_instancia PRIMARY KEY (id_instancia, involucrado),
    CONSTRAINT fk_involucrados_instancia FOREIGN KEY (id_instancia)
        REFERENCES instancias (id_instancia) ON DELETE RESTRICT
);

CREATE TABLE comentarios (
    id_comentario SERIAL PRIMARY KEY,
    nombre_entidad VARCHAR(30) NOT NULL,
    id_entidad INT NOT NULL,
    descripcion VARCHAR(150) NOT NULL,
    id_funcionario INT NOT NULL,
    confidencial BOOLEAN NOT NULL DEFAULT FALSE,
    eliminado BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_comentarios UNIQUE (nombre_entidad, id_entidad, id_funcionario, created_at),
    CONSTRAINT fk_comentarios_usuarios FOREIGN KEY (id_funcionario) REFERENCES funcionarios (id_usuario)
);

ALTER TABLE proyecto.comentarios
    ADD CONSTRAINT check_comentarios_entidad
        CHECK (nombre_entidad IN ('INSTANCIA', 'ESTUDIANTE')
            );

CREATE TABLE frecuencias (
    id_frecuencia   SERIAL PRIMARY KEY,
    periodicidad    VARCHAR(20) UNIQUE NOT NULL,
    eliminado       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE cate_recordatorios (
    id_cat_recordatorio SERIAL PRIMARY KEY,
    nombre              VARCHAR(30) UNIQUE NOT NULL,
    eliminado           BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE recordatorios (
    id_recordatorio     SERIAL PRIMARY KEY,
    titulo              VARCHAR(30) NOT NULL,
    codigo              VARCHAR(16) UNIQUE NOT NULL,
    id_cat_recordatorio INT NOT NULL,
    estado              VARCHAR(30) NOT NULL DEFAULT 'PENDIENTE',
    id_instancia        INT,
    id_estudiante       INT NOT NULL,
    id_frecuencia       INT NOT NULL,
    recurrente          BOOLEAN NOT NULL DEFAULT FALSE,
    eliminado           BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_inicio        TIMESTAMP NOT NULL,
    fecha_final         TIMESTAMP,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_recordatorios_categorias FOREIGN KEY (id_cat_recordatorio)
        REFERENCES cate_recordatorios (id_cat_recordatorio),
    CONSTRAINT fk_recordatorios_instancias FOREIGN KEY (id_instancia)
        REFERENCES instancias (id_instancia),
    CONSTRAINT fk_recordatorios_estudiantes FOREIGN KEY (id_estudiante)
        REFERENCES estudiantes (id_usuario),
    CONSTRAINT fk_recordatorios_frecuencias FOREIGN KEY (id_frecuencia)
        REFERENCES frecuencias (id_frecuencia)
);

CREATE RULE no_borrar_frecuencia_no_recurrente AS
    ON DELETE TO proyecto.frecuencias
    WHERE OLD.periodicidad = 'NO_RECURRENTE'
    DO INSTEAD NOTHING;

CREATE RULE no_modificar_frecuencia_no_recurrente AS
    ON UPDATE TO proyecto.frecuencias
    WHERE OLD.periodicidad = 'NO_RECURRENTE'
    DO INSTEAD NOTHING;

CREATE TABLE auditoria (
    id_auditoria    SERIAL PRIMARY KEY,
    id_usuario      INT NOT NULL,
    payload         TEXT NOT NULL,
    id_entidad      INT NOT NULL,
    accion          VARCHAR(20) NOT NULL,
    nombre_entidad  VARCHAR(30) NOT NULL CHECK (
    nombre_entidad IN (
            'Instancia', 'Usuario', 'Recordatorio', 'Estudiante', 'EstudiantePerfil','EstudianteImagen','TelefonoEstudiante','Funcionario',
            'Rol', 'Permiso', 'Incidencia', 'Carrera', 'Grupo', 'Archivo',
            'Certificado', 'EstadoSalud', 'InfoEstadoSalud',
            'CategoriaInstancia', 'CategoriaRecordatorio', 'FrecuenciaRecordatorio',
            'RolPermiso', 'UsuarioRol', 'Comentario'
        )
    ),
    fecha_registro  TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_auditoria_usuarios FOREIGN KEY (id_usuario)
        REFERENCES usuarios (id_usuario)
);

CREATE TABLE tokens (
    id_token        SERIAL PRIMARY KEY,
    id_usuario      INT NOT NULL,
    tipo            tipo_token NOT NULL DEFAULT 'ACCESS',
    token_value     TEXT NOT NULL,
    eliminado       BOOLEAN NOT NULL DEFAULT FALSE,
    expired_at      TIMESTAMP NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_tokens_usuarios FOREIGN KEY (id_usuario)
        REFERENCES usuarios (id_usuario),
    CONSTRAINT uk_tokens_value UNIQUE (token_value)
);

CREATE INDEX idx_usuarios_cedula ON usuarios USING HASH (cedula);
CREATE INDEX idx_usuarios_correo ON usuarios USING HASH (correo);
CREATE INDEX idx_funcionarios_num ON funcionarios USING HASH (num_funcionario);
CREATE INDEX idx_estudiantes_grupo ON estudiantes USING BTREE (id_grupo);
CREATE INDEX idx_instancias_estudiante_fecha ON instancias USING BTREE (id_estudiante, fecha);
CREATE INDEX idx_instancias_codigo ON instancias USING HASH (codigo);
CREATE INDEX idx_recordatorios_codigo ON recordatorios USING HASH (codigo);
CREATE INDEX idx_auditoria_usuario_fecha ON auditoria USING BTREE (id_usuario, fecha_registro);
CREATE INDEX idx_tokens_usuario ON tokens USING BTREE (id_usuario);
CREATE INDEX idx_tokens_expired_at ON tokens USING BTREE (expired_at);
CREATE INDEX idx_tokens_tipo ON tokens USING BTREE (tipo);

CREATE TABLE usuario_identidades (
    id              SERIAL PRIMARY KEY,
    id_usuario      INT NOT NULL,
    proveedor       VARCHAR(30) NOT NULL,
    subject         VARCHAR(255) NOT NULL,
    correo_idp      VARCHAR(100),
    eliminado       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_identidad_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario),
    CONSTRAINT uk_identidad_proveedor_sub UNIQUE (proveedor, subject)
);

CREATE INDEX idx_identidad_usuario ON usuario_identidades (id_usuario);

CREATE OR REPLACE FUNCTION trg_actualizar_fecha_modificacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER actualizar_fecha_modificacion_roles
    BEFORE UPDATE ON proyecto.roles
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_permisos
    BEFORE UPDATE ON proyecto.permisos
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_roles_permisos
    BEFORE UPDATE ON proyecto.roles_permisos
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_carreras
    BEFORE UPDATE ON proyecto.carreras
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_grupos
    BEFORE UPDATE ON proyecto.grupos
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_usuarios
    BEFORE UPDATE ON proyecto.usuarios
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_usuarios_roles
    BEFORE UPDATE ON proyecto.usuarios_roles
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_estudiantes
    BEFORE UPDATE ON proyecto.estudiantes
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_funcionarios
    BEFORE UPDATE ON proyecto.funcionarios
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_telefonos_estudiante
    BEFORE UPDATE ON proyecto.telefonos_estudiante
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_categ_instancia
    BEFORE UPDATE ON proyecto.cate_instancias
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_instancia
    BEFORE UPDATE ON proyecto.instancias
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_involucrados_instancia
    BEFORE UPDATE ON proyecto.involucrados_instancia
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_comentario
    BEFORE UPDATE ON proyecto.comentarios
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_frecuencia
    BEFORE UPDATE ON proyecto.frecuencias
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_categ_recordatorio
    BEFORE UPDATE ON proyecto.cate_recordatorios
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_estado_salud
    BEFORE UPDATE ON proyecto.estado_salud
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_archivo
    BEFORE UPDATE ON proyecto.archivos
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_certificado
    BEFORE UPDATE ON proyecto.certificados
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_recordatorio
    BEFORE UPDATE ON proyecto.recordatorios
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_tokens
    BEFORE UPDATE ON proyecto.tokens
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE TRIGGER actualizar_fecha_modificacion_usuario_identidades
    BEFORE UPDATE ON proyecto.usuario_identidades
    FOR EACH ROW
    EXECUTE FUNCTION trg_actualizar_fecha_modificacion();

CREATE OR REPLACE FUNCTION generar_codigo()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
DECLARE
    num_entidad INT;
    num_entidad_seis_digitos CHAR(6);
    prefijo VARCHAR(4);
BEGIN
    IF (tg_table_name = 'instancias') THEN
        num_entidad = (SELECT COUNT(1) FROM proyecto.instancias) + 1;
        prefijo = 'INST';
    ELSIF (tg_table_name = 'recordatorios') THEN
        num_entidad = (SELECT COUNT(1) FROM proyecto.recordatorios) + 1;
        prefijo = 'REC';
    ELSE
        num_entidad = 0;
    END IF;

    num_entidad_seis_digitos =
            CASE
                WHEN num_entidad < 10 THEN '00000' || num_entidad
                WHEN num_entidad < 100 THEN '0000' || num_entidad
                WHEN num_entidad < 1000 THEN '000' || num_entidad
                WHEN num_entidad < 10000 THEN '00' || num_entidad
                WHEN num_entidad < 100000 THEN '0' || num_entidad
            END;

    NEW.codigo = prefijo || '-' || DATE_PART('year', NOW()::DATE) || '-' || num_entidad_seis_digitos;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_generacion_codigo_instancia
    BEFORE INSERT
    ON proyecto.instancias
    FOR EACH ROW
    EXECUTE FUNCTION generar_codigo('Instancia');

CREATE TRIGGER trg_generacion_codigo_recordatorio
    BEFORE INSERT
    ON proyecto.recordatorios
    FOR EACH ROW
    EXECUTE FUNCTION generar_codigo('Recordatorio');

-- ============================================================================
-- Catálogo RBAC (RF33 + Estudiante): plantilla inicial, no dato operativo.
-- IDs de rol fijos para fixtures y seeds.
-- ============================================================================
INSERT INTO roles (id_rol, nombre, nivel) VALUES
    (1, 'Estudiante', 1),
    (2, 'Docente', 2),
    (3, 'Administrador', 5),
    (4, 'Psicopedagogo', 3),
    (5, 'Tutor', 2);
SELECT setval('roles_id_rol_seq', (SELECT MAX(id_rol) FROM roles));

INSERT INTO permisos (recurso, accion) VALUES
    ('estudiante', 'leer'), ('estudiante', 'crear'), ('estudiante', 'editar'), ('estudiante', 'eliminar'),
    ('estado-salud', 'leer'), ('estado-salud', 'crear'), ('estado-salud', 'editar'), ('estado-salud', 'eliminar'),
    ('instancia', 'leer'), ('instancia', 'crear'), ('instancia', 'editar'), ('instancia', 'eliminar'),
    ('incidencia', 'leer'), ('incidencia', 'crear'), ('incidencia', 'editar'), ('incidencia', 'eliminar'),
    ('comentario', 'leer'), ('comentario', 'crear'), ('comentario', 'eliminar'),
    ('comentario-confidencial', 'leer'), ('comentario-confidencial', 'crear'), ('comentario-confidencial', 'eliminar'),
    ('recordatorio', 'leer'), ('recordatorio', 'crear'), ('recordatorio', 'editar'), ('recordatorio', 'eliminar'),
    ('reporte', 'generar'), ('reporte', 'exportar'),
    ('categoria', 'crear'), ('categoria', 'editar'), ('categoria', 'eliminar'),
    ('carrera', 'crear'), ('carrera', 'editar'), ('carrera', 'eliminar'),
    ('grupo', 'crear'), ('grupo', 'editar'), ('grupo', 'eliminar'),
    ('frecuencia', 'crear'), ('frecuencia', 'editar'), ('frecuencia', 'eliminar'),
    ('rol', 'leer'), ('rol', 'crear'), ('rol', 'editar'), ('rol', 'eliminar'), ('rol', 'asignar'),
    ('permiso', 'leer'), ('permiso', 'crear'), ('permiso', 'editar'), ('permiso', 'eliminar'), ('permiso', 'asignar'),
    ('autorizacion', 'leer'), ('autorizacion', 'crear'), ('autorizacion', 'editar'), ('autorizacion', 'eliminar'), ('autorizacion', 'asignar-rol'),
    ('auditoria', 'leer');

INSERT INTO roles_permisos (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM roles r CROSS JOIN permisos p
WHERE r.nombre = 'Administrador';

INSERT INTO roles_permisos (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM roles r JOIN permisos p ON (
       (p.recurso = 'estudiante' AND p.accion IN ('leer', 'crear', 'editar'))
    OR (p.recurso = 'estado-salud' AND p.accion IN ('leer', 'crear', 'editar'))
    OR (p.recurso IN ('instancia', 'incidencia', 'comentario',
                      'comentario-confidencial', 'recordatorio', 'reporte'))
)
WHERE r.nombre = 'Psicopedagogo';

INSERT INTO roles_permisos (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM roles r JOIN permisos p ON (
       (p.recurso = 'estudiante' AND p.accion = 'leer')
    OR (p.recurso IN ('instancia', 'incidencia', 'comentario', 'recordatorio'))
    OR (p.recurso = 'reporte' AND p.accion = 'generar')
)
WHERE r.nombre = 'Docente';

INSERT INTO roles_permisos (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM roles r JOIN permisos p ON (
       (p.recurso = 'estudiante' AND p.accion = 'leer')
    OR (p.recurso = 'instancia' AND p.accion = 'leer')
    OR (p.recurso = 'incidencia' AND p.accion = 'leer')
    OR (p.recurso = 'comentario')
    OR (p.recurso = 'recordatorio')
    OR (p.recurso = 'reporte' AND p.accion = 'generar')
)
WHERE r.nombre = 'Tutor';

INSERT INTO roles_permisos (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM roles r JOIN permisos p ON (
       (p.recurso = 'estudiante' AND p.accion = 'leer')
    OR (p.recurso = 'recordatorio' AND p.accion = 'leer')
)
WHERE r.nombre = 'Estudiante';
