# #> imagens resolucao baixa
# 
# #> imagens muito pequenas
# #>    problema: resolucao ruim
# #>    solucao: area ponderacao
# 
# 
# #> imagens muito grandes , 
# #>    problema: não faz crop do setor
# #>    solucao: ajustar zoom
# 
# 
# 
# ### this script prepares the data used in the bot
# 
# library(geobr)
# library(data.table)
# 
# 
# 
# # download all census tracts
# cts <- geobr::read_census_tract(code_tract = 'all', year=2010, simplified = F)
# # wta <- geobr::read_weighting_area(code_weighting = 'all', year=2010, simplified = F)
# 
# # prep Population estimates
# # pop <- fread('R:/Dropbox/COVID19_Brazil_working_group/COVARIATES/census_tracts/census_tracts2010_brazil.csv')
# pop <- fread('https://github.com/rafapereirabr/todos_setores/releases/download/v0.1.0/census_tracts2010_brazil.csv')
# pop <- pop[, .(code_tract, pop_total)]
# pop[, code_tract := as.character(code_tract)]
# 
# # prep abbrev state info
# state <- geobr::read_state()
# state$geom <- NULL
# state <- state[, c('code_state', 'abbrev_state')]
# 
# # merge pop and abbrev state
# cts2 <- merge(cts, pop, by='code_tract', all.x=TRUE)
# cts2 <- merge(cts2, state, by='code_state', all.x=TRUE)
# 
# # filter populated census tracts ?
# 
# # subset columns
# class(cts2) <- c('sf', 'data.frame')
# cts2 <- cts2[, c('code_tract', 'zone', 'name_muni', 'abbrev_state', 'pop_total')]
# head(cts2)
# 
# 
# # create draw order of census tracts
# set.seed(42)
# cts2$seq <- sample(x = 1:nrow(cts2), size = nrow(cts2), replace = FALSE)
# 
# 
# # save table
# cts2$geometry <- NULL
# saveRDS(cts2, './input/table_census_tracts_2010.rds', compress = TRUE)
# 
# 
# # # fix eventual topoly errors
# # cts2 <- sf::st_make_valid(cts2)
# # 
# # 
# # # save census tracts
# # saveRDS(cts2, './input/census_tracts_2010.rds', compress = TRUE)
# # st_write(cts2, './input/census_tracts_2010.gpkg')
# # 
