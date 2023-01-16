https://gist.github.com/rafapereirabr/ec950cda051e9c37aba3f1f36e720af7


library(gdalio)
library(sf)
library(furrr)
library(future)
library(progressr)
library(pbapply)
options(scipen = 999)


# read census tracts
cts <- st_read('R:/Dropbox/git/bot_esquinadobrasil/input/census_tracts_2010.gpkg')

# cts <- subset(cts, pop_total > 0)

set.seed(41)
index <- sample.int(nrow(cts), 1000)




fff <- function(i){ # i = index[50]    i = 30518
  
  # select census tract
  temp_ct <- cts[i,]
  # plot(temp_ct)
  # mapview::mapview(temp_ct)
  
  
  # fix eventual topoly errors
  temp_ct <- sf::st_make_valid(temp_ct)
  
  
  ## {terra}
  gdalio_terra <- function(dsn, ..., band_output_type = "numeric") {
    v <- gdalio_data(dsn, ..., band_output_type  = band_output_type)
    g <- gdalio_get_default_grid()
    r <- terra::rast(terra::ext(g$extent), nrows = g$dimension[2], ncols = g$dimension[1], crs = g$projection)
    if (length(v) > 1) terra::nlyr(r) <- length(v)
    terra::setValues(r, do.call(cbind, v))
  }
  
  virtualearth_imagery <- '<GDAL_WMS>
  <Service name="VirtualEarth">
    <ServerUrl>http://a${server_num}.ortho.tiles.virtualearth.net/tiles/a${quadkey}.jpeg?g=90</ServerUrl>
  </Service>
  <MaxConnections>4</MaxConnections>
  <Cache/>
</GDAL_WMS>'
  
  ### calculate area extension
  # centroid coordinates
  coords <- st_centroid(temp_ct) |> st_coordinates()
  
  prj <- paste0("+proj=laea +lon_0=", coords[1], " +lat_0=", coords[2])
  temp_ct_prj <- sf::st_transform(temp_ct, prj)
  
  # bounding box
  ext <- sf::st_bbox(temp_ct_prj)[c(1, 3, 2, 4)]
  
  ### pick dimensions (resolution)
  ct_area <- sf::st_area(temp_ct_prj) |> as.numeric()
  dim <- ifelse(ct_area > 5000000, 5000, 9000)
  
  dim2 <-  as.integer(diff(ext)[c(1, 3)]) / *2
  
  
  ### prepare grid query
  grid1 <- list(extent = ext,
                dimension = dim2, # dim2, # c(dim, dim),
                projection = prj)
  
  gdalio_set_default_grid(grid1)
  
  img <- gdalio_terra(virtualearth_imagery, bands = 1:3)
  # terra::plotRGB(img)
  gc()
  
  ### mask and crop
  
  # mask raster with census tract
  temp_plot <- terra::mask(img, temp_ct_prj)
  
  rm(img)
  gc()
  
  # crop with buffer of 50 meters
  buff <- sf::st_buffer(temp_ct_prj, dist = 50)
  temp_plot <- terra::crop(temp_plot, buff)
  # terra::plotRGB(temp_plot)
  
  # image proportions
  r <- nrow(temp_plot) /ncol(temp_plot)
  
  # save image max(nrow(temp_plot), ncol(temp_plot))
  png(paste0('59_small_dim_dim_.png'), res = 300,
      width = 15,  height = 15*r, units = 'cm')
  terra::plotRGB(temp_plot)
  dev.off()
  
}

# pbapply::pblapply(X=index , FUN = fff)




future::plan(strategy = 'multisession', workers = 3)

furrr::future_map(.x = index, .f =fff, .progress = T)


# close multisession
plan(sequential)

gc()



