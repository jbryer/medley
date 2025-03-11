library(dplyr)
library(mice)

load("data-raw/DAACS-EC.rda")

cols <- c(
	retained = 'SuccessTerm1',
	income = 'INCOME_RANGE_CODE',
	employment = 'EMPLOYMENT_LVL_CODE',
	ell = 'ENGLISH_LANGUAGE_NATIVE',
	ed_mother = 'HIGHEST_ED_LVL_CODE_MOTHER',
	ed_father = 'HIGHEST_ED_LVL_CODE_FATHER',
	ethnicity = 'ETHNICITY',
	gender = 'GENDER',
	military = 'ACTIVE_MIL_STUDENT',
	age = 'Age',
	page_views = 'page_views',
	srl = 'srlTotal',
	# srl_strategies = 'srl_strategies',
	# srl_metacognition = 'srl_metacognition',
	# srl_motivation = 'srl_motivation',
	math = 'mathTotal',
	reading = 'readTotal',
	writing = 'writeTotal'
)

page_views <- table(events.students.ec$DAACS_ID) |> as.data.frame()
names(page_views) <- c('DAACS_ID', 'page_views')
daacs.ec <- merge(daacs.ec, page_views, by = 'DAACS_ID', all.x = TRUE)

daacs_formula <- paste0('retained ~ ', paste0(names(cols)[-1], collapse = ' + ')) |> as.formula()

daacs <- daacs.ec |>
	filter(Treat) |>
	rename(all_of(cols)) |>
	select(all_of(names(cols))) |>
	mutate(ell = as.logical(ell),
		   ed_mother = as.integer(ed_mother),
		   ed_father = as.integer(ed_father),
		   income = as.integer(income))

daacs$ethnicity <- as.character(daacs$ethnicity)
daacs[daacs$ethnicity %in% c('American Indian or Alaska Native',
							 'Asian', 'Native Hawaiian or Other Pacific Islander',
							 'Two or more races', 'Unknown'),]$ethnicity <- 'Other'
daacs$ethnicity <- as.factor(daacs$ethnicity)


impute_cols <- names(cols)[2:10]
daacs_mice <- mice(daacs[,impute_cols], m = 1, seed = 2112)
daacs <- cbind(daacs[, !(names(daacs) %in% impute_cols)],
			   complete(daacs_mice))

usethis::use_data(daacs, overwrite = TRUE)

