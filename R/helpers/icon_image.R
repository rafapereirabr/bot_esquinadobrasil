# ### this script ...
# 
# library(sf)
# library(terra)
# library(gdalio)
# library(rtweet)
# 
# 
# 
# 
# 
# ###### 2. Select area --------------------------------
# 
# 
# coords <- c(-59.96895647475754, -3.08358068688112) # manaus
# centroid <- st_point(coords) |> st_sfc(crs = 4674)
# 
#  
# # # -21.129280432171427, -47.995771712675754 ### praça
# # coords <- c(-38.443445, -12.930045) ### salvador
# # coords <- c(-46.730579175981866, -23.614641038575126) ### paraisopolis - SP
# # centroid <- st_point(coords) |> st_sfc(crs = 4674)
# # 
# # # mapview::mapview(centroid)
# 
# 
# radius <- 500 # meters
# centroid_utm <- st_transform(centroid, crs = 3857)
# buff <- st_buffer(centroid_utm, dist = radius)
# buff <- st_transform(buff, crs = 4674)
# plot(buff)
# # mapview::mapview(centroid) + buff
# 
# 
# ###### 2. image --------------------------------
# 
# # magick begins
# virtualearth_imagery <- tempfile(fileext = ".xml")
# 
# writeLines('<GDAL_WMS>
#   <Service name="VirtualEarth">
#     <ServerUrl>http://a${server_num}.ortho.tiles.virtualearth.net/tiles/a${quadkey}.jpeg?g=90</ServerUrl>
#   </Service>
#   <MaxConnections>4</MaxConnections>
#   <Cache/>
# </GDAL_WMS>', virtualearth_imagery)
# 
# 
# 
# 
# ## {terra}
# gdalio_terra <- function(dsn, ..., band_output_type = "numeric") {
#   v <- gdalio_data(dsn, ..., band_output_type  = band_output_type)
#   g <- gdalio_get_default_grid()
#   r <- terra::rast(terra::ext(g$extent), nrows = g$dimension[2], ncols = g$dimension[1], crs = g$projection)
#   if (length(v) > 1) terra::nlyr(r) <- length(v)
#   terra::setValues(r, do.call(cbind, v))
# }
# 
# 
# ### calculate area extension
# 
# 
# dim <- 12000
# ext <- 2000
# 
# 
# my_zoom <- paste0("+proj=laea +lon_0=", coords[1], " +lat_0=", coords[2])
# 
# 
# ### prepare grid query
# grid1 <- list(extent = c(-1, 1, -1, 1) * ext,
#               dimension = c(dim, dim),
#               projection = my_zoom)
# 
# gdalio_set_default_grid(grid1)
# 
# img <- gdalio_terra(virtualearth_imagery, bands = 1:3)
# # terra::plotRGB(img)
# 
# gc()
# 
# ### mask and crop
# 
# # reproject census tract
# buff2 <- st_transform(buff, crs= st_crs(img))
# buff2 <- st_sf(buff2)
# gc()
# 
# # mask raster with census tract
# temp_plot <- terra::mask(img, buff2)
# 
# gc()
# 
# # crop with buffer of 80 meters
# buff3 <- sf::st_buffer(buff2, dist = 50)
# temp_plot <- terra::crop(temp_plot, buff3)
# # terra::plotRGB(temp_plot)
# 
# # image proportions
# r <- nrow(temp_plot) /ncol(temp_plot)
# 
# # save image max(nrow(temp_plot), ncol(temp_plot))
# png('./images/icon0300_08.png', res = 300,
#     width = 8,  height = 8, units = 'cm')
# terra::plotRGB(temp_plot)
# dev.off()
# 
# 
