# EIS: Framework para Evaluaciones de Impacto en Salud de intervenciones urbanas

> Estado: documento en construcción. Las secciones de metodología y herramientas están confirmadas contra el código y los reportes revisados. Las secciones de reproducción paso a paso todavía están pendientes.

## Qué es este repositorio

Este repositorio reúne un framework metodológico para realizar Evaluaciones de Impacto en Salud (EIS / Health Impact Assessment) de intervenciones urbanas relacionadas con movilidad, calidad del aire y salud. El objetivo no es documentar un proyecto puntual, sino dejar un flujo de trabajo reproducible que cualquier investigador pueda aplicar a una intervención distinta, en una ciudad distinta.

Los casos de estudio de referencia (Primera Línea del Metro de Bogotá, ZUMA) son aplicaciones de ejemplo del framework, no su objeto central. Por diseño, este repositorio no incluye bases de datos: es una herramienta de código para que cada investigador la corra con sus propios datos, no un contenedor de los datos de un caso particular. Cada módulo documenta el esquema de entrada que espera y el esquema de salida que produce.


## Qué es una EIS en este proyecto

Una Evaluación de Impacto en Salud es una metodología prospectiva que estima, antes de que una intervención entre en operación, sus efectos potenciales sobre la salud de la población expuesta. Sigue el enfoque de seis fases recomendado por la OMS/OPS:

1. **Selección (screening)**: justificar por qué la intervención amerita una EIS.
2. **Alcance (scoping)**: delimitar qué desenlaces en salud se van a evaluar, con participación de actores institucionales y comunitarios.
3. **Análisis**: cuantificar el efecto potencial sobre los desenlaces priorizados.
4. **Reporte**: documentar el proceso y los hallazgos.
5. **Recomendaciones**: traducir los resultados en acciones de mejora y mitigación.
6. **Monitoreo y evaluación**: definir indicadores de seguimiento y, si es posible, repetir la evaluación con datos observados.

La fase de análisis es la que concentra la mayor parte del código de este repositorio. Se apoya en dos herramientas reimplementadas en Python siguiendo metodologías respaldadas por la OMS (AirQ+, GreenUr) y una herramienta que llama en vivo a la API oficial de la OMS/Sustrans (HEAT). Las tres corren sobre la misma área de influencia y convergen en una métrica común: muertes prematuras evitables al año y su valoración económica.

Un punto importante: las muertes evitables estimadas por cada contaminante o dimensión **no son sumables entre sí**, porque comparten población expuesta. Cada resultado debe leerse por separado.

## Herramientas de la fase de análisis

| Herramienta | Qué estima | Naturaleza del código en este repositorio | Dependencia externa |
|---|---|---|---|
| **AirQ+** | Muertes prematuras evitables por reducción de PM2.5, PM10 y NO2 | Reimplementación propia en Python de la metodología de AirQ+ (función exposición-respuesta log-lineal, PAF por unidad geográfica). No requiere instalar el software de la OMS; los resultados se validaron contra la herramienta oficial. | Ninguna. Corre localmente. |
| **GreenUr** | Muertes prematuras evitables por aumento de cobertura vegetal (NDVI) | Reimplementación propia en Python de la función exposición-respuesta de Rojas-Rueda et al. (2019). | Ninguna. Corre localmente. |
| **HEAT** | Muertes prematuras evitables y CO2 no emitido por aumento de caminata/ciclismo | Preparación de datos en Python (encuesta de movilidad) + llamadas en R a la API oficial de HEAT ("HaaS", `api.heatwalkingcycling.org`), que expone el mismo paquete R que usa la herramienta web de la OMS/Sustrans. | Sí: requiere conectividad a internet, un token de acceso a la API y una plantilla `.rds` exportada manualmente desde la interfaz web de HEAT. |

### AirQ+ (`airq_plus/`)

- Código: `AirQ+PM25.ipynb`, `AirQ+PM10.ipynb`, `AirQ+NO2.ipynb` — uno por contaminante, ejecutable sobre cualquier número de casos de estudio.
- Este módulo **no incluye datos**. El usuario debe construir su propio archivo de entrada.
- Esquema de entrada esperado (Excel, una fila por unidad geográfica de análisis):

  | Columna | Tipo | Descripción |
  |---|---|---|
  | `SETU_CCNCT` | texto | identificador de la unidad geográfica |
  | `MAYORES_30AÑOS` | numérico | población de 30 años o más |
  | `promedio_muertes_2015_2019_naturales_30_años` | numérico | promedio anual de muertes por causas naturales, población 30+ |
  | `MODELADO_PM25_2022` / `MODELADO_PM10_2022` / `kriging_no2_2022` | numérico | concentración del contaminante correspondiente (el nombre varía según notebook; ver la función `estandarizar_airq`) |

- La ruta de lectura (`METRO_AIRQ+.xlsx`, `ZUMA_AIRQ+.xlsx` en el código actual) se define explícitamente en cada notebook; para un caso nuevo se reemplaza esa ruta.
- Salida: CSV por escenario y zona, más un resumen agregado con muertes atribuibles evitables (central, límite inferior, superior) y FAP por unidad geográfica y escenario. Los outputs se generan al ejecutar el notebook; no se incluyen en el repositorio.

### GreenUr (`greenur/`)

- Código: `GreenUR.ipynb`, parametrizado por ruta de entrada (`RUTA_ENTRADA` al inicio del notebook).
- Este módulo **no incluye datos**.
- Esquema de entrada esperado (Excel, una fila por unidad geográfica):

  | Columna | Tipo | Descripción |
  |---|---|---|
  | `SETU_CCNCT` | texto | identificador de la unidad geográfica |
  | `NDVI_2022_mean` | numérico | NDVI promedio de la unidad geográfica |
  | `promedio_muertes_2015_2019_naturales_20_años` | numérico | promedio anual de muertes por causas naturales, población 20+ |

- Salida: un Excel con hojas `resultados_sector`, `resumen`, `resumen_grafico` y `variables_requeridas` (esta última documenta el esquema de entrada dentro del propio archivo de salida). No se incluye en el repositorio.

### HEAT (`heat/`)

- Código:
  - `01_preparacion_datos_movilidad.ipynb`: agrega la encuesta de movilidad local (módulos de personas y viajes) en minutos de caminata/ciclismo por persona/día, por unidad geográfica y tramo. Usa `geopandas` para cruzar la encuesta con capas GIS del área de influencia.
  - `02_llamado_api_heat.R`: llama a la API oficial de HEAT por escenario y exporta los resultados crudos.
- Este módulo **no incluye datos ni resultados**. Depende de insumos que el usuario debe conseguir por su cuenta:
  1. Encuesta de movilidad local con módulos de personas y viajes (el esquema de columnas que espera el notebook está documentado en sus primeras celdas).
  2. Capas GIS del área de influencia (buffer, trazado de la intervención, unidades geográficas de agregación).
  3. Para el llamado a la API: una plantilla `webapp_input` en formato `.rds`, exportada manualmente desde la interfaz web de HEAT (heatwalkingcycling.org/tool, "Export page"), y un token de acceso a la API vigente, provisto por el equipo de HEAT/Sustrans.
- El token se lee desde la variable de entorno `HEAT_API_TOKEN`; el script falla explícitamente si no está definida. No debe escribirse dentro del código.
- Documentación oficial de la API, incluida en `heat/docs/`: `README.html` explica el flujo de la API (`prepare_gdr`, `calc_results`, `results`) y dos codebooks (`HEAT_codebook_UI_inputvars_loops_expanded.csv`, `HEAT_codebook_default_background_parameters.csv`) documentan cada variable de entrada que espera HEAT. Estos tres archivos son documentación de referencia, no datos del proyecto.
- Salida: un data.frame por escenario con campos como `impacttotal`, `impacttotalco2`, `moneytotal` (ver ejemplos en `heat/docs/README.html`).
- Brecha pendiente: el paso que convierte el volcado crudo de la API en las tablas finales del reporte se hizo manualmente en Excel y todavía no está capturado como código.
- Las rutas de lectura de datos en `01_preparacion_datos_movilidad.ipynb` están escritas para el entorno original de quien lo desarrolló; deben ajustarse antes de ejecutarlo en otra máquina.

## Reporting (`reporting/`)

`reporting/sophia_zuma_tables.R` consolida las salidas de AirQ+, GreenUr y HEAT en las tablas resumen (población, área, NDVI, muertes prevenibles, FAP) que alimentan el reporte técnico. Por ahora está escrito específicamente para el caso ZUMA y espera los CSV/Excel de salida de los otros módulos como insumo.

## Casos de estudio de referencia

- Primera Línea del Metro de Bogotá (PLMB) — caso más desarrollado, con AirQ+, GreenUr y HEAT aplicados.
- ZUMA

Ninguno de estos casos trae sus datos dentro del repositorio; ver la sección de cada herramienta para el esquema de entrada esperado.

## Estructura del repositorio

```
EIS/
├── README.md
├── LICENSE
├── requirements.txt          # dependencias Python (AirQ+, GreenUr, preparación de datos de HEAT)
├── requirements_r.R          # dependencias R (llamadas a la API de HEAT, reporting)
├── airq_plus/                # módulo AirQ+ (calidad del aire) — solo código
├── greenur/                  # módulo GreenUr (cobertura vegetal) — solo código
├── heat/                     # módulo HEAT (movilidad activa) — código + documentación de la API
│   └── docs/
└── reporting/                # scripts que consolidan salidas de los módulos en tablas de reporte

```


## Insumos que cada módulo espera (no incluidos en el repositorio)

| Insumo | Módulo | Origen / esquema esperado |
|---|---|---|
| Archivo de entrada por caso de estudio (`<CASO>_AIRQ+.xlsx`) | AirQ+ | Ver esquema de columnas en la sección AirQ+ de este README |
| Archivo de entrada por caso de estudio (`<CASO>_GREENUR.xlsx` o equivalente) | GreenUr | Ver esquema de columnas en la sección GreenUr de este README |
| Encuesta de movilidad local (módulos personas y viajes) | HEAT — preparación de datos | Formato de la Encuesta de Movilidad de Bogotá 2023; columnas documentadas en la primera celda de `heat/01_preparacion_datos_movilidad.ipynb` |
| Capas GIS del área de influencia (buffer, trazado, unidades geográficas) | HEAT — preparación de datos | Shapefile o geopackage con la geometría de la intervención y sus unidades de agregación |
| Plantilla `webapp_input` (`.rds`) | HEAT — llamado a la API | Se exporta manualmente desde la interfaz web de HEAT (heatwalkingcycling.org/tool), "Export page" |
| Token de acceso a la API de HEAT | HEAT — llamado a la API | Se solicita al equipo de HEAT/Sustrans; se define como variable de entorno `HEAT_API_TOKEN`, nunca en el código |
| Código generalizado del módulo LST / rearborización | Fuera de alcance de este repositorio por ahora | Reporte técnico (sección de análisis de temperatura superficial) |


## Licencia

MIT. Ver [LICENSE](LICENSE).
