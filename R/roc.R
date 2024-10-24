#' Calculate the statistics for receiver operating characteristic curve
#'
#' This function was adapted from Raffel (https://github.com/joyofdata):
#' https://github.com/joyofdata/joyofdata-articles/blob/master/roc-auc/calculate_roc.R
#'
#' @param predictions predicted values.
#' @param observed actual observed outcomes.
#' @param cost_of_fp cost of a false positive.
#' @param cost_of_fn cost of a false negative.
#' @param n the number of steps to estimate.
#' @importFrom utils tail head
#' @importFrom stats as.formula glm
#' @export
calculate_roc <- function(predictions,
						  observed,
						  cost_of_fp = 1,
						  cost_of_fn = 1,
						  n = 100) {

	tpr <- function(threshold) {
		sum(predictions >= threshold & observed == 1) / sum(observed == 1)
	}

	fpr <- function(threshold) {
		sum(predictions >= threshold & observed == 0) / sum(observed == 0)
	}

	cost <- function(threshold, cost_of_fp, cost_of_fn) {
		sum(predictions >= threshold & observed == 0) * cost_of_fp +
			sum(predictions < threshold & observed == 1) * cost_of_fn
	}

	accuracy <- function(threshold) {
		sum(predictions >= threshold & observed == 1 |
			predictions < threshold & observed == 0) / length(predictions)
	}

	roc <- data.frame(threshold = seq(0, 1, length.out = n), tpr = NA, fpr = NA)
	roc$tpr <- sapply(roc$threshold, function(th) tpr(th))
	roc$fpr <- sapply(roc$threshold, function(th) fpr(th))
	roc$cost <- sapply(roc$threshold, function(th) cost(th, cost_of_fp, cost_of_fn))
	roc$accuracy <- sapply(roc$threshold, function(th) accuracy(th))

	class(roc) <- c('roc', 'data.frame')
	attr(roc, 'auc') <- abs(sum(diff(roc$fpr) * (head(roc$tpr,-1) + tail(roc$tpr,-1)))/2)
	tmp <- roc[order(abs(roc$threshold - 0.5)),]
	attr(roc, 'threshold') <- tmp[which.min(tmp$cost),]$threshold
	# attr(roc, 'threshold') <- roc[which.min(roc$cost),]$threshold
	attr(roc, 'cost_of_fp') <- cost_of_fp
	attr(roc, 'cost_of_fn') <- cost_of_fn
	attr(roc, 'predictions') <- predictions
	attr(roc, 'observed') <- observed

	return(roc)
}

#' Prints the results ROC
# print.roc <- function(x, ...) {
# 	summary(x, ...)
# }

#' @rdname calculate_roc
#' @param object result of [calculate_roc()].
#' @param digits number of digits to print.
#' @param ... currently not used.
#' @method summary roc
#' @export
summary.roc <- function(object, digits = 3, ...) {
	cat(paste0('AUC = ', round(attr(object, 'auc'), digits = digits), '\n',
			   'Cost of false-positive = ', attr(object, 'cost_of_fp'), '\n',
			   'Cost of false-negative = ', attr(object, 'cost_of_fn'), '\n',
			   'Threshold with minimum cost = ',
			   round(attr(object, 'threshold'), digits = digits)))
}

# Variables used in ggplot2 expression
utils::globalVariables(c("fpr", "tpr", "threshold", "cost"))

#' @rdname calculate_roc
#' @param x result of [calculate_roc()].
#' @param curve values can be cost, accuracy, or NULL.
#' @param ... currently unused.
#' @return a ggplot2 expression.
#' @import ggplot2
#' @method plot roc
#' @importFrom gridExtra grid.arrange
#' @export
plot.roc <- function(x, curve = 'accuracy', ...) {
	roc <- x
	idx_threshold <- which(roc$threshold == attr(roc, 'threshold'))

	p1 <- ggplot(roc, aes(x = fpr, y = tpr)) +
		geom_line() +
		geom_line(aes(threshold, threshold), color = 'blue') +
		geom_vline(xintercept = roc[idx_threshold, 'fpr', drop = TRUE], linetype = 2) +
		geom_hline(yintercept = roc[idx_threshold, 'tpr', drop = TRUE], linetype = 2) +
		xlim(c(0,1)) + ylim(c(0,1)) + coord_fixed() +
		xlab('False Positive Rate') + ylab("True Positive Rate") +
		ggtitle('ROC Curve', subtitle = paste0('AUC = ', round(attr(x, 'auc'), digits = 3)))

	if(curve == 'cost') {
		threshold.label <- paste0('Threshold with minimum cost = ',
								  round(attr(roc, 'threshold'), digits = 3))
		p2 <- ggplot(roc, aes(x = threshold, y = cost)) +
			geom_path() +
			geom_vline(xintercept = attr(x, 'threshold'), linetype = 2) +
			xlim(c(0,1)) +
			xlab('Threshold') +
			ylab(paste0('Cost (FN = ', round(attr(x, 'cost_of_fp'), digits = 3), '; ',
						'FP = ', round(attr(x, 'cost_of_fn'), digits = 3), ')')) +
			ggtitle('Cost Curve', subtitle = threshold.label)
	} else if(curve == 'accuracy') {
		threshold.label <- paste0('Threshold with maximum accuracy = ',
								  round(attr(roc, 'threshold'), digits = 3))
		p2 <- ggplot(roc, aes(x = threshold, y = accuracy)) +
			geom_path() +
			geom_vline(xintercept = attr(roc, 'threshold')) +
			ylim(c(0,1)) + xlim(c(0,1)) +
			xlab('Threshold') +
			ylab('Accuracy') +
			ggtitle('Accuracy Curve', subtitle = threshold.label)
	} else {
		return(p1)
	}

	gridExtra::grid.arrange(p1, p2, ncol = 2, respect = TRUE)
}

