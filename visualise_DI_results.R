library(tidyverse)
library(cowplot)
library(ggridges)
library(glue)
library(ggseg)
library(broom)
library(ggseg)
theme_set(theme_cowplot())

gaussian_DI_res = read.csv("data/HCP100_Directed_Information.csv")
plot_path <- "~/Library/CloudStorage/OneDrive-TheUniversityofSydney(Students)/github/Directed_information_fMRI/figures/"

################################################################################
# Q1: Is there a region-wise gradient of overall DI values?
gaussian_DI_res %>%
  group_by(Sample_ID, Brain_Region) %>%
  summarise(mean_DI = mean(di_gaussian, na.rm=T)) %>%
  ungroup() %>%
  group_by(Brain_Region) %>%
  mutate(mean_region_DI = mean(mean_DI)) %>%
  ungroup() %>%
  mutate(Brain_Region = fct_reorder(Brain_Region, mean_DI, .fun=mean)) %>%
  ggplot(data=., mapping=aes(y=Brain_Region, x=mean_DI, fill=mean_region_DI)) +
  geom_violin(scale="width") +
  geom_boxplot(width=0.1, fill=NA, outlier.shape = NA, color="white",lwd=0.3) +
  theme(legend.position="none") +
  xlab("Mean DI") +
  ylab("Cortical region") +
  scale_fill_viridis_c(na.value = "white")
ggsave(glue("{plot_path}/Mean_DI_by_region_violins.svg"),
       height=7, width=4.5, units="in", dpi=300)

# Let's plot this in the brain
mean_DI_by_region <- gaussian_DI_res %>%
  group_by(Brain_Region) %>%
  summarise(mean_DI = mean(di_gaussian, na.rm=T),
            sd_DI = sd(di_gaussian, na.rm=T)) %>%
  ungroup() %>%
  mutate(label = glue("lh_{Brain_Region}")) %>%
  left_join(., as_tibble(dk)) 

mean_DI_by_region %>%
  ggseg(atlas = dk, mapping = aes(fill = mean_DI),
        position = "stacked", colour = "gray20", hemisphere="left") +
  theme_void() +
  labs(fill = "Mean DI") +
  theme(plot.title = element_blank(),
        legend.position = "bottom") +
  scale_fill_viridis_c(na.value = "white")
ggsave(glue("{plot_path}/Mean_DI_by_region_ggseg.svg"),
       height=4, width=2.5, units="in", dpi=300)

################################################################################
# Q1: Within each hemisphere, is there a gradient of DI values to/from across brain regions?

# Split by hemisphere TO
gaussian_DI_res %>%
  mutate(Brain_Region = fct_reorder(Brain_Region, di_gaussian, .fun=mean)) %>%
  ggplot(data=., mapping=aes(y=Brain_Region, x=di_gaussian, fill=Brain_Region)) +
  geom_density_ridges(scale = 1.5) +
  theme(legend.position="none") +
  facet_grid(. ~ Hemi_to)

# Split by hemisphere FROM
gaussian_DI_res %>%
  mutate(Brain_Region = fct_reorder(Brain_Region, di_gaussian, .fun=mean)) %>%
  ggplot(data=., mapping=aes(y=Brain_Region, x=di_gaussian, fill=Brain_Region)) +
  geom_density_ridges(scale = 1.5) +
  theme(legend.position="none") +
  facet_grid(. ~ Hemi_from)

# A: YES there is a striking gradient from the entorhinal cortex (lowest DI) to the lateral occipital cortex (highest).
# Would be interesting to double click on these regions -- do they follow a hierarchy of e.g. sensory-fugal axis?
# Are they related to Yeo functional networks?
# Any differences in cortical thickness in these regions?
# Sensitivity analysis: what does the Pearson correlation ranking look like between the L/R for these regions?
# Does gaussian DI follow similar trends to that of Pearson correlation?
# An interesting follow-up for me and Ben would be to also compute DI_Gaussian between all 68 pairs of brain regions 
# And see if a similar pattern emerges -- which brain regions are most connected to the rest of the brain?
# We should visualize this hierarchy on the brain map

gaussian_DI_res %>%
  group_by(Brain_Region) %>%
  summarise(mean_DI = mean(di_gaussian)) %>%
  arrange(desc(mean_DI)) %>%
  mutate(DI_rank = row_number()) %>%
  mutate(label = glue("lh_{Brain_Region}")) %>%
  ggseg(atlas = dk, mapping = aes(fill=DI_rank),
        position = "stacked", colour = "gray50", hemisphere="left") +
  scale_fill_viridis_c(direction=-1) +
  theme_void() +
  theme(plot.title = element_blank()) 


################################################################################
# Q2: What is the asymmetry in DI between left-right hemispheres?

# What is the difference in DI by brain region?
region_DI_subtract_diffs <- gaussian_DI_res %>%
  group_by(Sample_ID, Brain_Region) %>%
  summarise(DI_LR = di_gaussian[Hemi_from=="left"],
            DI_RL = di_gaussian[Hemi_from=="right"]) %>%
  rowwise() %>%
  mutate(RL_minus_LR = DI_RL - DI_LR) %>%
  ungroup() %>%
  group_by(Brain_Region) %>%
  mutate(mean_RL_minus_LR = mean(RL_minus_LR),
         sd_RL_minus_LR = sd(RL_minus_LR)) %>%
  ungroup() %>%
  mutate(Brain_Region = fct_reorder(Brain_Region, mean_RL_minus_LR, .fun=median))

region_DI_subtract_diffs %>%
  ggplot(data=., mapping=aes(y=Brain_Region, x=RL_minus_LR, fill=mean_RL_minus_LR)) +
  geom_violin(scale="width") +
  geom_boxplot(width=0.1, lwd=0.7, outlier.shape=NA, color="gray60") +
  scale_fill_gradient2(high="#f47599", low="#5dc636", mid="white") +
  geom_vline(xintercept=0, linetype=2) +
  theme(legend.position="none")+
  xlab("R\u2192L minus L\u2192R DI") +
  ylab("Cortical region")
ggsave(glue("{plot_path}/RL_minus_LR_violins.svg"),
       height=7, width=4.5, units="in", dpi=300)

# Plot density distributions for left and right hemisphere per brain region
gaussian_DI_res %>%
  mutate(flow_dir = ifelse(Hemi_from=="right", "RL", "LR"),
         Brain_Region = factor(Brain_Region, levels=rev(levels(region_DI_subtract_diffs$Brain_Region)))) %>%
  ggplot(data=., mapping=aes(x=di_gaussian, color=flow_dir, fill=flow_dir)) +
  geom_density(alpha=0.2) +
  facet_wrap(Brain_Region ~ ., scales="free",
             ncol=5) +
  xlab("DI Gaussian") +
  ylab("Density") +
  scale_color_manual(values=c("RL"="#f47599", "LR"="#5dc636")) +
  scale_fill_manual(values=c("RL"="#f47599", "LR"="#5dc636")) +
  theme(axis.text.y = element_blank(),
        axis.ticks.y = element_blank())
ggsave(glue("{plot_path}/DI_distributions_by_region_density.svg"),
       height=9, width=9, units="in", dpi=300)

# Plot in the brain
region_DI_subtract_diffs %>%
  distinct(Brain_Region, mean_RL_minus_LR) %>%
  mutate(label = glue("lh_{Brain_Region}")) %>%
  left_join(., as_tibble(dk)) %>%
  ggseg(atlas = dk, mapping = aes(fill = mean_RL_minus_LR),
        position = "stacked", colour = "gray20", hemisphere="left") +
  theme_void() +
  scale_fill_gradient2(high="#f47599", low="#5dc636", mid="white", na.value = "white") +
  labs(fill = "Mean RL minus LR DI") +
  theme(plot.title = element_blank(),
        legend.position = "bottom")
ggsave(glue("{plot_path}/Mean_RL_minus_LR_by_region_ggseg.svg"),
       height=4, width=2.5, units="in", dpi=300)

################################################################################
# Paired T-test?
paired_T_test_res <- gaussian_DI_res %>%
  group_by(Sample_ID, Brain_Region) %>%
  summarise(DI_LR = di_gaussian[Hemi_from=="left"],
            DI_RL = di_gaussian[Hemi_from=="right"]) %>%
  pivot_longer(cols=c(DI_LR, DI_RL),
               names_to="Metric", values_to="Value") %>%
  group_by(Brain_Region) %>%
  nest() %>%
  mutate(
    test = map(data, ~ t.test(Value ~ Metric, data=.x, paired = TRUE)), # S3 list-col
    tidied = map(test, tidy)
  ) %>%
  unnest(tidied) %>%
  dplyr::select(Brain_Region, estimate, p.value) %>%
  ungroup() %>%
  mutate(p_val_Bonferroni = p.adjust(p.value, method="bonferroni"))


# Plot t-statistic distribution
paired_T_test_res %>%
  mutate(Brain_Region = fct_reorder(Brain_Region, estimate)) %>%
  mutate(est_fill = ifelse(p_val_Bonferroni<0.05, estimate, NA_real_)) %>%
  ggplot(data=., mapping=aes(y=Brain_Region, x=estimate, fill=est_fill)) +
  geom_bar(stat="identity")

gaussian_DI_res %>%
  group_by(Sample_ID, Brain_Region) %>%
  summarise(Left_vs_Right_Diff = (di_gaussian[Hemi_from=="left"] - di_gaussian[Hemi_from=="right"]) / abs(di_gaussian[Hemi_from=="left"] + di_gaussian[Hemi_from=="right"])) %>%
  ungroup() %>%
  mutate(Brain_Region = fct_reorder(Brain_Region, Left_vs_Right_Diff)) %>%
  ggplot(data=., mapping=aes(x=Brain_Region, y=Left_vs_Right_Diff)) +
  geom_violin(scale = "width")
