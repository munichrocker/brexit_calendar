library(tidyverse)
library(lubridate)
library(extrafont)

# load prerequistes

font_family <- "SZSansDigital"
font_family_light <- "SZSansDigital Light"
nudge_x_preset <- 2 # make it 3 for mobile plot

color_code <- c("Parlament tagt" = "#019bd4", "Parlament tagt nicht" = "#aed5e7", 
                "Parlament suspendiert" = "#f8d770", "Austrittstermin" = "#dd5045")

# load data, transform as Date

calendar_data <- read.csv("brexit_calender.csv")
calendar_data$date <- as.Date(calendar_data$date, format = "%d.%m.%y")

# Calculate different values from the data

calendar_data %>% 
  mutate(weekday = weekdays(date, abbreviate = TRUE),
         week_num = isoweek(date),
         day = str_extract(date, "\\d+$"),
         day_label = format(date, "%d. %b."),
         category = factor(category, levels = c("Parlament tagt", "Parlament tagt nicht", "Parlament suspendiert", "Austrittstermin"))) -> calendar_data

# create plot without annotations, that we can later build on top

plot <- ggplot(calendar_data, aes(weekday, week_num, fill = category)) +
  geom_tile(aes(fill = category), color = "white") + 
  scale_x_discrete(limits = c("Mo", "Di", "Mi", "Do", "Fr", "Sa", "So")) +
  scale_y_reverse(breaks = NULL) +
  scale_fill_manual(values = color_code) +
  coord_cartesian(clip = "off") +
  theme(panel.background = element_blank(),
        plot.margin = margin(1, 15, 1, 1, unit = "lines"),
        legend.position = c(0,1),
        legend.title = element_blank(),
        legend.direction = "horizontal",
        legend.margin = margin(20, 0, 20, 400),
        axis.title = element_blank(),
        axis.text = element_text(family = font_family_light),
        axis.ticks = element_blank())

# prepare labels

calendar_data %>% 
  filter(text != "") -> calendar_labels

# loop over labels and add them to plot with lines

for (i in 1:nrow(calendar_labels)) {
  current_row <- calendar_labels[i,]
  
  print(current_row$day_label)
  
  plot +
    geom_text(aes_(x = 8, y = current_row$text_kalenderwoche, label = current_row$day_label, hjust = 0, family = font_family, fontface = "bold"), nudge_x = 0.5) +
    geom_text(aes_(x = 8, y = current_row$text_kalenderwoche, label = current_row$text, hjust = 0, family = font_family_light), nudge_x = nudge_x_preset) -> plot
  
  if (current_row$pfeil_kalenderwoche > current_row$text_kalenderwoche) {
    print("Kalenderwoche > Textwoche")
    
    plot +
      geom_segment(aes_(x = 8, y = current_row$text_kalenderwoche, xend = current_row$pfeil_day_of_week, yend = current_row$text_kalenderwoche), colour = "#000000", size = 0.5) +
      geom_segment(aes_(x = current_row$pfeil_day_of_week, y = current_row$text_kalenderwoche, xend = current_row$pfeil_day_of_week, yend = (current_row$text_kalenderwoche + 0.75)), colour = "#000000", size = 0.5) -> plot
    
  } else if (current_row$pfeil_kalenderwoche < current_row$text_kalenderwoche) {
    
    print("Kalenderwoche < Textwoche")
    
    plot +
      geom_segment(aes_(x = 8, y = current_row$text_kalenderwoche, xend = current_row$pfeil_day_of_week, yend = current_row$text_kalenderwoche), colour = "#000000", size = 0.5) +
      geom_segment(aes_(x = current_row$pfeil_day_of_week, y = current_row$text_kalenderwoche, xend = current_row$pfeil_day_of_week, yend = (current_row$text_kalenderwoche - 0.75)), colour = "#000000", size = 0.5) -> plot
    
    
  } else {
    print("Kalenderwoche = Textwoche")
    
    plot +
      geom_segment(aes_(x = 8, y = current_row$text_kalenderwoche, xend = current_row$pfeil_day_of_week, yend = current_row$pfeil_kalenderwoche), colour = "#000000", size = 0.5) -> plot
    
  }
}

# print finished plot

plot

# save plot for desktop and mobile

ggsave(filename = "desktop.png", dpi = 144, width = 8.89, height = 6)

ggsave(filename = "mobile.png", dpi = 144, width = 6, height = 5)




