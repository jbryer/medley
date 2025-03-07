usethis::use_tidy_description()
devtools::document()
devtools::install()
devtools::check(cran = TRUE)

##### pkgdown site
# usethis::use_pkgdown()
pkgdown::build_site()
usethis::use_github_action('check-standard')

usethis::use_package('reshape2', type = 'imports')
usethis::use_package('kableExtra', type = 'suggests')

#### Data setup
source('data-raw/daacs-data-prep.R')


#### Hex Logo
library(hexSticker)
sticker(
	filename = "man/figures/medley.png",
	subplot = "man/figures/fruit_medley.png",
	s_x = 1,
	s_y = 1,
	s_width = 1,
	s_height = 1,
	package = "medley",
	p_color = "#FFFFFF",
	p_size = 24,
	p_family = "sans",
	p_fontface = "bold",
	p_x = 1,
	p_y = 1.1,
	white_around_sticker = TRUE,
	h_color = "#7DBA37",
	h_fill = "#F5DDAF",
	url = "github.com/jbryer/medley",
	# u_family = 'sans',
	u_color = "#F05364",
	u_size = 6
)
