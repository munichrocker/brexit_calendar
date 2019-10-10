# Make a calendar with Annotations in R

Shows the code to produce a annotated calendar in ggplot.

I was inspired by an BBC News graphic that showed a calendar with Dates relevant to the Brexit, that got updated each time, something new happened. See for example [here](https://www.bbc.co.uk/news/uk-politics-32810887).

I was trying to recreate that calendar in a form that stays flexible for other use cases. This was a very quick and dirty solution, so please don't expect something extensive.

![](desktop.png)

## The data

### Generally

The calendar is drawn from a csv which contains the whole month we want to show. The data comes in the following form:

| date     | category              | text                   | text_kalenderwoche | pfeil_kalenderwoche | pfeil_day_of_week |
|----------|-----------------------|------------------------|--------------------|---------------------|-------------------|
| 01.10.19 | Parlament tagt        |                        |                    |                     |                   |
| 02.10.19 | Parlament tagt        |                        |                    |                     |                   |
| 03.10.19 | Parlament tagt        |                        |                    |                     |                   |
| 04.10.19 | Parlament tagt nicht  |                        |                    |                     |                   |
| 05.10.19 | Parlament tagt nicht  |                        |                    |                     |                   |

* __date__ sets the calendar date. Currently the script is set to a German format.
* __category__ sets the fill category of the calendar. In this example: If the HoC is sitting, or not or if it's prorogued.
* __text__ contains the label that belongs to this date. It doesn't make use of that information yet, as yu still have to set the label's position manually in the next columns:
* __text_kalenderwoche__ is the week of the year (iso) where the label shows up
* __pfeil_kalenderwoche__ is the week of the year where the line will go, while
* __pfeil_day_of_week__ is the day of the week (starting at `1 = Monday`) to which the line will point.

### Examples

These lines have been extracted to provide as an example for the lines.

* `Parlament suspendiert` will be placed in week 40, its line will target the second cell on the week after that (a Tuesday).
* `Sondersitzung` is placed in week 43, while its line points to Saturday the week before.
* `geplantes Brexit-Datum` creates a horizontal line, where everything stays in week 44.


| date     | category              | text                   | text_kalenderwoche | pfeil_kalenderwoche | pfeil_day_of_week |
|----------|-----------------------|------------------------|--------------------|---------------------|-------------------|
| 08.10.19 | Parlament tagt        | Parlament suspendiert  | 40                 | 41                  | 2                 |
| 19.10.19 | Parlament tagt        | Sondersitzung          | 43                 | 42                  | 6                 |
| 31.10.19 | Austrittstermin       | geplantes Brexit-Datum | 44                 | 44                  | 4                 |

## The script

Is basically self-explanatory.

We first load the data from the csv and create some new variables from the dates that we need for plotting:

```
calendar_data %>% 
  mutate(weekday = weekdays(date, abbreviate = TRUE),
         week_num = isoweek(date),
         day = str_extract(date, "\\d+$"),
         day_label = format(date, "%d. %b."),
         category = factor(category, levels = c("Parlament tagt", "Parlament tagt nicht", "Parlament suspendiert", "Austrittstermin"))) -> calendar_data
```

We then create a simple ggplot with `geom_tile()`, until now without any annotations.

```
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
```

These annotations will be added in the for loop. It adds `geom_text()` with the dates and labels and `geom_segment()` for the lines to the plot - one after another. The script recognizes, if the values in `text_kalenderwoche` and `pfeil_kalenderwoche` differ and will adapt the line accordingly.

```
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
```

## Roadmap

This plot hasn't been tested with multiple months yet.

If it will be deployed for multiple projects it might be worth to adapt the function to place the labels based on the dates, not Week and day numbers.


