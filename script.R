library(ggplot2)
library(tibble)
suppressMessages(library(dplyr, quietly = TRUE))
library(readr)
library(patchwork)
#detach("package:dplyr", unload = T)

#Data in ----
# Specify data_in
col_type <-
  cols(cpu_id = col_character(),
       freq = col_double(),
       sample_id = col_double(),
       time_passed = col_factor())

ds <- read_csv("freq_log.csv" , col_types = col_type)
rm("col_type")
#plotting ----


general <- ggplot(ds) +
  scale_y_continuous(breaks = seq(floor(min(ds$freq)), ceiling(max(ds$freq)), .5) , limits = c(0,ceiling(max(ds$freq))) ) +
  scale_x_continuous(breaks = waiver()) +
  geom_line(aes(x = sample_id, y = freq, col = cpu_id)) +
  facet_wrap(~ cpu_id) +
  xlab("Sample") + ylab("Frequency") +
  ggtitle("Benchmark") +
  theme(legend.position = "none")

ggsave("benchmark.png",
       plot = general,
       width = 30,
       height = 5)


#data----

# Create a tibble with the mean frequency per second
grouped<-ds %>% group_by(cpu_id,time_passed) 
grouped<-summarise(grouped, mean(freq), .groups = "keep")
grouped <- grouped %>% rename(mean = `mean(freq)`)
grouped$time_passed = as.numeric(grouped$time_passed)-1

#obtain scale
xscale <- seq(min(grouped$time_passed), max(grouped$time_passed),(max(grouped$time_passed + 1)/4))
#xscale <- head(xscale, -1)
xscale <- c(xscale,max(grouped$time_passed))

yscale <- seq(floor(min(ds$freq)),ceiling(max(ds$freq)),.5)

by_sec <- ggplot(grouped) + 
  scale_x_time(breaks = xscale) +
  scale_y_continuous(breaks = yscale , limits = c(0,ceiling(max(ds$freq))) ) +  
  geom_line(aes(time_passed, mean, col=cpu_id)) + 
  facet_wrap(~cpu_id) + 
  xlab("Time") + 
  ylab("Frequency") + 
  ggtitle("Time ~ Mean Frequency") +
  theme(legend.position = "none")



ggsave(
  "benchmark_by_seconds.png",
  plot = by_sec,
  width = 10,
  height = 5
)

difference <- general / by_sec

ggsave(
  "benchmark_real_vs_mean.png",
  plot = difference,
  width = 10,
  height = 5
)


