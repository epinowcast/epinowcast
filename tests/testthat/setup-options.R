# We want to flag partial matching as part of our testing & continuous
# integration process because it makes code more brittle.
options(
  warnPartialMatchAttr = TRUE,
  warnPartialMatchDollar = TRUE,
  # This needs to remain FALSE for now as one of our indirect dependencies
  # (abind) uses partial matching in its code. See #343 for details.
  warnPartialMatchArgs = FALSE
)
