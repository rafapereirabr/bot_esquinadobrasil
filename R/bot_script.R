library(sf)
library(terra)
library(rtweet)
library(remotes)
# remotes::install_github("hypertidy/gdalio")
library(gdalio)


###### 0. Authenticate Tweeter API --------------------------------

# api keys
api_key <- Sys.getenv("TWITTER_CONSUMER_KEY")
api_secret <- Sys.getenv("TWITTER_CONSUMER_SECRET")
access_token  <- Sys.getenv("TWITTER_ACCESS_TOKEN")
access_secret <- Sys.getenv("TWITTER_ACCESS_TOKEN_SECRET")


# Authenticate
auth <- rtweet::rtweet_bot(api_key = api_key,
                           api_secret = api_secret,
                           access_token = access_token,
                           access_secret = access_secret)


rtweet::auth_as(auth)

message("passed twitter Authentication")




###### 1. determine tweet number sequence --------------------------------

# # via the order of the last tweet
# last_tweet <- rtweet::get_timeline(user = 'esquinadobrasil', 
#                                    n= 1, 
#                                    parse = F 
#                                   , token = auth
#                                    )
# 
# # find number position of the last tweet
# temp_df <- as.data.frame(last_tweet)
# pos <- temp_df$user$statuses_count
# 
# 
# # start next tweet :)
# pos <- ifelse(is.null(pos), 0, pos)
# i <- pos + 1
# message(i)


# via the last string in the last tweet
last_tweet <- rtweet::get_timeline(user = 'esquinadobrasil', 
                                   n= 1, 
                                   parse = T 
                                   , token = auth
                                   )

# get text
text <- last_tweet$full_text

# remove last link
text <- substr(text,1,nchar(text)-24)

# get last word
pos <- sub('^.* ([[:alnum:]]+)$', '\\1', text)
i <- as.numeric(pos) + 1
message(i)


## via alt text of image
# 
# # parsing the tweet data
# last_tweet_parsed <- rtweet::get_timeline(user = 'esquinadobrasil',
#                                           n = 1,
#                                           parse = T
#                                           )
# last_tweet_parsed$text
# 
# # getting the media_alt_text
# entities <- last_tweet_parsed$entities
# 
# entities[[1]]$media$ext_alt_text
# #>[1] NA
# 
# 
# 
# last_tweet <- rtweet::get_timeline(user = 'esquinadobrasil', 
#                                    n= 1, 
#                                    parse = F
#                                    )
# 
# last_tweet[[1]][[1]]$entities$media

###### 2. Get census tract data --------------------------------
message("Downloading census tract data")


# # read local data
# temp_ct <- read_sf('./input/census_tracts_2010.gpkg',
#                query = paste0('SELECT * FROM census_tracts_2010 WHERE seq = ',i))

# read local table data with all census tracts
all_cts <- readRDS('./input/table_census_tracts_2010.rds')

# subset census tract
temp_ct_table <- subset(all_cts, seq == i)
# temp_ct_table <- subset(all_cts, code_tract == 355030877000160)

# download census tract geometry data from geobr repo
  code_trct <- temp_ct_table$code_tract
  code_state <- substring(temp_ct_table$code_tract, 1, 2)
  
  ct_file <- paste0("https://github.com/ipeaGIT/geobr/releases/download/v1.7.0/", code_state, "census_tract_2010.gpkg")
  
  # read census tract
  temp_ct <- read_sf(ct_file,
                     query = paste0("SELECT * FROM '",code_state,"' WHERE code_tract = ", code_trct))

  
  
  
# fix eventual topoly errors
temp_ct <- sf::st_make_valid(temp_ct)
# plot(temp_ct)

# calculate area in Km2
area <- sf::st_area(temp_ct)
areakm <- as.numeric(area)  / 1e6
areakm_round2 <- round(areakm, 2)
area <- ifelse(areakm_round2 != 0, areakm_round2, round(areakm, 3))

gc()
###### 3. Prepare tweet --------------------------------
message("Preparing tweet")

# Google maps link
  centroid <- sf::st_centroid(temp_ct)
  coords <- sf::st_coordinates(centroid)
  coords <- round(coords, 4)
  
  ## https://stackoverflow.com/questions/47038116/google-maps-url-with-pushpin-and-satellite-basemap
  # googlemaps_link <- paste0('https://www.google.com/maps/search/?api=1&query=',coords[2],',',coords[1])
  googlemaps_link <- paste0("http://maps.google.com/maps?t=k&q=loc:",coords[2],"+",coords[1])
  # browseURL(googlemaps_link)
  
  
  
# prepare tweet text
  code_tract <- temp_ct$code_tract
  name_muni <- temp_ct$name_muni
  abbrev_state <- temp_ct_table$abbrev_state
  pop_total <- ifelse(is.na(temp_ct_table$pop_total), 0, temp_ct_table$pop_total)
  bairro <- temp_ct$name_neighborhood
  zone <- tolower(temp_ct_table$zone)
  zone <- ifelse(zone=='urbano', 'urbana', 'rural')
  
  # densidade
  densidade <- pop_total / areakm
  densidade_round2 <- round(densidade, 2)

    
  tweet_text <- paste0('Municipio: ', name_muni, ' - ',abbrev_state,
                       '\nSetor censitário: ', code_tract,
                       '\nPopulação: ', pop_total,
                       '\nÁrea (Km2): ', area,
                       '\nDensidade (hab/Km2): ', densidade_round2, 
                       '\nZona: ', zone, 
                       '\n\U1F5FA ', googlemaps_link, ' ', i)
  
  if (!is.na(bairro)) {
    tweet_text <- paste0('Municipio: ', name_muni, ' - ',abbrev_state,
                         '\nBairro: ', bairro,
                         '\nSetor censitário: ', code_tract,
                         '\nPopulação: ', pop_total,
                         '\nÁrea (Km2): ', area,
                         '\nDensidade (hab/Km2): ', densidade_round2, 
                         '\nZona: ', zone, 
                         '\n\U1F5FA ', googlemaps_link, ' ', i)
    }



###### 4. Prepare tweet image --------------------------------
message("Creating image plot")
  
  
# load function
source('./R/fun_save_image.R')

# save image to temp file
image_file <- save_image(temp_ct, i)
# image_file <- gsub("\\\\", "/", image_file)
# browseURL(image_file)


gc()
###### 5. Post tweet --------------------------------
message("Posting tweet")

# post a tweet from R
rtweet::post_tweet(
  status = tweet_text,
  media = image_file,
  media_alt_text = paste('sort', i),
  lat = coords[2],
  lon = coords[1],
  display_coordinates = TRUE,
  token = auth
  )
