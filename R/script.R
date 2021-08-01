library(sf)
library(geobr)
library(ggplot2)
library(gdalio) ## remotes::install_github("hypertidy/gdalio")


# download census tract data
ct <- read_census_tract(code_tract = 'all')
ct$area <- st_area(ct)
head(ct)

# select one census tract
ct1 <- ct[100,]

# get extent and projection
projection <- sf::st_crs(ct1)$wkt
extent <- st_bbox(ct1)[c("xmin", "xmax", "ymin", "ymax")]

## an imagery data source
rawf <- "https://raw.githubusercontent.com/hypertidy/gdalwebsrv/master/inst/gdalwmsxml/frmt_wms_virtualearth.xml"
download.file(rawf, tfile <- tempfile(fileext = ".xml"), mode = "wb")

gdalio::gdalio_set_default_grid(list(extent = extent, 
                             dimension = dev.size("px") * 3, 
                             projection = projection))

#' we use geom_sf and coord_sf to set up the projection, 
#' and then throw our longlats and our raster source at it
myraster <- gdalio_graphics(tfile, resample = "cubic")

# crop and mask
# my_crop <- raster::crop(myraster, vect(ct1))
# my_mask <- terra::mask(my_crop, vect(ct1))


###### generate plot --------------------------------
temp_plot <- ggplot() +
              geom_sf() + 
              coord_sf(default_crs = projection) + 
              annotation_raster(myraster, 
                                xmin = extent["xmin"], xmax = extent["xmax"], ymin = extent["ymin"], ymax = extent["ymax"]) +
              geom_sf(data = ct1, fill = "transparent", colour = "#feb845") + 
              xlim(extent[1:2]) + ylim(extent[3:4]) + 
              guides(col = "none") +
              theme_void()


ggsave(temp_plot, filename = 'a10.png', dpi=200)





###### Google maps link --------------------------------
#' check https://stackoverflow.com/questions/2660201/what-parameters-should-i-use-in-a-google-maps-url-to-go-to-a-lat-lon
centroid <- st_centroid(ct1)
coords <- st_coordinates(centroid)

googlemaps_link <- paste0('https://www.google.com/maps/search/?api=1&query=',coords[2],',',coords[1])
googlemaps_link



# prepare post text
 # population, state, municipality

# post Tweet
# update blog post


