suppressPackageStartupMessages({
	library(dplyr)
	library(tidyr)
	library(ggplot2)
	library(medley)
	library(xgboost)
	library(mice)
	library(ComplexHeatmap)
})

data('nhis', package = 'medley')

####################################################################################################
##### Dependent variables

nhis$ERNYR_P <- factor(
	nhis$ERNYR_P,
	levels = 1:11,
	labels = c('$01-$4,999','$5,000-$9,999','$10,000-$14,999','$15,000-$19,999',
			   '$20,000-$24,999','$25,000-$34,999','$35,000-$44,999','$45,000-$54,999',
			   '$55,000-$64,999','$65,000-$74,999','$75,000 and over'),
	ordered = TRUE
)
table(nhis$ERNYR_P, useNA = 'ifany')
nhis |>
	dplyr::filter(!is.na(ERNYR_P)) |>
	ggplot(aes(x = ERNYR_P)) + geom_bar() + coord_flip() + xlab('')
is.na(nhis$ERNYR_P) |> table() |> print() |> prop.table()

summary(nhis$BMI) # From adult file (exclude AHEIGHT, AWEIGHTP from analysis)
table(nhis$BMI)
hist(nhis$BMI)
is.na(nhis$BMI)  |> table() |> print() |> prop.table()

##### Feature selection
missing_threshold <- 0.7
p_threshold <- 0.01

# nhis$FHCHMCT |> recode_small_levels() |> table(useNA = 'ifany')

features <- data.frame(variable = names(nhis),
					   n_missing = NA_integer_,
					   percent_missing = NA_real_,
					   n_levels = NA_integer_,
					   test = NA_character_,
					   p_value = NA_real_,
					   smallest_count = NA_integer_,
					   table = NA_character_)
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
				features[i,]$n_levels <- nhis[,var] |> unique() |> length()
				features[i,]$test <- 'ANOVA'
				aov_out <- aov(formu, data = nhis)
				tmp <- aov_out |> summary() |> as.list()
				features[i,]$p_value <- tmp[[1]][1,]$`Pr(>F)`
				features[i,]$smallest_count <- min(table(nhis[,var]), na.rm = TRUE)

				# Recode small category counts to NA
				nhis[,var] <- recode_small_levels(nhis[,var], recode_to = 'to_remove')

				features[i,]$table <- crosstab(nhis[,var])
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
	dplyr::select(BMI, features_bmi$variable) |>
	dplyr::filter(!is.na(BMI))

# Removing rows where there is at least on predictor that had a "rare" value. This is
# obviously not ideal but since the purpose of this study is to evaluate the relative performance
# of different predictive modeling techniques and not about this particular prediction problem,
# I am going to proceed by removing them.
to_remove <- apply(nhis_bmi, 1, FUN = function(x) { any(x == 'to_remove', na.rm = TRUE)} )
table(to_remove, useNA = 'ifany') |> print() |> prop.table()
nhis_bmi <- nhis_bmi[!to_remove,]
for(i in 1:ncol(nhis_bmi)) {
	if(is.factor(nhis_bmi[,i])) {
		nhis_bmi[,i] <- nhis_bmi[,i] |> as.character() |> as.factor()
	}
}

# save(nhis_bmi, file = 'data/nhis_bmi.rda')
# tools::resaveRdaFiles('data/')

# nrow(nhis_bmi) * .05

missing_cols <- apply(nhis_bmi, 2, FUN = function(x) { sum(is.na(x)) > 0 })
shadow_matrix <- as.data.frame(!is.na(nhis_bmi[,missing_cols]))
ComplexHeatmap::make_comb_mat(shadow_matrix) |> ComplexHeatmap::UpSet(right_annotation = NULL)
# Only look at sets with at least 1,000 observations
comb_mat <- ComplexHeatmap::make_comb_mat(shadow_matrix)
comb_mat[(ComplexHeatmap::comb_size(comb_mat) > 1000)] |> ComplexHeatmap::UpSet(right_annotation = NULL)

# Vars with no missingness
names(missing_cols[!missing_cols])

var_sets <- get_variable_sets(data = nhis_bmi, formula = BMI ~ ., min_set_size = 0.05)
set.seed(2112); train_rows <- sample(nrow(nhis_bmi), nrow(nhis_bmi) * 0.75)
nhis_bmi_train <- nhis_bmi[train_rows,]
nhis_bmi_valid <- nhis_bmi[-train_rows,]

nhis_medley <- medley_train(
	data = nhis_bmi_train,
	formula = BMI ~ .,
	method = lm,
	var_sets = var_sets)
summary(nhis_medley)
nhis_medley$messages

nhis_bmi_predictions <- predict(
	nhis_medley,
	newdata = nhis_bmi_valid)

ggplot(data.frame(predicted = nhis_bmi_predictions,
				  observed = nhis_bmi_valid$BMI), aes(x = predicted, y = observed)) +
	geom_point(alpha = 0.05) +
	geom_abline() +
	coord_equal() +
	theme_minimal()

ggplot(data.frame(predicted = nhis_bmi_predictions,
				  observed = nhis_bmi_valid$BMI), aes(x = predicted, y = observed)) +
	geom_hex() +
	geom_abline() +
	scale_fill_gradient2(low = '#99d8c9', high = '#2ca25f') +
	# coord_equal() +
	theme_minimal()


length(nhis_medley$models)
nhis_medley$models[[7]] |> summary()

# R^2
cor(nhis_bmi_predictions, nhis_bmi_valid$BMI)^2

# mice imputation
nhis_bmi_mice <- mice(nhis_bmi[,-1])
nhis_bmi_complete <- cbind(BMI = nhis_bmi$BMI, complete(nhis_bmi_mice))
nhis_bmi_mice_train <- nhis_bmi_complete[train_rows,]
nhis_bmi_mice_valid <- nhis_bmi_complete[-train_rows,]
nhis_bmi_mice_lm <- glm(BMI ~ ., data = nhis_bmi_mice_train)
nhis_bmi_mice_predicted <- predict(nhis_bmi_mice_lm, newdata = nhis_bmi_mice_valid)
cor(nhis_bmi_mice_predicted, nhis_bmi_mice_valid$BMI)^2

lm(BMI ~ ., data = cbind(BMI = nhis_bmi$BMI, shadow_matrix)) |> summary()

nhis_bmi_complete2 <- cbind(ERNYR_P = nhis_bmi$ERNYR_P, complete(nhis_bmi_mice))
poly_out <- MASS::polr(ERNYR_P ~ ., data = nhis_bmi_mice_train, Hess=TRUE)

# xgboost
library(xgboost)
options(na.action='na.pass')
# https://stackoverflow.com/questions/5616210/model-matrix-with-na-action-null
train_data <- model.matrix(BMI ~ ., model.frame(~ ., nhis_bmi_train, na.action = na.pass))
train_data <- model.matrix.lm(BMI ~ ., nhis_bmi_train, na.action = na.pass)
# train_data <- model.frame(BMI ~ ., nhis_bmi_train, na.action=NULL)
# train_data <- xgb.DMatrix(nhis_bmi_train)
train_data <- Matrix::sparse.model.matrix(BMI ~ ., data = nhis_bmi_train)
nrow(nhis_bmi_train)
sum(complete.cases(nhis_bmi_train))
dim(train_data)
xg_out <- xgboost(data = train_data,
				  label = nhis_bmi_train$BMI,
				  max.depth = 2,
				  eta = 1,
				  nthread = 2,
				  nrounds = 2,
				  objective = "reg:squarederror")
xg_predicted <- predict(xg_out,
						Matrix::sparse.model.matrix(BMI ~ ., data = nhis_bmi_valid))
# R^2
cor(xg_predicted, nhis_bmi_valid$BMI)^2

xgboost_model <- function(formula, data, ...) {
	dep_var <- all.vars(formula)[1]
	xg <- list(
		model = xgboost(
			data = Matrix::sparse.model.matrix(formula, data = data),
			label = data[,dep_var,drop=TRUE],
			max.depth = 2,
			eta = 1,
			nthread = 2,
			nrounds = 2,
			objective = "reg:squarederror"),
		formula = formula,
		dep_var = dep_var
	)
	class(xg) <- 'xgboost_model'
	return(xg)
}

predict.xgboost_model <- function(object, newdata, ...) {

	predict(
		object = object$model,
		newdata = Matrix::as.matrix(object$formula, data = newdata),
		...
	)
}

nhis_medley_xg <- medley_train(
	data = nhis_bmi_train,
	formula = BMI ~ .,
	var_sets = var_sets,
	method = xgboost_model
)
# summary(nhis_medley_xg)

nhis_medley_xg_predictions <- predict(
	object = nhis_medley_xg,
	newdata = nhis_bmi_valid
)
