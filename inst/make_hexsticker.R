library(epinowcast)
library(hexSticker)
library(sysfonts)
library(ggplot2)

# font setup
font_add_google("Zilla Slab Highlight", "useme")

# get example output
nowcast <- enw_example("nowcast")
obs <- enw_example("observations")

# make standard plot
plot <- summary(nowcast)[, mean := NA] |>
  enw_plot_nowcast_quantiles(
    latest = obs[reference_date >= (max(reference_date) - 19)]
  )

# strip out most of the background
hex_plot <- plot +
  scale_x_continuous(breaks = NULL) +
  scale_y_continuous(breaks = NULL) +
  labs(x = "", y = "") +
  theme_void() +
  theme_transparent() +
  theme(legend.position = "none",
        panel.background = element_blank())

# make and save hexsticker
sticker(
  hex_plot,
  package = "epinowcast",
  p_size = 23,
  p_color = "#646770",
  s_x = 1,
  s_y = .85,
  s_width = 1.3,
  s_height = 0.85,
  h_fill = "#ffffff",
  h_color = "#646770",
  filename = "./man/figures/logo.png",
  url = "epinowcast.org",
  u_color = "#646770",
  u_size = 3.5
)
