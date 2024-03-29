#' Automatic estimation of number of principal components in PCA
#'
#' @description Automatic estimation of number of principal components in PCA
#' with PEnalized SEmi-integrated Likelihood (PESEL).
#'
#' @details Version: 0.7.5
#' @docType package
#' @name pesel-package
#' @importFrom stats cov
#' @importFrom graphics plot points
#' @importFrom utils head
#' @author{ Piotr Sobczyk,
#'          Julie Josse,
#'          Malgorzata Bogdan
#'
#' Maintainer: Piotr Sobczyk \email{pj.sobczyk@@gmail.com}
#' }
#' @references Piotr Sobczyk, Malgorzata Bogdan, Julie Josse
#' "Bayesian dimensionality reduction with PCA using penalized semi-integrated likelihood",
#' Journal of Computational and Graphical Statistics 2017
#'
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
NULL
