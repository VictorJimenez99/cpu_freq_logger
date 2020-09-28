library(ggplot2)
library(tibble)
library(dplyr)
library(readr)
library(patchwork)
#Data in ----
ds<-read_csv("freq_log.csv")
#plotting ----
general <- ggplot(ds) + 
  geom_line(aes(x=sample_id, y=freq, col = cpu_id))+ 
  facet_wrap(~cpu_id) + 
  xlab("Miliseconds") + ylab("Frequency") + 
  scale_y_continuous()+ ggtitle("Benchmark") +
  theme(legend.position = "none")

ggsave("Benchmark.png", plot = general,width = 30, height = 5)

samples <- max(ds$sample_id);

sub_sec <- ds %>% filter(sample_id > samples*.9 & samples)
sub_sec <- ggplot(sub_sec) + 
  geom_line(aes(x=sample_id, y=freq, col = cpu_id)) + 
  facet_wrap(~cpu_id) +
  ggtitle("Last 10% of samples") + 
  xlab("Miliseconds") + ylab("Frequency") + 
  scale_y_continuous() +
  theme(legend.position = "none")  

ggsave("last_10_percent.png", plot = sub_sec, width = 10, height = 5)

final<-general/sub_sec 
final <- final + theme(legend.position = "none")


ggsave("result.png", plot = final)

