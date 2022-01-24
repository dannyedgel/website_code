###
### This file pulls and maps county-level vacant homes data
###
### Date created:  22 Jan 2022
### Last modified: 22 Jan 2022
### Author: Danny Edgel
###

###
###   Housekeeping
###___________________________________________________

### install packages, if necessary
use.pkgs <- c("dplys", "tidycensus", "leaflet", "tigris", 'datasets', 'ggplot2')
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
           'B25004_001E',  # Total vacant housing units
           'B25004_002E',  # Total for rent vacant housing units
           'B25004_003E',  # Total rented, unoccupied vacant housing units
           'B25004_004E',  # Total for sale housing units
           'B25004_005E',  # Total sold, not occupied housing units
           'B25004_006E',  # Total seasonal, recreational, or occasionally used
           'B25004_007E',  # Total migrant worker housing units
           'B25004_008E',  # Total 'other' vacant housing units
)



###______________________________________________________________________________


###
###   Pull and combine needed data
###_________________________________________________________


# selected variables for 2015-2019
county.df <- get_acs( 'county',
                      variables = vars, 
                      output    = 'wide',
                      survey    = 'acs5',
                      year      = 2019 )


# pull county shapefile
county.sf <- counties_sf()
# county.sf <- counties(state = c(datasets::state.abb, 'DC'),
#                       year = 2019)

# add ACS data to shapefile
dat <- merge(county.sf, county.df, by.x = 'fips', by.y = 'GEOID')


###______________________________________________________________________________


###
###   Map vacant homes
###_________________________________________________________


# discretize vacant homes
br <- c(0, 1000, 5000, 10000, 50000, 100000, 150000)
dat$vhome_bracket <- cut(dat$B25004_008E,
                         breaks = br)

labs <- c('0-1k',
          '1k-5k',
          '5k-10k',
          '10k-50k',
          '50k-100k',
          '50k-150k')

# define color palette for choropleth
#pal <- colorNueric('RdBu', )
pal <- hcl.colors(length(br), 'Inferno', rev = TRUE, alpha = 0.7)



png(file = 'output/vacant_homes_total.png', width = 600, height = 350)
# generate map
map <- ggplot(dat) + 
  geom_sf(aes(fill = vhome_bracket), #B25004_008E),
          color = NA) + 
  coord_sf(crs = us_longlat_proj) + 
  scale_fill_manual(values = pal,
                    drop = FALSE,
                    na.value = 'grey80',
                    label = labs,
                    guide = guide_legend(direction = 'horizonal',
                                         nrow = 1,
                                         title = 'Truly Vacant Homes',
                                         title.position = 'left')) + 
  theme(legend.position = 'bottom',
        axis.text.x      = element_blank(),
        axis.text.y      = element_blank(),
        axis.ticks       = element_blank(),
        panel.background = element_blank())
map
dev.off()


# map vacant homes as a share of population
dat <- dat %>% mutate(vhome_percap = (B25004_008E / B01001_001E)*1000)
br <- c(0, 10, 20, 50, 75, 150, 300)
dat$vhome_bracket <- cut(dat$vhome_percap,
                         breaks = br)

labs <- c('0-10',
          '10-20',
          '20-50',
          '50-75',
          '75-150',
          '150-300')

pal <- hcl.colors(length(br), 'Inferno', rev = TRUE, alpha = 0.7)


png(file = 'output/vacant_homes_per1000.png', width = 600, height = 350)
map <- ggplot(dat) + 
  geom_sf(aes(fill = vhome_bracket), #B25004_008E),
          color = NA) + 
  coord_sf(crs = us_longlat_proj) + 
  scale_fill_manual(values = pal,
                    drop = FALSE,
                    na.value = 'grey80',
                    label = labs,
                    guide = guide_legend(direction = 'horizonal',
                                         nrow = 1,
                                         title = 'Truly Vacant Homes per 1,000',
                                         title.position = 'left')) + 
  theme(legend.position = 'bottom',
        axis.text.x      = element_blank(),
        axis.text.y      = element_blank(),
        axis.ticks       = element_blank(),
        panel.background = element_blank())
map
dev.off()


###_____________________________________________________________________________
