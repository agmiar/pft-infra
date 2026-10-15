-- ============================================================================
-- SEED OPERATIVO — admin bootstrap + catálogos de prueba (carreras/grupos).
-- Roles, permisos y roles_permisos viven en 01_schema.sql (RF33).
--
-- Notas:
--   - contrasenia del admin: "AdminSienep1" (BCrypt, min. 8 chars). Cambiar en prod (RF03).
--   - created_at / updated_at / eliminado salen por DEFAULT del schema.
-- ============================================================================

SET search_path TO proyecto, public;

-- Usuario administrador inicial (es funcionario para poder registrar instancias).
-- BCrypt hash de "AdminSienep1".
INSERT INTO usuarios (cedula, nombre, apellido, correo, contrasenia, sede, fecha_nacimiento, id_rol, estado)
VALUES
    ('55555550', 'Admin', 'SIENEP', 'admin@utec.edu.uy',
     '$2a$10$aV8qKBczTGkx9yomnCl/XeNMZPblGwezusUp.5cXDOjjRBMyELrP2', 'Fray Bentos', '1990-01-01',
     (SELECT id_rol FROM roles WHERE nombre = 'Administrador'), 'active');

INSERT INTO usuarios_roles (id_usuario, id_rol)
SELECT u.id_usuario, r.id_rol
FROM usuarios u, roles r
WHERE u.correo = 'admin@utec.edu.uy' AND r.nombre = 'Administrador';

INSERT INTO funcionarios (id_usuario, num_funcionario)
SELECT id_usuario, '000001' FROM usuarios WHERE correo = 'admin@utec.edu.uy';

-- Carreras y grupos de prueba para altas de estudiantes.
INSERT INTO carreras (nombre, sede) VALUES
    ('Licenciatura en Tecnologias de la Informacion', 'Fray Bentos'),
    ('Ingenieria en Mecatronica', 'Durazno'),
    ('Tecnologo en Informatica', 'Rivera');

INSERT INTO grupos (nombre, sede, id_carrera) VALUES
    ('FBA', 'Fray Bentos', (SELECT id_carrera FROM carreras WHERE nombre = 'Licenciatura en Tecnologias de la Informacion')),
    ('MDA', 'Durazno', (SELECT id_carrera FROM carreras WHERE nombre = 'Ingenieria en Mecatronica')),
    ('RIA', 'Rivera', (SELECT id_carrera FROM carreras WHERE nombre = 'Tecnologo en Informatica'));
