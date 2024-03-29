#' Automatic estimation of number of principal components in PCA
#' with PEnalized SEmi-integrated Likelihood (PESEL)
#'
#' Underlying assumption is that only small number of principal components,
#' associated with largest singular values, is relevent, while the rest of them
#' is noise. For a given numeric data set, function estimates the number of PCs
#' according to penalized likelihood criterion. Function adjusts the model used
#' to the case when number of variables is larger than the number of
#' observations.
#'
#' Please note that no categorical variables and missing values are allowed.
#'
#'
#' @param X a data frame or a matrix contatining only continuous variables
#' @param npc.min minimal number of principal components, for all the possible
#' number of PCs between npc.min and npc.max criterion is computed
#' @param npc.max maximal number of principal components, if greater than
#' dimensions of X, min(ncol(X), nrow(X))-1 is used, for all the possible
#' number of PCs between npc.min and npc.max criterion is computed
#' @param prior a numeric positive vector of length npc.max-ncp.min+1. Prior distribution on
#' number of principal components. Defaults to uniform distibution
#' @param scale a boolean, if TRUE (default value) then data is scaled before
#' applying criterion
#' @param method name of criterion to be used
#' @param asymptotics a character, asymptotics ('n' or 'p') to be used. Default is NULL
#' for which asymptotics is selected based on dimensions of X
#' @export
#' @return number of components
#' @examples
#' # EXAMPLE 1 - noise
#' with(set.seed(23), pesel(matrix(rnorm(10000), ncol = 100), npc.min = 0))
#'
#' # EXAMPLE 2 - fixed effects PCA model
#' sigma <- 0.5
#' k <-  5
#' n <- 100
#' numb.vars <- 10
#' # factors are drawn from normal distribution
#' factors <- replicate(k, rnorm(n, 0, 1))
#' # coefficients are drawn from uniform distribution
#' coeff <- replicate(numb.vars, rnorm(k, 0, 1))
#' SIGNAL <- scale(factors %*% coeff)
#' X <- SIGNAL + replicate(numb.vars, sigma * rnorm(n))
#' pesel(X)
#'
pesel <- function(X, npc.min = 0, npc.max = 10, prior = NULL, scale = TRUE,
                      method = c("heterogenous", "homogenous"), asymptotics = NULL){
  # preprocessing on X
  # number of components must be smaller than dimensions of X
  n = nrow(X)
  p = ncol(X)
  npc.max = min(npc.max, min(n,p)-1)
  npc.min = max(npc.min, 0)
  if(is.null(prior)){
    prior = rep(1/(npc.max - npc.min + 1), npc.max - npc.min + 1)
  } else if(length(prior) != npc.max - npc.min + 1){
    stop("Prior needs to be a vector of length npc.max - npc.min + 1")
  } else if(!is.numeric(prior)){
    stop("Prior needs to be a numeric vector")
  } else if(any(prior < 0)){
    stop("Prior needs to be a positive vector")
  }

  method = match.arg(method)

  if("data.frame" %in% class(X)){
    X = as.matrix(X)
  }

  if(sum(sapply(X, is.numeric)) < p){
    stop("All the variables have to be numeric")
  }
  missing = which(is.na(X))
  if(length(missing) !=  0){
    stop("There are missing values")
  }

  vals = numeric(length(prior))
  if(is.null(asymptotics)){
    vals = if(p > n) {
      if(scale[1] == TRUE){
        X = t(scale(X))
      } else{
        X = t(X)
      }
      X = as.matrix(X)
      switch(method,
             "heterogenous" = pesel_heterogeneous(X, npc.min, npc.max),
             "homogenous" = pesel_homogeneous(X, npc.min, npc.max))
    } else {
      if(scale[1] == TRUE){
        X <- t(as.matrix(scale(t(X))))
      }
      switch(method,
             "heterogenous" = pesel_heterogeneous(X, npc.min, npc.max),
             "homogenous" = pesel_homogeneous(X, npc.min, npc.max))
    }
  } else if(asymptotics == "p") {
    if(scale[1] == TRUE){
      X = t(scale(X))
    } else{
      X = t(X)
    }
    X <- as.matrix(X)
    vals = switch(method,
                  "heterogenous" = pesel_heterogeneous(X, npc.min, npc.max),
                  "homogenous" = pesel_homogeneous(X, npc.min, npc.max))
  } else if(asymptotics == "n") {
    if(scale[1] == TRUE){
      X <- t(as.matrix(scale(t(X))))
    }
    vals = switch(method,
                  "heterogenous" = pesel_heterogeneous(X, npc.min, npc.max),
                  "homogenous" = pesel_homogeneous(X, npc.min, npc.max))
  } else {
    stop("asymptotics must be either NULL, 'n' or 'p'")
  }
  posterior = vals + log(prior)
  posterior = posterior - max(posterior) + 20
  posterior = exp(posterior)/sum(exp(posterior))

  result = NULL
  result$nPCs = npc.min - 1 + which.max(vals + log(prior))
  result$vals = vals
  result$prior = prior
  result$posterior = posterior
  result$npc.min = npc.min
  result$npc.max = npc.max
  class(result) = "pesel.result"
  result
}


#' Plot pesel.result class object
#'
#' @param x pesel.result class object
#' @param posterior a boolean, if TRUE (default value) then posterior probablities are plotted
#' otherwise values of PeSeL criterion are plotted
#' @param ... Further arguments to be passed to or from other methods. They are ignored in this function.
#' @return No return value, called for side effects
#' @export
#' @keywords internal
  plot.pesel.result <- function(x, posterior = TRUE, ...){
  if(posterior){
    probs = x$posterior
    ylabel = "Posterior probability"
    title = "Posterior probabilities for PeSeL"
  } else{
    probs = x$vals + log(x$prior)
    ylabel = "PeSeL"
    title = "Number of components selected by PeSeL"
  }
  plot(x$npc.min:x$npc.max, probs, xlab = "Number of components",
       ylab = ylabel, main = title, type = "b")
  points(x$npc.min-1+which.max(probs), max(probs), col = "red")
}

#' Print pesel.result class object
#'
#' @param x pesel.result class object
#' @param ... Further arguments to be passed to or from other methods. They are ignored in this function.
#' @return No return value, called for side effects
#' @export
#' @keywords internal
print.pesel.result <- function(x,...){
  cat("$nPCs: ", x$nPCs, "\n")
  cat("$vals: value of PeSeL criterion\n")
  cat("$prior: prior probabilities\n")
  cat("$posterior: posterior probabilities\n")
  cat("$npc.min: ", x$npc.min, "\n")
  cat("$npc.max: ", x$npc.max, "\n")
}
