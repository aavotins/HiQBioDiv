dir.create("./Geodata/LAD")

# libs
if(!require(sf)) {install.packages("sf"); require(sf)}
if(!require(arrow)) {install.packages("arrow"); require(arrow)}
if(!require(sfarrow)) {install.packages("sfarrow"); require(sfarrow)}
if(!require(gdalUtilities)) {install.packages("gdalUtilities"); require(gdalUtilities)}
if(!require(httr)) {install.packages("httr"); require(httr)}
if(!require(tidyverse)) {install.packages("tidyverse"); require(tidyverse)}
if(!require(ows4R)) {install.packages("ows4R"); require(ows4R)}

# lejupielāde
wfs_bwk <- "https://karte.lad.gov.lv/arcgis/services/lauki/MapServer/WFSServer"
url <- parse_url(wfs_bwk)
url$query <- list(service = "wfs",
                  #version = "2.0.0", # fakultatīvi
                  request = "GetCapabilities"
)
vaicajums <- build_url(url)

bwk_client <- WFSClient$new(wfs_bwk, 
                            serviceVersion = "2.0.0")
bwk_client$getFeatureTypes() %>%
  map_chr(function(x){x$getTitle()})

dati <- read_sf(vaicajums) # 2025-02-18

# multipoligoni
ensure_multipolygons <- function(X) {
  tmp1 <- tempfile(fileext = ".gpkg")
  tmp2 <- tempfile(fileext = ".gpkg")
  st_write(X, tmp1)
  ogr2ogr(tmp1, tmp2, f = "GPKG", nlt = "MULTIPOLYGON")
  Y <- st_read(tmp2)
  st_sf(st_drop_geometry(X), geom = st_geometry(Y))
}
dati2 <- ensure_multipolygons(dati)

# pārbaudes
dati3 = dati2[!st_is_empty(dati2),,drop=FALSE] # OK
validity=st_is_valid(dati3) 
table(validity) # 13 invalīdi

dati4=st_make_valid(dati3)
table(st_is_valid(dati4)) # OK

# saglabāšana
sf::st_write(dati4, "./Geodata/LAD/LAD_lauki_20250218_all.gpkg")

rm(dati)
rm(dati2)
rm(dati3)

str(dati4)
head(dati4)

table(dati4$PERIOD_CODE,useNA="always")
tapply(dati4$DATA_CHANGED_DATE,dati4$PERIOD_CODE,summary)

dati5=dati4 %>% 
  filter(PERIOD_CODE==2024)
sfarrow::st_write_parquet(dati5, "./Geodata/LAD/LAD_lauki_20250218_2024.parquet")

