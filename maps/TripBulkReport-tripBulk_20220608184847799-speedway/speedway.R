library(sqldf)
library(tidyverse)
library(readxl)
library(sf)
library(sp)

################################################################################
# Muk speedway

setwd("~/LocalRStudio/LJ_Leading_Indicators/maps/")

tripheads <- read_delim("TripBulkReport-tripBulk_20220608184847799-speedway/schema/TripBulkReportTripsHeaders.csv") |>
  names()

trips <- read_csv("TripBulkReport-tripBulk_20220608184847799-speedway/data/trips.csv", col_names = tripheads, trim_ws = TRUE)

# number of trips from start grouped by id
start_trips <- sqldf("SELECT OriginCbg AS id,  StartLocLat, StartLocLon
                FROM trips
                WHERE Mode = 1")



cbg2021 <- st_read("tl_2021_53_bg/tl_2021_53_bg.shp")

#WGS84 is almost identical to NAD83
start_sf <- st_as_sf(start_trips, coords = c(lon = "StartLocLon", lat = "StartLocLat"), crs = "NAD83")

# go over, trasnlated from sp by sf vignette
start_rows <- sapply(st_intersects(start_sf,cbg2021), function(z) if (length(z)==0) NA_integer_ else z[1])
start_counts <- tibble(rownum = as.numeric(names(table(start_rows))), count = as.vector(table(start_rows)))

# filter block groups and compile df without geometry
start_df <- slice(cbg2021, start_counts$rownum) |>
  add_column(startpoints = start_counts$count) |>
  dplyr::select(id = GEOID, startpoints, geometry)


# number of trip to dest grouped by id
end_trips <- sqldf("SELECT DestCbg AS id, EndLocLat, EndLocLon
             FROM trips
             WHERE Mode = 1")

end_sf <- st_as_sf(end_trips, coords = c(lon = "EndLocLon", lat = "EndLocLat"), crs = "NAD83")

# go over, trasnlated from sp by sf vignette
end_rows <- sapply(st_intersects(end_sf,cbg2021), function(z) if (length(z)==0) NA_integer_ else z[1])
end_counts <- tibble(rownum = as.numeric(names(table(end_rows))), count = as.vector(table(end_rows)))

# filter block groups and compile df without geometry
end_df <- slice(cbg2021, end_counts$rownum) |>
  add_column(endpoints = end_counts$count) |>
  dplyr::select(id = GEOID, endpoints, geometry)

################################################################################
# ACS for household by cbg
acs <- read_csv("ACSDT5Y2020.B19013_2022-06-12T225944/ACSDT5Y2020.B19013_data_with_overlays_2022-05-03T115646.csv", skip = 1, na = "-")

# rename
acs_names <- names(acs) %>%
  gsub("\\!!", "__", .)
names(acs) <- acs_names

median_h_income <- acs |>
  dplyr::mutate(id = sub(".*US", "", id),
                mhi = `Estimate__Median household income in the past 12 months (in 2020 inflation-adjusted dollars)`,
                mhi = ifelse(mhi == "250,000+", 250000, as.numeric(mhi))) |>
  dplyr::select(id, mhi, gan = `Geographic Area Name`)

start_income <- left_join(start_df, median_h_income, by = "id")

end_income <- left_join(end_df, median_h_income, by = "id")

# corridor incomes

# mhi for the road
start_income %>%
  uncount(startpoints) %>%
  ggplot() + geom_histogram(aes(x = mhi), color = "black", fill = "pink") + 
  labs(title = "Speedway Median Household Income", subtitle = "sample start",
       x = "Median Household Income", y = "Count") +
  theme_classic()

# % of zones with mhi > $100,000
per <- start_income %>%
  uncount(startpoints) %>%
  dplyr::mutate(thous = ifelse(mhi >= 100000, 1, 0))

sum(per$thous, na.rm = T) / nrow(per)


end_income %>%
  uncount(endpoints) %>%
  ggplot() + geom_histogram(aes(x = mhi), color = "black", fill = "lightblue") + 
  labs(title = "Speedway Median Household Income", subtitle = "sample end",
       x = "Median Household Income", y = "Count") +
  theme_classic()

# % of zones with mhi > $100,000
per <- end_income %>%
  uncount(endpoints) %>%
  dplyr::mutate(thous = ifelse(mhi >= 100000, 1, 0))

sum(per$thous, na.rm = T) / nrow(per)

