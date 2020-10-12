cat("loading libraries...\n")
library(ggplot2)
library(tibble)
suppressMessages(library(dplyr, quietly = TRUE))
library(readr)
library(patchwork)
cat("Done\n")

args<-commandArgs(trailingOnly = T)
dir <- args[1]
dir <- paste(dir,"/", sep = "")
if(dir == "NA/")
{
  dir<-"./"
}

MAX_SAMPLES <- 15000
#Data in ----
# Specify data_in
col_type <-
  cols(cpu_id = col_character(),
       freq = col_double(),
       sample_id = col_double(),
       time_passed = col_factor())

cat("Reading .csv file...\n")

ds <- read_csv(paste(dir,"freq_log.csv",sep="") , col_types = col_type)
rm("col_type","args")
#plotting ----

cat("Formatting data...\n")
ds$freq = ds$freq/1000000


#data----

# Create a tibble with the mean frequency per second
cat("Mutating and extracting data...\n")
grouped<-ds %>% group_by(cpu_id,time_passed) 
grouped<-summarise(grouped, mean(freq), .groups = "keep")
grouped <- grouped %>% rename(mean = `mean(freq)`)
grouped$time_passed = as.numeric(grouped$time_passed)-1




write.csv(grouped,file = paste(dir,"mean_freq_per_sec.csv",sep = ""),row.names = F)


cat("Generating plots\n")

#Plotting ----
if(max(ds$sample_id) < MAX_SAMPLES) {
  general <- ggplot(ds) +
    scale_y_continuous(breaks = seq(floor(min(ds$freq)), ceiling(max(ds$freq)), .5) ,
                       limits = c(floor(min(ds$freq)), ceiling(max(ds$freq)))) +
    scale_x_continuous() +
    geom_line(aes(x = sample_id, y = freq, col = cpu_id)) +
    facet_wrap(~ cpu_id) +
    xlab("Sample") + ylab("Frequency") +
    ggtitle("Benchmark") +
    theme(legend.position = "none")
  
  ggsave(
    paste(dir, "benchmark.png", sep = ""),
    plot = general,
    width = 30,
    height = 5
  )
  
} else {
  cat("Sampling time was too long to plot every measurement...Skipping Samples-plot...\n")
}




#obtain scale
xscale <-
  seq(min(grouped$time_passed), max(grouped$time_passed),
      (max(grouped$time_passed + 1) / 4))
xscale <- trunc(xscale)
#xscale <- head(xscale, -1)
xscale <- c(xscale, max(grouped$time_passed))

yscale <- seq(floor(min(ds$freq)),ceiling(max(ds$freq)) + .5,.5)
h  <-length(unique(grouped$cpu_id))/2

unique_cpus <- unique(grouped$cpu_id)
improved_df <- tibble(x=c(), y=c(), cpu_id=c())

for (cpu_name in unique_cpus) {
  cur_cpu <- grouped %>% filter(cpu_id == cpu_name)
  spline_cpu <-
    as.data.frame(spline(cur_cpu$time_passed, cur_cpu$mean))
  spline_cpu$cpu_id <- cur_cpu$cpu_id
  
  improved_df <- bind_rows(improved_df, spline_cpu)
}


by_sec <- ggplot(grouped) +
  scale_x_time(breaks = xscale) +
  scale_y_continuous(breaks = seq(floor(min(ds$freq)), ceiling(max(ds$freq)) + .5 , .5) ,
                     limits = c(floor(min(ds$freq)), ceiling(max(ds$freq)) + .5)) +
  geom_line(data = improved_df, aes(x, y, col = cpu_id)) +
  geom_point(aes(x = time_passed, y = mean, color = cpu_id), size = .15) +
  facet_wrap( ~ cpu_id) +
  xlab("Time") +
  ylab("Frequency") +
  ggtitle("Time ~ Mean Frequency") +
  theme(legend.position = "none")
ggsave(
  paste(dir, "spline_mean_freq.png", sep = ""),
  plot = by_sec,
  width = 15,
  height = 2 * h
)


every_cpu_plot <- ggplot(grouped) +
  scale_x_time(breaks = xscale) +
  geom_line(data = improved_df, aes(x, y, col = cpu_id)) +
  geom_point(aes(x = time_passed, y = mean, color = cpu_id), size = .15) +
  xlab("Time") +
  ylab("Frequency") +
  ggtitle("Time ~ Mean Frequency") +
  theme(legend.position = "none")
ggsave(
  paste(dir, "mean_freq_combined.png", sep = ""),
  plot = every_cpu_plot,
  width = 15,
  height = 2 * h
)


if(max(ds$sample_id) < MAX_SAMPLES) {
  difference <- general / by_sec
  
  
  ggsave(
    paste(dir, "benchmark_real_vs_mean.png", sep = ""),
    plot = difference,
    width = 20,
    height = 10
  )
}
cat("The Script executed without any problems...\n")







