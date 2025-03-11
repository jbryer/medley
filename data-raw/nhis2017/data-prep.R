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

usethis::use_data(nhis, overwrite = TRUE)
# save(nhis, file = 'data/nhis.rda')
# tools::resaveRdaFiles('data/')


##### Dependent variables
summary(nhis$ERNYR_P) # From person file (exclude INCGRP4, INCGRP5 from analysis)
table(nhis$ERNYR_P, useNA = 'ifany')
hist(nhis$ERNYR_P)
is.na(nhis$ERNYR_P) |> table() |> print() |> prop.table()

summary(nhis$BMI) # From adult file (eclude AHEIGHT, AWEIGHTP from analysis)
table(nhis$BMI)
hist(nhis$BMI)
is.na(nhis$BMI)  |> table() |> print() |> prop.table()

##### Feature selection
missing_threshold <- 0.7
p_threshold <- 0.01
features <- data.frame(variable = names(nhis),
					   n_missing = NA_integer_,
					   percent_missing = NA_real_,
					   test = NA_character_,
					   p_value = NA_real_)
dep_var <- 'BMI'
for(i in 1:nrow(features)) {
	var <- features[i,]$variable
	formu <- as.formula(paste0(dep_var, ' ~ ', var))
	features[i,]$n_missing <- sum(is.na(nhis[,var]))
	features[i,]$percent_missing <- features[i,]$n_missing / nrow(nhis)
	if(var != dep_var & features[i,]$percent_missing <= missing_threshold) {
		if(is.factor(nhis[,i,drop=TRUE])) {
			if(length(unique(nhis[,i,drop=TRUE])) > 1) {
				# ANOVA
				features[i,]$test <- 'ANOVA'
				aov_out <- aov(formu, data = nhis)
				tmp <- aov_out |> summary() |> as.list()
				features[i,]$p_value <- tmp[[1]][1,]$`Pr(>F)`
			} # else there is only one level
		} else {
			features[i,]$test <- 't'
			# Correlation
			# lm_out <- lm(formu, data = nhis)
			cor_out <- cor.test(nhis[,dep_var], nhis[,var])
			features[i,]$p_value <- cor_out$p.value
		}
	}
}

# How many where p < p_threshold
(features$p_value < p_threshold) |> table(useNA = 'ifany') |> print() |> prop.table()

features <- features[order(features$p_value, decreasing = FALSE),]
head(features, n = 100)

features_bmi <- features[1:100,]

nhis_bmi <- nhis |>
	select(BMI, features_bmi$variable) |>
	filter(!is.na(BMI))

nrow(nhis_bmi) * .05

library(medley)
library(ComplexHeatmap)
missing_cols <- apply(nhis_bmi, 2, FUN = function(x) { sum(is.na(x)) > 0 })
shadow_matrix <- as.data.frame(!is.na(nhis_bmi[,missing_cols]))
ComplexHeatmap::make_comb_mat(shadow_matrix) |> ComplexHeatmap::UpSet()
# Only look at sets with at least 1,000 observations
comb_mat <- ComplexHeatmap::make_comb_mat(shadow_matrix)
comb_mat[(ComplexHeatmap::comb_size(comb_mat) > 1000)] |> ComplexHeatmap::UpSet()

get_variable_sets(data = nhis_bmi, formula = BMI ~ ., min_set_size = 0.05)
