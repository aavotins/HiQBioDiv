# libs ----
if(!require(sf)) {install.packages("sf"); require(sf)}
if(!require(tidyverse)) {install.packages("tidyverse"); require(tidyverse)}
if(!require(arrow)) {install.packages("arrow"); require(arrow)}
if(!require(sfarrow)) {install.packages("sfarrow"); require(sfarrow)}
if(!require(terra)) {install.packages("terra"); require(terra)}



# Task ----

# Template/reference rasters are necessary to produce matching layers througout the project.
## CRS of all the layers is EPSG:3059. All the layers are preppared as GeoTIFFs

# We have decided to 100 m raster grid cell resolution (epsg:3059) for species distribution modelling. 
## To have comparable inputs, we have decided to use 10 m resolution for all the input data. 
## That is 1/10 of the analysis resolution.

# To speed up calculations of some of the landscape metrics, we have decided to use also 500 m grid cell.

# Inputs ----

# administrative borders
## downloaded from: https://data.gov.lv/dati/lv/dataset/atr [2024-04-22]
adm_ter=read_sf("./Administrativas_teritorijas_2021.shp")
adm_ter$yes=1

# 100 m vector grid prepares in a script "./TemplateGrids_Vector.R"
tikls100=st_read_parquet("./tikls100_sauzeme.parquet")
b=terra::crs(tikls100)

# 10 m ----

rastrs=terra::rast(xmin=302800,xmax=772800,ymin=162900,ymax=448900, # BBOX of territory of Latvia, aexpanded by 10 km
                   resolution=10,crs=b)
# rasterisation of territory of Latvia
rast_LV=rasterize(vect(adm_ter),rastrs)
# writing raster file
terra::writeRaster(rast_LV,"./LV10m_10km.tif")


# 100 m ----

rastrs100=terra::rast(xmin=302800,xmax=772800,ymin=162900,ymax=448900,
                      resolution=100,crs=b)
# rasterisation of territory of Latvia
rast_LV100=rasterize(vect(adm_ter),rastrs100)
# writing raster file
terra::writeRaster(rast_LV100,"./LV100m_10km.tif")

# 500 m ----

rastrs500=terra::rast(xmin=302800,xmax=772800,ymin=162900,ymax=448900,resolution=500,crs=b)
# rasterisation of territory of Latvia
rast_LV500=rasterize(vect(adm_ter),rastrs500)
# writing raster file
terra::writeRaster(rast_LV500,"./LV500m_10km.tif")


