#' Stratified Generalized Linear Models
#'
#'
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
		ratio = 2,
		family = binomial(link = 'logit'),
		...
) {
	results <- list(
		formula = formula,
		data = data,
		ratio = ratio
	)
	Y_var <- all.vars(formula)[1]

	results$cont_tab <- data[,Y_var,drop=TRUE] |> table(useNA='ifany')
	prop_tab <- results$cont_tab |> prop.table()

	min_n <- min(results$cont_tab)
	max_n <- max(results$cont_tab)
	results$n_models <- floor(max_n / (min_n * ratio))

	big_group <- names(results$cont_tab)[results$cont_tab == max_n]
	small_group <- names(results$cont_tab)[results$cont_tab == min_n]

	results$assignment <- rep(1:results$n_models, length.out = max_n) |> sample()
	results$group_sizes <- table(results$assignment)

	results$model <- glm(formula = formula, data = data, family = family) # TODO: add ...

	small_rows <- which(data[,Y_var] == small_group)
	big_rows <- which(data[,Y_var] == big_group)

	results$fitted <- matrix(nrow = nrow(data), ncol = results$n_models)

	results$models <- list()
	for(i in 1:results$n_models) {
		rows <- c(big_rows[results$assignment == i], small_rows)
		df <- data[rows,]
		lr_out <- glm(formula, data = df, family = family) # TODO: add ...
		fitted_values <- fitted(lr_out)
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
	mitools::MIcombine(models)
}


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
#' @rdname stratified_glm
#' @param object results from `stratified_glm()`.
#' @param newdata optionally, a data frame in which to look for variables with which to predict. If omitted,
#'        the fitted linear predictors are used.
#' @export
predict.stratified.glm <- function(object, newdata = NULL, ...) {
	if(is.null(newdata)) {
		return(fitted(object))
	} else {
		fitted_values <- matrix(nrow = nrow(newdata), ncol = object$n_models)
		for(i in 1:object$n_models) {
			fitted_values[,i] <- predict(object$models[[i]]$model, newdata = newdata, ...)
		}
		return(fitted_values)
	}
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
	full_fitted <- fitted(x$model)
	df <- rbind(
		cbind(rep('Full', nrow(x$data)), full_fitted, x$data[,Y_var]),
		cbind(rep('Stratified', nrow(x$data)), fitted, x$data[,Y_var])
	) |> as.data.frame()
	names(df) <- c('Model', 'Fitted_Values', Y_var)
	df$Fitted_Values <- as.numeric(df$Fitted_Values)
	p <- ggplot2::ggplot(df, ggplot2::aes(x = Fitted_Values, color = .data[[Y_var]], fill = .data[[Y_var]])) +
		geom +
		xlim(c(0, 1))
	if(facet) {
		p <- p + ggplot2::facet_wrap(~ Model, ncol = 1)
	}
	return(p)
}


if(FALSE) {
	data('pisausa', package = 'PSAboot')
	data('pisa.psa.cols', package = 'PSAboot')

	pisa.psa.cols <- pisa.psa.cols[!pisa.psa.cols %in% c('ST10Q01', 'ST14Q01', 'ST21Q02')]

	pisausa$PUBPRIV |> table(useNA='ifany')
	pisausa$PUBPRIV |> table(useNA='ifany') |> prop.table()

	# formula <- paste0('PUBPRIV ~ ', paste0(pisa.psa.cols, collapse = ' + ')) |> as.formula()
	# data <- pisausa
	# ratio <- 2
	# family <- binomial(link = 'logit')

	results <- stratified_glm(
		formula = paste0('PUBPRIV ~ ', paste0(pisa.psa.cols, collapse = ' + ')) |> as.formula(),
		data = pisausa,
		ratio = 1
	)

	plot(results)
	summary(results)

	set.seed(2112); train_rows <- sample(nrow(pisausa), size = .8 * nrow(pisausa))
	data_train <- pisausa[train_rows,]
	data_valid <- pisausa[-train_rows,]
	table(data_train$PUBPRIV) |> prop.table()
	table(data_valid$PUBPRIV) |> prop.table()

	results_train <- stratified_glm(
		formula = paste0('PUBPRIV ~ ', paste0(pisa.psa.cols, collapse = ' + ')) |> as.formula(),
		data = data_train,
		ratio = 1
	)

	# Full model
	full_new_predictions <- predict(results_train$model, newdata = data_valid, type = 'response')
	hist(full_new_predictions)

	full_roc <- medley::calculate_roc(
		predictions = full_new_predictions,
		observed = data_valid$PUBPRIV == 'Private'
	)
	summary(full_roc)
	plot(full_roc)

	full_metrics <- reshape2::melt(full_roc[,c('threshold', 'sensitivity', 'specificity')],
								   measure.vars = c('sensitivity', 'specificity'))
	full_sensitivity <- full_metrics[full_metrics$variable == 'sensitivity',c('threshold', 'value')]
	names(full_sensitivity) <- c('x', 'y')

	full_specificity <- full_metrics[full_metrics$variable == 'specificity',c('threshold', 'value')]
	names(full_specificity) <- c('x', 'y')

	(full_intersection <- find_path_intersections(full_sensitivity, full_specificity))

	medley::confusion_matrix(
		observed = data_valid$PUBPRIV == 'Private',
		predicted = (full_new_predictions > full_intersection[1,1])
	)


	# Stratified model
	stratified_new_predictions <- predict(results_train, newdata = data_valid, type = 'response') |> apply(1, mean)
	hist(stratified_new_predictions)

	stratified_roc <- medley::calculate_roc(
		predictions = stratified_new_predictions,
		observed = data_valid$PUBPRIV == 'Private'
	)
	summary(stratified_roc)
	plot(stratified_roc)

	stratified_metrics <- reshape2::melt(stratified_roc[,c('threshold', 'sensitivity', 'specificity')],
								   measure.vars = c('sensitivity', 'specificity'))
	stratified_sensitivity <- stratified_metrics[stratified_metrics$variable == 'sensitivity',c('threshold', 'value')]
	names(stratified_sensitivity) <- c('x', 'y')

	stratified_specificity <- stratified_metrics[stratified_metrics$variable == 'specificity',c('threshold', 'value')]
	names(stratified_specificity) <- c('x', 'y')

	(stratified_intersection <- find_path_intersections(stratified_sensitivity, stratified_specificity))

	medley::confusion_matrix(
		observed = data_valid$PUBPRIV == 'Private',
		predicted = stratified_new_predictions > stratified_intersection[1,1]
	)

}

