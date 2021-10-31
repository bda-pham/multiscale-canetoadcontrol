install.packages(c("devtools", "dplyr", "ggplot2", "tidyr", "plyr", "Rcpp"))

library(devtools)
library(plyr)
library(dplyr)
library(ggplot2)
library(tidyr)
library(Rcpp)

weather_stations <- list("003003", "003066", "003030", "003028", "004019", "004068", "004028")
excluded_seasons <- list("003066" = list(2018, 2019))
station_stats = data.frame(matrix(ncol=5,nrow=0, dimnames=list(NULL, c("code", "max", "min", "mean", "sd"))))
for (weather_station in weather_stations) {
  weather_data <- read.table(paste("rainfall/IDCJAC0009_",weather_station,"_1800/IDCJAC0009_",weather_station,"_1800_Data.csv",sep=""),
                             header = T,
                             sep = ",",
                             skip = 0,
                             quote = "\"",
                             fill = TRUE)
  weather_data <- weather_data %>% 
    mutate(Rainy = if_else(!is.na(Rainfall.amount..millimetres.) & Rainfall.amount..millimetres. >= 1.0, 1, 0))
  weather_data <- weather_data %>% 
    mutate(Movable = if_else(Rainy == 1, 1, 0))
  
  season_data <- weather_data %>% 
    mutate(Wet_season = if_else(Month > 6, Year + 1, Year*1.0))
  
  recent_data = filter(season_data, Wet_season >= 2000 & Wet_season <= 2020)
  
  for (row in 1:nrow(recent_data)) {
    if (!is.na(recent_data[row, 7])) {
      days <- recent_data[row, 7]
      if (days > 1) {
        for(i in 1:days-1) {
          recent_data[row-i, "Rainy"] = 1
          recent_data[row-i, "Movable"] = 1
        }
      }
    }
    if (recent_data[row, "Rainy"] == 1) {
      for (i in 1:3) {
        if (row+i <= nrow(recent_data)) {
          recent_data[row+i,"Movable"] = 1
        }
      }
    }
  }
  grouped_season = filter(aggregate(cbind(Rainy, Movable) ~ Wet_season, recent_data, sum), !is.element(Wet_season, excluded_seasons[[weather_station]]))
  assign(paste("station_results",weather_station,sep=""), grouped_season)
  write.csv(grouped_season,paste('station_',weather_station,'.csv',sep=""))
  station_stats[nrow(station_stats)+1,] = list(weather_station, max(grouped_season[,"Movable"]),
                                               min(grouped_season[,"Movable"]), mean(grouped_season[,"Movable"]),
                                               sd(grouped_season[,"Movable"]))
}

ggplot(station_results003003, aes(x=Movable)) +
  geom_histogram(binwidth=20)

ggplot(station_results003066, aes(x=Movable)) +
  geom_histogram(binwidth=20)

ggplot(station_results003030, aes(x=Movable)) +
  geom_histogram(binwidth=20)

ggplot(station_results003028, aes(x=Movable)) +
  geom_histogram(binwidth=20)

ggplot(station_results004019, aes(x=Movable)) +
  geom_histogram(binwidth=20)

ggplot(station_results004068, aes(x=Movable)) +
  geom_histogram(binwidth=20)

ggplot(station_results004028, aes(x=Movable)) +
  geom_histogram(binwidth=20)



station_info = read.table("stations.csv",
                           header = T,
                           sep = ",",
                           skip = 0,
                           quote = "\"",
                           fill = TRUE,
                           colClasses=c('character','character', 'numeric', 'numeric'))
station_final <- plyr::join(station_info, station_stats, by="code", type="right")
write.csv(station_final,'station_final.csv')
