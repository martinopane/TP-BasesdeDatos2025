USE GD1C2025


GO



-- Tiempo
CREATE TABLE QUERY_MASTERS.BI_DimTiempo (
    ID_tiempo INT PRIMARY KEY,
    anio INT,
    cuatrimestre INT,
    mes INT
);
GO

-- Ubicación   
CREATE TABLE QUERY_MASTERS.BI_DimUbicacion (
    ID_ubicacion INT PRIMARY KEY,
    provincia VARCHAR(100),
    localidad VARCHAR(100) 
);
GO

-- Cliente
CREATE TABLE QUERY_MASTERS.BI_DimCliente (
    ID_cliente INT PRIMARY KEY,
    rango_etario VARCHAR(20) 
);
GO

-- Sucursal
CREATE TABLE QUERY_MASTERS.BI_DimSucursal (
    ID_sucursal INT PRIMARY KEY,
	ID_ubicacion INT FOREIGN KEY REFERENCES QUERY_MASTERS.BI_DimUbicacion (ID_ubicacion)
    
);

GO
-- Turno      
CREATE TABLE QUERY_MASTERS.BI_DimTurno (
    ID_turno INT PRIMARY KEY,
    descripcion VARCHAR(20) 
);

GO

-- Modelo de Sillón
CREATE TABLE QUERY_MASTERS.BI_DimModeloSillon (
    ID_modelo INT PRIMARY KEY,
    descripcion VARCHAR(100),
	precio DECIMAL(10,2)
    
);

GO

-- Tipo de Material
CREATE TABLE QUERY_MASTERS.BI_DimTipoMaterial (
    ID_material INT PRIMARY KEY,
    tipo VARCHAR(50), -- Tela, Madera, Relleno
	nombreMaterial VARCHAR (50),
	detalle VARCHAR(50)
);
GO

-- Estado del Pedido  
CREATE TABLE QUERY_MASTERS.BI_DimEstadoPedido (
    ID_estado INT PRIMARY KEY,
    estado VARCHAR(50)
);
GO


--TABLAS DE HECHOS:

-- Hecho Compra
CREATE TABLE QUERY_MASTERS.BI_HechoCompra (
    
    ID_tiempo INT FOREIGN KEY REFERENCES QUERY_MASTERS.BI_DimTiempo(ID_tiempo),
    ID_material INT FOREIGN KEY REFERENCES QUERY_MASTERS.BI_DimTipoMaterial(ID_material),
    ID_ubicacion INT FOREIGN KEY REFERENCES QUERY_MASTERS.BI_DimUbicacion(ID_ubicacion),
    total DECIMAL(10,2),
	PRIMARY KEY (ID_tiempo,ID_material,ID_ubicacion)
);
GO

-- Hecho Factura (Ventas)
CREATE TABLE QUERY_MASTERS.BI_HechoFactura (
    
    ID_tiempo INT FOREIGN KEY REFERENCES QUERY_MASTERS.BI_DimTiempo(ID_tiempo),
    ID_cliente INT FOREIGN KEY REFERENCES QUERY_MASTERS.BI_DimCliente(ID_cliente),
    ID_ubicacion INT FOREIGN KEY REFERENCES QUERY_MASTERS.BI_DimUbicacion(ID_ubicacion),
	ID_turno INT FOREIGN KEY REFERENCES QUERY_MASTERS.BI_DimTurno(ID_turno),
    total DECIMAL(10,2),
	promedio_facturas INT,
	PRIMARY KEY (ID_tiempo, ID_cliente,ID_ubicacion, ID_turno)
);
GO

--  Hecho Pedido
CREATE TABLE QUERY_MASTERS.BI_HechoPedido (
   
    ID_tiempo INT FOREIGN KEY REFERENCES QUERY_MASTERS.BI_DimTiempo(ID_tiempo),
    ID_cliente INT FOREIGN KEY REFERENCES QUERY_MASTERS.BI_DimCliente(ID_cliente),
    ID_ubicacion INT FOREIGN KEY REFERENCES QUERY_MASTERS.BI_DimUbicacion(ID_ubicacion),
	ID_turno INT FOREIGN KEY REFERENCES QUERY_MASTERS.BI_DimTurno(ID_turno),
    ID_modelo INT FOREIGN KEY REFERENCES QUERY_MASTERS.BI_DimModeloSillon(ID_modelo),
    ID_estado INT FOREIGN KEY REFERENCES QUERY_MASTERS.BI_DimEstadoPedido(ID_estado),
    volumen INT,
	conversion INT,
    tiempoDeFabricacion INT,
	PRIMARY KEY (ID_tiempo, ID_cliente, ID_modelo, ID_estado, ID_ubicacion, ID_turno)
);

GO

-- Hecho Envío
CREATE TABLE QUERY_MASTERS.BI_HechoEnvio (
    
    ID_tiempo INT FOREIGN KEY REFERENCES QUERY_MASTERS.BI_DimTiempo(ID_tiempo),
	ID_ubicacion INT FOREIGN KEY REFERENCES QUERY_MASTERS.BI_DimUbicacion(ID_ubicacion),
	porcentajeCumplimiento INT,
    totalPromedio DECIMAL(10,2),
	PRIMARY KEY (ID_tiempo,ID_ubicacion));

GO
CREATE OR ALTER PROCEDURE QUERY_MASTERS.BI_MigrarDimTiempo
AS
BEGIN
    SET NOCOUNT ON;
    WITH FechasUnicas AS (
SELECT CAST(fecha_compra AS DATE) AS fecha FROM QUERY_MASTERS.Compra WHERE fecha_compra IS NOT NULL
UNION
SELECT CAST(fecha_hora AS DATE) FROM QUERY_MASTERS.Pedido WHERE fecha_hora IS NOT NULL
UNION
SELECT CAST(fecha_hora AS DATE) FROM QUERY_MASTERS.Factura WHERE fecha_hora IS NOT NULL
UNION
SELECT CAST(fecha AS DATE) FROM QUERY_MASTERS.Envio WHERE fecha IS NOT NULL
UNION
SELECT CAST(fecha_programada AS DATE) FROM QUERY_MASTERS.Envio WHERE fecha_programada IS NOT NULL),
TiempoCalculado AS (
SELECT DISTINCT
DATEPART(YEAR, fecha) AS anio,
DATEPART(MONTH, fecha) AS mes,
CEILING(DATEPART(MONTH, fecha) / 4.0) AS cuatrimestre
FROM FechasUnicas)
INSERT INTO QUERY_MASTERS.BI_DimTiempo (ID_tiempo, anio, cuatrimestre, mes)
SELECT 
ROW_NUMBER() OVER (ORDER BY anio, mes) AS ID_tiempo,
anio,
cuatrimestre,
mes
FROM TiempoCalculado;
END;
GO


EXEC QUERY_MASTERS.BI_MigrarDimTiempo;

GO
CREATE OR ALTER PROCEDURE QUERY_MASTERS.BI_MigrarDimUbicacion
AS
BEGIN
WITH UbicacionesUnicas AS (
SELECT 
p.nombre AS provincia,
l.nombre AS localidad
FROM QUERY_MASTERS.Localidad l
JOIN QUERY_MASTERS.Provincia p ON l.ID_provincia = p.ID_provincia
GROUP BY p.nombre, l.nombre)
INSERT INTO QUERY_MASTERS.BI_DimUbicacion (ID_ubicacion, provincia, localidad)
SELECT 
ROW_NUMBER() OVER (ORDER BY provincia, localidad) AS ID_ubicacion,
provincia,
localidad
FROM UbicacionesUnicas;
END;
GO

EXEC QUERY_MASTERS.BI_MigrarDimUbicacion
GO
CREATE OR ALTER PROCEDURE QUERY_MASTERS.BI_MigrarDimCliente
AS
BEGIN
SET NOCOUNT ON;
;WITH 
ClientesUnicos AS (
SELECT DISTINCT
cl.ID_cliente AS CodigoCliente,
cl.fecha_nacimiento AS FechaNacimiento
FROM QUERY_MASTERS.Cliente AS cl
WHERE cl.ID_cliente IS NOT NULL),
ClientesConEdad AS (SELECT CodigoCliente,
DATEDIFF(YEAR, FechaNacimiento, GETDATE())
-CASE
WHEN DATEADD(YEAR,
DATEDIFF(YEAR, FechaNacimiento, GETDATE()),
FechaNacimiento) > GETDATE()
THEN 1 ELSE 0
END AS Edad
FROM ClientesUnicos)
INSERT INTO QUERY_MASTERS.BI_DimCliente (
ID_cliente,
rango_etario)
SELECT
ROW_NUMBER() OVER (ORDER BY CodigoCliente) AS ID_cliente, 
CASE
WHEN Edad < 25 THEN 'Menor de 25'
WHEN Edad BETWEEN 25 AND 35 THEN '25-35'
WHEN Edad BETWEEN 35 AND 50 THEN '35-50'
ELSE '50+'
END AS rango_etario
FROM ClientesConEdad;
END;
GO

EXEC QUERY_MASTERS.BI_MigrarDimCliente;

GO
CREATE OR ALTER PROCEDURE QUERY_MASTERS.BI_MigrarDimSucursal
AS
BEGIN
SET NOCOUNT ON;
;WITH
SucursalesUnicas AS (
SELECT DISTINCT
s.ID_sucursal AS SucursalNaturalID,
s.ID_localidad
FROM QUERY_MASTERS.Sucursal AS s
WHERE s.ID_sucursal IS NOT NULL
),
SucursalesConUbicacion AS (
SELECT
su.SucursalNaturalID,
du.ID_ubicacion            
FROM SucursalesUnicas AS su
LEFT JOIN QUERY_MASTERS.Localidad AS l
ON su.ID_localidad = l.ID_localidad
LEFT JOIN QUERY_MASTERS.Provincia AS p
ON l.ID_provincia = p.ID_provincia
INNER JOIN QUERY_MASTERS.BI_DimUbicacion AS du
ON du.provincia = p.nombre
AND du.localidad = l.nombre)
INSERT INTO QUERY_MASTERS.BI_DimSucursal (
ID_sucursal,
ID_ubicacion ) 
SELECT
ROW_NUMBER() OVER (ORDER BY ID_ubicacion) AS ID_sucursal,  
ID_ubicacion         
FROM SucursalesConUbicacion;
END;
GO


EXEC QUERY_MASTERS.BI_MigrarDimSucursal;

GO
CREATE OR ALTER PROCEDURE QUERY_MASTERS.BI_MigrarDimTurno
AS
BEGIN
SET NOCOUNT ON;
;WITH TurnosUnicos AS (
SELECT DISTINCT
CASE
WHEN DATEPART(HOUR, f.fecha_hora) BETWEEN 8  AND 13 THEN '08:00-14:00'
WHEN DATEPART(HOUR, f.fecha_hora) BETWEEN 14 AND 19 THEN '14:00-20:00'
END AS descripcion
FROM QUERY_MASTERS.Factura AS f
WHERE f.fecha_hora IS NOT NULL)
INSERT INTO QUERY_MASTERS.BI_DimTurno (
ID_turno,
descripcion
)
SELECT
ROW_NUMBER() OVER (ORDER BY descripcion) AS ID_turno,  
descripcion
FROM TurnosUnicos;
END;
GO
EXEC QUERY_MASTERS.BI_MigrarDimTurno;

GO
CREATE OR ALTER PROCEDURE QUERY_MASTERS.BI_MigrarDimModeloSillon
AS
BEGIN
SET NOCOUNT ON;
;WITH SillonesUnicos AS (
SELECT DISTINCT
mo.Sillon_Modelo_Descripcion AS descripcion,
mo.sillon_modelo_precio       AS precio
FROM QUERY_MASTERS.Sillon AS s
INNER JOIN QUERY_MASTERS.Modelo AS mo
ON s.id_Modelo = mo.id_Modelo
WHERE mo.Sillon_Modelo_Descripcion IS NOT NULL     )
INSERT INTO QUERY_MASTERS.BI_DimModeloSillon (
ID_modelo,
descripcion,
precio)
SELECT
ROW_NUMBER() OVER (
ORDER BY descripcion
) AS ID_modelo,
descripcion, precio
FROM SillonesUnicos;
END;
GO

EXEC QUERY_MASTERS.BI_MigrarDimModeloSillon;
GO

CREATE OR ALTER PROCEDURE QUERY_MASTERS.BI_MigrarDimTipoMaterial
AS
BEGIN
SET NOCOUNT ON;
;WITH MaterialesConDetalle AS (
SELECT
m.id_Material AS MaterialNaturalID,
m.tipo AS tipo,
m.nombre AS nombreMaterial,
CASE
WHEN m.tipo = 'Tela '
THEN 'Color ' + t.tela_Color + ', Textura ' + t.tela_Textura
WHEN m.tipo = 'Madera'
THEN 'Color ' + ma.madera_color + ', Dureza ' + ma.madera_dureza
WHEN m.tipo = 'Relleno '
THEN 'Densidad ' + CAST(r.relleno_densidad AS VARCHAR(50))
ELSE NULL
END AS detalle
FROM QUERY_MASTERS.Material AS m                                    
LEFT JOIN QUERY_MASTERS.Tela    AS t ON t.id_Material = m.id_Material 
LEFT JOIN QUERY_MASTERS.Madera  AS ma ON ma.id_Material = m.id_Material
LEFT JOIN QUERY_MASTERS.Relleno AS r ON r.id_Material = m.id_Material)
INSERT INTO QUERY_MASTERS.BI_DimTipoMaterial (
ID_material,
tipo,
nombreMaterial,
detalle)
SELECT
ROW_NUMBER() OVER (ORDER BY tipo, nombreMaterial) AS ID_material,  
tipo,
nombreMaterial,
detalle
FROM MaterialesConDetalle
WHERE detalle IS NOT NULL;  
END;
GO

EXEC QUERY_MASTERS.BI_MigrarDimTipoMaterial;

GO
CREATE OR ALTER PROCEDURE QUERY_MASTERS.BI_MigrarDimEstadoPedido
AS
BEGIN
SET NOCOUNT ON;
;WITH EstadosUnicos AS (
SELECT DISTINCT
p.estado
FROM QUERY_MASTERS.Pedido AS p
WHERE p.estado IS NOT NULL
)
    INSERT INTO QUERY_MASTERS.BI_DimEstadoPedido (
        ID_estado,
        estado)
SELECT
ROW_NUMBER() OVER (ORDER BY estado) AS ID_estado,
estado
FROM EstadosUnicos;
END;
GO
EXEC QUERY_MASTERS.BI_MigrarDimEstadoPedido;


GO
CREATE OR ALTER PROCEDURE QUERY_MASTERS.BI_MigrarHechoEnvio
AS
BEGIN 
SET NOCOUNT ON;
TRUNCATE TABLE QUERY_MASTERS.BI_HechoEnvio;
;WITH EnviosValidos AS (
SELECT
e.*,
dt.ID_tiempo,
du.ID_ubicacion
FROM QUERY_MASTERS.Envio AS e
INNER JOIN QUERY_MASTERS.BI_DimTiempo AS dt
ON dt.anio = DATEPART(YEAR, e.fecha)
AND dt.mes = DATEPART(MONTH, e.fecha)
AND dt.cuatrimestre = CEILING(DATEPART(MONTH, e.fecha) / 4.0)
JOIN QUERY_MASTERS.Factura f ON f.nro_factura = e.nro_factura
JOIN QUERY_MASTERS.Cliente c ON c.ID_cliente = f.id_cliente
JOIN QUERY_MASTERS.Localidad L ON L.ID_localidad = c.ID_localidad
JOIN QUERY_MASTERS.Provincia p ON p.ID_provincia = L.ID_provincia
JOIN QUERY_MASTERS.BI_DimUbicacion du ON du.provincia = p.nombre AND du.localidad = L.nombre
WHERE e.fecha IS NOT NULL AND e.fecha_programada IS NOT NULL AND e.total IS NOT NULL)
    INSERT INTO QUERY_MASTERS.BI_HechoEnvio (
        ID_tiempo,
        ID_ubicacion,
        porcentajeCumplimiento,
        totalPromedio)
    SELECT
        ID_tiempo,
        ID_ubicacion,
        CAST(SUM(CASE WHEN fecha <= fecha_programada THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(18,2)) AS porcentajeCumplimiento,
        CAST(AVG(total) AS DECIMAL(18,2)) AS totalPromedio
    FROM EnviosValidos
    GROUP BY ID_tiempo, ID_ubicacion;
END;
GO

EXEC QUERY_MASTERS.BI_MigrarHechoEnvio;

GO
CREATE OR ALTER PROCEDURE QUERY_MASTERS.BI_MigrarHechoPedido
AS
BEGIN
SET NOCOUNT ON;
INSERT INTO QUERY_MASTERS.BI_HechoPedido (        
ID_tiempo,
ID_cliente,
ID_ubicacion,
ID_turno,       
ID_modelo,
ID_estado,
volumen ,
conversion ,
tiempoDeFabricacion )
SELECT       
dt.ID_tiempo,
p.ID_cliente,
du.ID_ubicacion,
dtt.ID_turno,   
si.id_Modelo,
dest.ID_estado,
COUNT(*) volumen,
( ( 
SELECT COUNT(*)
FROM QUERY_MASTERS.Pedido p2 
WHERE 
p2.estado = p.estado AND 
p2.ID_sucursal = p.ID_sucursal AND
MONTH(p2.fecha_hora) = MONTH(p.fecha_hora)) /
(SELECT COUNT(*) 
FROM QUERY_MASTERS.Pedido p2 
WHERE 
MONTH(p2.fecha_hora) = MONTH(p.fecha_hora)
AND
p2.ID_sucursal = p.ID_sucursal)) * 100 AS conversion,
AVG(ISNULL(DATEDIFF(DAY, p.fecha_hora, f.fecha_hora), 0)) AS tiempodefabricacion	
FROM QUERY_MASTERS.Pedido  p
JOIN QUERY_MASTERS.DetallePedido dp 
ON dp.ID_Pedido = p.nro_pedido
JOIN QUERY_MASTERS.Sillon si
ON si.id_Sillon = dp.ID_Sillon
JOIN QUERY_MASTERS.Sucursal  su
ON p.ID_sucursal = su.ID_sucursal
JOIN QUERY_MASTERS.Localidad l
ON su.ID_localidad = l.ID_localidad
JOIN QUERY_MASTERS.Provincia pr
ON l.ID_provincia = pr.ID_provincia
JOIN QUERY_MASTERS.Cliente c	   
ON c.ID_cliente = p.ID_cliente
left JOIN QUERY_MASTERS.Factura f
ON f.id_cliente = c.ID_cliente
JOIN QUERY_MASTERS.BI_DimTiempo AS dt
ON dt.anio = DATEPART(YEAR,  p.fecha_hora)
AND dt.mes = DATEPART(MONTH, p.fecha_hora)
AND dt.cuatrimestre = CEILING(DATEPART(MONTH, p.fecha_hora) / 4.0) 
JOIN QUERY_MASTERS.BI_DimUbicacion AS du
ON du.provincia = pr.nombre
AND du.localidad = l.nombre
JOIN QUERY_MASTERS.BI_DimEstadoPedido AS dest
ON dest.estado = p.estado
JOIN QUERY_MASTERS.BI_DimTurno AS dtt
ON dtt.descripcion = CASE
WHEN DATEPART(HOUR, p.fecha_hora) BETWEEN 8 AND 13 THEN '08:00-14:00'
WHEN DATEPART(HOUR, p.fecha_hora) BETWEEN 14 AND 19 THEN '14:00-20:00'                                
END
GROUP BY     
dt.ID_tiempo,
p.ID_cliente,
du.ID_ubicacion,
dtt.ID_turno,   
si.id_Modelo,
dest.ID_estado,
p.estado,
MONTH(p.fecha_hora),
p.ID_sucursal
END;
GO

EXEC QUERY_MASTERS.BI_MigrarHechoPedido;


GO
CREATE OR ALTER PROCEDURE QUERY_MASTERS.BI_MigrarHechoFactura
AS
BEGIN
SET NOCOUNT ON;
WITH Promedios AS (
SELECT 
du2.ID_ubicacion,
MONTH(f2.fecha_hora) AS mes,
YEAR(f2.fecha_hora) AS anio,
AVG(f2.total) AS promedio_facturas
FROM QUERY_MASTERS.Factura f2
JOIN QUERY_MASTERS.Sucursal su2 ON f2.ID_sucursal = su2.ID_sucursal
JOIN QUERY_MASTERS.Localidad l2 ON su2.ID_localidad = l2.ID_localidad
JOIN QUERY_MASTERS.Provincia p2 ON l2.ID_provincia = p2.ID_provincia
JOIN QUERY_MASTERS.BI_DimUbicacion du2 
ON du2.provincia = p2.nombre AND du2.localidad = l2.nombre
GROUP BY du2.ID_ubicacion, MONTH(f2.fecha_hora), YEAR(f2.fecha_hora))
    INSERT INTO QUERY_MASTERS.BI_HechoFactura (
        ID_tiempo,
        ID_cliente,
        ID_ubicacion,
        ID_turno,
        total,
        promedio_facturas
)SELECT
dt.ID_tiempo,
dc.ID_cliente,
du.ID_ubicacion,
t.ID_turno,
SUM(df.subtotal) AS total,
ISNULL(p.promedio_facturas, 0) AS promedio_facturas
FROM QUERY_MASTERS.Factura AS f
INNER JOIN QUERY_MASTERS.DetalleFactura AS df ON f.nro_factura = df.id_factura
INNER JOIN QUERY_MASTERS.Sucursal AS su ON f.id_sucursal = su.ID_sucursal
INNER JOIN QUERY_MASTERS.Localidad AS l ON su.ID_localidad = l.ID_localidad
INNER JOIN QUERY_MASTERS.Provincia AS pr ON l.ID_provincia = pr.ID_provincia
INNER JOIN QUERY_MASTERS.BI_DimTiempo AS dt 
ON dt.anio = DATEPART(YEAR, f.fecha_hora)
AND dt.mes = DATEPART(MONTH, f.fecha_hora)
AND dt.cuatrimestre = CEILING(DATEPART(MONTH, f.fecha_hora) / 4.0)
INNER JOIN QUERY_MASTERS.BI_DimUbicacion AS du 
ON du.provincia = pr.nombre AND du.localidad = l.nombre
INNER JOIN QUERY_MASTERS.BI_DimTurno AS t 
ON t.descripcion = CASE 
WHEN DATEPART(HOUR, f.fecha_hora) BETWEEN 8 AND 13 THEN '08:00-14:00'
WHEN DATEPART(HOUR, f.fecha_hora) BETWEEN 14 AND 19 THEN '14:00-20:00'
END
INNER JOIN QUERY_MASTERS.BI_DimCliente AS dc ON dc.ID_cliente = f.ID_cliente
LEFT JOIN Promedios p 
ON p.ID_ubicacion = du.ID_ubicacion
AND p.mes = MONTH(f.fecha_hora)
AND p.anio = YEAR(f.fecha_hora)
GROUP BY
dt.ID_tiempo,
dc.ID_cliente,
du.ID_ubicacion,
t.ID_turno,
p.promedio_facturas;
END;
GO
EXEC QUERY_MASTERS.BI_MigrarHechoFactura;

GO
CREATE OR ALTER PROCEDURE QUERY_MASTERS.BI_MigrarHechoCompra
AS
BEGIN
SET NOCOUNT ON;
INSERT INTO QUERY_MASTERS.BI_HechoCompra (
ID_tiempo,
ID_material,
ID_ubicacion,
total)
SELECT
dt.ID_tiempo,
dc.id_material,
du.ID_ubicacion,
SUM(dc.subtotal) AS total
FROM QUERY_MASTERS.Compra AS c
JOIN QUERY_MASTERS.DetalleCompra AS dc
ON c.ID_compra = dc.id_compra
JOIN QUERY_MASTERS.Sucursal AS su
ON c.ID_sucursal = su.ID_sucursal
JOIN QUERY_MASTERS.Localidad AS l
ON su.ID_localidad = l.ID_localidad
JOIN QUERY_MASTERS.Provincia AS pr
ON l.ID_provincia = pr.ID_provincia	
JOIN QUERY_MASTERS.BI_DimTiempo AS dt
ON dt.anio = DATEPART(YEAR, c.fecha_compra)
AND dt.mes= DATEPART(MONTH, c.fecha_compra)
AND dt.cuatrimestre = CEILING(DATEPART(MONTH, c.fecha_compra) / 4.0)
JOIN QUERY_MASTERS.BI_DimUbicacion AS du
ON du.provincia = pr.nombre
AND du.localidad = l.nombre
GROUP BY
dt.ID_tiempo,
dc.id_material,
du.ID_ubicacion
END;
GO

EXEC QUERY_MASTERS.BI_MigrarHechoCompra;


GO 
CREATE OR ALTER VIEW QUERY_MASTERS.VistaGanancias
AS
WITH Ventas AS (
SELECT 
ID_ubicacion,
ID_tiempo,
SUM(ISNULL(total, 0)) AS total_ventas
FROM QUERY_MASTERS.BI_HechoFactura
GROUP BY ID_ubicacion, ID_tiempo),
Compras AS (
SELECT 
ID_ubicacion,
ID_tiempo,
SUM(ISNULL(total, 0)) AS total_compras
FROM QUERY_MASTERS.BI_HechoCompra
GROUP BY ID_ubicacion, ID_tiempo)
SELECT 
v.ID_ubicacion,
ds.ID_sucursal,
dt.mes,
dt.anio,
ISNULL(v.total_ventas, 0) - ISNULL(c.total_compras, 0) AS ganancias
FROM Ventas v
LEFT JOIN Compras c 
ON v.ID_ubicacion = c.ID_ubicacion AND v.ID_tiempo = c.ID_tiempo
JOIN QUERY_MASTERS.BI_DimSucursal ds 
ON ds.ID_ubicacion = v.ID_ubicacion
JOIN QUERY_MASTERS.BI_DimTiempo dt 
ON dt.ID_tiempo = v.ID_tiempo


GO 

CREATE OR ALTER VIEW QUERY_MASTERS.VistaFacturaPromedioMensual
AS
SELECT
dt.anio AS Anio,
dt.cuatrimestre AS Cuatrimestre,
du.provincia AS ProvinciaSucursal,
AVG(ISNULL(hf.promedio_facturas, 0)) promedioFacturas
FROM
QUERY_MASTERS.BI_DimTiempo dt
INNER JOIN
QUERY_MASTERS.BI_HechoFactura hf ON dt.ID_tiempo = hf.ID_tiempo
INNER JOIN
QUERY_MASTERS.BI_DimUbicacion du ON hf.ID_ubicacion = du.ID_ubicacion
GROUP BY
dt.anio,
dt.cuatrimestre,
du.provincia
	
GO
CREATE OR ALTER VIEW QUERY_MASTERS.VistaRendimientoModelos
AS
WITH ModelSales AS (
SELECT
dt.anio AS Anio,
dt.cuatrimestre AS Cuatrimestre,
du.localidad AS LocalidadSucursal,
dc.rango_etario AS RangoEtarioCliente,
dm.descripcion AS ModeloDescripcion,
SUM(ISNULL(hp.volumen, 0)) AS TotalVentasModelo 
FROM
QUERY_MASTERS.BI_HechoPedido hp
    INNER JOIN QUERY_MASTERS.BI_DimTiempo dt ON hp.ID_tiempo = dt.ID_tiempo
    INNER JOIN QUERY_MASTERS.BI_DimCliente dc ON hp.ID_cliente = dc.ID_cliente
    INNER JOIN QUERY_MASTERS.BI_DimUbicacion du ON hp.ID_ubicacion = du.ID_ubicacion
    INNER JOIN QUERY_MASTERS.BI_DimModeloSillon dm ON hp.ID_modelo = dm.ID_modelo
    GROUP BY
dt.anio,
dt.cuatrimestre,
du.localidad,
dc.rango_etario,
dm.descripcion
),
RankedModelSales AS (
    SELECT *,
ROW_NUMBER() OVER (
PARTITION BY Anio, Cuatrimestre, LocalidadSucursal, RangoEtarioCliente
ORDER BY TotalVentasModelo DESC, ModeloDescripcion) AS RowNum
FROM ModelSales
)
SELECT
    Anio,
    Cuatrimestre,
    LocalidadSucursal,
    RangoEtarioCliente,
    ModeloDescripcion,
    TotalVentasModelo
FROM
RankedModelSales
WHERE
RowNum <= 3;

GO 
CREATE OR ALTER VIEW QUERY_MASTERS.VistaVolumenPedidos
AS
SELECT
    dt.anio AS Anio,
    dt.mes AS Mes,
    ds.ID_sucursal AS Sucursal,
    dtu.descripcion AS Turno,
    COUNT(*) AS CantidadPedidos
FROM
QUERY_MASTERS.BI_HechoPedido hp
INNER JOIN
QUERY_MASTERS.BI_DimTiempo dt ON hp.ID_tiempo = dt.ID_tiempo
INNER JOIN
QUERY_MASTERS.BI_DimUbicacion du ON hp.ID_ubicacion = du.ID_ubicacion 
INNER JOIN
QUERY_MASTERS.BI_DimSucursal ds ON du.ID_ubicacion = ds.ID_ubicacion                                                                 
INNER JOIN
QUERY_MASTERS.BI_DimTurno dtu ON dtu.ID_turno = hp.ID_turno
                                            

GROUP BY
dt.anio,
dt.mes,
ds.ID_sucursal,
dtu.descripcion

GO 
CREATE OR ALTER VIEW QUERY_MASTERS.VistaConversionPedidos AS
SELECT
    dt.anio AS Anio,
    dt.cuatrimestre AS Cuatrimestre,
    ds.ID_sucursal AS Sucursal,
    dep.estado AS EstadoPedido,
    AVG(ISNULL(hp.conversion, 0)) pedidoConversion
FROM
QUERY_MASTERS.BI_HechoPedido   AS hp
INNER JOIN QUERY_MASTERS.BI_DimTiempo AS dt ON hp.ID_tiempo  = dt.ID_tiempo
INNER JOIN QUERY_MASTERS.BI_DimUbicacion AS du ON hp.ID_ubicacion = du.ID_ubicacion
INNER JOIN QUERY_MASTERS.BI_DimSucursal AS ds ON du.ID_ubicacion = ds.ID_ubicacion
INNER JOIN QUERY_MASTERS.BI_DimEstadoPedido AS dep ON hp.ID_estado  = dep.ID_estado
GROUP BY
dt.anio, 
dt.cuatrimestre,
ds.ID_sucursal,	
dep.estado;
	
GO
CREATE OR ALTER VIEW QUERY_MASTERS.VistaPromedioCompras
AS
SELECT
dt.anio AS Anio,
dt.mes AS Mes,
ISNULL(AVG(hc.total), 0) AS PromedioComprasMensual
FROM
QUERY_MASTERS.BI_HechoCompra hc
INNER JOIN
QUERY_MASTERS.BI_DimTiempo dt ON hc.ID_tiempo = dt.ID_tiempo
GROUP BY
dt.anio,
dt.mes

GO 
CREATE OR ALTER VIEW QUERY_MASTERS.VistaComprasPorTipoMaterial
AS
SELECT
dt.anio AS Anio,
dt.cuatrimestre AS Cuatrimestre,
ds.ID_sucursal AS ID_Sucursal,
dmt.tipo AS TipoMaterial,
ISNULL(SUM(hc.total), 0) AS ImporteTotalGastado
FROM
QUERY_MASTERS.BI_HechoCompra hc
INNER JOIN
QUERY_MASTERS.BI_DimTiempo dt ON hc.ID_tiempo = dt.ID_tiempo
INNER JOIN
QUERY_MASTERS.BI_DimTipoMaterial dmt ON hc.ID_material = dmt.ID_material
INNER JOIN
QUERY_MASTERS.BI_DimUbicacion du ON hc.ID_ubicacion = du.ID_ubicacion
INNER JOIN
QUERY_MASTERS.BI_DimSucursal ds ON du.ID_ubicacion = ds.ID_ubicacion
GROUP BY
dt.anio,
dt.cuatrimestre,
ds.ID_sucursal,
dmt.tipo	
GO
CREATE OR ALTER VIEW QUERY_MASTERS.VistaPorcentajeCumplimientoEnvios
AS
SELECT
dt.anio AS Anio,
dt.mes AS Mes, 
AVG(ISNULL(he.porcentajeCumplimiento, 0)) porcentajePromedioCumplimiento
FROM
QUERY_MASTERS.BI_HechoEnvio he
INNER JOIN
QUERY_MASTERS.BI_DimTiempo dt ON he.ID_tiempo = dt.ID_tiempo
GROUP BY
dt.anio,
dt.mes

GO
CREATE OR ALTER VIEW QUERY_MASTERS.VistaLocalidadesMayorCostoEnvio
AS
WITH EnvioPorLocalidad AS (
SELECT
du.provincia,
du.localidad,
AVG(ISNULL(he.totalPromedio, 0)) AS PromedioCostoEnvio
FROM QUERY_MASTERS.BI_HechoEnvio AS he
JOIN QUERY_MASTERS.BI_DimUbicacion du ON he.ID_ubicacion = du.ID_ubicacion  
GROUP BY du.localidad, du.provincia
),
Ranking AS (
SELECT
localidad,
provincia,
PromedioCostoEnvio,
DENSE_RANK() OVER (ORDER BY PromedioCostoEnvio DESC) AS Posicion
FROM EnvioPorLocalidad
)
SELECT TOP 3
localidad,
provincia,
PromedioCostoEnvio
FROM Ranking
WHERE Posicion <= 3;
GO
CREATE OR ALTER VIEW QUERY_MASTERS.VistaTiempoPromedioFabricacion
AS
SELECT 
ds.ID_sucursal,
dt.anio,
dt.cuatrimestre,
AVG(ISNULL(hp.tiempoDeFabricacion, 0)) fabricacionPromedio
FROM QUERY_MASTERS.BI_HechoPedido hp
JOIN QUERY_MASTERS.BI_DimSucursal ds ON  ds.ID_ubicacion = hp.ID_ubicacion
JOIN QUERY_MASTERS.BI_DimTiempo dt ON dt.ID_tiempo = hp.ID_tiempo   
GROUP BY
ds.ID_sucursal,
dt.anio,
dt.cuatrimestre
	


--hecho envio - 16744
--hecho factura - 16079
--hecho pedido - 54250
--hecho compra - 612