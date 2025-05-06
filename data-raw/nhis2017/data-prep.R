# National Health Interview Survey (NHIS)
# https://archive.cdc.gov/www_cdc_gov/nchs/nhis/nhis_2017_data_release.htm
# This dataset was used by Perez-Lebel et al (2022)
# https://academic.oup.com/gigascience/article/doi/10.1093/gigascience/giac013/6568998?login=false
# NHIS	income_screening	0.52	R2	A	20987	96	R	ERNYR-P
# 	Predict the income earned on the previous year with information from tables: household, family, person and adult.
#

library(dplyr)
library(tidyr)

##### Download files from NHIS
nhis_files <- c(
	'https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2017/familyxxcsv.zip',
	'https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2017/househldcsv.zip',
	'https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2017/injpoiepcsv.zip',
	'https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2017/personsxcsv.zip',
	'https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2017/samchildcsv.zip',
	'https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2017/samadultcsv.zip'
)

out_dir <- 'data-raw/nhis2017/'
for(file in nhis_files) {
	dest_file <- paste0(out_dir, basename(file))
	download.file(file, dest_file)
	unzip(dest_file, exdir = out_dir)
}
unlink(paste0(out_dir, '*.zip')) # Delete the zip files

##### Merge data files
family <- read.csv('data-raw/nhis2017/familyxx.csv')
household <- read.csv('data-raw/nhis2017/househld.csv')
injury <- read.csv('data-raw/nhis2017/injpoiep.csv')
person <- read.csv('data-raw/nhis2017/personsx.csv')
child <- read.csv('data-raw/nhis2017/samchild.csv')
adult <- read.csv('data-raw/nhis2017/samadult.csv')

nhis <- merge(
		household,
		family,
		by = c('SRVY_YR', 'HHX'),
		suffixes = c('', '1_to_drop')) |>
	merge(
		person,
		by = c('SRVY_YR', 'HHX', 'FMX'),
		suffixes = c('', '2_to_drop')
		) |>
	merge(
		adult,
		by = c('SRVY_YR', 'HHX', 'FMX', 'FPX'),
		suffixes = c('', '3_to_drop')) |>
	# drop_na(ERNYR_P) |>
	select(!ends_with('_to_drop')) |>
	select(!c(INCGRP4, INCGRP5, SRVY_YR)) |>
	mutate( # Recode missing values in dependent variables
		ERNYR_P = case_when(
			ERNYR_P >= 90 ~ NA,
			.default = ERNYR_P
		),
		BMI = case_when(
			BMI >= 9999 ~ NA,
			.default = BMI
		)
	)

# Convert variables with fewer unique values to factor
convert_to_factor <- apply(nhis, 2, FUN = function(x) { length(unique(x)) <= 5})
table(convert_to_factor)
nhis[,convert_to_factor] <- lapply(nhis[,convert_to_factor], as.factor)

# usethis::use_data(nhis, overwrite = TRUE) # This is causing issues with building the package
save(nhis, file = 'data/nhis.rda')
tools::resaveRdaFiles('data/')

