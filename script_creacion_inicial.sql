USE GD1C2025
GO
CREATE SCHEMA QUERY_MASTERS
GO

-- Tabla Material
CREATE TABLE QUERY_MASTERS.Material (
    id_Material INTEGER PRIMARY KEY,
    tipo VARCHAR(15),
    nombre VARCHAR(15),
    precio_Adicional DECIMAL(10, 2)
);

-- Tabla Medida 
CREATE TABLE QUERY_MASTERS.Medida (
    id_Medida INTEGER  PRIMARY KEY,
    sillon_Medida_Alto DECIMAL(10, 2),
    sillon_Medida_Ancho DECIMAL(10, 2),
    sillon_Medida_Profundidad DECIMAL(10, 2),
    sillon_Medida_Precio DECIMAL(10, 2)  
);

-- Tabla Modelo
CREATE TABLE QUERY_MASTERS.Modelo (
    id_Modelo INTEGER PRIMARY KEY,
    sillon_Modelo_Descripcion VARCHAR(100),
    sillon_Modelo_Precio DECIMAL(10, 2)
);

CREATE TABLE QUERY_MASTERS.Sillon (
    id_Sillon INTEGER PRIMARY KEY,
    id_Modelo INTEGER REFERENCES QUERY_MASTERS.Modelo,
    id_Medida INTEGER REFERENCES QUERY_MASTERS.Medida,    
);

-- Tabla Madera
CREATE TABLE QUERY_MASTERS.Madera (
    id_Madera INTEGER PRIMARY KEY,
    id_Material INTEGER REFERENCES QUERY_MASTERS.Material(id_Material),
    madera_color VARCHAR(15),
    madera_dureza VARCHAR(15)  
);

-- Tabla Relleno
CREATE TABLE QUERY_MASTERS.Relleno (
    id_Relleno INTEGER PRIMARY KEY,
    id_Material INTEGER REFERENCES QUERY_MASTERS.Material(id_Material),
    relleno_densidad INTEGER
);

-- Tabla Tela
CREATE TABLE QUERY_MASTERS.Tela (
    id_Tela INTEGER PRIMARY KEY,
    id_Material INTEGER REFERENCES QUERY_MASTERS.Material(id_Material),
    tela_Color VARCHAR(15),
    tela_Textura VARCHAR(15)
);

-- Tabla Provincia
CREATE TABLE QUERY_MASTERS.Provincia (
    ID_provincia INT PRIMARY KEY,
    nombre VARCHAR(100)
);

-- Tabla Localidad
CREATE TABLE QUERY_MASTERS.Localidad (
    ID_localidad INT PRIMARY KEY,
    ID_provincia INT FOREIGN KEY REFERENCES QUERY_MASTERS.Provincia(ID_provincia),
    nombre VARCHAR(100)
);

-- Tabla Cliente
CREATE TABLE QUERY_MASTERS.Cliente (
    ID_cliente INT PRIMARY KEY,
    ID_localidad INT FOREIGN KEY REFERENCES QUERY_MASTERS.Localidad(ID_localidad),
    DNI INT,
    nombre VARCHAR(100),
    apellido VARCHAR(100),
    fecha_nacimiento DATE,
    mail VARCHAR(100),
    direccion VARCHAR(200),
    telefono INT
);

-- Tabla Sucursal
CREATE TABLE QUERY_MASTERS.Sucursal (
    ID_sucursal INT PRIMARY KEY,
    ID_localidad INT FOREIGN KEY REFERENCES QUERY_MASTERS.Localidad(ID_localidad),
	ID_provincia INT FOREIGN KEY REFERENCES QUERY_MASTERS.Provincia(ID_provincia),
    direccion VARCHAR(200),
    telefono VARCHAR(20),
    mail VARCHAR(100)
);

-- Tabla Proveedor
CREATE TABLE QUERY_MASTERS.Proveedor (
    ID_proveedor INT PRIMARY KEY,
    ID_localidad INT FOREIGN KEY REFERENCES QUERY_MASTERS.Localidad(ID_localidad),
    cuit VARCHAR(20),
    direccion VARCHAR(200),
    telefono VARCHAR(20),
    mail VARCHAR(100)
);

-- Tabla Compra
CREATE TABLE QUERY_MASTERS.Compra (
    ID_compra INT PRIMARY KEY,
	nro_compra INT,
    ID_sucursal INT FOREIGN KEY REFERENCES QUERY_MASTERS.Sucursal(ID_sucursal),
    ID_proveedor INT FOREIGN KEY REFERENCES QUERY_MASTERS.Proveedor(ID_proveedor),
    fecha_compra DATETIME,
    total DECIMAL(10,2)
);

-- Tabla Pedido
CREATE TABLE QUERY_MASTERS.Pedido (
    ID_pedido INTEGER PRIMARY KEY,
	nro_pedido INTEGER, 
	ID_sucursal INT FOREIGN KEY REFERENCES QUERY_MASTERS.Sucursal(ID_sucursal),
    ID_cliente INT FOREIGN KEY REFERENCES QUERY_MASTERS.Cliente(ID_cliente),
    fecha_hora DATETIME,
    total DECIMAL(10, 2),
    estado VARCHAR(50)
);

-- Tabla DetallePedido 
CREATE TABLE QUERY_MASTERS.DetallePedido(
    ID_detalle_pedido INTEGER IDENTITY (1,1) PRIMARY KEY,
    ID_Pedido INTEGER,
    ID_Sillon INTEGER REFERENCES QUERY_MASTERS.Sillon(ID_Sillon),
    cantidad INTEGER,
    precio_unitario DECIMAL(10,2),  
    subtotal DECIMAL(10,2)          
);


-- Tabla Factura
CREATE TABLE QUERY_MASTERS.Factura(
    id_factura INTEGER IDENTITY (1,1),
	nro_factura INTEGER,
    id_cliente INTEGER REFERENCES QUERY_MASTERS.Cliente(ID_cliente),
    id_sucursal INTEGER REFERENCES QUERY_MASTERS.Sucursal(ID_sucursal),
    fecha_hora DATETIME,
    total DECIMAL(10,2)
);


-- Tabla Envío
CREATE TABLE QUERY_MASTERS.Envio (
    id_envio INT IDENTITY (1,1) PRIMARY KEY,
    numero INT,
	fecha_programada DATE,
    fecha DATE,
    importe_traslado DECIMAL(10,2),
	importe_subida DECIMAL(10,2),
	total FLOAT,
    nro_factura INTEGER
);
-- Tabla DetalleFactura
CREATE TABLE QUERY_MASTERS.DetalleFactura(
    id_detalle_factura INTEGER IDENTITY (1,1) PRIMARY KEY,
    id_factura INTEGER,
    precio_unitario DECIMAL(10,2),
    cantidad INTEGER,
    subtotal DECIMAL(10,2)
);

-- Tabla DetalleCompra
CREATE TABLE QUERY_MASTERS.DetalleCompra(
    id_detalle_compra INTEGER IDENTITY (1,1) PRIMARY KEY,  
    id_compra INTEGER REFERENCES QUERY_MASTERS.Compra(ID_compra),
    id_material INTEGER REFERENCES QUERY_MASTERS.Material(id_Material),
    precio_unitario DECIMAL(10,2),
    cantidad INTEGER,
    subtotal DECIMAL(10,2)
);


 GO
CREATE PROCEDURE QUERY_MASTERS.MigrarDatos_Materiales
AS
BEGIN


INSERT INTO QUERY_MASTERS.Material (id_Material,tipo,nombre,precio_Adicional)
SELECT	DISTINCT ROW_NUMBER() OVER (ORDER BY Material_Tipo DESC) AS id_Material,Material_Tipo,Material_Nombre,Material_Precio FROM gd_esquema.Maestra
WHERE Material_Tipo IS NOT NULL AND Material_Nombre IS NOT NULL
  GROUP BY 
        Material_Tipo, 
        Material_Nombre, 
        Material_Precio


INSERT INTO QUERY_MASTERS.Medida (id_Medida,sillon_medida_alto,sillon_medida_ancho,sillon_medida_profundidad,sillon_medida_precio)
SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY sillon_medida_alto) AS id_Medida,Sillon_Medida_Alto,Sillon_Medida_Ancho,Sillon_Medida_Profundidad,Sillon_Medida_Precio FROM gd_esquema.Maestra
WHERE Sillon_Medida_Alto IS NOT NULL AND Sillon_Medida_Ancho IS NOT NULL AND Sillon_Medida_Precio IS NOT NULL
GROUP BY Sillon_Medida_Alto, 
         Sillon_Medida_Ancho, 
         Sillon_Medida_Profundidad, 
         Sillon_Medida_Precio

INSERT INTO QUERY_MASTERS.Modelo (id_Modelo,Sillon_Modelo_Descripcion,sillon_modelo_precio)
SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY Sillon_Modelo_Descripcion) AS id_Modelo,Sillon_Modelo_Descripcion,Sillon_Modelo_Precio FROM gd_esquema.Maestra
WHERE Sillon_Modelo_Descripcion IS NOT NULL AND Sillon_Modelo_Precio IS NOT NULL
 GROUP BY Sillon_Modelo_Codigo,
			 Sillon_Modelo,
			 Sillon_Modelo_Descripcion,
			 Sillon_Modelo_Precio


INSERT INTO QUERY_MASTERS.Madera (id_Madera,id_Material,madera_color,madera_dureza)
SELECT DISTINCT  ROW_NUMBER() OVER (ORDER BY M.id_Material) AS id_Madera,M.id_Material,MA.madera_Color,MA.madera_Dureza
				FROM gd_esquema.Maestra MA JOIN QUERY_MASTERS.Material M	
					ON MA.Material_Tipo = M.tipo AND MA.Material_Nombre = M.nombre
WHERE MA.madera_Color IS NOT NULL AND MA.madera_Dureza IS NOT NULL
GROUP BY     id_Material,
			 MA.Madera_Color,
			 MA.Madera_Dureza
			 


INSERT INTO QUERY_MASTERS.Tela (id_Tela,id_material, tela_Color, tela_Textura)
SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY M.id_Material) AS id_Tela,M.id_Material,Ma.tela_Color,Ma.tela_Textura
FROM gd_esquema.Maestra MA 
				JOIN QUERY_MASTERS.Material M 
					ON Ma.Material_Tipo = M.tipo AND Ma.Material_Nombre = M.nombre
WHERE Ma.tela_Color IS NOT NULL AND Ma.tela_Textura IS NOT NULL
GROUP BY     M.id_Material,
			 MA.tela_Color,
			 MA.tela_Textura


INSERT INTO QUERY_MASTERS.Relleno (id_Relleno,id_material, relleno_densidad)
SELECT DISTINCT  ROW_NUMBER() OVER (ORDER BY M.id_Material) AS id_Relleno,M.id_Material,Ma.relleno_Densidad 
				FROM gd_esquema.Maestra MA
						JOIN QUERY_MASTERS.Material M ON Ma.Material_Tipo = M.tipo AND Ma.Material_Nombre = M.nombre
WHERE Ma.relleno_Densidad IS NOT NULL
GROUP BY     M.id_Material,
			 MA.relleno_Densidad
			 

INSERT INTO QUERY_MASTERS.Sillon(id_Sillon,id_Modelo,id_Medida)
SELECT DISTINCT MA.Sillon_Codigo, MO.id_modelo, ME.id_medida
			FROM gd_esquema.Maestra MA 
						JOIN QUERY_MASTERS.Modelo MO ON MA.Sillon_Modelo_Descripcion = MO.sillon_Modelo_Descripcion AND MA.Sillon_Modelo_Precio = MO.sillon_Modelo_Precio
						JOIN QUERY_MASTERS.Medida ME ON MA.Sillon_Medida_Ancho = ME.sillon_Medida_Ancho AND MA.Sillon_Medida_Alto = ME.sillon_Medida_Alto AND MA.Sillon_Medida_Profundidad = ME.sillon_Medida_Profundidad
						
WHERE MA.Sillon_Codigo IS NOT NULL


END;
 
GO
EXECUTE QUERY_MASTERS.MigrarDatos_Materiales;

GO
CREATE PROCEDURE QUERY_MASTERS.MigrarProvincias
AS
BEGIN  

INSERT INTO QUERY_MASTERS.Provincia (ID_provincia,nombre)
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY Cliente_Provincia),Cliente_Provincia AS nombre
FROM (
    SELECT DISTINCT Cliente_Provincia 
    FROM gd_esquema.Maestra
) AS provs
WHERE Cliente_Provincia IS NOT NULL
END;

GO
EXEC QUERY_MASTERS.MigrarProvincias;

GO
GO
CREATE OR ALTER PROCEDURE QUERY_MASTERS.MigrarLocs
AS
BEGIN
    INSERT INTO QUERY_MASTERS.Localidad (ID_localidad, ID_provincia, nombre)
    SELECT 
        ROW_NUMBER() OVER (ORDER BY loc.Cliente_Localidad) AS ID_localidad,
        p.ID_provincia,
        loc.Cliente_Localidad
    FROM (
        SELECT DISTINCT Cliente_Localidad AS Cliente_Localidad, Cliente_Provincia AS Cliente_Provincia FROM gd_esquema.Maestra
        UNION
        SELECT DISTINCT Sucursal_Localidad, Sucursal_Provincia FROM gd_esquema.Maestra
        UNION
        SELECT DISTINCT Proveedor_Localidad, Proveedor_Provincia FROM gd_esquema.Maestra
    ) AS loc
    JOIN QUERY_MASTERS.Provincia p ON p.nombre = loc.Cliente_Provincia
    WHERE loc.Cliente_Localidad IS NOT NULL AND loc.Cliente_Provincia IS NOT NULL
    GROUP BY p.ID_provincia, loc.Cliente_Localidad;
END;

GO
EXEC QUERY_MASTERS.MigrarLocs;

GO 
CREATE PROCEDURE QUERY_MASTERS.MigrarClientes
AS
BEGIN  
WITH ClientesUnicos AS (
    SELECT 
        m.Cliente_Dni,
        m.Cliente_Nombre,
        m.Cliente_Apellido,
        m.Cliente_FechaNacimiento,
        m.Cliente_Mail,
        m.Cliente_Direccion,
        m.Cliente_Telefono,
        l.ID_localidad,
        ROW_NUMBER() OVER (PARTITION BY m.Cliente_Dni ORDER BY m.Cliente_Nombre) AS rn
    FROM gd_esquema.Maestra AS m
    JOIN QUERY_MASTERS.Localidad AS l
        ON l.nombre = m.Cliente_Localidad
    WHERE m.Cliente_Dni IS NOT NULL
)

INSERT INTO QUERY_MASTERS.Cliente (
    ID_cliente, ID_localidad, DNI, nombre, apellido, fecha_nacimiento, mail, direccion, telefono
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY Cliente_Dni) AS ID_cliente,
    ID_localidad,
    Cliente_Dni,
    Cliente_Nombre,
    Cliente_Apellido,
    Cliente_FechaNacimiento,
    Cliente_Mail,
    Cliente_Direccion,
    Cliente_Telefono
FROM ClientesUnicos
WHERE rn = 1;
END;

GO
EXEC QUERY_MASTERS.MigrarClientes

GO
CREATE PROCEDURE QUERY_MASTERS.MigrarSucs
AS
BEGIN  
INSERT INTO QUERY_MASTERS.Sucursal(ID_sucursal,ID_localidad,ID_provincia,direccion,telefono,mail)
	SELECT Sucursal_NroSucursal,L.ID_localidad, p.ID_provincia,Sucursal_Direccion, Sucursal_telefono, Sucursal_mail 
	FROM gd_esquema.Maestra join QUERY_MASTERS.Provincia P on Sucursal_Provincia = P.nombre
		join QUERY_MASTERS.Localidad L on Sucursal_Localidad = L.nombre and L.ID_provincia = P.ID_provincia
		group by Sucursal_NroSucursal ,Sucursal_Direccion,p.ID_provincia, Sucursal_mail, Sucursal_telefono,L.ID_localidad
END;
GO
EXEC QUERY_MASTERS.MigrarSucs;

GO
CREATE PROCEDURE QUERY_MASTERS.MigrarProvs
AS
BEGIN  
WITH ProveedoresUnicos AS (
        SELECT 
            Proveedor_Cuit,
            Proveedor_Direccion,
            Proveedor_Telefono,
            Proveedor_Mail,
            L.ID_localidad,
            ROW_NUMBER() OVER (PARTITION BY Proveedor_Cuit ORDER BY Proveedor_Direccion) AS rn
        FROM gd_esquema.Maestra MP
        JOIN QUERY_MASTERS.Localidad L 
            ON L.nombre = MP.Proveedor_Localidad
        JOIN QUERY_MASTERS.Provincia P 
            ON P.ID_provincia = L.ID_provincia AND P.nombre = MP.Proveedor_Provincia
        WHERE Proveedor_Cuit IS NOT NULL
    )
    INSERT INTO QUERY_MASTERS.Proveedor (
        ID_proveedor,ID_localidad, cuit, direccion, telefono, mail
    )
    SELECT 
	    ROW_NUMBER () OVER (ORDER BY Proveedor_Cuit),
        ID_localidad,
        Proveedor_Cuit,
        Proveedor_Direccion,
        Proveedor_Telefono,
        Proveedor_Mail
    FROM ProveedoresUnicos
    WHERE rn = 1
	GROUP BY  ID_localidad,
        Proveedor_Cuit,
        Proveedor_Direccion,
        Proveedor_Telefono,
        Proveedor_Mail
END;

GO
EXEC QUERY_MASTERS.MigrarProvs;

GO
CREATE PROCEDURE QUERY_MASTERS.MigrarCompras
AS
BEGIN  
INSERT INTO QUERY_MASTERS.Compra (
    ID_compra,nro_compra,ID_Sucursal,ID_proveedor, fecha_compra, total)
SELECT 
    ROW_NUMBER() OVER (ORDER BY m.Compra_Numero) AS ID_compra,
    m.Compra_Numero,
    s.ID_sucursal,
    p.ID_proveedor,
    m.Compra_Fecha,
    m.Compra_Total
FROM gd_esquema.Maestra AS m
JOIN QUERY_MASTERS.Sucursal AS s
    ON s.ID_sucursal = m.Sucursal_NroSucursal
JOIN QUERY_MASTERS.Proveedor AS p
    ON p.cuit = m.Proveedor_Cuit
WHERE m.Compra_Numero is not null
GROUP BY m.Compra_Numero,
    s.ID_sucursal,
    p.ID_proveedor,
    m.Compra_Fecha,
    m.Compra_Total
END;

GO
EXEC QUERY_MASTERS.MigrarCompras

GO
CREATE PROCEDURE QUERY_MASTERS.MigrarPeds
AS
BEGIN  
INSERT INTO QUERY_MASTERS.Pedido (
ID_pedido,nro_pedido,ID_sucursal, ID_cliente, fecha_hora, total, estado)
SELECT DISTINCT 
    ROW_NUMBER () OVER (ORDER BY m.Pedido_Numero),
    m.Pedido_Numero,
    s.ID_sucursal,
    c.ID_cliente,
    m.Pedido_Fecha,
    m.Pedido_Total,
    m.Pedido_Estado
FROM gd_esquema.Maestra AS m
JOIN QUERY_MASTERS.Sucursal AS s
    ON s.ID_sucursal = m.Sucursal_NroSucursal
JOIN QUERY_MASTERS.Cliente AS c
    ON c.DNI = m.Cliente_Dni
WHERE m.Pedido_Fecha IS NOT NULL
GROUP BY    m.Pedido_Numero,
			s.ID_sucursal,
			c.ID_cliente,
			m.Pedido_Fecha,
			m.Pedido_Total,
			m.Pedido_Estado
END;
GO
EXEC QUERY_MASTERS.MigrarPeds;
GO
CREATE PROCEDURE QUERY_MASTERS.MigrarFactura
AS 
BEGIN
INSERT INTO QUERY_MASTERS.Factura(nro_factura,id_cliente,id_sucursal,fecha_hora,total)
SELECT DISTINCT Factura_Numero,c.ID_cliente,s.ID_sucursal,ma.Factura_Fecha,Factura_Total FROM gd_esquema.Maestra ma
			JOIN QUERY_MASTERS.Cliente c  ON ma.Cliente_Dni = c.DNI
			JOIN QUERY_MASTERS.Sucursal s ON s.ID_sucursal = ma.Sucursal_NroSucursal
WHERE Factura_Numero IS NOT NULL

END;
GO
EXEC QUERY_MASTERS.MigrarFactura;
GO

CREATE PROCEDURE QUERY_MASTERS.MigrarEnvio
AS 
BEGIN
INSERT INTO QUERY_MASTERS.Envio(numero,fecha_programada,fecha,importe_traslado,importe_subida,total,nro_factura)
SELECT Envio_Numero,Envio_Fecha_Programada,Envio_Fecha,Envio_ImporteTraslado,Envio_importeSubida,Envio_Total,Factura_Numero FROM gd_esquema.Maestra
WHERE Envio_Numero IS NOT NULL
END;
GO
EXEC QUERY_MASTERS.MigrarEnvio;

GO
CREATE PROCEDURE QUERY_MASTERS.MigrarDetalleCompra
AS 
BEGIN
INSERT INTO QUERY_MASTERS.DetalleCompra(id_compra,id_material,precio_unitario,cantidad,subtotal)
SELECT c.ID_compra,MT.id_Material,MA.Detalle_Compra_Precio,MA.Detalle_Compra_Cantidad,MA.Detalle_Compra_SubTotal
FROM gd_esquema.Maestra ma
			JOIN QUERY_MASTERS.Compra c ON c.nro_compra = ma.Compra_Numero
			JOIN QUERY_MASTERS.Material MT ON MT.nombre = ma.Material_Nombre AND MT.tipo = ma.Material_Tipo
WHERE MA.Detalle_Compra_Precio IS NOT NULL
END;

GO
EXEC QUERY_MASTERS.MigrarDetalleCompra;

GO
CREATE PROCEDURE QUERY_MASTERS.MigrarDetallePedido
AS 
BEGIN
INSERT INTO QUERY_MASTERS.DetallePedido(ID_Pedido,ID_Sillon,cantidad,precio_unitario,subtotal)
SELECT DISTINCT p.nro_pedido,S.id_Sillon,ma.Detalle_Pedido_Cantidad,ma.Detalle_Pedido_Precio,ma.Detalle_Pedido_SubTotal
FROM gd_esquema.Maestra ma
			JOIN QUERY_MASTERS.Pedido p ON p.nro_pedido = ma.Pedido_Numero
			JOIN QUERY_MASTERS.Sillon S ON S.id_Sillon = MA.Sillon_Codigo
WHERE MA.Detalle_Pedido_Cantidad IS NOT NULL
END;


GO
EXEC QUERY_MASTERS.MigrarDetallePedido;


GO
CREATE PROCEDURE QUERY_MASTERS.MigrarDetalleFactura
AS 
BEGIN
INSERT INTO QUERY_MASTERS.DetalleFactura(id_factura,precio_unitario,cantidad,subtotal)
SELECT f.nro_factura,ma.Detalle_Factura_Precio,ma.Detalle_Pedido_Cantidad,ma.Detalle_Factura_SubTotal
FROM gd_esquema.Maestra ma
			JOIN QUERY_MASTERS.Factura f ON f.nro_factura = ma.Factura_Numero
WHERE ma.Detalle_Factura_Precio IS NOT NULL
END;

GO
EXEC QUERY_MASTERS.MigrarDetalleFactura;