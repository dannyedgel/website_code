###
### This file pulls and maps tract-level vacant homes data
###
### Date created:  23 Jan 2022
### Last modified: 23 Jan 2022
### Author: Danny Edgel
###

###
###   Housekeeping
###___________________________________________________

### install packages, if necessary
use.pkgs <- c("dplys", "tidycensus", "leaflet", "tigris", 'datasets', 
              'ggplot2', 'scales')
for ( x in use.pkgs ){
  pkgs <- setdiff(use.pkgs,.packages(all=T))
  if (length(pkgs)>0){install.packages(x,
                                       repos = "http://cran.us.r-project.org")}
}
remotes::install_github("hrbrmstr/albersusa")

### clear workspace
rm(list = ls())

### establish directory
setwd('C:/Users/edgel/Google Drive/100 Beers/vacant_homes')

### load packages
library(tidycensus)
library(dplyr)
library(ggplot2)
library(tigris)
library(albersusa)
#library(leaflet)

### set Census api key
key <- '4b24646e184003d35b4f815066372760da7fe2d4'
census_api_key(key)

###_________________________________________________________________________________


###
###   Define variable query
###___________________________________________________



vars <- c( 'B01001_001E', # Total population
           'B25001_001E',  # Total housing units
           'B25004_008E'  # Total 'other' vacant housing units
)



###______________________________________________________________________________


###
###   Pull and combine needed data
###_________________________________________________________


# selected variables for counties in 2015-2019
county.df <- get_acs( 'county',
                      variables = vars, 
                      output    = 'wide',
                      survey    = 'acs5',
                      year      = 2019 )


# loop through counties, pulling tract variables and shapefiles
county.df <- county.df %>% arrange(desc(B01001_001E))
subsample <- county.df[1:150, ]
dat.list        <- vector(mode = 'list', length = length(subsample$GEOID) + 1)
names(dat.list) <- c('All Counties', subsample$NAME)
i <- 2
for (x in subsample$GEOID){
  tr <- tigris::tracts(state  = substr(x, 1, 2),
                       county = substr(x, 3, 5),
                       year   = 2019)
  df <- get_acs('tract',
                state     = substr(x, 1, 2),
                county    = substr(x, 3, 5),
                variables = vars,
                year      = 2019,
                output    = 'wide',
                survey    = 'acs5')
  
  df$county.fips <- x
  
  dat.list[[i]] <- merge(tr, df, by = 'GEOID')
  i <- i + 1
}

# pull county shapefile
county.sf <- counties_sf()

dat.list[[1]] <- merge(county.sf, county.df, by.x = 'fips', by.y = 'GEOID')

###______________________________________________________________________________

save(list = c('dat.list'), file = 'code/vacant_homes/objects.RData')


###
###   Map vacant homes
###_________________________________________________________

shiny::runApp('code/vacant_homes')
rsconnect::deployApp('code/vacant_homes', account = 'edgeldan')

###_____________________________________________________________________________
