# Variables used in ggplot2 expression
utils::globalVariables(c('pt', 'y', 'Fitted_Values'))

#' Stratified Generalized Linear Models
#'
#' This modeling approach subdivides the majority class into strata of size of the minority class, times a ratio
#' (which is 1 by default). The models are combined using the same technique for combining multiple imputed
#' data sets in order to not decrease standard error estimates with artificially large sample sizes. See
#' stratified_glm vignette for more details.
#'
#' @param formula an object of class "formula" (or one that can be coerced to that class): a symbolic description
#'        of the model to be fitted. See [stats::glm()] for more information.
#' @param data an optional data frame, list or environment (or object coercible by as.data.frame to a data frame)
#'        containing the variables in the model. See [stats::glm()] for more information.
#' @param family a description of the error distribution and link function to be used in the model. This should
#'        almost always be `binomial(link='logit')`.
#' @param ratio the ratio of the small-to-large group. That is, how many observations from the larger group should
#'        be randomly selected. A ratio of 1 means that there are the (approximately) same number of observations
#'        in both outcome groups.
#' @param ... other parameters passed to [stats::glm()]. Use with caution since multiple models will run with subsets
#'        of the data. Hence, parameters like `weights` and `subset` will not work.
#' @rdname stratified_glm
#' @return a list object with the following elements:
#' \describe{
#'     \item{formula}{an object of class "formula" (or one that can be coerced to that class): a symbolic description
#'                    of the model to be fitted.}
#'     \item{data}{data frame used for the model fitting.}
#'     \item{ratio}{the ratio used for the big to small group.}
#'     \item{cont_tab}{the contingency table for the outcome variable.}
#'     \item{data_big}{subset of `data` for the bigger of the two groups.}
#'     \item{data_small}{subset of `data` for the larger of the two groups.}
#'     \item{model}{the [stats::glm()] results using all the data.}
#'     \item{n_models}{the number of models that will be estimated.}
#'     \item{assignment}{a numeric vector equal to `nrow(data)` that corresponds to what.}
#'     \item{models}{a list with the following elements for each model run:
#'         \describe{
#'             \item{model}{the results of [stats::glm()].}
#'             \item{data}{the subset of `data` used for this iteration.}
#'             \item{fitted}{the fitted values for this iteration. Note that the order of this vector corresponds
#'                           to the `data` subset for this iteration, not the full data.}
#'             \item{rows}{an integer vector mapping the rows from this iteration back to the full data frame.}
#'         }
#'     }
#'     \item{fitted}{matrix of fitted values. The columns correspond to each model iteration.}
#' }
#' @export
stratified_glm <- function(
		formula,
		data,
		ratio = 1,
		family = stats::binomial(link = 'logit'),
		...
) {
	results <- list(
		formula = formula,
		data = data,
		ratio = ratio
	)
	Y_var <- all.vars(formula)[1]

	results$formula <- formula
	results$data <- data
	results$cont_tab <- data[,Y_var,drop=TRUE] |> table(useNA='ifany')
	prop_tab <- results$cont_tab |> prop.table()

	min_n <- min(results$cont_tab)
	max_n <- max(results$cont_tab)
	results$n_models <- floor(max_n / (min_n * ratio))

	if(results$n_models == 1) {
		stop('There is not enough imbalance to estimate the model.')
	}

	big_group <- names(results$cont_tab)[results$cont_tab == max_n]
	small_group <- names(results$cont_tab)[results$cont_tab == min_n]

	results$assignment <- rep(1:results$n_models, length.out = max_n) |> sample()
	results$group_sizes <- table(results$assignment)

	results$model <- glm(formula = formula, data = data, family = family, ...)

	small_rows <- which(data[,Y_var] == small_group)
	big_rows <- which(data[,Y_var] == big_group)

	results$fitted <- matrix(nrow = nrow(data), ncol = results$n_models)

	results$models <- list()
	for(i in 1:results$n_models) {
		rows <- c(big_rows[results$assignment == i], small_rows)
		df <- data[rows,]
		lr_out <- glm(formula, data = df, family = family, ...)
		fitted_values <- stats::fitted(lr_out)
		results$models[[i]] <- list(
			model = lr_out,
			data = df,
			fitted = fitted_values,
			rows = rows
		)
		results$fitted[rows, i] <- fitted_values
	}

	class(results) <- c('stratified.glm', 'list')
	return(results)
}

#' Summary function for stratified logistic regression.
#' @rdname stratified_glm
#' @param object results from `stratified_glm()`.
#' @param ... other parameters passed to [mitools::MIcombine()].
#' @return the results from [mitools::MIcombine()].
#' @export
summary.stratified.glm <- function(object, ...) {
	models <- list()
	for(i in 1:object$n_models) {
		models[[i]] <- object$models[[i]]$model
	}
	mic <- mitools::MIcombine(models)
	data.frame(
		coefficients = stats::coef(mic),
		se = sqrt(diag(stats::vcov(mic))),
		p = MIcombineP(mic)
	)
}

#' Calculate p-values from [mitools::MIcombine()] object.
#' This is an internal function.
#' @param MIcombineRes results from [mitools::MIcombine()].
#' @param digits integer indicating the number of decimal places (round) or significant digits (signif) to be used.
#' @return a numeric vector of the p-values.
MIcombineP <- function(MIcombineRes, digits = 3) {
	tStat <- MIcombineRes$coefficients / sqrt(diag(MIcombineRes$variance))
	pVals <- 2 * pt(-abs(tStat), df = MIcombineRes$df)
	round(pVals, digits)
}

#' Get fitted values for stratified logistic regression.
#' @rdname stratified_glm
#' @param object results from `stratified_glm()`.
#' @return a numeric vector with the fitted values. Note that for the small group, the fitted value
#'         is the average across all models. Individual vectors of fitted values can be retrieved
#'         from `object$fitted`.
#' @export
fitted.stratified.glm <- function(object, ...) {
	apply(object$fitted, 1, mean, na.rm = TRUE)
}

#' Get predictions for stratified logistic regression.
#' from the pooled estimates.
#' @rdname stratified_glm
#' @param object results from `stratified_glm()`.
#' @param newdata optionally, a data frame in which to look for variables with which to predict. If omitted,
#'        the fitted linear predictors are used.
#' @export
predict.stratified.glm <- function(object, newdata = NULL, ...) {
	if(is.null(newdata)) {
		newdata <- object$data
	}
	# Leaving this here for now. This averages the estimates over all the models
	# fitted_values <- matrix(nrow = nrow(newdata), ncol = object$n_models)
	# for(i in 1:object$n_models) {
	# 	fitted_values[,i] <- predict(object$models[[i]]$model, newdata = newdata, ...)
	# }
	# return(fitted_values)
	models <- list()
	for(i in 1:object$n_models) {
		models[[i]] <- object$models[[i]]$model
	}
	mic <- mitools::MIcombine(models)
	mm <- stats::model.matrix(object$formula, data = newdata)
	z <- apply(mm[,names(mic$coefficients)], 1, FUN = function(x) {
		sum(x * mic$coefficients) })
	p <- 1 / (1 + exp(-1 * z))
	return(p)
}

#' Plot function for stratified logistic regression.
#' @rdname stratified_glm
#' @param x results from `stratified_glm()`
#' @param geom the `ggplot2` geometry to use. Typically [ggplot2::geom_density()] or [ggplot2::geom_histogram()].
#' @param facet whether to use [ggplot2::facet_wrap()] based on the model type.
#' @param ... currently not used.
#' @return a `ggplot2` expression.
#' @export
plot.stratified.glm <- function(x, geom = ggplot2::geom_density(alpha = 0.5), facet = TRUE, ...) {
	Y_var <- all.vars(x$formula)[1]
	fitted <- apply(x$fitted, 1, mean, na.rm = TRUE)
	fitted <- predict(x)
	full_fitted <- stats::fitted(x$model)
	df <- rbind(
		cbind(rep('Full', nrow(x$data)), full_fitted, x$data[,Y_var]),
		cbind(rep('Stratified', nrow(x$data)), fitted, x$data[,Y_var])
	) |> as.data.frame()
	names(df) <- c('Model', 'Fitted_Values', Y_var)
	df$Fitted_Values <- as.numeric(df$Fitted_Values)
	p <- ggplot2::ggplot(df, ggplot2::aes(x = Fitted_Values, color = .data[[Y_var]], fill = .data[[Y_var]])) +
		geom +
		xlim(c(0, 1)) +
		xlab('Fitted Values')
	if(facet) {
		p <- p + ggplot2::facet_wrap(~ Model, ncol = 1, scales = 'free_y')
	}
	return(p)
}

#' Create stratified data sets for modeling training and validation.
#' @param data data frame to split.
#' @param outcome_col the variable used for stratification.
#' @param train_prop proportion of observations used for the training data set.
#' @return a list with to data frames, `train` and `validation`.
#' @export
stratified_split <- function(data, outcome_col, train_prop = 0.8) {
	indices_by_group <- split(seq_len(nrow(data)), data[[outcome_col]])

	train_indices <- lapply(indices_by_group, function(indices) {
		sample_size <- round(length(indices) * train_prop)
		sample(indices, size = sample_size, replace = FALSE)
	})

	train_idx <- unlist(train_indices)

	train_set <- data[train_idx, , drop = FALSE]
	val_set   <- data[-train_idx, , drop = FALSE]

	return(list(train = train_set, validation = val_set))
}
