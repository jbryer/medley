usethis::use_tidy_description()
devtools::document()
devtools::install()
devtools::check(cran = TRUE)

tools::checkRdaFiles("data/")

##### pkgdown site
# usethis::use_pkgdown()
pkgdown::build_site()
# usethis::use_github_action('check-standard')

# usethis::use_package('reshape2', type = 'imports')
# usethis::use_package('kableExtra', type = 'suggests')

#### Data setup
source('data-raw/daacs/data-prep.R')
source('data-raw/nhis/data-prep.R')
