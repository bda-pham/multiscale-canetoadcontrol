install.packages(c("devtools", "dplyr", "ggplot2", "tidyr", "extrafont"))
install.packages("gridExtra")
install.packages("cowplot")
library(gridExtra)
library(cowplot)
library(devtools)
library(dplyr)
library(ggplot2)
library(tidyr)
library(scales)
library(stringr)

fence_data <- read.table("results/toads fence breach-table.csv",
                           header = T,
                           sep = ",",
                           skip = 6,
                           quote = "\"",
                           fill = TRUE)
fence_data2 <- read.table("results/toads fence breach 2-table.csv",
                         header = T,
                         sep = ",",
                         skip = 6,
                         quote = "\"",
                         fill = TRUE)
mean_results = aggregate(colonised.wp ~ fence.breach.chance, rbind(fence_data, fence_data2), mean)
ggplot(mean_results, aes(x=fence.breach.chance, y=colonised.wp)) +
  geom_line() +
  labs(x="Breach chance (probability / day)", y="Colonisation probability") +
  # scale_y_continuous(limits = c(0, 0.7))+
  theme_minimal()

fence_data3 <- read.table("results/toads fence fix interval2-table.csv",
                          header = T,
                          sep = ",",
                          skip = 6,
                          quote = "\"",
                          fill = TRUE)
fence_data4 <- read.table("results/toads fence fix interval2b-table.csv",
                         header = T,
                         sep = ",",
                         skip = 6,
                         quote = "\"",
                         fill = TRUE)
fence_compare_data <- filter(grouped_base, colonisers.perwave == 20 & max.distance <= 100 & move.days == 160)
fence_compare_data <- rename(fence_compare_data, colonised.wp = colonisation.prob)
fence_compare_data <- fence_compare_data[c("max.distance", "colonised.wp")] %>% 
  mutate(fence.fix.interval = "no fence")

mean_results = aggregate(colonised.wp ~ fence.fix.interval + max.distance, rbind(fence_data3,fence_data4), mean)
ggplot(rbind(mean_results, fence_compare_data), aes(x=max.distance, y=colonised.wp, group=fence.fix.interval)) +
  geom_line(aes(color=factor(fence.fix.interval))) +
  labs(x="Fence maintenance interval", y="Colonisation probability") +
  # scale_y_continuous(limits = c(0, 0.7))+
  theme_minimal()

fence_data <- read.table("results/toads fence fix interval break chance2-table.csv",
                          header = T,
                          sep = ",",
                          skip = 6,
                          quote = "\"",
                          fill = TRUE)
mean_results = aggregate(colonised.wp ~ fence.fix.interval + fence.break.chance, fence_data, mean)
ggplot(mean_results, aes(x=fence.break.chance, y=colonised.wp, group=fence.fix.interval)) +
  geom_line(aes(color=factor(fence.fix.interval)), size=1.1) +
  labs(x="Fence break chance", y="Colonisation probability", color="Repair interval") +
  # scale_y_continuous(limits = c(0, 0.7))+
  theme_minimal()+
  theme(text = element_text(size=13))
ggsave("fence-fix-interval-break-chance.pdf", width=12, height=7, units="cm", path="./figures/")


trap_data_male <- read.table("results/toads trap male-table.csv",
                          header = T,
                          sep = ",",
                          skip = 6,
                          quote = "\"",
                          fill = TRUE)
trap_data_male <- trap_data_male %>% 
  mutate(trap.type = "Male")
trap_data_female <- read.table("results/toads trap female-table.csv",
                        header = T,
                        sep = ",",
                        skip = 6,
                        quote = "\"",
                        fill = TRUE)
trap_data_female <- trap_data_female %>% 
  mutate(trap.type = "Female")
trap_data <- rbind(trap_data_male, trap_data_female)
mean_results = aggregate(colonised.wp ~ trap.mode + trap.type, trap_data, mean)
mean_results <- mean_results %>%
  mutate(trap.mode = str_to_title(trap.mode))
ggplot(mean_results, aes(x=trap.type, y=colonised.wp, fill=trap.mode)) +
  geom_bar(position="dodge", stat="identity") +
  labs(x="Type of trap", y="Colonisation probability", fill="Trap mode") +
  # scale_y_continuous(limits = c(0, 0.7))+
  theme_minimal_hgrid(13)
ggsave("trap-male-female.pdf", width=15, height=7, units="cm", path="./figures/")


trap_data <- read.table("results/toads trap dest source 6060-table.csv",
                        header = T,
                        sep = ",",
                        skip = 6,
                        quote = "\"",
                        fill = TRUE)
trap_data2<- read.table("results/toads trap dest source-table.csv",
                        header = T,
                        sep = ",",
                        skip = 6,
                        quote = "\"",
                        fill = TRUE)
mean_results = aggregate(colonised.wp ~ trap.mode + trap.density, trap_data, mean)
p1 <- ggplot(mean_results, aes(x=trap.density, y=colonised.wp, group=trap.mode)) +
  geom_line(aes(color=trap.mode), size=1.1) +
  labs(x="Trap density (traps / 100m)", y="Colonisation probability", color="Trap mode") +
  # scale_y_continuous(limits = c(0, 0.7))+
  theme_minimal_grid(13)

mean_results = aggregate(colonised.wp ~ trap.mode + trap.density, trap_data2, mean)
p2 <- ggplot(mean_results, aes(x=trap.density, y=colonised.wp, group=trap.mode)) +
  geom_line(aes(color=trap.mode), size=1.1) +
  labs(x="Trap density (traps / 100m)", y="", color="Trap mode") +
  scale_y_continuous(limits = c(0, 1))+
  theme_minimal() +
  theme(text = element_text(size=13), legend.position = "none", axis.title.y = element_blank())

legend <- get_legend(p1)
# 3. Remove the legend from the box plot
#+++++++++++++++++++++++
p1 <- p1 + theme(legend.position="none")
# 4. Arrange ggplot2 graphs with a specific width
grid.arrange(p1, p2, legend, ncol=3, widths=c(2.35, 2.2, 0.8))


mean_results = aggregate(colonised.wp ~ trap.mode + trap.density + max.distance, trap_data2, mean)
mean_results <- mean_results %>%
  mutate(trap.mode = str_to_title(trap.mode))
ggplot(mean_results, aes(x=trap.density, y=colonised.wp, group=trap.mode)) +
  geom_line(aes(color=trap.mode), size=1.1) +
  labs(x="Trap density (traps / 100m)", y="Colonisation probability", color="Trap mode") +
  scale_y_continuous(limits = c(0, 1))+
  theme_minimal_grid(13)
ggsave("trap-dest-source.pdf", width=11, height=7, units="cm", path="./figures/")

cap_dis_data <- read.table("results/cap dis relation.csv",
                             header = T,
                             sep = ",",
                             skip = 0,
                             quote = "\"",
                             fill = TRUE)
#ggplot(filter(cap_dis_data, capacity < 160), aes(x=capacity, y=distance, group=prob)) +
ggplot(cap_dis_data, aes(x=capacity, y=distance/10, group=prob)) +
  geom_line(aes(color=factor(prob)), size=1.1) +
  labs(x="Capacity (toads/day)", y="Distance (km)", color="Colonisation probability") +
  scale_x_continuous(breaks=cap_dis_data[,1]) +
  theme_minimal_grid(13)+
  theme(legend.position = "right",
        legend.direction = "vertical",
        legend.background = element_rect(fill="white", size=12, color="white"))
ggsave("cap-dist-relation.pdf", width=17, height=6, units="cm", path="./figures/")


gender_req_data <- read.table("results/toads gender req new radius-table.csv",
                             header = T,
                             sep = ",",
                             skip = 6,
                             quote = "\"",)

grouped_req = aggregate(colonised.wp ~ colon.req + max.distance, gender_req_data, mean)
grouped_req <- grouped_req %>% 
  mutate(colon.req = if_else(colon.req == "both-genders", "Both genders", "Two of any gender"))
ggplot(grouped_req, aes(x=max.distance/10, y=colonised.wp, group=colon.req)) +
  geom_line(aes(color=colon.req), size=1.1) +
  # scale_y_continuous(limits = c(0, 0.7))+
  scale_x_continuous(breaks=seq(5,35,by=5))+
  labs(x="Distance (km)", y="Colonisation probability", color="Requirement") +
  theme_minimal_grid(13)
ggsave("colon-req.pdf", width=12, height=7, units="cm", path="./figures/")

angle_data <- read.table("results/toads angle dev-table.csv",
                              header = T,
                              sep = ",",
                              skip = 6,
                              quote = "\"",
                              fill = TRUE)
ggplot(angle_data, aes(x=mean.angle.dev, y=mean.meander)) +
  geom_line(size=1.1) +
  geom_ribbon(aes(ymax = mean.meander + dev.meander, ymin = mean.meander - dev.meander), alpha = 0.2) +
  scale_y_continuous(limits = c(0.2, 1))+
  labs(x="Mean angle deviation (degrees)", y="Meander ratio") +
  theme_minimal_grid(13)
ggsave("angle.pdf", width=10, height=7, units="cm", path="./figures/")


radius_data <- read.table("results/toads dest radius 3-table.csv",
                          header = T,
                          sep = ",",
                          skip = 6,
                          quote = "\"",
                          fill = TRUE)
radius_data2 <- read.table("results/toads dest radius 2-table.csv",
                          header = T,
                          sep = ",",
                          skip = 6,
                          quote = "\"",
                          fill = TRUE)
radius_data = rbind(radius_data, radius_data2)
grouped_radius = aggregate(colonised.wp ~ dest.radius + max.distance, radius_data, mean)
grouped_radius <- grouped_radius %>% 
  mutate(dest.radius = ifelse(dest.radius == 0, 1, dest.radius))
ggplot(grouped_radius, aes(x=dest.radius/10, y=colonised.wp, color=factor(max.distance/10))) +
  geom_line(size=1.1) +
  scale_x_continuous(breaks=c(0.1,0.4,0.8,1.2,1.6,2, 2.4,2.8))+
  labs(x="Detection radius (km)", y="Colonisation probability", color="Distance (km)") +
  theme_minimal_grid(13)
ggsave("detect-radius.pdf", width=12, height=7, units="cm", path="./figures/")

  
 process_final_data <- function (final_df) {
  final_df <- final_df %>% 
    mutate(colonised.wp.140 = if_else(X.step. <= 140, 1, 0))
  
  final_df <- final_df %>% 
    mutate(colonised.wp.120 = if_else(X.step. <= 120, 1, 0))
  
  final_df <- final_df %>% 
    mutate(colonised.wp.100 = if_else(X.step. <= 100, 1, 0))
  
  final_df <- final_df %>% 
    mutate(colonised.wp.80 = if_else(X.step. <= 80, 1, 0))
  
  final_df <- final_df %>% 
    mutate(colonised.wp.60 = if_else(X.step. <= 60, 1, 0))
  
  final_df <- final_df %>% 
    mutate(colonised.wp.40 = if_else(X.step. <= 40, 1, 0))
  
  grouped_df = aggregate(cbind(colonised.wp, colonised.wp.140, colonised.wp.120, colonised.wp.100, colonised.wp.80, colonised.wp.60, colonised.wp.40)
                            ~ max.distance + colonisers.perwave, final_df, mean)
  grouped_df_long = gather(grouped_df, move.days, colonisation.prob, colonised.wp:colonised.wp.40, factor_key=TRUE)
  levels(grouped_df_long$move.days)[levels(grouped_df_long$move.days)=="colonised.wp"] <- "160"
  levels(grouped_df_long$move.days)[levels(grouped_df_long$move.days)=="colonised.wp.140"] <- "140"
  levels(grouped_df_long$move.days)[levels(grouped_df_long$move.days)=="colonised.wp.120"] <- "120"
  levels(grouped_df_long$move.days)[levels(grouped_df_long$move.days)=="colonised.wp.100"] <- "100"
  levels(grouped_df_long$move.days)[levels(grouped_df_long$move.days)=="colonised.wp.80"] <- "80"
  levels(grouped_df_long$move.days)[levels(grouped_df_long$move.days)=="colonised.wp.60"] <- "60"
  levels(grouped_df_long$move.days)[levels(grouped_df_long$move.days)=="colonised.wp.40"] <- "40"
  return(grouped_df_long)
}

final_data <- read.table("results/toads final-table.csv",
                          header = T,
                          sep = ",",
                          skip = 6,
                          quote = "\"",
                          fill = TRUE)

grouped_base <- process_final_data(final_data)
spread_df <- filter(grouped_base, move.days == 160)
ggplot(spread_df, aes(x=max.distance/10, y=colonisation.prob, group=colonisers.perwave)) +
  geom_line(aes(color=factor(colonisers.perwave)), size=1.1) +
  scale_x_continuous(breaks=seq(2,20,by=2))+
  labs(x="Distance (km)", y="Colonisation probability", color="Capacity (toads/day)") +
  theme_minimal_grid(13)
ggsave("spread-cap.pdf", width=15, height=7, units="cm", path="./figures/")


ggplot(spread_df, aes(x=max.distance, y=colonisers.perwave)) +
  geom_tile(aes(fill=colonisation.prob), size=1.1) +
  scale_fill_gradient2(low = "white", high = "seagreen1") +
  geom_text(aes(label=ifelse(colonisation.prob<=0 | colonisation.prob>0.995, sprintf("%0.0f", colonisation.prob), sprintf("%0.3f", colonisation.prob))),size=3) +
  scale_x_continuous(breaks=seq(20,200,by=20))+
  scale_y_continuous(breaks=seq(20,100,by=20))+
  labs(x="Distance", y="Capacity", fill="Colonisation probability") +
  theme_minimal_grid(13)

movedays_df <- filter(grouped_base, (move.days == 40 | move.days == 80 | move.days == 120 | move.days==160)
                      & colonisers.perwave == 60)
ggplot(movedays_df, aes(x=max.distance/10, y=colonisation.prob, group=move.days)) +
  geom_line(aes(color=factor(move.days)), size=1.1) +
  scale_x_continuous(breaks=seq(2,20,by=2))+
  labs(x="Distance (km)", y="Colonisation probability", color="Active days") +
  theme_minimal_grid(13)
ggsave("spread-activedays.pdf", width=13, height=7, units="cm", path="./figures/")


movedays_df <- filter(grouped_base, colonisers.perwave == 100)
movedays_df <- movedays_df %>% 
  mutate(colonisation.prob.100 = colonisation.prob * 100)
ggplot(movedays_df, aes(x=max.distance, y=move.days)) +
  geom_tile(aes(fill=colonisation.prob), size=1.1) +
  scale_fill_gradient2(low = "white", high = "seagreen1") +
  geom_text(aes(label=ifelse(colonisation.prob<=0.005 | colonisation.prob==1, sprintf("%0.0f", colonisation.prob), sprintf("%0.2f", colonisation.prob))),size=3) +
  scale_x_continuous(breaks=seq(20,200,by=20))+
  labs(x="Distance", y="Active days", fill="Colonisation probability") +
  theme_minimal_grid(13)
ggsave("spread-activedays-matrix.pdf", width=14, height=7, units="cm", path="./figures/")

write.csv(grouped_base,'toads final.csv')

final_fence_data <- read.table("results/toads final w fence 7-table.csv",
                               header = T,
                               sep = ",",
                               skip = 6,
                               quote = "\"",
                               fill = TRUE)
grouped_fence7 = process_final_data(final_fence_data)
write.csv(grouped_fence7,'toads final w fence 7.csv')

final_fence_data <- read.table("results/toads final w fence 30-table.csv",
                          header = T,
                          sep = ",",
                          skip = 6,
                          quote = "\"",
                          fill = TRUE)
grouped_fence30 = process_final_data(final_fence_data)
write.csv(grouped_fence30,'toads final w fence 30.csv')

final_fence_trap_data <- read.table("results/toads final w fence 30 trap dest 1-table.csv",
                               header = T,
                               sep = ",",
                               skip = 6,
                               quote = "\"",
                               fill = TRUE)
grouped_fence30_trap1 = process_final_data(final_fence_trap_data)
write.csv(grouped_fence30_trap1,'toads final w fence 30 trap dest 1.csv')

final_fence_trap_data <- read.table("results/toads final w fence 7 trap dest 1-table.csv",
                                    header = T,
                                    sep = ",",
                                    skip = 6,
                                    quote = "\"",
                                    fill = TRUE)
grouped_fence7_trap1 = process_final_data(final_fence_trap_data)
write.csv(grouped_fence7_trap1,'toads final w fence 7 trap dest 1.csv')

final_fence_trap_data <- read.table("results/toads final w fence 30 trap dest 2-table.csv",
                                    header = T,
                                    sep = ",",
                                    skip = 6,
                                    quote = "\"",
                                    fill = TRUE)
grouped_fence30_trap2 = process_final_data(final_fence_trap_data)
write.csv(grouped_fence30_trap2,'toads final w fence 30 trap dest 2.csv')

final_fence_trap_data <- read.table("results/toads final w fence 7 trap dest 2-table.csv",
                                    header = T,
                                    sep = ",",
                                    skip = 6,
                                    quote = "\"",
                                    fill = TRUE)
grouped_fence7_trap2 = process_final_data(final_fence_trap_data)
write.csv(grouped_fence7_trap2,'toads final w fence 7 trap dest 2.csv')

final_trap_data <- read.table("results/toads final w trap dest 1-table.csv",
                               header = T,
                               sep = ",",
                               skip = 6,
                               quote = "\"",
                               fill = TRUE)
grouped_trap1 = process_final_data(final_trap_data)
write.csv(grouped_trap1,'toads final w trap dest 1.csv')

final_trap_data <- read.table("results/toads final w trap dest 2-table.csv",
                              header = T,
                              sep = ",",
                              skip = 6,
                              quote = "\"",
                              fill = TRUE)
grouped_trap2 = process_final_data(final_trap_data)
write.csv(grouped_trap2,'toads final w trap dest 2.csv')


compare_control <- cbind(grouped_base, Trap=grouped_trap1[,"colonisation.prob"],
                         Fence=grouped_fence30[,"colonisation.prob"], Trap.and.Fence=grouped_fence30_trap1[,"colonisation.prob"])

cc_long <- compare_control[,4:7] %>% 
  gather(Method, Control.Prob, -colonisation.prob)

cc_long$Method <- factor(cc_long$Method, levels = unique(cc_long$Method))

ggplot(cc_long, aes(x=colonisation.prob, y=Control.Prob, color=Method)) +
  geom_point(size=3, alpha=0.4) +
  geom_abline(intercept=0,slope=1) +
  labs(x="Colonisation probability - no control", y="Colonisation probability - with control") +
  scale_color_manual(values=c("#F8766D", "#00BA38", "#619CFF"), labels=c("Trap", "Fence", "Trap and fence")) +
  theme_minimal_grid(13)
ggsave("trap-fence-impact.pdf", width=13, height=9, units="cm", path="./figures/")

compare_control <- cbind(grouped_base, Trap=grouped_trap2[,"colonisation.prob"],
                         Fence=grouped_fence7[,"colonisation.prob"], Trap.and.Fence=grouped_fence7_trap2[,"colonisation.prob"])
citation()
cc_long <- compare_control[,4:7] %>% 
  gather(Method, Control.Prob, -colonisation.prob)

cc_long$Method <- factor(cc_long$Method, levels = unique(cc_long$Method))

ggplot(cc_long, aes(x=colonisation.prob, y=Control.Prob, color=Method)) +
  geom_point(size=3, alpha=0.4) +
  geom_abline(intercept=0,slope=1) +
  labs(x="Colonisation probability - no control", y="Colonisation probability - with control") +
  theme_minimal_grid(13)

cc_long2 <- compare_control %>% 
  gather(Method, Control.Prob, -c(max.distance, colonisers.perwave, move.days))
cc_long2 <- filter(cc_long2, colonisers.perwave==100 & move.days==160 & max.distance %% 40 == 0 & max.distance < 200)
cc_long2 <- cc_long2 %>% 
  mutate(Method = if_else(Method == "colonisation.prob", "Without.Control", Method))
cc_long2$Method <- factor(cc_long2$Method, levels = unique(cc_long2$Method))
ggplot(cc_long2, aes(x=max.distance/10, y=Control.Prob, color=Method)) +
  geom_line(aes(color=Method), size = 1.1) +
  #scale_x_continuous(breaks=seq(20,200,by=20))+
  scale_color_manual(values=c("gray", "#F8766D", "#00BA38", "#619CFF"), labels=c("Without control", "Trap", "Fence", "Trap and fence")) +
  labs(x="Distance (km)", y="Colonisation probability", color="Control method") +
  theme_minimal_grid(13)
ggsave("trap-fence-distance.pdf", width=12, height=7, units="cm", path="./figures/")

