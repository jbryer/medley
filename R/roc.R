# Variables used in ggplot2 expression
utils::globalVariables(c("value", "variable", "fpr", "tpr", "threshold", "cost"))

#' Calculate the statistics for receiver operating characteristic curve
#'
#' This function
#'
#' @param predictions predicted values.
#' @param observed actual observed outcomes.
#' @param cost_of_fp cost of a false positive.
#' @param cost_of_fn cost of a false negative.
#' @param n the number of steps to estimate.
#' @importFrom utils tail head
#' @importFrom stats as.formula glm
#' @references This function was adapted from Raffel (https://github.com/joyofdata):
#' https://github.com/joyofdata/joyofdata-articles/blob/master/roc-auc/calculate_roc.R
#' @export
#' @rdname calculate_roc
#' @examples
#' data('pisa', package = 'medley')
#' ggplot2::theme_set(ggplot2::theme_minimal())
#' lr_out <- glm(Public ~ ., data = pisa, family = binomial(link = 'logit'))
#' roc <- medley::calculate_roc(
#'     predictions = fitted(lr_out),
#'     observed = pisa$Public
#' )
#' summary(roc)
#' plot(roc)
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

	sensitivity <- function(threshold) {
		sum(predictions >= threshold & observed == 1) /
			sum(observed == 1)
	}

	specificity <- function(threshold) {
		sum(predictions < threshold & observed == 0) /
			sum(observed == 0)
	}

	roc <- data.frame(threshold = seq(0, 1, length.out = n), tpr = NA, fpr = NA)
	roc$tpr <- sapply(roc$threshold, function(th) tpr(th))
	roc$fpr <- sapply(roc$threshold, function(th) fpr(th))
	roc$cost <- sapply(roc$threshold, function(th) cost(th, cost_of_fp, cost_of_fn))
	roc$accuracy <- sapply(roc$threshold, function(th) accuracy(th))
	roc$sensitivity <- sapply(roc$threshold, function(th) sensitivity(th))
	roc$specificity <- sapply(roc$threshold, function(th) specificity(th))

	# Find the threshold where sensitivity and specificity intersect
	metrics <- reshape2::melt(roc[,c('threshold', 'sensitivity', 'specificity')],
							  measure.vars = c('sensitivity', 'specificity'))
	sensitivity_path <- metrics[metrics$variable == 'sensitivity',c('threshold', 'value')]
	names(sensitivity_path) <- c('x', 'y')
	specificity_path <- metrics[metrics$variable == 'specificity',c('threshold', 'value')]
	names(specificity_path) <- c('x', 'y')
	intersection <- find_path_intersections(sensitivity_path, specificity_path)

	class(roc) <- c('roc', 'data.frame')
	attr(roc, 'auc') <- abs(sum(diff(roc$fpr) * (head(roc$tpr,-1) + tail(roc$tpr,-1)))/2)
	tmp <- roc[order(abs(roc$threshold - 0.5)),]
	attr(roc, 'threshold') <- tmp[which.min(tmp$cost),]$threshold
	attr(roc, 'intersection') <- intersection[1,1]
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
	metrics <- reshape2::melt(object[,c('threshold', 'accuracy', 'sensitivity', 'specificity')],
							  measure.vars = c('accuracy', 'sensitivity', 'specificity'))
	accuracy_x <- attr(object, 'threshold')
	accuracy_y <- object[object$threshold >= accuracy_x,][1,]$accuracy
	intersection_x <- attr(object, 'intersection')
	intersection_y <- object[object$threshold >= intersection_x,][1,]$accuracy
	cost_x <- attr(object, 'threshold')
	cost_y <- object[object$threshold >= cost_x,][1,]$accuracy

	cat(paste0('AUC = ', round(attr(object, 'auc'), digits = digits), '\n',
			   'Cost of false-positive = ', attr(object, 'cost_of_fp'), '\n',
			   'Cost of false-negative = ', attr(object, 'cost_of_fn'), '\n',
			   'Threshold with minimum cost = ',
			   round(cost_x, digits = digits), ' (accuracy = ', 100 * round(cost_y, digits = digits), '%)\n',
			   'Threshold with maximum accuracy = ',
			   round(accuracy_x, digits = digits), ' (accuracy = ', 100 * round(accuracy_y, digits = digits), '%)\n',
			   'Sensitivity and specificity intersection = ',
			   round(intersection_x, digits = digits), ' (accuracy = ', 100 * round(intersection_y, digits = digits), '%)'
		)
	)
}

#' @rdname calculate_roc
#' @param x result of [calculate_roc()].
#' @param curve values can be `cost`, `accuracy`, or `NULL`.
#' @param legend.theme [ggplot2::theme()] elements used to define the
#'        positioning of the legend.
#' @param digits the number of digits to print.
#' @param ... currently not used.
#' @return a ggplot2 expression.
#' @import ggplot2
#' @method plot roc
#' @export
plot.roc <- function(
		x,
		curve = 'accuracy',
		legend.theme = ggplot2::theme(legend.position = 'none'),
#		legend.theme =  ggplot2::theme(
#		     legend.position = 'inside',
#		     legend.position.inside = c(0.05, 0.5),
#		     legend.title = ggplot2::element_blank(),
#		     legend.background = ggplot2::element_rect(fill = "white", color = "grey50"),
#		     legend.justification = "left"
#		),
		digits = 2,
		...
) {
	roc <- x
	idx_threshold <- which(roc$threshold == attr(roc, 'threshold'))

	p1 <- ggplot(roc, aes(x = fpr, y = tpr)) +
		geom_line() +
		geom_line(aes(threshold, threshold), color = 'blue') +
		# geom_vline(xintercept = roc[idx_threshold, 'fpr', drop = TRUE], linetype = 2) +
		# geom_hline(yintercept = roc[idx_threshold, 'tpr', drop = TRUE], linetype = 2) +
		xlim(c(0,1)) + ylim(c(0,1)) +
		coord_equal() +
		xlab('False Positive Rate') + ylab("True Positive Rate") +
		ggtitle('ROC Curve', subtitle = paste0('AUC = ', round(attr(roc, 'auc'), digits = digits)))

	if(curve == 'cost') {
		#threshold.label <- paste0('Threshold with minimum cost = ',
		#						  round(attr(roc, 'threshold'), digits = digits))
		threshold.label <- paste0('Cost of false positive = ',
								  round(attr(roc, 'cost_of_fp'), digits = digits), '; ',
								  'Cost of false negative = ',
								  round(attr(roc, 'cost_of_fn'), digits = digits))
		p2 <- ggplot(roc, aes(x = threshold, y = cost)) +
			geom_path() +
			geom_vline(xintercept = attr(x, 'threshold'), linetype = 2) +
			xlim(c(0,1)) +
			xlab('Threshold') +
			ylab(paste0('Cost (FN = ', round(attr(x, 'cost_of_fp'), digits = digits), '; ',
						'FP = ', round(attr(x, 'cost_of_fn'), digits = digits), ')')) +
			ggtitle('Cost Curve', subtitle = threshold.label)
	} else if(curve == 'accuracy') {
		threshold.label <- ' '

		metrics <- reshape2::melt(roc[,c('threshold', 'accuracy', 'sensitivity', 'specificity')],
								  measure.vars = c('accuracy', 'sensitivity', 'specificity'))

		accuracy_x <- attr(roc, 'threshold')
		accuracy_y <- roc[roc$threshold >= accuracy_x,][1,]$accuracy
		intersection_x <- attr(roc, 'intersection')
		intersection_y <- roc[roc$threshold >= intersection_x,][1,]$accuracy

		metric_labels <- data.frame(
			variable = metrics[!duplicated(metrics$variable),]$variable,
			x = c(0, 0, 0),
			y = metrics[!duplicated(metrics$variable),]$value
		)

		p2 <- ggplot(metrics, aes(x = threshold, y = value, color = variable)) +
			geom_path() +
			scale_color_brewer('Metric', type = 'qual', palette = 2) +
			geom_segment(x = intersection_x,
						 y = 0,
						 xend = intersection_x,
						 yend = intersection_y,
						 linetype = 3,
						 color = 'black') +
			geom_segment(x = 0,
						 y = intersection_y,
						 xend = intersection_x,
						 yend = intersection_y,
						 linetype = 3,
						 color = 'black') +
			geom_point(x = intersection_x,
					   y = intersection_y,
					   size = 3,
					   color = 'black') +
			geom_label(x = 0,
					   y = intersection_y,
					   label = round(intersection_y, digits = digits),
					   #vjust = ifelse(intersection_y < 0.5, -0.2, 1.2),
					   vjust = 0.5,
					   hjust = 1,
					   size = 3,
					   color = 'black') +
			geom_label(x = intersection_x,
					   y = 0,
					   label = round(intersection_x, digits = digits),
					   #vjust = ifelse(intersection_x < 0.5, -0.2, 1.2),
					   vjust = 1,
					   hjust = 0.5,
					   size = 3,
					   #angle = 270,
					   color = 'black') +
			geom_segment(x = accuracy_x,
						 y = 0,
						 xend = accuracy_x,
						 yend = accuracy_y,
						 linetype = 4,
						 color = 'black') +
			geom_segment(x = 0,
						 y = accuracy_y,
						 xend = accuracy_x,
						 yend = accuracy_y,
						 linetype = 4,
						 color = 'black') +
			geom_point(x = accuracy_x,
					   y = accuracy_y,
					   size = 3,
					   color = 'black') +
			geom_label(x = 0,
					   y = accuracy_y,
					   label = round(accuracy_y, digits = digits),
					   #vjust = ifelse(accuracy_y < 0.5, -0.2, 1.2),
					   vjust = 0.5,
					   hjust = 1,
					   size = 3,
					   color = 'black') +
			geom_label(x = accuracy_x,
					   y = 0,
					   label = round(accuracy_x, digits = digits),
					   #vjust = ifelse(accuracy_x < 0.5, -0.2, 1.2),
					   vjust = 1,
					   hjust = 0.5,
					   size = 3,
					   #angle = 270,
					   color = 'black') +
			geom_label(data = metric_labels, aes(x = x, y = y, label = variable),
					   hjust = -0.05, vjust = 0) +
			legend.theme +
			coord_equal() +
			ylim(c(-0.05,1)) + xlim(c(-0.05,1)) +
			xlab('Threshold') +
			ylab('Accuracy') +
			ggtitle('Accuracy Curve', subtitle = threshold.label)
	} else {
		return(p1)
	}

	gridExtra::grid.arrange(p1,
							p2,
							ncol = 2,
							respect = TRUE)
}

#' Find the x and y coordinates where two paths intersect.
#'
#' This function will find the coordinates where two lines intersect.
#'
#' @param df1 data frame for the first line.
#' @param df2 data frame for the second line.
#' @param x_col the name of the column for the x-coordinate.
#' @param y_col the name of the column for the y-coordinate.
#' @return a data frame with the intersections.
#' @export
find_path_intersections <- function(df1, df2, x_col = names(df1)[1], y_col = names(df1)[2]) {
	mat1 <- as.matrix(df1[, c(x_col, y_col)])
	mat2 <- as.matrix(df2[, c(x_col, y_col)])

	line1 <- sf::st_linestring(mat1)
	line2 <- sf::st_linestring(mat2)

	# Find the geometric intersection
	intersection <- sf::st_intersection(line1, line2)

	# Check if an intersection exists and extract the coordinates
	if(sf::st_is_empty(intersection)) {
		warning("No intersection found between the paths.")
		return(data.frame(X = numeric(0), Y = numeric(0)))
	}

	# Extract coordinates (handles multiple intersection points if paths cross repeatedly)
	coords <- sf::st_coordinates(intersection)

	# Return clean data frame of the intersection coordinates
	result <- data.frame(coords[, "X"], coords[, "Y"])
	names(result) <- c(x_col, y_col)
	return(result)
}
