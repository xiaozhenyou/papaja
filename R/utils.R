#' Validate function input
#'
#' This function can be used to validate the input to functions. \emph{This function is not exported.}
#'
#' @param x Function input.
#' @param name Character. Name of variable to validate; if \code{NULL} variable name of object supplied to \code{x} is used.
#' @param check_class Character. Name of class to expect.
#' @param check_mode Character. Name of mode to expect.
#' @param check_integer Logical. If \code{TRUE} an object of type \code{integer} or a whole number \code{numeric} is expected.
#' @param check_NA Logical. If \code{TRUE} an non-\code{NA} object is expected.
#' @param check_infinite Logical. If \code{TRUE} a finite object is expected.
#' @param check_length Integer. Length of the object to expect.
#' @param check_dim Numeric. Vector of object dimensions to expect.
#' @param check_range Numeric. Vector of length 2 defining the expected range of the object.
#' @param check_cols Character. Vector of columns that are intended to be in a \code{data.frame}.
#'
#' @examples
#' \dontrun{
#' in_paren <- TRUE # Taken from printnum()
#' validate(in_paren, check_class = "logical", check_length = 1)
#' validate(in_paren, check_class = "numeric", check_length = 1)
#' }

validate <- function(
  x
  , name = NULL
  , check_class = NULL
  , check_mode = NULL
  , check_integer = FALSE
  , check_NA = TRUE
  , check_infinite = TRUE
  , check_length = NULL
  , check_dim = NULL
  , check_range = NULL
  , check_cols = NULL
) {
  if(is.null(name)) name <- deparse(substitute(x))

  if(is.null(x)) stop(paste("The parameter '", name, "' is NULL.", sep = ""))

  if(!is.null(check_dim) && !all(dim(x) == check_dim)) stop(paste("The parameter '", name, "' must have dimensions " , paste(check_dim, collapse=""), ".", sep = ""))
  if(!is.null(check_length) && length(x) != check_length) stop(paste("The parameter '", name, "' must be of length ", check_length, ".", sep = ""))

  if(!check_class=="function"&&any(is.na(x))) {
    if(check_NA) stop(paste("The parameter '", name, "' is NA.", sep = ""))
    else return(TRUE)
  }

  if(check_infinite && "numeric" %in% methods::is(x) && is.infinite(x)) stop(paste("The parameter '", name, "' must be finite.", sep = ""))
  if(check_integer && "numeric" %in% methods::is(x) && x %% 1 != 0) stop(paste("The parameter '", name, "' must be an integer.", sep = ""))

  for(x.class in check_class) {
    if(!methods::is(x, x.class)) stop(paste("The parameter '", name, "' must be of class '", x.class, "'.", sep = ""))
  }

  for (x.mode in check_mode) {
    if(!check_mode %in% mode(x)) stop(paste("The parameter '", name, "' must be of mode '", x.mode, "'.", sep = ""))
  }

  if(!is.null(check_cols)) {
    test <- check_cols %in% colnames(x)

    if(!all(test)) {
      stop(paste0("Variable '", check_cols[!test], "' is not present in your data.frame.\n"))
    }
  }

  if(!is.null(check_range) && any(x < check_range[1] | x > check_range[2])) stop(paste("The parameter '", name, "' must be between ", check_range[1], " and ", check_range[2], ".", sep = ""))
  TRUE
}



#' Create empty container for results
#'
#' Creates the default empty container for the results of \code{\link{apa_print}}. \emph{This function is not exported.}
#'
#' @return
#'    A named list containing the following components according to the input:
#'
#'    \describe{
#'      \item{\code{estimate}}{A (named list of) character strings giving effect size estimates.}
#'      \item{\code{statistic}}{A (named list of) character strings giving test statistic, parameters, and \emph{p} values.}
#'      \item{\code{full_report}}{A (named list of) character strings comprised of \code{estimate} and \code{statistic} for each factor.}
#'      \item{\code{table}}{A \code{data.frame} containing all results; can, for example, be passed to \code{\link{apa_table}}.}
#'    }

apa_print_container <- function() {
  list(
    estimate = NULL
    , statistic = NULL
    , full_result = NULL
    , table = NULL
  )
}


#' Escape symbols for LaTex output
#'
#' This function is a copy of the non-exported function \code{escape_latex} from the \pkg{knitr} package.
#' \emph{This function is not exported.}
#'
#' @param x Character.
#' @param newlines Logical. Determines if \code{\\n} are escaped.
#' @param spaces Logical. Determines if multiple spaces are escaped.
#'
#' @examples
#' \dontrun{
#' in_paren <- TRUE # Taken from printnum()
#' validate(in_paren, check_class = "logical", check_length = 1)
#' validate(in_paren, check_class = "numeric", check_length = 1)
#' }


escape_latex <- function (x, newlines = FALSE, spaces = FALSE) {
  x <- gsub("\\\\", "\\\\textbackslash", x)
  x <- gsub("([#$%&_{}])", "\\\\\\1", x)
  x <- gsub("\\\\textbackslash", "\\\\textbackslash{}", x)
  x <- gsub("~", "\\\\textasciitilde{}", x)
  x <- gsub("\\^", "\\\\textasciicircum{}", x)
  if (newlines)
    x <- gsub("(?<!\n)\n(?!\n)", "\\\\\\\\", x, perl = TRUE)
  if (spaces)
    x <- gsub("  ", "\\\\ \\\\ ", x)
  x
}


#' Convert name of statistic
#'
#' This function converts a character generated by R-functions that describes a statistic and converts it into the
#' corresponding character required by APA guidelines (6th edition). \emph{This function is not exported.}
#'
#' @param x Chracter.
#'
#' @examples
#' \dontrun{
#' convert_stat_name("rho")
#' convert_stat_name("mean of the differences")
#' convert_stat_name("t")
#' }

convert_stat_name <- function(x) {
  validate(x, check_class = "character")

  new_stat_name <- gsub("-squared", "^2", x, ignore.case = TRUE)

  if(length(new_stat_name) == 2 && grepl("mean", new_stat_name)) new_stat_name <- "\\Delta M"
  if(all(grepl("prop \\d", new_stat_name))) {
    new_stat_name <- NULL
    return(new_stat_name)
  }

  new_stat_name <- switch(
    new_stat_name
    , new_stat_name
    , cor = "r"
    , rho = "r_{\\mathrm{s}}"
    , tau = "\\uptau"
    , `mean of x` = "M"
    , `(pseudo)median` = "Mdn^*"
    , `mean of the differences` = "M_d"
    , `difference in location` = "Mdn_d"
    , `Bartlett's K^2` = "K^2"
  )

  new_stat_name <- gsub("x|chi", "\\\\chi", new_stat_name, ignore.case = TRUE)

  new_stat_name
}


#' Create confidence interval string
#'
#' Creates a character string from an object with attribute. \emph{This function is not exported.}
#'
#' @param x Numeric. Either a \code{vector} of length 2 with attribute \code{conf.level} or a two-column \code{matrix}
#'    and confidence region bounds as column names (e.g. "2.5 \%" and "97.5 \%") and coefficient names as row names.
#' @param conf_level Numeric. Vector of length 2 giving the lower and upper bounds of the confidence region in case
#'    they cannot be determined from column names or attributes of \code{x}.
#' @param ... Arguments to pass to \code{\link{printnum}}.
#'
#' @seealso \code{\link{printnum}}
#' @examples
#' \dontrun{
#' print_confint(c(1, 2), conf_level = 0.95)
#' }

print_confint <- function(
  x
  , conf_level = NULL
  , ...
) {
  sapply(x, validate, check_class = "numeric", check_infinite = FALSE)

  if(is.data.frame(x)) x <- as.matrix(x)
  ci <- printnum(x, ...)

  if(!is.null(attr(x, "conf.level"))) conf_level <- attr(x, "conf.level")

  if(!is.null(conf_level)) {
    validate(conf_level, check_class = "numeric", check_length = 1, check_range = c(0, 100))
    if(conf_level < 1) conf_level <- conf_level * 100
    conf_level <- paste0(conf_level, "\\% CI ")
  }

  if(!is.matrix(x)) {
    validate(ci, "x", check_length = 2)
    apa_ci <- paste0(conf_level, "$[", paste(ci, collapse = "$, $"), "]$")
    return(apa_ci)
  } else {
    if(!is.null(rownames(ci))) {
      terms <- sanitize_terms(rownames(ci))
    } else {
      terms <- 1:nrow(ci)
    }

    if(!is.null(colnames(ci)) && is.null(conf_level)) {
      conf_level <- as.numeric(gsub("[^.|\\d]", "", colnames(ci), perl = TRUE))
      conf_level <- 100 - conf_level[1] * 2
      conf_level <- paste0(conf_level, "\\% CI ")
    }

    apa_ci <- list()
    for(i in 1:length(terms)) {
      apa_ci[[terms[i]]] <- paste0(conf_level, "$[", paste(ci[i, ], collapse = "$, $"), "]$")
    }

    apa_ci <- lapply(apa_ci, function(x) sub("$\\infty$", "\\infty", x, fixed = TRUE)) # Fix extra $

    if(length(apa_ci) == 1) apa_ci <- unlist(apa_ci)
    return(apa_ci)
  }
}


#' Sanitize term names
#'
#' Remove characters from term names that will be difficult to adress using the \code{$}-operator. \emph{This function is
#' not exported.}
#'
#' @param x Character. Vector of term-names to be sanitized.
#' @param standardized Logical. If \code{TRUE} the name of the function \code{\link{scale}} will be
#'    removed from term names.
#'
#' @examples
#' \dontrun{
#' sanitize_terms(c("(Intercept)", "Factor A", "Factor B", "Factor A:Factor B", "scale(FactorA)"))
#' }

sanitize_terms <- function(x, standardized = FALSE) {
  if(standardized) x <- gsub("scale\\(", "z_", x)   # Remove scale()
  x <- gsub("\\(|\\)", "", x)                       # Remove parentheses
  x <- gsub("\\W", "_", x)                          # Replace non-word characters with "_"
  x
}


#' Prettify term names
#'
#' Remove parentheses, replace colons with \code{$\\times$}. Useful to prettify term names in \code{apa_print()} tables.
#' \emph{This function is not exported.}
#'
#' @param x Character. Vector of term-names to be prettified
#' @param standardized Logical. If \code{TRUE} the name of the function \code{\link{scale}} will be
#'    removed from term names.
#'
#' @examples
#' NULL

prettify_terms <- function(x, standardized = FALSE) {
  if(standardized) x <- gsub("scale\\(", "", x)       # Remove scale()
  x <- gsub("\\(|\\)|`|.+\\$", "", x)                 # Remove parentheses and backticks
  x <- gsub('.+\\$|.+\\[\\["|"\\]\\]|.+\\[.*,\\s*"|"\\s*\\]', "", x) # Remove data.frame names
  x <- gsub("\\_|\\.", " ", x)                        # Remove underscores
  for (i in 1:length(x)) {
    x2 <- unlist(strsplit(x[i], split = ":"))
    substring(x2, first = 1, last = 1) <- toupper(substring(x2, first = 1, last = 1))
    x[i] <- paste(x2, collapse = " $\\times$ ")
  }
  x
}


#' Select parameters
#'
#' If a \code{list} holds vectors of parameter values, this function extracts the i-th parameter value from each vector and creates
#' a new \code{list} with these values. Especially helpful if a function is call repeatedly via \code{do.call} with different
#' parameter values from within a function.
#'
#' @param x List. A list of parameter values
#' @param i Integer. The i-th element of each vector that is to be extracted.
#'
#' @examples
#' NULL

sel <- function(x, i){
  x <- x[(i-1)%%length(x)+1]
  return(x)
}


#' Set defaults
#'
#' A helper function that is intended for internal use. A list \code{ellipsis} may be manipulated by overwriting (via \code{set}) or adding (via \code{set.if.null}) list elements.
#'
#' @param ellipsis A \code{list}, usually a list that comes from an ellipsis
#' @param set A named  \code{list} of parameters that are intended to be set.
#' @param set.if.null A named \code{list} of parameters that are intended to be set if and only if the parameter is not already in \code{ellipsis}.

defaults <- function(ellipsis, set = NULL, set.if.null = NULL) {

  ellipsis <- as.list(ellipsis)

  for (i in names(set)) {
    ellipsis[[i]] <- set[[i]]
  }
  for (i in names(set.if.null)) {
    if(is.null(ellipsis[[i]])) ellipsis[[i]] <- set.if.null[[i]]
  }
  return(ellipsis)
}



#' Sort ANOVA table by effects
#'
#' Sorts rows in ANOVA table produced by \code{\link{apa_print}} by complexity (i.e., main effects,
#' two-way interactions, three-way interactions, etc.).
#'
#' @param x data.frame. An arbitrary data.frame with a column named "Effect", e.g., a table element
#'    produced by \code{\link{apa_print}}.
#'
#' @return Returns the same data.frame with reordered rows.
#' @export
#'
#' @examples
#' ## From Venables and Ripley (2002) p. 165.
#' npk_aov <- aov(yield ~ block + N * P * K, npk)
#' npk_aov_results <- apa_print(npk_aov)
#' sort_effects(npk_aov_results$table)

sort_effects <- function(x) {
  validate(x, check_class = "data.frame", check_cols = "Effect")

  x[order(sapply(regmatches(x$Effect, gregexpr("\\\\times", x$Effect)), length)), ]
}



# Defines phrases used throughout the manuscript
localize <- function(x) {
  switch(
    x
    , list( # Default
      author_note = "Author note"
      , abstract = "Abstract"
      , keywords = "Keywords"
      , word_count = "Word count"
      , table = "Table"
      , figure = "Figure"
      , note = "Note"
      , correspondence = "Correspondence concerning this article should be addressed to "
      , email = "E-mail"
    )
    , german = list(
      author_note = "Anmerkung des Autors"
      , abstract = "Zusammenfassung"
      , keywords = "Schl\u00fcsselw\u00f6rter"
      , word_count = "Wortanzahl"
      , table = "Tabelle"
      , figure = "Abbildung"
      , note = "Anmerkung"
      , correspondence = "Schriftverkehr diesen Artikel betreffend sollte adressiert sein an "
      , email = "E-Mail"
    )
  )
}

package_available <- function(x) x %in% rownames(utils::installed.packages())
