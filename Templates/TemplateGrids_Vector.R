# libs ----
library(arrow)
library(tidyverse)
library(sf)
library(sfarrow)


# inputs ----

# administrative borders
## 
admin=read_sf("./Templates/TemplateGrids/administrativas_teritorijas_2021/Administrativas_teritorijas_2021.shp")
ggplot(admin)+geom_sf()

# 100 m grid
##

# 1000 m grid
##


# 100 m ----
tikls100=st_read_parquet("./Templates/TemplateGrids/tikls100_sauzeme.parquet")
tikls100_2=tikls100[admin,,]

ggplot(tikls100)+geom_sf()+labs(title="100 m")



# 1000 m ----
tikls1000=st_read_parquet("./Templates/TemplateGrids/tikls1k_sauzeme.parquet")
ggplot(tikls1000)+geom_sf()+labs(title="1000 m")

tikls1000$ID1km=tikls1000$ID
punkti=st_read_parquet("./Templates/TemplateGridPoints/pts100_sauzeme.parquet")
savienots=st_join(punkti,tikls1000[,"ID1km"])
st_write_parquet(savienots,"./Templates/TemplateGridPoints/pts100_sauzeme.parquet")

pievienosanai=data.frame(savienots) %>% 
  dplyr::select(id,ID1km)
tikls100=tikls100 %>% 
  left_join(pievienosanai,by="id")
st_write_parquet(tikls100,"./Templates/TemplateGrids/tikls100_sauzeme.parquet")


# 300 m ----

tikls300=st_make_grid(tikls100,cellsize=c(300,300))
plot(tikls300)
tikls300_LV=tikls300[tikls100,,]
tikls300_LV=st_as_sf(tikls300_LV)
ggplot(tikls300_LV)+geom_sf()
tikls300_LV$rinda300=rownames(tikls300_LV)
st_write_parquet(tikls300_LV,"./Templates/TemplateGrids/tikls300_sauzeme.parquet")
rm(tikls300)

tikls300_LV=st_read_parquet("./Templates/TemplateGrids/tikls300_sauzeme.parquet")
centri300=st_centroid(tikls300_LV)
centri300$X=st_coordinates(centri300)[,1]
centri300$Y=st_coordinates(centri300)[,2]
st_write_parquet(centri300,"./Templates/TemplateGridPoints/pts300_sauzeme.parquet")

punkti=st_read_parquet("./Templates/TemplateGridPoints/pts100_sauzeme.parquet")
savienots=st_join(punkti,tikls300_LV)
st_write_parquet(savienots,"./Templates/TemplateGridPoints/pts100_sauzeme.parquet")

pievienosanai=data.frame(savienots) %>% 
  dplyr::select(id,rinda300)
tikls100=tikls100 %>% 
  left_join(pievienosanai,by="id")
st_write_parquet(tikls100,"./Templates/TemplateGrids/tikls100_sauzeme.parquet")

rm(tikls300_LV)
rm(centri300)
rm(pievienosanai)
rm(admin)
rm(savienots)

# 500 m ----
tikls500=st_make_grid(t100_apvienots,cellsize = 500,crs=3059)
st_bbox(tikls500)
t500=st_as_sf(tikls500)
t500$rinda500=rownames(t500)
tikls500_2=tikls500[admin,,]
sfarrow::st_write_parquet(t500,"./tikls500_sauzeme.parquet")


tikls500=st_read_parquet("./Templates/TemplateGrids/tikls500_sauzeme.parquet")
ggplot(tikls500)+geom_sf()


tikls500$rinda500=tikls500$rinda500
st_write_parquet(tikls500,"./Templates/TemplateGrids/tikls500_sauzeme.parquet")

centri500=st_centroid(tikls500)
centri500$X=st_coordinates(centri500)[,1]
centri500$Y=st_coordinates(centri500)[,2]
st_write_parquet(centri500,"./Templates/TemplateGridPoints/pts500_sauzeme.parquet")
savienots=st_join(centri500,tks50km)
savienots=savienots %>% 
  mutate(tks50km=NUMURS) %>% 
  dplyr::select(rinda500,X,Y,tks50km)
st_write_parquet(savienots,"./Templates/TemplateGridPoints/pts500_sauzeme.parquet")
pievienosanai=data.frame(savienots) %>% 
  dplyr::select(rinda500,tks50km)
tikls500=tikls500 %>% 
  left_join(pievienosanai,by="rinda500")
st_write_parquet(tikls500,"./Templates/TemplateGrids/tikls500_sauzeme.parquet")




savienots=st_join(punkti,tikls500)
st_write_parquet(savienots,"./Templates/TemplateGridPoints/pts100_sauzeme.parquet")

pievienosanai=data.frame(savienots) %>% 
  dplyr::select(id,rinda500)
tikls100=tikls100 %>% 
  left_join(pievienosanai,by="id")
st_write_parquet(tikls100,"./Templates/TemplateGrids/tikls100_sauzeme.parquet")

# TKS 50 km karšu lapas ----

tikls100=st_read_parquet("./Templates/TemplateGrids/tikls100_sauzeme.parquet")
tikls1000=st_read_parquet("./Templates/TemplateGrids/tikls1k_sauzeme.parquet")
st_layers("../../../../GIS/GIS_Latvija10.2/GIS_Latvija10.2/GIS_Latvija10.2.gdb/")
tks50km=st_read("../../../../GIS/GIS_Latvija10.2/GIS_Latvija10.2/GIS_Latvija10.2.gdb/",layer="satelitkarte_tks93_50000")
ggplot(tks50km)+geom_sf()+labs(title="satelitkarte_tks93_50000")


tikls100$tks50km=NA
tikls1000$tks50km=NA

max(table(tks50km$NUMURS,useNA="always"))
numuri=levels(factor(tks50km$NUMURS))

for(i in 1:length(numuri)){
  print(i)
  sakums=Sys.time()
  numurs=numuri[i]
  lapa=tks50km %>% filter(NUMURS == numurs)
  
  mazais=tikls100[lapa,,]
  tikls100$tks50km=ifelse(tikls100$id %in% mazais$id,numurs,tikls100$tks50km)

  lielais=tikls1000[lapa,,]
  tikls1000$tks50km=ifelse(tikls1000$ID %in% lielais$ID,numurs,tikls1000$tks50km)
  
  beigas=Sys.time()
  ilgums=beigas-sakums
  print(ilgums)
}
table(tikls100$tks50km,useNA="always")
table(tikls1000$tks50km,useNA="always")

skaits100=data.frame(tikls100) %>% 
  group_by(id) %>% 
  summarize(skaits=n())
max(skaits100$skaits)

skaits1000=data.frame(tikls1000) %>% 
  group_by(ID) %>% 
  summarize(skaits=n())
max(skaits1000$skaits)


st_write_parquet(tikls100,"./Templates/TemplateGrids/tikls100_sauzeme.parquet")
st_write_parquet(tikls1000,"./Templates/TemplateGrids/tikls1k_sauzeme.parquet")

#ggplot()+
#  geom_sf(data=tks50km)+
#  geom_sf(data=lapa,col="red")

centri300=st_join(centri300,tks50km)
centri300b=centri300 %>% 
  mutate(tks50km=NUMURS) %>% 
  dplyr::select(rinda300,X,Y,tks50km)
st_write_parquet(centri300b,"./Templates/TemplateGridPoints/pts300_sauzeme.parquet")

for(i in 1:length(numuri)){
  numurs=numuri[i]
  lapa=centri300b %>% filter(tks50km==numurs)
  buferi=st_buffer(lapa,dist=3000)
  st_write_parquet(buferi,paste0("./Templates/TemplateGridPoints/lapas/pts300_r3000_",numurs,".parquet"))
}



centri1km=st_centroid(tikls1000)
for(i in 1:length(numuri)){
  numurs=numuri[i]
  lapa=centri1km %>% filter(tks50km==numurs)
  buferi=st_buffer(lapa,dist=10000)
  st_write_parquet(buferi,paste0("./Templates/TemplateGridPoints/lapas/pts1km_r10000_",numurs,".parquet"))
}

tikls100=st_read_parquet("./Templates/TemplateGrids/tikls100_sauzeme.parquet")
numuri=levels(factor(tikls100$tks50km))
for(i in 1:length(numuri)){
  numurs=numuri[i]
  lapa=tikls100 %>% filter(tks50km==numurs)
  st_write_parquet(lapa,paste0("./Templates/TemplateGrids/lapas/tikls100_",numurs,".parquet"))
}

