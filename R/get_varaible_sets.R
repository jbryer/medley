#' Gets list of model formulas based upon the missing data pattern in the data set.
#'
#' @param data the data.frame.
#' @param formula the formula that includes all the possible variables to consider
#'        for the predictive models.
#' @param min_set_size the minimum set size as a percentage to include as a model.
#' @return a list of formulas, in order to be used, for the predictive models.
#' @importFrom ComplexHeatmap comb_size make_comb_mat
#' @export
get_variable_sets <- function(data, formula, min_set_size = 0.1) {
	formula <- expand_formula(formula, data)
	dep_var <- all.vars(formula)[1]
	n_missing_by_var <- apply(data, 2, FUN = function(x) { sum(is.na(x)) })
	if(n_missing_by_var[1] != 0) {
		stop('Missing values in the dependent variable is not supported..')
	}
	if(sum(n_missing_by_var == 0) < 2) {
		# TODO: this may not be a hard requirement
		stop('At least one independent variable must have no missingness.')
	}
	shadow_matrix <- as.data.frame(!is.na(data))
	comb_mat <- ComplexHeatmap::make_comb_mat(shadow_matrix)
	sets <- as.data.frame(comb_mat, stringsAsFactors = FALSE)
	sets <- sets[,ComplexHeatmap::comb_size(comb_mat) / nrow(data) > min_set_size]

	if(ncol(sets) == 0) { # Not sure the minimum number of sets
		stop(paste0('No sets contained at least ', min_set_size * 100, '% of rows.'))
	}

	vars_per_set <- apply(sets, 2, sum)
	sets <- sets[,order(vars_per_set, decreasing = TRUE)]
	sets <- sets[row.names(sets) != dep_var,]

	var_sets <- list()
	for(i in seq_len(ncol(sets))) {
		var_sets[[i]] <- paste0(
			dep_var, ' ~ ', paste0(row.names(sets)[sets[,i] == 1], collapse = ' + ')
		) |> as.formula()
	}
	class(var_sets) <- 'variableset'
	attr(var_sets, 'shadow_matrix') <- shadow_matrix
	attr(var_sets, 'combination_matrix') <- comb_mat
	return(var_sets)
}

#' @rdname get_variable_sets
#' @param x the results from `get_variable_sets()`.
#' @param ... currently unused.
#' @method print variableset
#' @export
print.variableset <- function(x, ...) {
	print(x[seq_len(length(x))], showEnv = FALSE)
}
