# Initialize functions for R logging

.h2o.calcLogFileName <- function() {
  paste0(tempdir(), "/rest.log")
}

.h2o.getLogFileName <- function() {
  name <- get("LOG_FILE_NAME", .pkg.env)
  if (is.null(name))
    name <- .h2o.calcLogFileName()
  name
}

.h2o.isLogging <- function() {
  get("IS_LOGGING", .pkg.env)
}

.h2o.logRest <- function(message) {
  if (.h2o.isLogging())
    write(x = message, file = .h2o.getLogFileName(), append = TRUE)
}

h2o.logIt <- function(m, tmp, commandOrErr, isPost = TRUE) {
  # Legacy.  Do nothing.
}

#' @export
h2o.startLogging <- function(file) {
  if (missing(file)) {
    logFileName <- .h2o.calcLogFileName()
  } else {
    stopifnot(is.character(file))
    logFileName <- file
  }
  assign("LOG_FILE_NAME", logFileName, .pkg.env)
  assign("IS_LOGGING", TRUE, envir = .pkg.env)
  cat("Appending REST API transactions to log file", logFileName, "\n")
}

#' @export
h2o.stopLogging <- function() {
  assign("IS_LOGGING", FALSE, envir = .pkg.env)
  cat("Logging stopped\n")
}

#' @export
h2o.clearLog <- function() {
  file.remove(.h2o.getLogFileName())
  cat("Removed file ", .h2o.getLogFileName(), "\n")
}

#' @export
h2o.openLog <- function(type) {
  myFile <- .h2o.getLogFileName()
  if(!file.exists(myFile))
    stop(myFile, " does not exist")

  if(.Platform$OS.type == "windows")
    shell.exec(paste0("open '", myFile, "'"))
  else
    system(paste0("open '", myFile, "'"))
}

#' Log a message on the server-side logs
#'
#' This is helpful when running several pieces of work one after the other on a single H2O
#' cluster and you want to make a notation in the H2O server side log where one piece of
#' work ends and the next piece of work begins.
#'
#' \code{h2o.logAndEcho} sends a message to H2O for logging. Generally used for debugging purposes.
#'
#' @param message A character string with the message to write to the log.
#' @param conn An \code{H2OConnection} object pointing to a running H2O cluster.
#' @seealso \code{\link{H2OConnection}}
#' @export
h2o.logAndEcho <- function(message, conn = h2o.getConnection()) {
  if (is(message, "H2OConnection")) {
    temp <- message
    message <- conn
    conn <- temp
  }

  if(!is(conn, "H2OConnection"))
    stop("`conn` must be an H2OConnection object")

  if(!is.character(message))
    stop("`message` must be a character string")

  res <- .h2o.__remoteSend(conn, .h2o.__LOGANDECHO, message = message, method = "POST")
  res$message
}

#' Download H2O Log Files to Disk
#'
#' \code{h2o.downloadAllLogs} downloads all H2O log files to local disk. Generally used for debugging purposes.
#'
#' @param conn An \code{H2OConnection} object pointing to a running H2O cluster.
#' @param dirname (Optional) A character string indicating the directory that the log file should be saved in.
#' @param filename (Optional) A character string indicating the name that the log file should be saved to.
#' @seealso \code{\link{H2OConnection}}
#' @export
h2o.downloadAllLogs <- function(conn = h2o.getConnection(), dirname = ".", filename = NULL) {
  if(!is(conn, "H2OConnection"))
    stop("`conn` must be an H2OConnection object")

  if(!is.character(dirname) || length(dirname) != 1L || is.na(dirname) || !nzchar(dirname))
    stop("`dirname` must be a non-empty character string")

  if(!is.character(filename) || length(filename) != 1L || is.na(filename) || !nzchar(filename))
    stop("`filename` must be a non-empty character string")

  url <- paste0("http://", conn@ip, ":", conn@port, "/", .h2o.__DOWNLOAD_LOGS)
  if(!file.exists(dirname))
    dir.create(dirname)

  cat("Downloading H2O logs from server...\n")
  h <- basicHeaderGatherer()
  tempfile <- getBinaryURL(url, headerfunction = h$update, verbose = TRUE)

  # Get filename from HTTP header of response
  if(is.null(filename)) {
    atch <- h$value()[["Content-Disposition"]]
    ind <- regexpr("filename=", atch)[[1L]]
    if(ind == -1L)
      stop("Header corrupted: Expected attachment filename in Content-Disposition")
    filename <- substr(atch, ind + nchar("filename="), nchar(atch))
  }

  myPath <- file.path(normalizePath(dirname), filename)

  cat("Writing H2O logs to", myPath, "\n")
  writeBin(tempfile, myPath)
}
