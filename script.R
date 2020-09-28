library(ggplot2)
library(tibble)
library(dplyr)
library(readr)
library(patchwork)
#Data in ----
ds<-read_csv("freq_log.csv")
#plotting ----
general<-ggplot(ds) + geom_line(aes(x=sample_id, y=freq, col = cpu_id))+ facet_wrap(~cpu_id)+
  theme(legend.position = "none") + xlab("Miliseconds") + ylab("Frequency") + 
  scale_y_continuous()


samples <- max(ds$sample_id);

sub_sec <- ds %>% filter(sample_id > samples*.9 & samples)
sub_sec <- ggplot(sub_sec) + geom_line(aes(x=sample_id, y=freq, col = cpu_id))+ facet_wrap(~cpu_id)+
  theme(legend.position = "none") + xlab("Miliseconds") + ylab("Frequency") + 
  scale_y_continuous()

final<-general/sub_sec 
final & theme(legend.position = "none")

