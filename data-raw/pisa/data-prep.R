library(multilevelPSA)
library(pisa) # remotes::install_github('jbryer/pisa')
data('pisana', package = 'multilevelPSA')
data("pisa.psa.cols", package = 'multilevelPSA')
data("pisa.catalog.student", package = 'pisa')


pisa <- pisana[pisana$CNT == 'USA',c('PUBPRIV', pisa.psa.cols)]

# For the documentation
names(pisa) %in% names(pisa.catalog.student)
pisa_variables <- pisa.catalog.student[names(pisa)]
pisa_variables <- c(Public = 'Public', pisa_variables[!is.na(pisa_variables)])
paste0(paste0('\\item{', names(pisa_variables), '}{', pisa_variables, '}'), collapse = '\n') |> cat()

# Remove values where there are not many observations
threshold <- 0.03
for(i in names(pisa)) {
	if(all(c('Yes', 'No') %in% unique(pisa[,i]))) {
		pisa[,i] <- pisa[,i] == 'Yes'
	} else {
		tab <- table(pisa[,i]) |> prop.table()
		small_levels <- tab[tab < threshold]
		if(length(small_levels) > 0) {
			print(paste0('Removing small levels from ', i, ': ', paste0(names(small_levels), collapse = ', ')))
			rows <- pisa[,i] %in% names(small_levels)
			pisa[rows, i] <- NA
		}
	}
	if(is.factor(pisa[,i])) {
		pisa[,i] <- as.factor(as.character(pisa[,i]))
	}
}
table(complete.cases(pisa)) |> prop.table()
table(pisa$PUBPRIV, complete.cases(pisa))
mice_out <- mice::mice(pisa, m = 1)
pisa <- mice::complete(mice_out)
# pisa <- pisa[complete.cases(pisa),]
table(complete.cases(pisa))

for(i in names(pisa)) {
	print(paste0(i, ': ', length(unique(pisa[,i]))))
}

pisa$Public <- pisa$PUBPRIV == 'Public'
pisa$PUBPRIV <- NULL
pisa$ST20Q14 <- NULL

usethis::use_data(pisa, pisa_variables, overwrite = TRUE)
