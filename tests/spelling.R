if (requireNamespace("spelling", quietly = TRUE)) {
  # Only run spell check when RUN_SPELLING_CHECK is set to avoid
  # inconsistencies between R versions
  run_spelling <- Sys.getenv("RUN_SPELLING_CHECK", "false")

  if (tolower(run_spelling) == "true") {
    spelling::spell_check_test(
      vignettes = TRUE,
      error = TRUE,
      skip_on_cran = TRUE,
      lang = "en-GB"
    )
  }
}
