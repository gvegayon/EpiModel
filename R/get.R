
#' @title Extract Network Objects from Network Simulations
#'
#' @description Extracts the network object from either a network epidemic model
#'              object generated with \code{netsim}, a network diagnostic
#'              simulation generated with \code{netdx}, or a \code{netsim_dat}
#'              object used internally in \code{netsim}. For \code{netdx} or
#'              \code{netsim} with \code{tergmLite == FALSE}, the extracted
#'              network object is a \code{networkDynamic}, which can be
#'              collapsed down to a static \code{network} object with the
#'              \code{collapse} and \code{at} arguments. For \code{netsim} with
#'              \code{tergmLite == TRUE}, the extracted network object is the
#'              final \code{networkLite}, the \code{collapse} argument should be
#'              \code{FALSE}, and the \code{at} argument should be missing. For
#'              \code{netsim_dat}, the \code{collapse} and \code{at} arguments
#'              are not supported, and the network object is either the current
#'              \code{networkLite} (if \code{tergmLite == TRUE}) or the current
#'              \code{networkDynamic} (if \code{tergmLite == FALSE}).
#'
#' @param x An \code{EpiModel} object of class \code{\link{netsim}},
#'        \code{\link{netdx}}, or \code{netsim_dat}.
#' @param sim Simulation number of extracted network, for \code{netdx} and
#'        \code{netsim}.
#' @param network Network number, for \code{netsim} or \code{netsim_dat} objects
#'        with multiple overlapping networks (advanced use, and not applicable
#'        to \code{netdx} objects).
#' @param collapse If \code{TRUE}, collapse the \code{networkDynamic} object to
#'        a static \code{network} object at a specified time step. Applicable to
#'        \code{netdx} objects and \code{netsim} objects with
#'        \code{tergmLite == FALSE}.
#' @param at If \code{collapse} is \code{TRUE}, the time step at which the
#'        extracted network should be collapsed. Applicable to \code{netdx}
#'        objects and \code{netsim} objects with \code{tergmLite == FALSE}.
#' @param ... Additional arguments.
#'
#' @details
#' This function requires that the network object is saved during the network
#' simulation while running either \code{\link{netsim}} or \code{\link{netdx}}.
#' For the former, that is specified by setting the \code{save.network}
#' parameter in \code{\link{control.net}} to \code{TRUE}. For the latter, that
#' is specified with the \code{keep.tnetwork} parameter directly in
#' \code{\link{netdx}}.
#'
#' @return For \code{netdx} or \code{netsim} with \code{tergmLite == FALSE}, a
#'         \code{networkDynamic} object (if \code{collapse = FALSE}) or a
#'         static \code{network} object (if \code{collapse = TRUE}). For
#'         \code{netsim} with \code{tergmLite == TRUE} or \code{netsim_dat} with
#'         \code{tergmLite == TRUE}, a \code{networkLite} object. For
#'         \code{netsim_dat} with \code{tergmLite == FALSE}, a
#'         \code{networkDynamic} object.
#'
#' @keywords extract
#' @export
#'
#' @examples
#' # Set up network and TERGM formula
#' nw <- network_initialize(n = 100)
#' nw <- set_vertex_attribute(nw, "group", rep(1:2, each = 50))
#' formation <- ~edges
#' target.stats <- 50
#' coef.diss <- dissolution_coefs(dissolution = ~offset(edges), duration = 20)
#'
#' # Estimate the model
#' est <- netest(nw, formation, target.stats, coef.diss)
#'
#' # Run diagnostics, saving the networkDynamic objects
#' dx <- netdx(est, nsteps = 10, nsims = 3, keep.tnetwork = TRUE,
#'             verbose = FALSE)
#'
#' # Extract the network for simulation 2 from dx object
#' get_network(dx, sim = 2)
#'
#' # Extract and collapse the network from simulation 1 at time step 5
#' get_network(dx, collapse = TRUE, at = 5)
#'
#' # Parameterize the epidemic model, and simulate it
#' param <- param.net(inf.prob = 0.3, inf.prob.g2 = 0.15)
#' init <- init.net(i.num = 10, i.num.g2 = 10)
#' control <- control.net(type = "SI", nsteps = 10, nsims = 3, verbose = FALSE)
#' mod <- netsim(est, param, init, control)
#'
#' # Extract the network for simulation 2 from mod object
#' get_network(mod, sim = 2)
#'
#' ## Extract and collapse the network from simulation 1 at time step 5
#' get_network(mod, collapse = TRUE, at = 5)
#'
get_network <- function(x, ...) {
  UseMethod("get_network")
}

#' @rdname get_network
#'
#' @export
#'
get_network.netdx <- function(x, sim = 1, collapse = FALSE, at, ...) {

  ## Warnings and checks ##
  nsims <- x$nsims
  if (length(sim) > 1 || sim > nsims) {
    stop("Specify a single sim between 1 and ", nsims, call. = FALSE)
  }

  if (is.null(x$network)) {
    stop("Network object not saved in netdx object.
          Check keep.tnetwork parameter", call. = FALSE)
  }

  nsteps <- x$nsteps
  if (collapse == TRUE && (missing(at) || at > nsteps || at < 0)) {
    stop("Specify collapse time step between 0 and ", nsteps, call. = FALSE)
  }

  ## Extraction ##
  out <- x$network[[sim]]

  ## Collapsing
  if (collapse == TRUE) {
    out <- network.collapse(out, at = at)
  }

  return(out)
}

#' @rdname get_network
#'
#' @export
#'
get_network.netsim <- function(x, sim = 1, network = 1, collapse = FALSE, at, ...) {

  ## Warnings and checks ##
  nsims <- x$control$nsims
  if (length(sim) > 1 || sim > nsims) {
    stop("Specify a single sim between 1 and ", nsims, call. = FALSE)
  }

  if (x$control$tergmLite == TRUE && collapse == TRUE) {
    stop("Argument `collapse` should be FALSE when x$control$tergmLite == TRUE",
         call. = FALSE)
  }

  if (x$control$tergmLite == TRUE && missing(at) == FALSE) {
    stop("Argument `at` should be missing when x$control$tergmLite == TRUE",
         call. = FALSE)
  }

  if (is.null(x$network)) {
    stop("Network object not saved in netsim object. Check control.net settings.",
         call. = FALSE)
  }

  if (network < 1 || network > x$num.nw) {
    stop("Specify network between 1 and ", x$num.nw, call. = FALSE)
  }

  nsteps <- x$control$nsteps
  if (collapse == TRUE && (missing(at) || at > nsteps || at < 0)) {
    stop("Specify collapse time step between 0 and ", nsteps, call. = FALSE)
  }

  ## Extraction ##
  out <- x$network[[sim]][[network]]

  ## Collapsing
  if (collapse == TRUE) {
    out <- network.collapse(out, at = at)
  }

  return(out)
}

#' @rdname get_network
#'
#' @export
#'
get_network.netsim_dat <- function(x, network = 1L, ...) {
  if (get_control(x, "tergmLite") == FALSE) {
    ## networkDynamic
    nw <- x$run$nw[[network]]
  } else {
    ## networkLite
    attr_list <- raw_get_attr_list(x)
    nw <- networkLite(x$run$el[[network]], attr_list, x$run$net_attr[[network]])
  }
  return(nw)
}


#' @title Set Network State During netsim Simulation
#'
#' @description This function updates the \code{netsim_dat} object given a
#'              network representing the current state of the simulation.
#'
#' @param x a \code{netsim_dat} object
#' @param network the index of the network to set on \code{x}
#' @param nw the value of the network to set on \code{x}
#'
#' @details If running \code{tergmLite} simulation, this function updates
#' \code{x$el[[network]]} and (if \code{tergmLite.track.duration} is \code{TRUE}
#' for the network index \code{network}) the network attributes \code{"time"}
#' and \code{"lasttoggle"} in \code{x$net_attr[[network]]}. If not running
#' \code{tergmLite} simulation, this function updates the \code{networkDynamic}
#' object stored in \code{x$nw[[network]]}. The input \code{nw} should be of
#' class \code{networkLite} when running \code{tergmLite} simulation, and of
#' class \code{networkDynamic} when not running \code{tergmLite} simulation.
#'
#' @return the \code{netsim_dat} object with the network state updated
#'
#' @export
#' @keywords netUtils internal
#'
set_network <- function(x, ...) {
  UseMethod("set_network")
}

#' @rdname set_network
#'
#' @export
#'
set_network.netsim_dat <- function(x, network = 1L, nw, ...) {
  if (get_control(x, "tergmLite") == TRUE) {
    x$run$el[[network]] <- as.edgelist(nw)
    if (get_network_control(x, network, "tergmLite.track.duration") == TRUE) {
      x$run$net_attr[[network]][["time"]] <- nw %n% "time"
      x$run$net_attr[[network]][["lasttoggle"]] <- nw %n% "lasttoggle"
    }
  } else {
    x$run$nw[[network]] <- nw
  }
  return(x)
}

#' @title Extract Transmissions Matrix from Network Epidemic Model
#'
#' @description Extracts the matrix of transmission data for each transmission
#'              event that occurred within a network epidemic model.
#'
#' @param x An \code{EpiModel} object of class \code{\link{netsim}}.
#' @param sim Simulation number of extracted network.
#' @param deduplicate If \code{TRUE}, randomly select one transmission event in
#'        the case that multiple events current per newly infected agent within
#'        a time step.
#'
#' @return
#' A data frame with the following standard columns:
#' \itemize{
#'  \item \strong{at:} the time step at which the transmission occurred.
#'  \item \strong{sus:} the ID number of the susceptible (newly infected) node.
#'  \item \strong{inf:} the ID number of the infecting node.
#'  \item \strong{infDur:} the duration of the infecting node's disease at the
#'        time of the transmission.
#'  \item \strong{transProb:} the probability of transmission per act.
#'  \item \strong{actRate:} the rate of acts per unit time.
#'  \item \strong{finalProb:} the final transmission probability for the
#'        transmission event.
#' }
#'
#' @keywords extract
#' @export
#'
#' @examples
#' ## Simulate SI epidemic on two-group Bernoulli random graph
#' nw <- network_initialize(n = 100)
#' nw <- set_vertex_attribute(nw, "group", rep(1:2, each = 50))
#' formation <- ~edges
#' target.stats <- 50
#' coef.diss <- dissolution_coefs(dissolution = ~offset(edges), duration = 20)
#' est <- netest(nw, formation, target.stats, coef.diss, verbose = FALSE)
#' param <- param.net(inf.prob = 0.3, inf.prob.g2 = 0.15)
#' init <- init.net(i.num = 10, i.num.g2 = 10)
#' control <- control.net(type = "SI", nsteps = 10, nsims = 3, verbose = FALSE)
#' mod <- netsim(est, param, init, control)
#'
#' ## Extract the transmission matrix from simulation 2
#' get_transmat(mod, sim = 2)
#'
get_transmat <- function(x, sim = 1, deduplicate = TRUE) {

  ## Warnings and checks
  if (!inherits(x, "netsim")) {
    stop("x must be of class netsim", call. = FALSE)
  }

  if (sim > x$control$nsims) {
    stop("Specify sim between 1 and ", x$control$nsims, call. = FALSE)
  }

  if (x$control$save.transmat == FALSE || is.null(x$stats$transmat)) {
    stop("transmat not saved in netsim object, check control.net settings",
         call. = FALSE)
  }

  ## Extraction
  out <- x$stats$transmat[[sim]]
  out <- dplyr::as_tibble(out)

  if (deduplicate) {
    out <- dplyr::sample_n(dplyr::group_by(out, .data$at, .data$sus), 1)
  }

  class(out) <- c("transmat", class(out))
  return(out)
}


#' @title Extract Network Statistics from netsim or netdx Object
#'
#' @description Extracts network statistics from a network epidemic model
#'              simulated with \code{netsim} or a network diagnostics object
#'              simulated with \code{netdx}. Statistics can be returned either
#'              as a single data frame or as a list of matrices (one matrix
#'              for each simulation).
#'
#' @param x An \code{EpiModel} object of class \code{\link{netsim}} or
#'        \code{\link{netdx}}.
#' @param sim A vector of simulation numbers from the extracted object.
#' @param network Network number, for \code{netsim} objects with multiple
#'        overlapping networks (advanced use, and not applicable to \code{netdx}
#'        objects).
#' @param mode Either \code{"data.frame"} or \code{"list"}, indicating the
#'        desired output.
#'
#' @return A data frame or list of matrices containing the network statistics.
#'
#' @keywords extract
#' @export
#'
#' @examples
#' # Two-group Bernoulli random graph TERGM
#' nw <- network_initialize(n = 100)
#' nw <- set_vertex_attribute(nw, "group", rep(1:2, each = 50))
#' formation <- ~edges
#' target.stats <- 50
#' coef.diss <- dissolution_coefs(dissolution = ~offset(edges), duration = 20)
#' est <- netest(nw, formation, target.stats, coef.diss, verbose = FALSE)
#'
#' dx <- netdx(est, nsim = 3, nsteps = 10, verbose = FALSE,
#'             nwstats.formula = ~edges + isolates)
#' get_nwstats(dx)
#' get_nwstats(dx, sim = 1)
#'
#' # SI epidemic model
#' param <- param.net(inf.prob = 0.3, inf.prob.g2 = 0.15)
#' init <- init.net(i.num = 10, i.num.g2 = 10)
#' control <- control.net(type = "SI", nsteps = 10, nsims = 3,
#'                        nwstats.formula = ~edges + meandeg + degree(0:5),
#'                        verbose = FALSE)
#' mod <- netsim(est, param, init, control)
#'
#' # Extract the network statistics from all or sets of simulations
#' get_nwstats(mod)
#' get_nwstats(mod, sim = 2)
#' get_nwstats(mod, sim = c(1, 3))
#'
#' # On the fly summary stats
#' summary(get_nwstats(mod))
#' colMeans(get_nwstats(mod))
#'
get_nwstats <- function(x, sim, network = 1, mode = c("data.frame", "list")) {

  mode <- match.arg(mode)

  ## Warnings and checks ##
  if (!(class(x) %in% c("netsim", "netdx"))) {
    stop("x must be of class netsim or netdx", call. = FALSE)
  }

  if (inherits(x, "netsim")) {
    nsims <- x$control$nsims
    nsteps <- x$control$nsteps
  } else {
    if (x$dynamic == TRUE) {
      nsims <- x$nsims
      nsteps <- x$nsteps
    } else {
      nsims <- 1
      nsteps <- x$nsims
    }
  }

  if (missing(sim)) {
    sim <- 1:nsims
  }
  if (max(sim) > nsims) {
    stop("Specify sims less than or equal to ", nsims, call. = FALSE)
  }

  if (inherits(x, "netsim")) {
    if (x$control$save.nwstats == FALSE || is.null(x$stats$nwstats)) {
      stop("Network statistics not saved in netsim object, check control.net
           settings", call. = FALSE)
    }
    if (network > x$num.nw) {
      stop("Specify network between 1 and ", x$num.nw, call. = FALSE)
    }
  }

  ## Extraction
  if (inherits(x, "netsim")) {
    out <- lapply(x$stats$nwstats, function(n) n[[network]])
    out <- out[sim]
  } else if (inherits(x, "netdx")) {
    out <- x$stats[sim]
  }

  if (mode == "list") {
    return(lapply(out, as.matrix))
  }

  out <- as.data.frame(do.call("rbind", out))
  out$time <- rep(seq_len(min(nsteps, nrow(out))), length(sim))
  out$sim <- rep(sim, each = min(nsteps, nrow(out)))
  row.names(out) <- seq_len(nrow((out)))
  out <- out[, c((ncol(out) - 1):ncol(out), 1:(ncol(out) - 2))]

  if (inherits(x, "netdx") && x$dynamic == FALSE) {
    out <- out[, -2]
    names(out)[1] <- "sim"
  }

  return(out)
}


#' @title Extract Network Model Parameters
#'
#' @description Extracts a list of network model parameters saved in the
#'              initialization module.
#'
#' @param x Main \code{netsim_dat} data object used in \code{netsim} simulations.
#' @param network Network number, for simulations with multiple networks
#'        representing the population.
#'
#' @keywords extract internal
#' @export
#'
get_nwparam <- function(x, network = 1) {
  x$nwparam[[network]]
}


#' @title Extract Network Simulations
#'
#' @description Subsets the entire \code{netsim} object to a subset of
#'              simulations, essentially functioning like a reverse of
#'              \code{merge}.
#'
#' @param x An object of class \code{netsim}.
#' @param sims Either a numeric vector of simulation numbers to retain in the
#'        output object, or \code{"mean"}, which selects the one simulation with
#'        the value of the variable specified in \code{var} closest to the mean
#'        of \code{var} across all simulations.
#' @param var A character vector of variables to retain from \code{x} if
#'        \code{sims} is a numeric vector, or a single variable name for
#'        selecting the average simulation from the set if \code{sims = "mean"}.
#'
#' @return An updated object of class \code{netsim} containing only the
#'         simulations specified in \code{sims} and the variables specified in
#'         \code{var}.
#'
#' @keywords extract
#' @export
#'
#' @examples
#' # Network model estimation
#' nw <- network_initialize(n = 100)
#' formation <- ~edges
#' target.stats <- 50
#' coef.diss <- dissolution_coefs(dissolution = ~offset(edges), duration = 20)
#' est1 <- netest(nw, formation, target.stats, coef.diss, verbose = FALSE)
#'
#' # Epidemic model
#' param <- param.net(inf.prob = 0.3)
#' init <- init.net(i.num = 10)
#' control <- control.net(type = "SI", nsteps = 10, nsims = 3, verbose.int = 0)
#' mod1 <- netsim(est1, param, init, control)
#'
#' # Get sim 2
#' s.g2 <- get_sims(mod1, sims = 2)
#'
#' # Get sims 2 and 3 and keep only a subset of variables
#' s.g2.small <- get_sims(mod1, sims = 2:3, var = c("i.num", "si.flow"))
#'
#' # Extract the mean simulation for the variable i.num
#' sim.mean <- get_sims(mod1, sims = "mean", var = "i.num")
#'
get_sims <- function(x, sims, var) {

  if (!inherits(x, "netsim")) {
    stop("x must be of class netsim", call. = FALSE)
  }

  nsims <- x$control$nsims

  if (missing(sims)) {
    stop("Specify sims as a vector of simulations or \"mean\" ", call. = FALSE)
  }
  if (length(sims) == 1 && sims ==
        "mean" && (missing(var) || length(var) > 1)) {
    stop("If sims == 'mean' then var must be a single varible name",
         call. = FALSE)
  }

  if (length(sims) == 1 && sims == "mean") {
    d <- tail(x$epi[[var]], 1)
    md <- mean(as.numeric(d))
    sims <- which.min(abs(d - md))
  }

  if (max(sims) > nsims) {
    stop("Maximum sims value for this object is ", nsims, call. = FALSE)
  }

  out <- x
  out$control$nsims <- length(sims)
  newnames <- paste0("sim", seq_len(out$control$nsims))

  delsim <- setdiff(1:nsims, sims)
  if (length(delsim) > 0) {
    for (i in seq_along(out$epi)) {
      out$epi[[i]] <- out$epi[[i]][, -delsim, drop = FALSE]
    }

    if (!is.null(out$run)) {
      out$run[delsim] <- NULL
      names(out$run) <- newnames
    }
    if (!is.null(out$network)) {
      out$network[delsim] <- NULL
      names(out$network) <- newnames
    }
    if (!is.null(out$stats$nwstats)) {
      out$stats$nwstats[delsim] <- NULL
      names(out$stats$nwstats) <- newnames
    }
    if (!is.null(out$stats$transmat)) {
      out$stats$transmat[delsim] <- NULL
      names(out$stats$transmat) <- newnames
    }
    if (!is.null(out$diss.stats)) {
      out$diss.stats[delsim] <- NULL
      names(out$diss.stats) <- newnames
    }
    if (!is.null(out$control$save.other)) {
      oname <- out$control$save.other
      for (i in seq_along(oname)) {
        out[[oname[i]]][delsim] <- NULL
        names(out[[oname[i]]]) <- newnames
      }
    }
  }

  if (!missing(var)) {
    match.vars <- which(var %in% names(x$epi))
    out$epi <- out$epi[match.vars]
  }

  return(out)
}


#' @title Get Arguments from EpiModel Parameterization Functions
#'
#' @description Returns a list of argument names and values for use for
#'              parameter processing functions.
#'
#' @param formal.args The output of \code{formals(sys.function())}.
#' @param dot.args The output of \code{list(...)}.
#'
#' @return A list of argument names and values.
#'
#' @export
#' @keywords internal
#'
get_args <- function(formal.args, dot.args) {
  p <- list()
  formal.args[["..."]] <- NULL
  for (arg in names(formal.args)) {
    p[arg] <- list(get(arg, pos = parent.frame()))
  }

  names.dot.args <- names(dot.args)
  if (length(dot.args) > 0) {
    for (i in seq_along(dot.args)) {
      p[[names.dot.args[i]]] <- dot.args[[i]]
    }
  }
  return(p)
}

#' @title Extract the Parameter Set from Network Simulations
#'
#' @param sims An \code{EpiModel} object of class \code{netsim}.
#'
#' @return A \code{data.frame} with one row per simulation and one column per
#'   parameter or parameter element where the parameters are of size > 1.
#'
#' @section Output Format:
#' The outputted \code{data.frame} has one row per simulation and the columns
#' correspond to the parameters used in this simulation.
#'
#' The column name will match the parameter name if it is a size 1 parameter or
#' if the parameter is of size > 1, there will be N columns (with N being the
#' size of the parameter) named \code{parameter.name_1},
#' \code{parameter.name_2}, ..., \code{parameter.name_N}.
#'
#'
#' @examples
#'
#' # Setup network
#' nw <- network_initialize(n = 50)
#'
#' est <- netest(
#'   nw, formation = ~edges,
#'   target.stats = c(25),
#'   coef.diss = dissolution_coefs(~offset(edges), 10, 0),
#'   verbose = FALSE
#' )
#'
#' init <- init.net(i.num = 10)
#'
#' n <- 5
#'
#' related.param <- data.frame(
#'   dummy.param = rbeta(n, 1, 2)
#' )
#'
#'  my.randoms <- list(
#'    act.rate = param_random(c(0.25, 0.5, 0.75)),
#'    dummy.param = function() rbeta(1, 1, 2),
#'    dummy.strat.param = function() c(
#'      rnorm(1, 0, 10),
#'      rnorm(1, 10, 1)
#'    )
#'  )
#'
#' param <- param.net(
#'   inf.prob = 0.3,
#'   dummy = c(0, 1, 2),
#'   random.params = my.randoms
#' )
#'
#' control <- control.net(type = "SI", nsims = 3, nsteps = 5, verbose = FALSE)
#' mod <- netsim(est, param, init, control)
#'
#' get_param_set(mod)
#' @export
get_param_set <- function(sims) {
  if (!inherits(sims, "netsim")) {
    stop("`sims` must be of class netsim")
  }

  p.random <- sims[["param"]][["random.params.values"]]
  fixed.names <- setdiff(
    names(sims[["param"]]),
    c(names(p.random), "random.params", "random.params.values")
  )

  p.fixed <- sims[["param"]][fixed.names]

  d.param <- data.frame(sim = seq_len(sims[["control"]][["nsims"]]))

  # Fixed parameters
  for (i in seq_along(p.fixed)) {
    val <- p.fixed[[i]]
    name <- names(p.fixed)[i]
    l <- length(val)

    if (l > 1) {
      name <- paste0(name, "_", seq_len(l))
    }

    names(val) <- name
    d.param <- cbind(d.param, t(val))
  }

  # Random parameters
  for (i in seq_along(p.random)) {
    val <- p.random[[i]]
    name <- names(p.random)[i]

    if (is.list(val)) {
      l <- length(val[[1]])
      val <- matrix(Reduce(c, val), ncol = l, byrow = TRUE)
      colnames(val) <- paste0(name, "_", seq_len(l))
      d.param <- cbind(d.param, val)
    } else {
      d.param[name] <- val
    }
  }

  return(d.param)
}

#' @title Extract the Attributes History from Network Simulations
#'
#' @param sims An \code{EpiModel} object of class \code{netsim}.
#'
#' @return A list of \code{data.frame}s, one for each "measure" recorded in the
#' simulation by the \code{record_attr_history} function.
#'
#' @examples
#' \dontrun{
#'
#' # With `sims` the result of a `netsim` call
#' get_attr_history(sims)
#'
#' }
#'
#' @export
#'
get_attr_history <- function(sims) {
  if (!inherits(sims, "netsim")) {
    stop("`sims` must be of class netsim")
  }

  simnames <- names(sims[["attr.history"]])

  dfs <- list()

  for (name in simnames) {
    records <- sims[["attr.history"]][[name]]
    records <- records$as_list()
    attributes <- vapply(records, function(x) x[["attribute"]], "")
    attributes.names <- unique(attributes)

    simnum <- as.numeric(sub("[^0-9]*", "", name))

    for (a in attributes.names) {
      parts <- Filter(function(x) x[["attribute"]] == a, records)
      parts <- lapply(parts, dplyr::as_tibble)
      d <- dplyr::bind_rows(parts)
      d[["sim"]] <- simnum
      d <- dplyr::select(d, "sim", "time", "attribute", "uids", "values")
      dfs[[a]] <- dplyr::bind_rows(dfs[[a]], d)
    }
  }

  return(dfs)
}
