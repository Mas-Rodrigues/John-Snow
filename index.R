# JOHN SNOW & THE CHOLERA EPIDEMIC IN MID-19TH CENTURY LONDON -------------
# John Snow history: "https://pt.wikipedia.org/wiki/John_Snow"

# DATA --------------------------------------------------------------------
url <- "https://geodacenter.github.io/data-and-lab/data/snow.zip"
dest <- "data/raw"

if (!dir.exists(dest)) dir.create(dest, recursive = TRUE)

file_zip <- file.path(dest, "snow.zip")

if (!file.exists(file_zip)) {
    download.file(url = url, destfile = file_zip, mode = "wb")
}
unzip(zipfile = file_zip, exdir = dest)

pumps <- sf::st_read(file.path(dest, "snow6/pumps.geojson")) |> 
    sf::st_transform(crs = 4326)

dbh <- sf::st_read(file.path(dest, "snow1/deaths_nd_by_house.geojson")) |> 
    sf::st_transform(crs = 4326)

# KDE --------------------------------------------------------------------
dbh_kde <- dbh |> 
    sf::st_transform("EPSG:27700") |> 
    sfhotspot::hotspot_kde(
        bandwidth_adjust = 0.5,
        weights = deaths,
        grid_type = "hex"
    ) |> 
    dplyr::filter(n > 0) |> 
    sf::st_transform("EPSG:4326")

# PLOT --------------------------------------------------------------------
# palette
pal <- leaflet::colorNumeric(
    palette = "viridis",
    domain = dbh_kde$kde
)

# map
leaflet::leaflet() |> 
    leaflet::addProviderTiles("CartoDB.DarkMatter") |> 
    leaflet::addPolygons(
        data = dbh_kde,
        fillColor = ~pal(kde),
        fillOpacity = 0.7,
        color = NA,
        smoothFactor = 0.5,
        label = ~paste0(sum, " morte(s) nesta célula"),
        popup = ~paste0(
            "<strong>Estatísticas do Hexágono:</strong><br/>",
            "• <strong>Mortes no local (sum):</strong> ", sum, "<br/>",
            "• <strong>Endereços afetados (n):</strong> ", n, "<br/>",
            "• <strong>Valor KDE (Densidade):</strong> ", round(kde, 2)
        ),
        group = "Densidade de casos"
    ) |>
    leaflet::addCircleMarkers(
        data = pumps$geometry,
        radius = 5,
        stroke = FALSE,
        color = "white",
        opacity = 0.9,
        fillOpacity = 0.8,
        popup = pumps$name,
        group = "Bombas"
    ) |>
    leaflet::addLayersControl(
        overlayGroups = c("Densidade de casos", "Bombas"),
        options = leaflet::layersControlOptions(collapsed = FALSE)
    ) |>
    leaflet::addScaleBar(position = "bottomleft") |>
    leaflet::addLegend(
        pal = pal,
        values = dbh_kde$kde,
        position = "bottomright",
        title = "Densidade de casos"
    )
