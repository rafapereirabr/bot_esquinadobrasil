library(sf)
library(geobr)
library(ggplot2)
library(gdalio) ## remotes::install_github("hypertidy/gdalio")

library(twitteR)
library(rtweet)

###### 1. Download census tract data -------------------------
ct <- read_census_tract(code_tract = 'all', simplified = FALSE, year=2010)
ct <- sf::st_make_valid(ct)
ct$area <- st_area(ct)
head(ct)

ct_largetst <- subset(ct, area == max(ct$area)) # 150530405000051
ct_smallest <- subset(ct, area == min(ct$area)) # 210060005000047 






# select a census tract
ct1 <- ct[1000,]
ct1 <- ct_largetst

# get extent and projection
projection <- sf::st_crs(ct1)$wkt
extent <- st_bbox(ct1)[c("xmin", "xmax", "ymin", "ymax")]



###### 2. Download imagery data -------------------------

## an imagery data source
#rawf_osm <- "https://raw.githubusercontent.com/hypertidy/gdalwebsrv/master/inst/gdalwmsxml/frmt_wms_openstreetmap_tms.xml"
rawf_ve <- "https://raw.githubusercontent.com/hypertidy/gdalwebsrv/master/inst/gdalwmsxml/frmt_wms_virtualearth.xml"
download.file(rawf_ve, tfile <- tempfile(fileext = ".xml"), mode = "wb")

###### 3. Prepare raster -------------------------

gdalio::gdalio_set_default_grid(list(extent = extent, 
                             dimension = dev.size("px") * 3, 
                             projection = projection))

#' we use geom_sf and coord_sf to set up the projection, 
#' and then throw our long lats and our raster source at it
myraster <- gdalio_graphics(tfile, resample = "cubic")

# crop and mask
# my_crop <- raster::crop(myraster, vect(ct1))
# my_mask <- terra::mask(my_crop, vect(ct1))


###### 4. Generate plot --------------------------------
temp_plot <- ggplot() +
              geom_sf() + 
              coord_sf(default_crs = projection) + 
              annotation_raster(myraster, 
                                xmin = extent["xmin"], xmax = extent["xmax"], ymin = extent["ymin"], ymax = extent["ymax"]) +
              geom_sf(data = ct1, fill = "transparent", colour = "#feb845") + 
              xlim(extent[1:2]) + ylim(extent[3:4]) + 
              guides(col = "none") +
              theme_void()


ggsave(temp_plot, filename = './plot/temp_tract2.png', dpi=200)





###### 5. Prepare tweet text --------------------------------

# Google maps link
  #' check https://stackoverflow.com/questions/2660201/what-parameters-should-i-use-in-a-google-maps-url-to-go-to-a-lat-lon
  centroid <- st_centroid(ct1)
  coords <- st_coordinates(centroid)
  googlemaps_link <- paste0('https://www.google.com/maps/search/?api=1&query=',coords[2],',',coords[1])

  # prepare tweet text
  name_muni <- ct1$name_muni
  code_tract <- ct1$code_tract
  zone <- tolower(ct1$zone)
  
  # Tweet
  tweet_text <- paste0('Municipio de ', name_muni, '. Setor censitário n. ', code_tract, '. Zona ', zone, '. Link Google maps: ', googlemaps_link) 

  
  token <- rtweet::get_tokens()
  
# post Tweet
# update blog post


  post_tweet( status = tweet_text,
              media = './plot/temp_tract2.png')
  
  