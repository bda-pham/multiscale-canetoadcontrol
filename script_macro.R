install.packages(c("devtools", "dplyr", "ggplot2", "tidyr", "extrafont", "directlabels"))
install.packages("directlabels")

library(gridExtra)
library(cowplot)
library(devtools)
library(dplyr)
library(ggplot2)
library(tidyr)
library(directlabels)

spread_data <- read.table("results/toads - large - graph spread-table.csv",
                          header = T,
                          sep = ",",
                          skip = 6,
                          quote = "\"",
                          fill = TRUE)
spread_data2 <- read.table("results/toads - large - graph spread high capacity-table.csv",
                          header = T,
                          sep = ",",
                          skip = 6,
                          quote = "\"",
                          fill = TRUE)
spread_data3 <- read.table("results/toads - large - graph spread highcap 1-table.csv",
                          header = T,
                          sep = ",",
                          skip = 6,
                          quote = "\"",
                          fill = TRUE)

spread_data <- spread_data[,1:14]
spread_data2 <- spread_data2[,1:14]
spread_data3 <- subset(spread_data3, select = -wet.year.extra.days)

plot_data <- rbind(spread_data, spread_data2, spread_data3)

library(scales)
show_col(hue_pal()(3))
ggplot(plot_data, aes(x=factor(spread.boost), y=ticks, color=factor(spread.boost))) +
  #geom_line(aes(color=factor(active.cloc)), size=1.1, color="gray", show.legend = FALSE) +
  
  geom_violin(adjust=3, size=1, width=1.5) +
  stat_summary(fun.data = "mean_sdl", fun.args = list(mult = 1), geom = "crossbar", width=0.08) +
  scale_color_manual(values=c("#F8766D","#00BA38","#619CFF"),labels=c("60 (default)","240","960"))+
  labs(x="No. controlled water points", y="Region colonisation prob.", color="Capacity (toads/day)") +
  theme_minimal_grid(13) +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank())
#geom_dl(aes(label = active.cloc), method = list(dl.trans(x = x - 0.2), "first.points", cex = 0.8)) +
#geom_dl(aes(label = active.cloc), method = list(dl.trans(x = x + 0.2), "last.points", cex = 0.8))
ggsave("control-excl.pdf", width=13, height=8, units="cm", path="./figures/")

#control_loc_data <- read.table("results/toads - large - graph control loc excl-table.csv",
control_loc_data <- read.table("results/toads - large - graph excl-table.csv",
                                header = T,
                                sep = ",",
                                skip = 6,
                                quote = "\"",
                                fill = TRUE)

control_loc_data <- control_loc_data %>% 
  mutate(region.colonised. = if_else(region.colonised.=="true", 1, 0))
mean_results <- aggregate(region.colonised. ~ no.controlled.wp + active.cloc, control_loc_data, mean)

ggplot(filter(mean_results, active.cloc %in% c(3,4,10,14,15,16)), aes(x=no.controlled.wp, y=region.colonised., group=active.cloc)) +
  #geom_line(aes(color=factor(active.cloc)), size=1.1, color="gray", show.legend = FALSE) +
  geom_line(aes(color=factor(active.cloc)), size=1.1) +
  scale_x_continuous(breaks = seq(4, 14, 2)) +
  geom_vline(aes(xintercept=14), linetype = "22") +
  labs(x="No. controlled water points", y="Region colonisation probability", color="Control location") +
  theme_minimal_grid(13) +
  theme(axis.title.y=element_text(size=12))
  #geom_dl(aes(label = active.cloc), method = list(dl.trans(x = x - 0.2), "first.points", cex = 0.8)) +
  #geom_dl(aes(label = active.cloc), method = list(dl.trans(x = x + 0.2), "last.points", cex = 0.8))
ggsave("control-excl.pdf", width=13, height=8, units="cm", path="./figures/")


control_fence_data <- read.table("results/toads - large - graph control loc fence-table.csv",
                               header = T,
                               sep = ",",
                               skip = 6,
                               quote = "\"",
                               fill = TRUE)

control_fence_data <- control_fence_data %>% 
  mutate(region.colonised. = if_else(region.colonised.=="true", 1, 0))

mean_results <- aggregate(ticks ~ active.cloc + fence, control_fence_data, mean)

#mean_results <- filter(rbind(mean_results, mean_results2), active.cloc %in% c(3, 4, 10, 14, 15, 16))

mean_results <- mean_results %>% 
  mutate(fence = if_else(fence=="fence7", "Weekly", "Monthly"))
ggplot(mean_results, aes(x=factor(active.cloc), y=ticks, color=factor(fence))) +
  #geom_line(data = mean_results, aes(color=factor(active.cloc), linetype=fence), size=1.1, color="gray", show.legend = FALSE) +
  geom_segment(data = subset(mean_results, fence == "Weekly"), aes(x=factor(active.cloc), xend=factor(active.cloc), y=80, yend=ticks)) + 
  geom_segment(data = subset(mean_results, fence == "Monthly"), aes(x=factor(active.cloc), xend=factor(active.cloc), y=80, yend=ticks)) + 
  geom_point(size=3) + 
  coord_cartesian(ylim = c(80, 110)) +
  geom_abline(intercept=86.7, slope=0, linetype="dashed") +
  labs(x="Control location", y="Time to colonise region (years)", color="Repair frequency") +
  theme_minimal_grid(13)
ggsave("control-fence.pdf", width=12, height=8, units="cm", path="./figures/")


control_trap_data <- read.table("results/toads - large - graph trap-table.csv",
                                header = T,
                                sep = ",",
                                skip = 6,
                                quote = "\"",
                                fill = TRUE)
control_trap_data <- control_trap_data %>% 
  mutate(region.colonised. = if_else(region.colonised.=="true", 1, 0))
mean_results = aggregate(ticks ~ no.controlled.wp + active.cloc + trap, control_trap_data, mean)
ggplot(mean_results, aes(x=no.controlled.wp, y=ticks, color=active.cloc, linetype=trap)) +
  geom_line(data = filter(mean_results, active.cloc %in% c(14,15)), aes(color=factor(active.cloc), linetype=trap), size=1.1) +
  scale_x_continuous(breaks = c(4, 6, 8, 10, 12, 14)) +
  scale_linetype_manual(labels = c("1 / 100m", "2 / 100m"), values = c("solid","22")) +
  labs(x="No. controlled water points", y="Time to colonise region (years)", color="Control location", linetype="Trap density") +
  theme_minimal_grid(13)
ggsave("control-trap.pdf", width=12, height=8, units="cm", path="./figures/")


control_fencetrap_data <- read.table("results/toads - large - graph control loc fence trap 500-table.csv",
                                header = T,
                                sep = ",",
                                skip = 6,
                                quote = "\"",
                                fill = TRUE)
control_fencetrap_data2 <- read.table("results/toads - large - graph control loc fence trap 500b-table.csv",
                                     header = T,
                                     sep = ",",
                                     skip = 6,
                                     quote = "\"",
                                     fill = TRUE)
control_fencetrap_data <- rbind(control_fencetrap_data, control_fencetrap_data2)
control_fencetrap_data <- control_fencetrap_data %>% 
  mutate(region.colonised. = if_else(region.colonised.=="true", 1, 0))
control_fencetrap_data <- control_fencetrap_data %>% 
  unite("fencetrap", trap:fence, remove=FALSE)

mean_results = aggregate(ticks ~ no.controlled.wp + active.cloc + fencetrap, control_fencetrap_data, mean)
ggplot(mean_results, aes(x=no.controlled.wp, y=ticks, color=active.cloc, linetype=fencetrap)) +
  geom_line(data = filter(mean_results, active.cloc %in% c(14,15)), aes(color=factor(active.cloc), linetype=fencetrap), size=1.1) +
  scale_x_continuous(breaks = c(4, 6, 8, 10, 12, 14)) +
  scale_linetype_manual(values = c("solid","22","dotted", "longdash")) +
  labs(x="No. controlled water points", y="Time to colonise region (years)", color="Control location", linetype="Trap density") +
  theme_minimal_grid(13)

mean_results = aggregate(region.colonised. ~ no.controlled.wp + active.cloc + fencetrap, control_fencetrap_data, mean)
ggplot(mean_results, aes(x=no.controlled.wp, y=region.colonised., color=active.cloc, linetype=fencetrap)) +
  geom_line(data = filter(mean_results, active.cloc %in% c(14,15)), aes(color=factor(active.cloc), linetype=fencetrap), size=1.1) +
  scale_x_continuous(breaks = c(4, 6, 8, 10, 12, 14)) +
  scale_y_continuous(limits = c(0, 1)) +
  scale_linetype_manual(values = c("solid","dashed", "22","dotted"), 
                        labels = c("Monthly - Density 1", "Weekly - Density 1", "Monthly - Density 2", "Weekly - Density 2")) +
  labs(x="No. controlled water points", y="Region conlonisation probability", color="Control location", linetype="Fence - Trap") +
  theme_minimal_grid(13) +
  theme(axis.title.y=element_text(size=12)) +
  facet_grid(cols = vars(active.cloc))
ggsave("control-fencetrap.pdf", width=15, height=7, units="cm", path="./figures/")


#control_fenceexcl_data <- read.table("results/toads - large - graph control loc excl fence-table.csv",
control_fenceexcl_data <- read.table("results/toads - large - graph control loc excl fence-table.csv",
                                     header = T,
                                     sep = ",",
                                     skip = 6,
                                     quote = "\"",
                                     fill = TRUE)

control_fenceexcl_data <- control_fenceexcl_data %>% 
  mutate(region.colonised. = if_else(region.colonised.=="true", 1, 0), wet.year.extra.days = 14)
control_fenceexcl_data <- subset(control_fenceexcl_data, select = -ticks)
control_fenceexcl_data <- rbind(filter(control_loc_data, no.controlled.wp %% 2 == 0), control_fenceexcl_data)
control_fenceexcl_data$fence <- factor(control_fenceexcl_data$fence, levels = unique(control_fenceexcl_data$fence))
mean_results = aggregate(region.colonised. ~ no.controlled.wp + active.cloc + fence, control_fenceexcl_data, mean)
#mean_results <- filter(mean_results, fence != "fence30")
ggplot(mean_results, aes(x=no.controlled.wp, y=region.colonised., color=active.cloc, linetype=fence)) +
  geom_line(aes(color=factor(active.cloc), linetype=fence), size=1.1) +
  scale_x_continuous(breaks = c(4, 6, 8, 10, 12, 14)) +
  geom_vline(aes(xintercept=14), linetype = "22") +
  scale_linetype_manual(labels = c("No fence", "Monthly repair", "Weekly repair"), values = c("dotted","22","solid")) +
  labs(x="No. controlled water points", y="Region colonisation probability", color="Control location", linetype="Fence") +
  theme_minimal_grid(13) +
  facet_wrap(~ active.cloc, ncol = 2)
ggsave("control-fenceexcl.pdf", width=14, height=13, units="cm", path="./figures/")


control_trapexcl_data <- read.table("results/toads - large - graph control loc excl trap-table.csv",
                                     header = T,
                                     sep = ",",
                                     skip = 6,
                                     quote = "\"",
                                     fill = TRUE)
control_trapexcl_data <- control_trapexcl_data %>% 
  mutate(region.colonised. = if_else(region.colonised.=="true", 1, 0), wet.year.extra.days = 14)
control_trapexcl_data <- subset(control_trapexcl_data, select = -ticks)
control_trapexcl_data <- rbind(control_trapexcl_data, filter(control_loc_data, no.controlled.wp %% 2 == 0))
mean_results = aggregate(region.colonised. ~ no.controlled.wp + active.cloc + trap, control_trapexcl_data, mean)

ggplot(filter(mean_results, no.controlled.wp <= 20), aes(x=no.controlled.wp, y=region.colonised., color=active.cloc, linetype=trap)) +
  geom_line(aes(color=factor(active.cloc), linetype=trap), size=1.1) +
  scale_x_continuous(breaks = c(4, 6, 8, 10, 12, 14, 16, 18, 20)) +
  geom_vline(aes(xintercept = 14), linetype="22") +
  scale_linetype_manual(labels = c("No trap", "1 / 100m", "2 / 100m"), values = c("dotted","22","solid")) +
  labs(x="No. controlled water points", y="Region colonisation probability", color="Control location", linetype="Trap density") +
  theme_minimal_grid(13) +
  facet_wrap(~ active.cloc, ncol = 2) 
ggsave("control-trapexcl.pdf", width=14, height=13, units="cm", path="./figures/")


control_excl_highcap_data <- read.table("results/toads - large - graph excl high cap-table.csv",
                               header = T,
                               sep = ",",
                               skip = 6,
                               quote = "\"",
                               fill = TRUE)
control_excl_highcap_data1 <- read.table("results/toads - large - graph excl highcap 1-table.csv",
                                        header = T,
                                        sep = ",",
                                        skip = 6,
                                        quote = "\"",
                                        fill = TRUE)

control_excl_highcap_data <- control_excl_highcap_data %>% 
  mutate(wet.year.extra.days = 14)
control_excl_highcap_data <- control_excl_highcap_data %>% 
  mutate(region.colonised. = if_else(region.colonised.=="true", 1, 0))
control_excl_highcap_data1 <- control_excl_highcap_data1 %>% 
  mutate(region.colonised. = if_else(region.colonised.=="true", 1, 0))

mean_results <- aggregate(region.colonised. ~ no.controlled.wp + active.cloc + spread.boost,
                          rbind(control_loc_data, control_excl_highcap_data, control_excl_highcap_data1), mean)

ggplot(filter(mean_results, no.controlled.wp <= 20 & active.cloc %in% c(3,4,10,14,15,16)),
       aes(x=no.controlled.wp, y=region.colonised., color = factor(active.cloc), linetype = spread.boost)) +
  #geom_line(aes(color=factor(active.cloc)), size=1.1, color="gray", show.legend = FALSE) +
  geom_line(aes(color=factor(active.cloc), linetype = factor(spread.boost)), size=1.1) +
  geom_vline(aes(xintercept=14), linetype = "22") +
  scale_x_continuous(breaks = seq(4, 24, 2)) +
  scale_linetype_manual(labels=c("60 (default)","240", "960"), values = c("dotted", "22", "solid")) +
  labs(x="No. controlled water points", y="Region colonisation probability", color="Control location", linetype="Capacity (toads/day)") +
  theme_minimal_grid(13) +
  facet_wrap(~ active.cloc, ncol = 2) 
ggsave("control-excl-highcap.pdf", width=16, height=12, units="cm", path="./figures/")


 #control_fenceexcl_data <- read.table("results/toads - large - graph control loc excl fence-table.csv",
control_fenceexcl_highcap_data <- read.table("results/toads - large - graph excl fence high cap2-table.csv",
                                     header = T,
                                     sep = ",",
                                     skip = 6,
                                     quote = "\"",
                                     fill = TRUE)
control_fenceexcl_highcap_data2 <- read.table("results/toads - large - graph excl fence high cap-table.csv",
                                      header = T,
                                      sep = ",",
                                      skip = 6,
                                      quote = "\"",
                                      fill = TRUE)
control_fenceexcl_highcap_data <- rbind(control_fenceexcl_highcap_data, control_fenceexcl_highcap_data2)
control_fenceexcl_highcap_data <- control_fenceexcl_highcap_data %>% 
  mutate(region.colonised. = if_else(region.colonised.=="true", 1, 0), wet.year.extra.days = 14)
control_fenceexcl_highcap_data <- subset(control_fenceexcl_highcap_data, select = -ticks)
control_fenceexcl_highcap_data <- rbind(control_fenceexcl_highcap_data, filter(control_fenceexcl_data, fence=="fence7"))
control_fenceexcl_highcap_data$fence <- factor(control_fenceexcl_highcap_data$fence, levels = unique(control_fenceexcl_highcap_data$fence))
mean_results = aggregate(region.colonised. ~ no.controlled.wp + active.cloc + spread.boost, control_fenceexcl_highcap_data, mean)
#mean_results <- filter(mean_results, fence != "fence30")
ggplot(filter(mean_results, no.controlled.wp <= 20), aes(x=no.controlled.wp, y=region.colonised., color=active.cloc, linetype=factor(spread.boost))) +
  geom_line(aes(color=factor(active.cloc), linetype=factor(spread.boost)), size=1.1) +
  scale_x_continuous(breaks = c(4, 6, 8, 10, 12, 14, 16, 18, 20)) +
  geom_vline(aes(xintercept=14), linetype="22")+
  #scale_linetype_manual(labels = c("60 (default)", "960"), values = c("dotted","solid")) +
  labs(x="No. controlled water points", y="Region colonisation prob.", color="Control location", linetype="Capacity (toads/day)") +
  theme_minimal_grid(13) +
  facet_wrap(~ active.cloc, ncol = 2) 

control_trapexcl_highcap_data <- read.table("results/toads - large - graph excl trap high cap-table.csv",
                                    header = T,
                                    sep = ",",
                                    skip = 6,
                                    quote = "\"",
                                    fill = TRUE)
control_trapexcl_highcap_data1 <- read.table("results/toads - large - graph excl trap highcap 1-table.csv",
                                            header = T,
                                            sep = ",",
                                            skip = 6,
                                            quote = "\"",
                                            fill = TRUE)

control_trapexcl_highcap_data <- control_trapexcl_highcap_data %>% 
  mutate(region.colonised. = if_else(region.colonised.=="true", 1, 0), wet.year.extra.days = 14)
control_trapexcl_highcap_data <- subset(control_trapexcl_highcap_data, select = -ticks)
control_trapexcl_highcap_data1 <- control_trapexcl_highcap_data1 %>% 
  mutate(region.colonised. = if_else(region.colonised.=="true", 1, 0), wet.year.extra.days = 14)
control_trapexcl_highcap_data <- rbind(control_trapexcl_highcap_data, control_trapexcl_highcap_data1)

control_trapexcl_highcap_data <- rbind(control_trapexcl_highcap_data, filter(control_trapexcl_data, trap=="trap2"))
mean_results = aggregate(region.colonised. ~ no.controlled.wp + active.cloc + spread.boost, control_trapexcl_highcap_data, mean)

ggplot(filter(mean_results, no.controlled.wp <= 14), aes(x=no.controlled.wp, y=region.colonised., color=active.cloc, linetype=spread.boost)) +
  geom_line(aes(color=factor(active.cloc), linetype=factor(spread.boost)), size=1.1) +
  scale_x_continuous(breaks = c(4, 6, 8, 10, 12, 14, 16, 18, 20)) +
  geom_vline(aes(xintercept = 14), linetype = "22") +
  scale_linetype_manual(labels = c("60 (default)", "240", "960"), values = c("dotted","22","solid")) +
  labs(x="No. controlled water points", y="Region colonisation probability", color="Control location", linetype="Capacity (toads/day)") +
  theme_minimal_grid(13) +
  facet_wrap(~ active.cloc, ncol = 2) 
ggsave("control-trapexcl-highcap.pdf", width=14, height=13, units="cm", path="./figures/")


control_excl_rain_data <- read.table("results/toads - large - graph control loc excl rain-table.csv",
                                        header = T,
                                        sep = ",",
                                        skip = 6,
                                        quote = "\"",
                                        fill = TRUE)

control_excl_rain_data <- control_excl_rain_data %>% 
  mutate(region.colonised. = if_else(region.colonised.=="true", 1, 0))
control_loc_data <- control_loc_data %>% 
  mutate(wet.year.extra.days = 14)

mean_results <- aggregate(region.colonised. ~ no.controlled.wp + active.cloc + wet.year.interval,
                          rbind(control_loc_data, control_excl_rain_data), mean)

ggplot(filter(mean_results, no.controlled.wp <= 14 & no.controlled.wp),
       aes(x=no.controlled.wp, y=region.colonised., color=active.cloc, linetype=factor(wet.year.interval))) +
  geom_line(aes(color=factor(active.cloc)), size=1.1) +
  scale_x_continuous(breaks = c(4, 6, 8, 10, 12, 14, 16, 18, 20)) +
  geom_vline(aes(xintercept = 14), linetype = "22") +
  scale_linetype_manual(labels = c("5 years - 28 days", "10 years - 14 days (default)"), values = c("solid","dotted")) +
  labs(x="No. controlled water points", y="Region colonisation probability", color="Control location", linetype="Wet year interval - Extra days") +
  theme_minimal_grid(13) +
  facet_wrap(~ active.cloc, ncol = 2) 
ggsave("control-excl-rain.pdf", width=15, height=13, units="cm", path="./figures/")


#control_fenceexcl_data <- read.table("results/toads - large - graph control loc excl fence-table.csv",
control_fenceexcl_rain_data <- read.table("results/toads - large - graph control loc excl fence rain-table.csv",
                                             header = T,
                                             sep = ",",
                                             skip = 6,
                                             quote = "\"",
                                             fill = TRUE)
control_fenceexcl_rain_data <- control_fenceexcl_rain_data %>% 
  mutate(region.colonised. = if_else(region.colonised.=="true", 1, 0))
control_fenceexcl_rain_data <- subset(control_fenceexcl_rain_data, select = -ticks)
control_fenceexcl_data <- control_fenceexcl_data %>% 
  mutate(wet.year.extra.days = 14)

control_fenceexcl_rain_data <- rbind(control_fenceexcl_rain_data, filter(control_fenceexcl_data, fence=="fence7"))
control_fenceexcl_rain_data$fence <- factor(control_fenceexcl_rain_data$fence, levels = unique(control_fenceexcl_rain_data$fence))
mean_results = aggregate(region.colonised. ~ no.controlled.wp + active.cloc + wet.year.interval, control_fenceexcl_rain_data, mean)
#mean_results <- filter(mean_results, fence != "fence30")
ggplot(filter(mean_results, no.controlled.wp <= 20), aes(x=no.controlled.wp, y=region.colonised., 
                                                         color=factor(active.cloc), linetype=factor(wet.year.interval))) +
  geom_line(size=1.1) +
  scale_x_continuous(breaks = c(4, 6, 8, 10, 12, 14, 16, 18, 20)) +
  geom_vline(aes(xintercept=14), linetype="22")+
  scale_linetype_manual(labels = c("5 years - 28 days", "10 years - 14 days (default)"), values = c("solid","dotted")) +
  labs(x="No. controlled water points", y="Region colonisation probability", 
       color="Control location", linetype="Wet year interval - Extra days") +
  theme_minimal_grid(13) +
  facet_wrap(~ active.cloc, ncol = 2) 
ggsave("control-fenceexcl-rain.pdf", width=15, height=13, units="cm", path="./figures/")
