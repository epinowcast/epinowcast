# These tests check that `use_batched_likelihood` (enw_fit_opts()) is a
# pure implementation choice: it must not change the log density or the
# gradient, whether or not within-chain threading is used.
#
# Each configuration needs a report-date model. Without one the reference
# model is used directly as probabilities (`ref_as_p = 1` in the Stan
# model), which skips the hazard-to-probability step the batched path
# replaces, so the two paths would agree trivially.
skip_on_cran()
skip_on_local()

pobs <- enw_example("preprocessed")

batched_configs <- list(
  snapshots = list(
    report = enw_report(~ (1 | day_of_week), data = pobs),
    likelihood_aggregation = "snapshots"
  ),
  groups = list(
    report = enw_report(~ (1 | day_of_week), data = pobs),
    likelihood_aggregation = "groups"
  ),
  non_parametric = list(
    reference = enw_reference(
      parametric = ~0, distribution = "none",
      non_parametric = ~ 1 + (1 | delay), data = pobs
    ),
    report = enw_report(~ (1 | day_of_week), data = pobs),
    likelihood_aggregation = "snapshots"
  )
)

fit_batched_config <- function(config, model, threads_per_chain, batched) {
  modules <- config[setdiff(names(config), "likelihood_aggregation")]
  suppressMessages(do.call(epinowcast, c(
    list(
      data = pobs,
      model = model,
      fit = enw_fit_opts(
        sampler = silent_enw_sample, save_warmup = FALSE, pp = FALSE,
        nowcast = FALSE, chains = 1, iter_warmup = 20, iter_sampling = 20,
        refresh = 0, seed = 101, threads_per_chain = threads_per_chain,
        likelihood_aggregation = config$likelihood_aggregation,
        use_batched_likelihood = batched
      )
    ),
    modules
  )))
}

test_that(
  paste(
    "use_batched_likelihood gives the same log_prob()/grad_log_prob() as",
    "the per-snapshot path, with threading off and on"
  ),
  {
    # log_prob() needs model methods, which cmdstanr only builds when it
    # compiles, so a cached executable cannot be reused here.
    model <- enw_model(
      threads = TRUE, compile_model_methods = TRUE, force_recompile = TRUE,
      target_dir = file.path(tempdir(), "batched-likelihood"), verbose = FALSE
    )
    for (config_name in names(batched_configs)) {
      for (threads_per_chain in c(1L, 2L)) {
        config <- batched_configs[[config_name]]
        nc0 <- fit_batched_config(config, model, threads_per_chain, FALSE)
        nc1 <- fit_batched_config(config, model, threads_per_chain, TRUE)
        # Guard against a vacuous comparison (see the note at the top).
        expect_gt(nc0$data[[1]]$model_rep, 0)
        f0 <- nc0$fit[[1]]
        f1 <- nc1$fit[[1]]
        f0$init_model_methods(seed = 1, verbose = FALSE)
        f1$init_model_methods(seed = 1, verbose = FALSE)
        u <- f0$unconstrain_draws(format = "draws_matrix", inc_warmup = FALSE)
        for (i in seq_len(nrow(u))) {
          d <- as.numeric(u[i, ])
          lp0 <- f0$log_prob(d, jacobian = TRUE)
          lp1 <- f1$log_prob(d, jacobian = TRUE)
          expect_equal(lp0, lp1, tolerance = 1e-10)
          expect_equal(
            f0$grad_log_prob(d, jacobian = TRUE),
            f1$grad_log_prob(d, jacobian = TRUE),
            tolerance = 1e-8
          )
        }
      }
    }
  }
)
