#!/usr/bin/env Rscript

# EpiModel Profile-Ready Benchmarking Script
# Designed to profile simulate_dat performance bottleneck
# Generated by: GitHub Copilot (Claude Sonnet 4)
# Date: July 16, 2025
# Purpose: Profiling-focused benchmark for analyzing simulate_dat bottleneck
# Reference: GitHub issue #935 - simulate_dat performance optimization

library(EpiModel)

# For profiling, you can uncomment the line below:
# library(profvis)

# Set seed for reproducibility
set.seed(12345)

cat("EpiModel Profile Benchmark - simulate_dat focus\n")
cat("Network: 1000 nodes, 30 steps, 5 sims\n")
cat("Configured for tergmLite with network resimulation\n\n")

# Network setup
nw <- network_initialize(n = 1000)

# Use a slightly more complex model to stress test simulate_dat
nw <- set_vertex_attribute(nw, "group", rbinom(1000, 1, 0.5))
formation <- ~edges + nodematch("group")
target.stats <- c(500, 150)  # 500 edges, 150 homophilous edges
coef.diss <- dissolution_coefs(dissolution = ~offset(edges), duration = 20)

cat("Estimating network model...\n")
est <- netest(nw, formation, target.stats, coef.diss, verbose = FALSE)

# Epidemic parameters
param <- param.net(inf.prob = 0.3, act.rate = 1.0)
init <- init.net(i.num = 20)

# Control settings optimized for profiling simulate_dat
control <- control.net(
  type = "SI",
  nsteps = 30,
  nsims = 5,  # Fewer sims for focused profiling
  resimulate.network = TRUE,  # This triggers simulate_dat calls
  tergmLite = TRUE,          # Use tergmLite as mentioned in issue
  verbose = FALSE,
  # Default TERGM control - this is where bottleneck may be
  save.nwstats = TRUE
)

cat("Starting simulation with profiling focus...\n")

# To profile this script, wrap the netsim call like this:
# profvis({
#   mod <- netsim(est, param, init, control)
# })

# For benchmarking without profvis:
start_time <- Sys.time()
mod <- netsim(est, param, init, control)
end_time <- Sys.time()

runtime <- as.numeric(end_time - start_time, units = "secs")

cat("\n=== PROFILE BENCHMARK RESULTS ===\n")
cat(sprintf("Total runtime: %.2f seconds\n", runtime))
cat(sprintf("Average per simulation: %.2f seconds\n", runtime / 5))
cat(sprintf("Average per time step: %.3f seconds\n", runtime / (30 * 5)))

# Key performance metrics for simulate_dat analysis
cat("\n=== PERFORMANCE CONTEXT ===\n")
cat("Network size:", 1000, "nodes\n")
cat("Average degree:", mean(get_degree(get_network(mod))), "\n")
cat("Final infected:", sum(mod$epi$i.num[31, ], na.rm = TRUE), "\n")
cat("Network resimulations:", 30 * 5, "total\n")

cat("\n=== PROFILING INSTRUCTIONS ===\n")
cat("To profile this script:\n")
cat("1. Uncomment 'library(profvis)' at the top\n")
cat("2. Wrap the netsim call with profvis({ ... })\n")
cat("3. Look for time spent in 'simulate_dat' and 'ergm_model.term_list'\n")

cat("\nBenchmark completed - ready for profiling!\n")
