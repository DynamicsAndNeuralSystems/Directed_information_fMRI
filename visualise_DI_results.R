library(tidyverse)
librar
library(cowplot)
theme_set(theme_cowplot())

gaussian_DI_res = read.csv("data/HCP100_Directed_Information.csv")

# Split by hemisphere
gaussian_DI_res %>%
  mutate(Brain_Region = fct_reorder(Brain_Region, di_gaussian, .fun=mean)) %>%
  ggplot(data=., mapping=aes(y=Brain_Region, x=di_gaussian, fill=Brain_Region)) +
  geom_density_ridges(scale = 1.5) +
  theme(legend.position="none") +
  facet_grid(. ~ Hemi_to)

# Split by hemisphere
gaussian_DI_res %>%
  mutate(Brain_Region = fct_reorder(Brain_Region, di_gaussian, .fun=mean)) %>%
  ggplot(data=., mapping=aes(y=Brain_Region, x=di_gaussian, fill=Brain_Region)) +
  geom_density_ridges(scale = 1.5) +
  theme(legend.position="none") +
  facet_grid(. ~ Hemi_to)