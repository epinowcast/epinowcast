skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
skip_on_local()

# `expected_obs_from_snaps_batched()` is a pure-Stan, mathematically
# identical reformulation of `expected_obs_from_snaps()`: it replaces one
# `inv_logit()`/`log1m()`/`cumulative_sum()` call per snapshot with a
# single call spanning every snapshot in the range, resetting the
# within-snapshot survival recurrence at each snapshot boundary. These
# tests check the two give the same log expected observations.
#
# Stan's `array[,] int` (and higher-dimensional integer arrays) are exposed
# to R as nested lists (one list level per dimension), unlike `matrix`
# (a real-valued 2D type), which stays a plain R matrix.
array_to_nested_list <- function(x) {
  d <- dim(x)
  if (is.null(d) || length(d) == 1) {
    return(as.integer(x))
  }
  rec <- function(x, d) {
    if (length(d) == 1) {
      return(as.integer(x))
    }
    rest <- d[-1]
    lapply(seq_len(d[1]), function(i) {
      idx <- c(
        list(x, i), rep(list(quote(expr = )), length(rest)),
        list(drop = FALSE)
      )
      sub <- array(do.call(`[`, idx), dim = rest)
      rec(sub, rest)
    })
  }
  rec(x, d)
}

make_batched_test_case <- function(seed, g = 2L, t = 6L, dmax = 5L,
                                   s = 10L, ref_p = 1L, ref_np = 0L,
                                   rep_h = 1L, ref_as_p = 0L,
                                   rep_agg_p = 0L) {
  withr::with_seed(seed, {
    sg <- sample(seq_len(g), s, replace = TRUE)
    st <- sample(seq_len(t), s, replace = TRUE)
    sl <- sample(seq_len(dmax), s, replace = TRUE)
    csl <- cumsum(sl)
    sdmax <- rep(dmax, s)
    csdmax <- cumsum(sdmax)

    imp_obs <- lapply(seq_len(g), function(x) rnorm(t, 2, 0.3))

    nrefp <- max(1L, g)
    refp_lh <- matrix(rnorm(dmax * nrefp, 0, 1), nrow = dmax, ncol = nrefp)
    dpmfs <- sample(seq_len(nrefp), s, replace = TRUE)

    refnp_lh <- if (ref_np) rnorm(csdmax[s], 0, 1) else numeric(0)

    srdlh <- if (rep_h) rnorm(t + dmax + 5, 0, 1) else numeric(0)
    rdlurd_mat <- if (rep_h) {
      matrix(
        sample(seq_along(srdlh), g * (t + dmax), replace = TRUE),
        nrow = g, ncol = t + dmax
      )
    } else {
      matrix(1L, nrow = g, ncol = t + dmax)
    }

    rep_agg_n_selected <- array(0L, dim = c(g, t, dmax))
    rep_agg_selected_idx <- array(0L, dim = c(g, t, dmax, dmax))
  })

  list(
    start = 1L, end = s, imp_obs = imp_obs,
    rdlurd = array_to_nested_list(rdlurd_mat), srdlh = srdlh,
    refp_lh = refp_lh, dpmfs = dpmfs, ref_p = ref_p, rep_h = rep_h,
    ref_as_p = ref_as_p, sl = sl, csl = csl, sg = sg, st = st,
    n = csl[s], refnp_lh = refnp_lh, ref_np = ref_np, sdmax = sdmax,
    csdmax = csdmax, rep_agg_p = rep_agg_p,
    rep_agg_n_selected = array_to_nested_list(rep_agg_n_selected),
    rep_agg_selected_idx = array_to_nested_list(rep_agg_selected_idx)
  )
}

expect_batched_equal <- function(d) {
  old <- do.call(expected_obs_from_snaps, d)
  new <- do.call(expected_obs_from_snaps_batched, d)
  expect_identical(is.nan(old), is.nan(new))
  expect_identical(is.infinite(old), is.infinite(new))
  finite <- is.finite(old) & is.finite(new)
  expect_equal(old[finite], new[finite], tolerance = 1e-8)
}

configs <- expand.grid(
  ref_p = c(0L, 1L), ref_np = c(0L, 1L), rep_h = c(0L, 1L),
  ref_as_p = c(0L, 1L)
)

test_that(
  "expected_obs_from_snaps_batched() matches expected_obs_from_snaps() ",
  {
    for (cfg_i in seq_len(nrow(configs))) {
      cfg <- configs[cfg_i, ]
      for (seed in 1:10) {
        d <- make_batched_test_case(
          seed = seed * 1000 + cfg_i, ref_p = cfg$ref_p,
          ref_np = cfg$ref_np, rep_h = cfg$rep_h, ref_as_p = cfg$ref_as_p
        )
        expect_batched_equal(d)
      }
    }
  }
)

test_that(
  "expected_obs_from_snaps_batched() matches for a single-snapshot range",
  {
    d <- make_batched_test_case(seed = 99, s = 1L, t = 1L, g = 1L)
    expect_batched_equal(d)
  }
)

test_that(
  paste(
    "expected_obs_from_snaps_batched() matches for many snapshots and",
    "groups (many_snapshots_dow-like)"
  ),
  {
    d <- make_batched_test_case(
      seed = 7, g = 6L, t = 60L, dmax = 20L, s = 300L
    )
    expect_batched_equal(d)
  }
)

test_that(
  "expected_obs_from_snaps_batched() matches with probability aggregation",
  {
    d <- make_batched_test_case(
      seed = 42, s = 4L, ref_p = 1L, rep_h = 1L, rep_agg_p = 1L
    )
    dmax_agg <- 5L
    g_agg <- 2L
    t_agg <- 6L
    nsel <- array(0L, dim = c(g_agg, t_agg, dmax_agg))
    sidx <- array(0L, dim = c(g_agg, t_agg, dmax_agg, dmax_agg))
    for (gg in seq_len(g_agg)) {
      for (tt in seq_len(t_agg)) {
        for (dd in seq_len(dmax_agg)) {
          nsel[gg, tt, dd] <- 1L
          sidx[gg, tt, dd, 1] <- dd
        }
      }
    }
    d$rep_agg_n_selected <- array_to_nested_list(nsel)
    d$rep_agg_selected_idx <- array_to_nested_list(sidx)
    expect_batched_equal(d)
  }
)

test_that(
  paste(
    "expected_obs_from_snaps_batched() matches for the retrospective",
    "(no delay/report effects) path"
  ),
  {
    d <- make_batched_test_case(
      seed = 5, ref_p = 0L, ref_np = 0L, rep_h = 0L
    )
    d$sl <- rep(1L, length(d$sl))
    d$csl <- cumsum(d$sl)
    d$sdmax <- d$sl
    d$csdmax <- cumsum(d$sdmax)
    d$n <- d$csl[d$end]
    expect_batched_equal(d)
  }
)

# Restrict a full test case to snapshots `start:end`, as a `reduce_sum()`
# slice does, and optionally make some snapshots zero-length.
slice_test_case <- function(d, start, end, zero = integer(0)) {
  d$sl[zero] <- 0L
  d$csl <- cumsum(d$sl)
  d$start <- as.integer(start)
  d$end <- as.integer(end)
  d$n <- sum(d$sl[start:end])
  d
}

test_that(
  paste(
    "expected_obs_from_snaps_batched() matches on sub-ranges and with",
    "zero-length snapshots"
  ),
  {
    for (cfg_i in seq_len(nrow(configs))) {
      cfg <- configs[cfg_i, ]
      for (seed in 1:5) {
        d <- make_batched_test_case(
          seed = seed * 77 + cfg_i, s = 12L, ref_p = cfg$ref_p,
          ref_np = cfg$ref_np, rep_h = cfg$rep_h, ref_as_p = cfg$ref_as_p
        )
        expect_batched_equal(slice_test_case(d, 4L, 9L, zero = c(4L, 6L)))
        expect_batched_equal(slice_test_case(d, 12L, 12L))
        expect_batched_equal(slice_test_case(d, 2L, 12L, zero = 12L))
      }
    }
  }
)

test_that(
  paste(
    "expected_obs_from_snaps_batched() matches with the +Inf terminal",
    "logit hazard at the maximum delay"
  ),
  {
    for (seed in 1:5) {
      d <- make_batched_test_case(seed = seed, s = 10L, dmax = 5L)
      # Parametric reference hazards pin the final hazard to 1, so the
      # logit hazard at the maximum delay is +Inf.
      d$refp_lh[5, ] <- Inf
      d$sl[c(2, 5, 9)] <- 5L
      d$csl <- cumsum(d$sl)
      d$n <- d$csl[d$end]
      expect_batched_equal(d)
    }
  }
)

test_that(
  paste(
    "expected_obs_from_snaps_batched() keeps a saturated hazard within",
    "its own snapshot"
  ),
  {
    for (lh in c(40, 800, Inf)) {
      d <- make_batched_test_case(seed = 3, s = 6L, dmax = 5L)
      d$sl <- rep(5L, 6)
      d$csl <- cumsum(d$sl)
      d$n <- d$csl[d$end]
      # A hazard that rounds to 1 before the final delay makes log1m()
      # return -Inf. Only later slots of the same snapshot may be affected.
      d$refp_lh[2, ] <- lh
      expect_batched_equal(d)
      new <- do.call(expected_obs_from_snaps_batched, d)
      expect_false(anyNA(new))
    }
  }
)

test_that(
  "expected_obs_from_snaps_batched() keeps a NaN hazard within its snapshot",
  {
    d <- make_batched_test_case(seed = 4, s = 6L, dmax = 5L)
    d$sl <- rep(5L, 6)
    d$csl <- cumsum(d$sl)
    d$n <- d$csl[d$end]
    d$refp_lh[2, 1] <- NaN
    d$dpmfs <- c(2L, 1L, 2L, 2L, 2L, 2L)
    expect_batched_equal(d)
  }
)
