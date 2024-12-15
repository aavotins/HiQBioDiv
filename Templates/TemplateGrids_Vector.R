# libs ----
if(!require(sf)) {install.packages("sf"); require(sf)}
if(!require(tidyverse)) {install.packages("tidyverse"); require(tidyverse)}
if(!require(arrow)) {install.packages("arrow"); require(arrow)}
if(!require(sfarrow)) {install.packages("sfarrow"); require(sfarrow)}


# inputs ----

# administrative borders
## downloaded from: https://data.gov.lv/dati/lv/dataset/atr [2024-04-22]
admin=read_sf("./Administrativas_teritorijas_2021.shp")
ggplot(admin)+geom_sf()

# 100 m grid
## downloaded from: https://data.gov.lv/dati/lv/dataset/rezgis [2024-04-22]

# 1000 m grid
## downloaded from: https://data.gov.lv/dati/lv/dataset/rezgis [2024-04-22]

# tks50km
## distributed by Envirotech as a part of GIS_Latvia10.2
## due to limited finadability included in uploads

# Task ----

# filter only those polygons that overlap with administrative borders
# ensure crs=epsg:3059
# create centroid points
# ensure ID fields of any other joinable grid present in 100 m grid
# create additional 300 m and 500 m grids joinable to 100 m grid

# to ensure longevity, prepare *.gpkg with layers corresponding to *.parquet for storage
# to ensure replicability, store also *.parquet files used in analysis

# 100 m ----

tikls100=read_sf("./grid_lv_100.gpkg",layer="grid_lv_100")
tikls100$yes=1

tikls100=st_transform(tikls100,crs=3059)

tikls100_sauszeme=tikls100[adm_ter,,]
st_write_parquet(tikls100_sauszeme,"./tikls100_sauzeme.parquet")

centri100=st_centroid(tikls100_sauszeme)
st_write_parquet(centri100,"./pts100_sauzeme.parquet")

tks50km=st_read_parquet("./tks93_50km.parquet")
savienots=st_join(centri100,tks50km)
savienots=savienots %>% 
  mutate(tks50km=NUMURS) %>% 
  dplyr::select(id,yes,tks50km)
st_write_parquet(savienots,"./pts100_sauzeme.parquet")

# 1000 m ----

tikls1000=read_sf("./grid_lv_1k/Grid_LV_1k.shp")
tikls1000$yes=1
tikls1000_sauszeme=tikls1000[adm_ter,,]
sfarrow::st_write_parquet(tikls1000_sauszeme,"./tikls1k_sauzeme.parquet")

tikls1000_sauszeme$ID1km=tikls1000_sauszeme$ID
punkti=st_read_parquet("./pts100_sauzeme.parquet")
savienots=st_join(punkti,tikls1000_sauszeme[,"ID1km"])
st_write_parquet(savienots,"./pts100_sauzeme.parquet")

pievienosanai=data.frame(savienots) %>% 
  dplyr::select(id,ID1km)
tikls100=tikls100 %>% 
  left_join(pievienosanai,by="id")
st_write_parquet(tikls100,"./tikls100_sauzeme.parquet")

tks50km=st_read_parquet("./tks93_50km.parquet")
centri1000=st_centroid(tikls1000_sauszeme)
centri1000=st_join(centri1000,tks50km)
centri1000=centri1000 %>% 
  mutate(tks50km=NUMURS) %>% 
  dplyr::select(ID1km,tks50km)
st_write_parquet(centri1000,"./pts1000_sauzeme.parquet")


# 300 m ----

tikls300=st_make_grid(tikls100,cellsize=c(300,300))
tikls300_LV=tikls300[tikls100,,]
tikls300_LV=st_as_sf(tikls300_LV)
tikls300_LV$rinda300=rownames(tikls300_LV)
st_write_parquet(tikls300_LV,"./tikls300_sauzeme.parquet")

tikls300_LV=st_read_parquet("./tikls300_sauzeme.parquet")
centri300=st_centroid(tikls300_LV)
st_write_parquet(centri300,"./pts300_sauzeme.parquet")

tks50km=st_read_parquet("./tks93_50km.parquet")
centri300=st_join(centri300,tks50km)
centri300b=centri300 %>% 
  mutate(tks50km=NUMURS) %>% 
  dplyr::select(rinda300,tks50km)
st_write_parquet(centri300b,"./pts300_sauzeme.parquet")

punkti=st_read_parquet("./pts100_sauzeme.parquet")
savienots=st_join(punkti,tikls300_LV)
st_write_parquet(savienots,"./pts100_sauzeme.parquet")

pievienosanai=data.frame(savienots) %>% 
  dplyr::select(id,rinda300)
tikls100=tikls100 %>% 
  left_join(pievienosanai,by="id")
st_write_parquet(tikls100,"./tikls100_sauzeme.parquet")


# 500 m ----
tikls500=st_make_grid(tikls100,cellsize = 500,crs=3059)
t500=st_as_sf(tikls500)
t500$rinda500=rownames(t500)
sfarrow::st_write_parquet(t500,"./tikls500_sauzeme.parquet")


centri500=st_centroid(tikls500)
st_write_parquet(centri500,"./pts500_sauzeme.parquet")

tks50km=st_read_parquet("./tks93_50km.parquet")
savienots=st_join(centri500,tks50km)
savienots=savienots %>% 
  mutate(tks50km=NUMURS) %>% 
  dplyr::select(rinda500,tks50km)
st_write_parquet(savienots,"./pts500_sauzeme.parquet")
pievienosanai=data.frame(savienots) %>% 
  dplyr::select(rinda500,tks50km)
tikls500=tikls500 %>% 
  left_join(pievienosanai,by="rinda500")
st_write_parquet(tikls500,"./tikls500_sauzeme.parquet")


savienots=st_join(punkti,tikls500)
st_write_parquet(savienots,"./pts100_sauzeme.parquet")

pievienosanai=data.frame(savienots) %>% 
  dplyr::select(id,rinda500)
tikls100=tikls100 %>% 
  left_join(pievienosanai,by="id")
st_write_parquet(tikls100,"./tikls100_sauzeme.parquet")

# gpkg ----
st_write(tikls100,"./vector_grids.gpkg",layer="tikls100_sauzeme")
st_write(tikls300,"./vector_grids.gpkg",layer="tikls300_sauzeme")
st_write(tikls500,"./vector_grids.gpkg",layer="tikls500_sauzeme")
st_write(tikls1000,"./vector_grids.gpkg",layer="tikls1km_sauzeme")
st_write(centri100,"./vector_grids.gpkg",layer="pts100_sauzeme")
st_write(centri300,"./vector_grids.gpkg",layer="pts300_sauzeme")
st_write(centri500,"./vector_grids.gpkg",layer="pts500_sauzeme")
st_write(centri1000,"./vector_grids.gpkg",layer="pts1000_sauzeme")
st_write(tks50km,"./vector_grids.gpkg",layer="tks93_50km")