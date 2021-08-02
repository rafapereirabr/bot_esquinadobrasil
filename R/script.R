library(sf)
library(geobr)
library(ggplot2)
library(data.table)
library(gdalio) ## remotes::install_github("hypertidy/gdalio")

library(twitteR)
library(rtweet)

###### 1. Download census tract sf data -------------------------
ct <- read_census_tract(code_tract = 'all', simplified = TRUE, year=2010)

ct_largetst <- subset(ct, area == max(ct$area)) # 150530405000051
ct_smallest <- subset(ct, area == min(ct$area)) # 210060005000047 






# select a census tract
all_tracts <- data.table::fread( './input/code_tract_all.csv')
temp_code_tract <- sample(all_tracts$code_tract, 1, replace = FALSE, prob = NULL)
ct1 <- subset(ct, code_tract == temp_code_tract) 
# ct1 <- subset(ct, code_tract == 330340105000173) # 210060005000047 




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
# my_mask <- mask(my_crop, vect(ct1))


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


ggsave(temp_plot, filename = './plot/temp_tract10.png', dpi=200)





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
  
  # Create Tweet post 
  tweet_text <- paste0('Municipio de ', name_muni, '. Setor censitário n. ', code_tract, '. Zona ', zone, '. Link Google maps: ', googlemaps_link) 

  # authenticate
  token <- rtweet::get_tokens()
  
  # Tweet !
  post_tweet( status = tweet_text,
              media = './plot/temp_tract2.png')
  
  # update blog post
  
  
  # github actions
  https://github.com/marketplace/actions/twitter-bot-action
  https://itnext.io/tweet-from-github-actions-e289de58988a
  
  
  https://www.rostrum.blog/2020/09/21/londonmapbot/
  https://twitter.com/londonmapbot
  
  
  https://enrico.spinielli.net/post/writing-a-twitter-bot-in-r/
    https://twitter.com/italiancomuni
  