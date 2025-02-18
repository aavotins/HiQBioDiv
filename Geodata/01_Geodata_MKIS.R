dir.create("./Geodata/MKIS")

# libs
if(!require(sf)) {install.packages("sf"); require(sf)}
if(!require(arrow)) {install.packages("arrow"); require(arrow)}
if(!require(sfarrow)) {install.packages("sfarrow"); require(sfarrow)}
if(!require(gdalUtilities)) {install.packages("gdalUtilities"); require(gdalUtilities)}
if(!require(httr)) {install.packages("httr"); require(httr)}
if(!require(tidyverse)) {install.packages("tidyverse"); require(tidyverse)}
if(!require(ows4R)) {install.packages("ows4R"); require(ows4R)}

# lejupielāde
wfs_bwk <- "https://lvmgeoserver.lvm.lv/geoserver/zmni/ows"
url <- parse_url(wfs_bwk)
url$query <- list(service = "wfs",
                  version = "2.0.0", # fakultatīvi
                  request = "GetCapabilities"
)
#vaicajums <- build_url(url)

bwk_client <- WFSClient$new(wfs_bwk, 
                            serviceVersion = "2.0.0")
#bwk_client$getFeatureTypes() %>%
#  map_chr(function(x){x$getTitle()})

#bwk_client$getFeatureTypes() %>%
#  map_chr(function(x){x$getName()})

bwk_client$getFeatureTypes(pretty = TRUE)
#                              name                           title
#1                    zmni:zmni_dam                   Aizsargdambji
#2           zmni:zmni_watercourses             Dabiskās ūdensteces
#3              zmni:zmni_dampicket                   Dambju piketi
#4             zmni:zmni_drainpipes                          Drenas
#5        zmni:zmni_draincollectors                 Drenu kolektori
#6      zmni:zmni_networkstructures            Drenāžas tīkla būves
#7                zmni:zmni_ditches                          Grāvji
#8              zmni:zmni_hydropost          Hidrometriskie posteņi
#9     zmni:zmni_bigdraincollectors        Liela diametra kolektori
#10    zmni:zmni_stateriverspickets                          Piketi
#11  zmni:zmni_polderpumpingstation          Polderu sūknu stacijas
#12       zmni:zmni_polderterritory             Polderu teritorijas
#13             zmni:zmni_catchment                 Sateces baseini
#14      zmni:zmni_connectionpoints                     Savienojumi
#15 zmni:zmni_statecontrolledrivers     Valsts nozīmes ūdensnotekas
#16            zmni:zmni_zmniregion                    ZMNI reģions
#17     zmni:zmni_waterdrainditches      Ūdensnotekas (novadgrāvji)
#18           zmni:zmni_ditchpicket    Ūdensnoteku un grāvju piketi
#19       zmni:zmni_stateriversline                  Ūdensteču asis
#20    zmni:zmni_stateriverspolygon Ūdensteču ūdens virsmas laukumi


aizsargdambji <- wfs_bwk %>% 
  parse_url() %>% 
  list_merge(query = list(service = "wfs",
                          request = "GetFeature",
                          typeName = "zmni:zmni_dam",
                          srsName = "EPSG:3059")) %>% 
  build_url() %>% 
  read_sf(crs = 3059)
aizsargdambji2 = aizsargdambji[!st_is_empty(aizsargdambji),,drop=FALSE] # OK
aizsargdambji2=st_cast(aizsargdambji2,"MULTILINESTRING")
table(st_is_valid(aizsargdambji2)) # OK
sf::st_write(aizsargdambji2, "./Geodata/MKIS/MKIS_aizsargdambji.gpkg")
rm(aizsargdambji)
rm(aizsargdambji2)


