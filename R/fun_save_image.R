# generate image


###### support fun --------------------------------


## {terra}
gdalio_terra <- function(dsn, ..., band_output_type = "numeric") {
  v <- gdalio_data(dsn, ..., band_output_type  = band_output_type)
  g <- gdalio_get_default_grid()
  r <- terra::rast(terra::ext(g$extent), nrows = g$dimension[2], ncols = g$dimension[1], crs = g$projection)
  if (length(v) > 1) terra::nlyr(r) <- length(v)
  terra::setValues(r, do.call(cbind, v))
}


# function to save image to local temp file and return file address
save_image <- function(temp_ct){


### magick begins
virtualearth_imagery <- tempfile(fileext = ".xml")

writeLines('<GDAL_WMS>
  <Service name="VirtualEarth">
    <ServerUrl>http://a${server_num}.ortho.tiles.virtualearth.net/tiles/a${quadkey}.jpeg?g=90</ServerUrl>
  </Service>
  <MaxConnections>4</MaxConnections>
  <Cache/>
</GDAL_WMS>', virtualearth_imagery)


### calculate area extension

  # bounding box
  bb <- sf::st_bbox(temp_ct)
  
  # width length
  point12 <- st_point(c(bb[1], bb[2])) |> st_sfc(crs = st_crs(temp_ct)) 
  point32 <- st_point(c(bb[3], bb[2])) |> st_sfc(crs = st_crs(temp_ct)) 
  x_dist <- st_distance(point12, point32) |> as.numeric()
  
  # height length
  point12 <- st_point(c(bb[1], bb[2])) |> st_sfc(crs = st_crs(temp_ct)) 
  point14 <- st_point(c(bb[1], bb[4])) |> st_sfc(crs = st_crs(temp_ct)) 
  y_dist <- st_distance(point12, point14) |> as.numeric()
  
  
### pick dimensions (resolution)
  ct_area <- sf::st_area(temp_ct) |> as.numeric()
  dim <- ifelse(ct_area > 5000000, 5000, 10000)
  
  ext <- (max(x_dist, y_dist) * 1.05) |> round()
  ext <- ifelse(ext < 2000, 2000, ext)
  # ext <- ifelse(ct_area > 5000000, 2e5, 2e3)
  
  # centroid coordinates
  coords <- st_centroid(temp_ct) |> st_coordinates()
  
  my_zoom <- paste0("+proj=laea +lon_0=", coords[1], " +lat_0=", coords[2])
  
  
### prepare grid query
  grid1 <- list(extent = c(-1, 1, -1, 1) * ext,
                dimension = c(dim, dim), 
                projection = my_zoom)
  
  gdalio_set_default_grid(grid1)
  
  img <- gdalio_terra(virtualearth_imagery, bands = 1:3)
  # terra::plotRGB(img)
  
### mask and crop

  # reproject census tract
  temp_ct2 <- st_transform(temp_ct, crs= st_crs(img))
  
  # mask raster with census tract
  temp_plot <- terra::mask(img, temp_ct2)
  
  # crop with buffer of 80 meters
  buff <- sf::st_buffer(temp_ct2, dist = 50)
  temp_plot <- terra::crop(temp_plot, buff)
  # terra::plotRGB(temp_plot)
  
  # image proportions
  r <- nrow(temp_plot) /ncol(temp_plot)
  
  # save image to tempfile
  tempd <- tempdir()
  image_file <- paste0(tempd, '/image.png')
  
  png(image_file, res = 500, width = 15, height = 15*r, units = 'cm') 
  raster::plotRGB(temp_plot)
  dev.off()
  
  return(image_file)
}
