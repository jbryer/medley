
<!-- README.md is generated from README.Rmd. Please edit that file -->

# medley: Predictive Modeling with Missing Data

<!-- badges: start -->

[![](https://www.r-pkg.org/badges/version/medley?color=orange)](https://cran.r-project.org/package=medley)
[![](https://img.shields.io/badge/devel%20version-0.9.0-blue.svg)](https://github.com/jbryer/medley)
[![R build
status](https://github.com/jbryer/medley/workflows/R-CMD-check/badge.svg)](https://github.com/jbryer/medley/actions)
<!-- badges: end -->

The goal of medley is to provide a framework for training predictive
models where there is a systematic pattern of missing data. For example,
situations where baseline data may be available but as time progresses
additional variables may be available. This framework allows for
training models for different combinations of data availability allowing
for single function call to get predictions on new data.

## Installation

You can install the development version of medley like so:

``` r
remotes::install_github('jbryer/medley')
```
