# JOHN SNOW & THE CHOLERA EPIDEMIC IN MID-19TH CENTURY LONDON -------------

# Sources:
# John Snow history: "https://pt.wikipedia.org/wiki/John_Snow"
# data: "https://geodacenter.github.io/data-and-lab/snow/"

# PACKAGES ----------------------------------------------------------------

library(tidyverse)
library(leaflet)
library(sfhotspot)

# DATA --------------------------------------------------------------------

# URL direct to "Snow" dataset ZIP
url <- "https://geodacenter.github.io/data-and-lab/data/snow.zip"
destino <- "data/raw"

# Create folder if it doesn't exist
if (!dir.exists(destino)) dir.create(destino, recursive = TRUE)

arquivo_zip <- file.path(destino, "snow.zip")

# Download zip file (binary "wb")
if (!file.exists(arquivo_zip)) {
  download.file(url = url, destfile = arquivo_zip, mode = "wb")
}

# unzip into 'data/raw'
unzip(zipfile = arquivo_zip, exdir = destino)

# Learning data 
pumps <- sf::st_read(file.path(destino, "snow6/pumps.geojson")) |> 
  sf::st_transform(crs = 4326)

subdistricts <- sf::st_read(file.path(destino, "snow8/subdistricts.geojson")) |> 
  sf::st_transform(crs = 4326)

dbh <- sf::st_read(file.path(destino, "snow1/deaths_nd_by_house.geojson")) |> 
  sf::st_transform(crs = 4326)

cd <- sf::st_read(file.path(destino, "snow5/deaths_by_8rings.geojson")) |> 
  sf::st_transform(crs = 4326)

# total deaths (residents and non-residents)
cd |> 
  sf::st_drop_geometry() |> 
  dplyr::summarise(sum(deaths))

# mean distance at water pump
dbh |> 
  sf::st_drop_geometry() |> 
  dplyr::summarise(mean(dis_bspump))


# STAT --------------------------------------------------------------------

## correlation

# distance between pump and deaths
stats::cor(dbh$deaths, dbh$dis_bspump, method = "spearman")

# distance between pump and sewers
stats::cor(dbh$deaths, dbh$dis_sewers, method = "spearman")

# distance between pump and pestfields (former Craven Estate)
stats::cor(dbh$deaths, dbh$dis_pestf, method = "spearman")


# PLOT --------------------------------------------------------------------

# Graf of deaths and distance pump
dbh |> 
  #dplyr::select(deaths, dis_bspump) |> 
  dplyr::filter(deaths >= 1) |> 
  ggplot2::ggplot()+
  ggplot2::geom_point(ggplot2::aes(dis_bspump, deaths))

# Leaflet Map
Snow <-
  leaflet::leaflet() |> 
  leaflet::addTiles() |> 
  leaflet::addCircleMarkers(
    data = dbh$geometry,
    radius = dbh$deaths,
    stroke = FALSE,
    color = "red",
    weight = dbh$deaths,
    opacity = 0.9,
    fillOpacity = 0.8,
    popup = paste("Mortes: ", dbh$deaths, sep = "")
  ) |>  
  leaflet::addCircleMarkers(
    data = pumps$geometry,
    radius = 5,
    stroke = FALSE,
    color = "black",
    opacity = 0.9,
    fillOpacity = 0.8,
    popup = pumps$name
  )

Snow


# KERNEL DENSITY ----------------------------------------------------------

# Kernel Density
dbh_kde <- dbh |> 
  sf::st_transform("EPSG:27700") |> 
  sfhotspot::hotspot_kde(
    bandwidth_adjust = 0.5,
    weights = deaths,
    grid_type = "hex"
  ) |> 
  sf::st_transform("EPSG:4326")

# Map
ggplot2::ggplot()+
  #ggspatial::annotation_map_tile(type = "cartoligth", zoomin = 0)+
  ggplot2::geom_sf(
    ggplot2::aes(fill = kde),
    data = dbh_kde,
    alpha = 0.5,
    colour = NA
  )+
  ggplot2::geom_sf(
    data = pumps,
    size = 2.5,
    fill = "black"
  )+
  ggplot2::scale_fill_viridis_c()
