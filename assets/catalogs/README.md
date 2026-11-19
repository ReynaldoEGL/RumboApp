# Catálogos de Rumbo

Los catálogos son datos de referencia independientes de los vehículos
registrados por los usuarios.

## Formato de archivos

Cada catálogo utiliza un objeto JSON con:

- `schemaVersion`: versión de la estructura del archivo.
- `catalogId`: identificador del catálogo.
- `catalogRevision`: revisión del contenido.
- `items`: registros que se convertirán en modelos de dominio.

Los identificadores de las marcas y modelos son slugs estables.
Los nombres visibles pueden cambiar sin modificar su relación.

## Catálogos de vehículos

`vehicles/brands.json` contiene marcas y tipos de vehículo admitidos.

`vehicles/models.json` contiene modelos y la marca a la que pertenece
cada registro mediante `brandId`.

La lista inicial es una semilla de desarrollo. No representa un
catálogo exhaustivo del mercado mexicano ni garantiza que cada modelo
se comercialice actualmente en cada país.

No deben inferirse versiones, motores, consumos ni años de fabricación
a partir de la existencia de un modelo en esta lista.

## Catálogos geográficos

`geography/countries.json` utiliza códigos ISO 3166-1 alpha-2 y alpha-3.

`geography/regions.json` utiliza códigos ISO 3166-2 cuando están
disponibles.

La primera revisión incluye una lista inicial de países y las
32 entidades federativas de México. Las regiones de otros países
se incorporarán posteriormente.

## Ampliación y mantenimiento

Para agregar una marca o modelo:

1. Conservar el formato del archivo.
2. Asignar un identificador estable y único.
3. Asociar cada modelo con un `brandId` existente.
4. Declarar los tipos de vehículo correspondientes.
5. Verificar el JSON y ejecutar las pruebas.

Los catálogos son de solo lectura desde la aplicación.
Su futura actualización remota se administrará mediante una fuente
de datos controlada, no mediante cambios enviados libremente por
los usuarios.

Los datos de catálogos nunca deben confundirse con los vehículos
personales guardados en `users/{uid}/vehicles`.