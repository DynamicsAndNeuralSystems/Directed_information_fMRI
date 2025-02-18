
################################################################################
# How do directed SPI values differ to vs. from each brain region across cohorts?
if (!(file.exists(glue("{data_path}/pyspi14_directed_to_vs_from_regions_by_group.feather")))) {
  UCLA_CNP_pyspi14 <- pyarrow_feather$read_feather("~/data/UCLA_CNP/processed_data/UCLA_CNP_AROMA_2P_GMR_pyspi14_filtered.feather")  %>%
    left_join(., UCLA_CNP_metadata) %>%
    filter(!is.na(Diagnosis))
  ABIDE_ASD_pyspi14 <- pyarrow_feather$read_feather("~/data/ABIDE_ASD/processed_data/ABIDE_ASD_FC1000_pyspi14_filtered.feather")  %>%
    left_join(., ABIDE_ASD_metadata) %>%
    filter(!is.na(Diagnosis))
  merged_pyspi14 <- plyr::rbind.fill(UCLA_CNP_pyspi14, ABIDE_ASD_pyspi14) 
  
  rm(UCLA_CNP_pyspi14)
  rm(ABIDE_ASD_pyspi14)
  
  # Iterate over each DIRECTED SPI
  for (directed_SPI in SPI_info %>% filter(Directed=="Yes") %>% pull(pyspi_name)) {
    directed_SPI_data <- subset(merged_pyspi14, SPI==directed_SPI)
    
    # For each brain region, compute the 
  }
  
  cor_list <- list()
}

pyspi14_lm_beta_coefficients %>%
  separate(Region_Pair, into=c("From", "To"), sep="_") %>%
  dplyr::select(Comparison_Group, SPI, From, To, estimate) %>%
  pivot_longer(cols=c(From, To), names_to="Direction", values_to="Brain_Region") %>%
  group_by(Comparison_Group, SPI, Brain_Region, Direction) %>%
  summarise(mean_estimate = mean(abs(estimate)),
            sd_estimate = sd(abs(estimate))) %>%
  left_join(., SPI_info, by=c("SPI"="pyspi_name")) %>%
  filter(Directed=="Yes") %>%
  mutate(Comparison_Group = factor(Comparison_Group, levels = c("SCZ", "BP", "ADHD", "ASD"))) %>%
  ggplot(data=., mapping=aes(x=Direction, y=mean_estimate, group=Brain_Region, color=Comparison_Group)) +
  geom_line(alpha=0.8) +
  facet_grid(Figure_name ~ Comparison_Group, switch="y", space="free") +
  scale_color_manual(values = c("SCZ"="#573DC7", 
                                "BP"="#D5492A", 
                                "ADHD"="#0F9EA9",
                                "ASD"="#C47B2F")) +
  ylab("Mean |\u03b2| per Region") +
  scale_x_discrete(expand=c(0.1,0.1)) +
  theme(legend.position = "none",
        axis.text.y = element_text(size=10),
        strip.text = element_text(angle=0, face="bold"),
        strip.text.y.left = element_text(angle=0, face="bold"),
        strip.placement = "outside",
        strip.background = element_blank())
ggsave(glue("{plot_path}/pyspi14_SPI_beta_coefficients_directed_SPIs.svg"),
       width=7, height=6, units="in", dpi=300)

################################################################################
# How do lm beta coefficients differ TO vs. FROM each region for the directed SPIs?

pyspi14_lm_beta_coefficients %>%
  separate(Region_Pair, into=c("From", "To"), sep="_") %>%
  dplyr::select(Comparison_Group, SPI, From, To, estimate) %>%
  pivot_longer(cols=c(From, To), names_to="Direction", values_to="Brain_Region") %>%
  group_by(Comparison_Group, SPI, Brain_Region, Direction) %>%
  summarise(mean_estimate = mean(abs(estimate)),
            sd_estimate = sd(abs(estimate))) %>%
  left_join(., SPI_info, by=c("SPI"="pyspi_name")) %>%
  filter(Directed=="Yes") %>%
  mutate(Comparison_Group = factor(Comparison_Group, levels = c("SCZ", "BP", "ADHD", "ASD"))) %>%
  ggplot(data=., mapping=aes(x=Direction, y=mean_estimate, group=Brain_Region, color=Comparison_Group)) +
  geom_line(alpha=0.8) +
  facet_grid(Figure_name ~ Comparison_Group, switch="y", space="free") +
  scale_color_manual(values = c("SCZ"="#573DC7", 
                                "BP"="#D5492A", 
                                "ADHD"="#0F9EA9",
                                "ASD"="#C47B2F")) +
  ylab("Mean |\u03b2| per Region") +
  scale_x_discrete(expand=c(0.1,0.1)) +
  theme(legend.position = "none",
        axis.text.y = element_text(size=10),
        strip.text = element_text(angle=0, face="bold"),
        strip.text.y.left = element_text(angle=0, face="bold"),
        strip.placement = "outside",
        strip.background = element_blank())
ggsave(glue("{plot_path}/pyspi14_SPI_beta_coefficients_directed_SPIs.svg"),
       width=7, height=6, units="in", dpi=300)
