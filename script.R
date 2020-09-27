library(tidyverse)
#Data in ----
ds<-read_csv("freq_log.csv")
#plotting ----
ggplot(ds) + geom_line(aes(x=log_id, y=freq, col = cpu_id))+ facet_wrap(~cpu_id)+
  theme(legend.position = "none") + xlab("Miliseconds") + ylab("Frequency") + 
  scale_y_continuous(limits = c(0,2))

