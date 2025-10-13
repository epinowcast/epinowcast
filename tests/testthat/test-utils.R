test_that(
  ".format_delay_with_units formats correctly for different timesteps",
  {
    # Daily timestep
    expect_identical(
      epinowcast:::.format_delay_with_units(7, "day"),
      "7 days"
    )
    expect_identical(
      epinowcast:::.format_delay_with_units(1, "day"),
      "1 day"
    )

    # Weekly timestep
    expect_identical(
      epinowcast:::.format_delay_with_units(3, "week"),
      "3 weeks (21 days)"
    )
    expect_identical(
      epinowcast:::.format_delay_with_units(1, "week"),
      "1 week (7 days)"
    )

    # Monthly timestep
    expect_identical(
      epinowcast:::.format_delay_with_units(2, "month"),
      "2 months"
    )
    expect_identical(
      epinowcast:::.format_delay_with_units(1, "month"),
      "1 month"
    )

    # Custom numeric timestep
    expect_identical(
      epinowcast:::.format_delay_with_units(4, 5),
      "4 5-days (20 days)"
    )

    # With pre-computed daily_max_delay
    expect_identical(
      epinowcast:::.format_delay_with_units(
        2, "week",
        daily_max_delay = 14
      ),
      "2 weeks (14 days)"
    )
  }
)
