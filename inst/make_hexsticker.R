library(epinowcast)
library(ggpubr)
library(hexSticker)
library(sysfonts)
library(ggplot2)

# font setup
font_add_google("Zilla Slab Highlight", "useme")

# get example output
nowcast <- enw_example("nowcast")
obs <- enw_example("observations")

# make standard plot
plot <- plot(
  nowcast,
  latest = obs[reference_date >= (max(reference_date) - 19)]
)

hex_plot <- plot +
  scale_x_continuous(breaks = NULL) +
  scale_y_continuous(breaks = NULL) +
  labs(x = "", y = "") +
  theme_void() +
  theme_transparent() +
  theme(legend.position = "none",
        panel.background = element_blank())

sticker(hex_plot,
        package = "epinowcast",
        p_size = 23,
        p_color = "#646770",
        s_x = 1,
        s_y = .8,
        s_width = 1.5,
        s_height = 0.7,
        h_fill = "#646770",
        h_color = "#ffffff",
        filename = "./man/figures/logo.png",
        url = "epiforecasts.io/epinowcast",
        u_color = "#646770",
        u_size = 3.5)