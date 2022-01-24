###
### This file pulls national ACS data on vacant homes from 2005 to the latest
### (reliable) ACS
###
### Date created:  22 Jan 2022
### Last modified: 22 Jan 2022
### Author: Danny Edgel
###

###
###   Housekeeping
###___________________________________________________

### install packages, if necessary
use.pkgs <- c("dplys", "tidycensus")
for ( x in use.pkgs ){
  pkgs <- setdiff(use.pkgs,.packages(all=T))
  if (length(pkgs)>0){install.packages(x,
                                       repos = "http://cran.us.r-project.org")}
}


### clear workspace
rm(list = ls())

### establish directory
setwd('C:/Users/edgel/Google Drive/100 Beers/vacant_homes')

### load packages
library(tidycensus)
library(dplyr)


### set Census api key
key <- ''
census_api_key(key)

###_________________________________________________________________________________


###
###   Define variable query
###___________________________________________________



vars <- c( 'B01001_001E', # Total population
           'B25001_001E',  # Total housing units
           'B25002_002E',  # Total occupied housing units
           'B25002_003E',  # Total vacant housing units
           'B25003_001E',  # Total housing tenure
           'B25004_001E',  # Total vacant housing units
           'B25004_002E',  # Total for rent vacant housing units
           'B25004_003E',  # Total rented, unoccupied vacant housing units
           'B25004_004E',  # Total for sale housing units
           'B25004_005E',  # Total sold, not occupied housing units
           'B25004_006E',  # Total seasonal, recreational, or occasionally used
           'B25004_007E',  # Total migrant worker housing units
           'B25004_008E',  # Total 'other' vacant housing units
           'B25005_001E',  # Total vacant housing units 
           'B25005_002E',  # Total vacant housing units with residence elsewhere
           'B25005_003E'  # Total vacant housing units w/o residence elsewhere
           
)



###______________________________________________________________________________


###
###   Pull selected variables for all years - national
###_________________________________________________________

## pull ACS variable for an early and later period: the latest ACS year, 
## and the 5 years preceding the latest 5-year period (with no overlap)
for (yr in 2005:2019){
  
  ### use the get_acs function from tidycensus to query all of the
  ### variables defined above 
  dat <- suppressMessages( get_acs( 'us', 
                                    variables = vars, 
                                    output    = 'wide',
                                    survey    = 'acs1', 
                                    year      = yr ) )
  
  assign(paste0('us.acs.', as.character(yr)), dat)
  
  ### export to .csv file for manipulation and use in Stata
  write.csv(dat, paste0('data/us_acs_data_', as.character(yr), '.csv'))
}
  

###_____________________________________________________________________________
