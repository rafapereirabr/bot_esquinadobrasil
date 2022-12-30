### this script ...

library(sf)
library(terra)
library(gdalio)
library(rtweet)




###### 0. Authenticate Tweeter API --------------------------------

client_id <- 'zzz'
client_secret <- 'zzz'

## api keys
api_key <- "zzz"
api_secret <- "zzz"

#tokens
access_token  <- 'zzz'
access_secret <- 'zzz'
bearer_token <- 'zzz'

# Authenticate
auth <- rtweet::rtweet_bot(api_key = api_key,
                           api_secret = api_secret,
                           access_token = access_token,
                           access_secret = access_secret
)

auth_as(auth)


###### 1. determine tweet number sequence --------------------------------

# get last tweet
last_tweet <- rtweet::get_my_timeline(n = 1, parse = F)

# find number positio of the last tweet
temp_df <- as.data.frame(last_tweet)
pos <- temp_df$user$statuses_count
i <- pos + 1


###### 2. Select census tracts --------------------------------

# # read local data
# temp_ct <- read_sf('./input/census_tracts_2010.gpkg',
#                query = paste0('SELECT * FROM census_tracts_2010 WHERE seq = ',i))

# read local table data with all census tracts
all_cts <- readRDS('./input/table_census_tracts_2010.rds')

# # all_cts <- readRDS('./input/census_tracts_2010.rds')
# all_cts$area <- st_area(all_cts)
# 
# # largest and smallest tracts
# subset(all_cts, area == max(all_cts$area))$code_tract
# # 150530405000051 /// 134241
# subset(all_cts, area == min(all_cts$area))$code_tract
# # 210060005000047 /// seq 305451

# subset census tract
temp_ct_table <- subset(all_cts, seq == i)

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




###### 3. Prepare tweet text --------------------------------

# Google maps link
#' check https://stackoverflow.com/questions/2660201/what-parameters-should-i-use-in-a-google-maps-url-to-go-to-a-lat-lon
centroid <- sf::st_centroid(temp_ct)
coords <- sf::st_coordinates(centroid)
coords <- round(coords, 4)
googlemaps_link <- paste0('https://www.google.com/maps/search/?api=1&query=',coords[2],',',coords[1])

# prepare tweet text
code_tract <- temp_ct$code_tract
name_muni <- temp_ct$name_muni
abbrev_state <- temp_ct_table$abbrev_state
pop_total <- temp_ct_table$pop_total
bairro <- temp_ct$name_neighborhood
zone <- tolower(temp_ct_table$zone)
zone <- ifelse(zone=='urbano', 'urbana', 'rural')

# prepare tweet text
tweet_text <- paste0('Municipio: ', name_muni, ' - ',abbrev_state,
                     '\nSetor censitário: ', code_tract,
                     '\nPopulação: ', pop_total,
                     '\nZona: ', zone,
                     '\n\U1F5FA ', googlemaps_link)

if (!is.na(bairro)) {
  tweet_text <- paste0('Municipio: ', name_muni, ' - ',abbrev_state,
                            '\nBairro: ', bairro,
                            '\nSetor censitário: ', code_tract,
                            '\nPopulação: ', pop_total,
                            '\nZona: ', zone,
                            '\n\U1F5FA ', googlemaps_link)
  }


###### 4. Prepare tweet image --------------------------------

source('./R/fun_save_image.R')

image_file <- save_image(temp_ct)



###### 5. Post tweet --------------------------------

# post a tweet from R
post_tweet(status = tweet_text,
           media = image_file,
           # media_alt_text = paste0(i),
           lat = coords[2],
           lon = coords[1],
           display_coordinates = TRUE
)


