#' H2O Generalized Linear Models
#'
#' Fit a generalized linear model, specified by a response variable, a set of predictors, and a description of the error distribution.
#'
#' @param x A vector containing the names or indices of the predictor variables to use in building the GLM model.
#' @param y A character string or index that represent the response variable in the model.
#' @param training_frame An \code{\linkS4class{H2OFrame}} object containing the variables in the model.
#' @param destination_key (Optional) An unique hex key assigned to the resulting model. If none is given, a key will automatically be generated.
#' @param validation_frame An \code{\linkS4class{H2OFrame}} object containing the variables in the model.
#' @param max_iter A non-negative integer specifying the maximum number of iterations.
#' @param beta_eps A non-negative number specifying the magnitude of the maximum difference between the coefficient estimates from successive iterations.
#'        Defines the convergence criterion for \code{h2o.glm}.
#' @param solver A character string specifying the solver used: ADMM (supports more features), L_BFGS (scales better for datasets with many columns)
#' @param standardize A logical value indicating whether the numeric predictors should be standardized to have a mean of 0 and a variance of 1 prior to
#'        training the models.
#' @param family A character string specifying the distribution of the model:  gaussian, binomial, poisson, gamma, tweedie.
#' @param link A character string specifying the link function. The default is the canonical link for the \code{family}. The supported links for each of
#'        the \code{family} specifications are:
#'        \code{"gaussian"}: \code{"identity"}, \code{"log"}, \code{"inverse"}\cr
#'        \code{"binomial"}: \code{"logit"}, \code{"log"}\cr
#'        \code{"poisson"}: \code{"log"}, \code{"identity"}\cr
#'        \code{"gamma"}: \code{"inverse"}, \code{"log"}, \code{"identity"}\cr
#'        \code{"tweedie"}: \code{"tweedie"}\cr
#' @param tweedie_variance_power A numeric specifying the power for the variance function when \code{family = "tweedie"}.
#' @param tweedie_link_power A numeric specifying the power for the link function when \code{family = "tweedie"}.
#' @param alpha A numeric in [0, 1] specifying the elastic-net mixing parameter.
#'                The elastic-net penalty is defined to be:
#'                \deqn{P(\alpha,\beta) = (1-\alpha)/2||\beta||_2^2 + \alpha||\beta||_1 = \sum_j [(1-\alpha)/2 \beta_j^2 + \alpha|\beta_j|]},
#'                making \code{alpha = 1} the lasso penalty and \code{alpha = 0} the ridge penalty.
#' @param lambda A non-negative shrinkage parameter for the elastic-net, which multiplies \eqn{P(\alpha,\beta)} in the objective function.
#'               When \code{lambda = 0}, no elastic-net penalty is applied and ordinary generalized linear models are fit.
#' @param prior1 (Optional) A numeric specifying the prior probability of class 1 in the response when \code{family = "binomial"}.
#'               The default prior is the observational frequency of class 1.
#' @param lambda_search A logical value indicating whether to conduct a search over the space of lambda values starting from the lambda max, given
#'                      \code{lambda} is interpreted as lambda min.
#' @param nlambdas The number of lambda values to use when \code{lambda_search = TRUE}.
#' @param lambda_min_ratio Smallest value for lambda as a fraction of lambda.max. By default if the number of observations is greater than the
#'                         the number of variables then \code{lambda_min_ratio} = 0.0001; if the number of observations is less than the number
#'                         of variables then \code{lambda_min_ratio} = 0.01.
#' @param use_all_factor_levels A logical value indicating whether dummy variables should be used for all factor levels of the categorical predictors.
#'                              When \code{TRUE}, results in an over parameterized models.
#' @param n_folds (Currently Unimplemented)
#' @param ...
#' @export
h2o.glm <- function(x, y, training_frame, destination_key, validation_frame,
                    max_iterations = 50,
                    beta_epsilon = 0,
                    balance_classes = FALSE,
                    class_sampling_factors,
                    max_after_balance_size = 5.0,
                    solver = c("ADMM", "L_BFGS"),
                    standardize = TRUE,
                    family = c("gaussian", "binomial", "poisson", "gamma", "tweedie"),
                    link = c("family_default", "identity", "logit", "log", "inverse", "tweedie"),
                    tweedie_variance_power = NaN,
                    tweedie_link_power = NaN,
                    alpha = 0.5,
                    prior = 0.0,
                    lambda = 1e-05,
                    lambda_search = FALSE,
                    nlambdas = -1,
                    lambda_min_ratio = -1.0,
                    use_all_factor_levels = FALSE,
                    nfolds,
                    beta_constraints = NULL,
                    ...
                    )
{
  if (!is.null(beta_constraints)) {
      if (!inherits(beta_constraints, "data.frame") && !inherits(beta_constraints, "H2OFrame"))
        stop(paste("`beta_constraints` must be an H2OParsedData or R data.frame. Got: ", class(beta_constraints)))
      if (inherits(beta_constraints, "data.frame")) {
        beta_constraints <- as.h2o(training_frame@conn, beta_constraints)
      }
  }
  #Handle ellipses
  if (length(list(...)) > 0)
    dots <- .model.ellipses( list(...))

  if (!inherits(training_frame, "H2OFrame"))
   tryCatch(training_frame <- h2o.getFrame(training_frame),
            error = function(err) {
              stop("argument \"training_frame\" must be a valid H2OFrame or key")
            })

  # Parameter list to send to model builder
  parms <- list()
  parms$training_frame <- training_frame
  args <- .verify_dataxy(training_frame, x, y)
  parms$ignored_columns <- args$x_ignore
  parms$response_column <- args$y
  if(!missing(max_iterations))
    parms$max_iterations <- max_iterations
  if(!missing(beta_epsilon))
    parms$beta_epsilon <- beta_epsilon
  if(!missing(class_sampling_factors))
    parms$class_sampling_factors <- class_sampling_factors
  if(!missing(max_after_balance_size))
    parms$max_after_balance_size <- max_after_balance_size
  if(!missing(solver))
    parms$solver <- solver
  if(!missing(standardize))
    parms$standardize <- standardize
  if(!missing(family))
    parms$family <- family
  if(!missing(link))
    parms$link <- link
  if(!missing(tweedie_variance_power))
    parms$tweedie_variance_power <- tweedie_variance_power
  if(!missing(tweedie_link_power))
    parms$tweedie_link_power <- tweedie_link_power
  if(!missing(alpha))
    parms$alpha <- alpha
  if(!missing(prior))
    parms$prior <- prior
  if(!missing(lambda))
    parms$lambda <- lambda
  if(!missing(lambda_search))
    parms$lambda_search <- lambda_search
  if(!missing(nlambdas))
    parms$nlambdas <- nlambdas
  if(!missing(lambda_min_ratio))
    parms$lambda_min_ratio <- lambda_min_ratio
  if(!missing(use_all_factor_levels))
    parms$use_all_factor_levels <- use_all_factor_levels
  # For now, accept nfolds in the R interface if it is 0 or 1, since those values really mean do nothing.
  # For any other value, error out.
  # Expunge nfolds from the message sent to H2O, since H2O doesn't understand it.
  if(!missing(nfolds))
    if (nfolds > 1) stop("nfolds >1 not supported")
  #   parms$nfolds <- nfolds
  if(!missing(beta_constraints))
    parms$beta_constraints <- beta_constraints

  m <- .h2o.createModel(training_frame@conn, 'glm', parms)
  m@model$coefficients <- m@model$coefficients_table[,2]
  names(m@model$coefficients) <- m@model$coefficients_table[,1]
  m
}

#' @export
h2o.makeGLMModel <- function(model,beta) {
   cat("beta =",beta,",",paste("[",paste(as.vector(beta),collapse=","),"]"))
   res = .h2o.__remoteSend(model@conn, method="POST", .h2o.__GLMMakeModel, model=model@key, names = paste("[",paste(paste("\"",names(beta),"\"",sep=""), collapse=","),"]",sep=""), beta = paste("[",paste(as.vector(beta),collapse=","),"]",sep=""))
   m <- h2o.getModel(key=res$key$name)
   m@model$coefficients <- m@model$coefficients_table[,2]
   names(m@model$coefficients) <- m@model$coefficients_table[,1]
   m
}

#' @export
h2o.startGLMJob <- function(x, y, training_frame, destination_key, validation_frame,
                    #AUTOGENERATED Params
                    max_iterations = 50,
                    beta_epsilon = 0,
                    balance_classes = FALSE,
                    class_sampling_factors,
                    max_after_balance_size = 5.0,
                    solver = c("ADMM", "L_BFGS"),
                    standardize = TRUE,
                    family = c("gaussian", "binomial", "poisson", "gamma", "tweedie"),
                    link = c("family_default", "identity", "logit", "log", "inverse", "tweedie"),
                    tweedie_variance_power = NaN,
                    tweedie_link_power = NaN,
                    alpha = 0.5,
                    prior = 0.0,
                    lambda = 1e-05,
                    lambda_search = FALSE,
                    nlambdas = -1,
                    lambda_min_ratio = 1.0,
                    use_all_factor_levels = FALSE,
                    nfolds = 0,
                    beta_constraints = NULL,
                    ...
                    )
{
  if (!is.null(beta_constraints)) {
      if (!inherits(beta_constraints, "data.frame") && !inherits(beta_constraints, "H2OFrame"))
        stop(paste("`beta_constraints` must be an H2OParsedData or R data.frame. Got: ", class(beta_constraints)))
      if (inherits(beta_constraints, "data.frame")) {
        beta_constraints <- as.h2o(training_frame@conn, beta_constraints)
      }
  }

  if (!inherits(training_frame, "H2OFrame"))
      tryCatch(training_frame <- h2o.getFrame(training_frame),
               error = function(err) {
                 stop("argument \"training_frame\" must be a valid H2OFrame or key")
              })

    parms <- list()
    args <- .verify_dataxy(training_frame, x, y)
    parms$ignored_columns <- args$x_ignore
    parms$response_column <- args$y
    parms$training_frame  = training_frame
    parms$beta_constraints = beta_constraints
    if(!missing(destination_key))
      parms$destination_key <- destination_key
    if(!missing(validation_frame))
      parms$validation_frame <- validation_frame
    if(!missing(max_iterations))
      parms$max_iterations <- max_iterations
    if(!missing(beta_epsilon))
      parms$beta_epsilon <- beta_epsilon
    if(!missing(balance_classes))
      parms$balance_classes <- balance_classes
    if(!missing(class_sampling_factors))
      parms$class_sampling_factors <- class_sampling_factors
    if(!missing(max_after_balance_size))
      parms$max_after_balance_size <- max_after_balance_size
    if(!missing(solver))
      parms$solver <- solver
    if(!missing(standardize))
      parms$standardize <- standardize
    if(!missing(family))
      parms$family <- family
    if(!missing(link))
      parms$link <- link
    if(!missing(tweedie_variance_power))
      parms$tweedie_variance_power <- tweedie_variance_power
    if(!missing(tweedie_link_power))
      parms$tweedie_link_power <- tweedie_link_power
    if(!missing(alpha))
      parms$alpha <- alpha
    if(!missing(prior))
      parms$prior <- prior
    if(!missing(lambda))
      parms$lambda <- lambda
    if(!missing(lambda_search))
      parms$lambda_search <- lambda_search
    if(!missing(nlambdas))
      parms$nlambdas <- nlambdas
    if(!missing(lambda_min_ratio))
      parms$lambda_min_ratio <- lambda_min_ratio
    if(!missing(use_all_factor_levels))
      parms$use_all_factor_levels <- use_all_factor_levels
    if(!missing(nfolds))
      parms$nfolds <- nfolds

    .h2o.startModelJob(training_frame@conn, 'glm', parms)
}

#' @export
h2o.getGLMModel <- function(keys) {
  job_key  <- keys[[1]]
  dest_key <- keys[[1]]
  .h2o.__waitOnJob(conn, job_key)
  model <- h2o.getModel(dest_key, conn)
  if (delete_train)
    h2o.rm(temp_train_key)
  if (!is.null(params$validation_frame))
    if (delete_valid)
      h2o.rm(temp_valid_key)
  model
}