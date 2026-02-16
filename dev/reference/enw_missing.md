# Missing reference data model module

Missing reference data model module

## Usage

``` r
enw_missing(formula = ~1, data)
```

## Arguments

- formula:

  A formula (as implemented in
  [`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md))
  describing the missing data proportion on the logit scale by reference
  date. This can use features defined by reference date as defined in
  `metareference` as produced by
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).
  Set to `~0` to disable the missing data model when no missingness is
  present (the model is not estimated in this case). When a model is
  specified, an intercept is always required. See
  [`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md)
  for details on formula syntax.

- data:

  Output from
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).

## Value

A list containing the supplied formulas, data passed into a list
describing the models, a `data.frame` describing the priors used, and a
function that takes the output data and priors and returns a function
that can be used to sample from a tightened version of the prior
distribution.

## See also

Model modules
[`enw_expectation()`](https://package.epinowcast.org/dev/reference/enw_expectation.md),
[`enw_fit_opts()`](https://package.epinowcast.org/dev/reference/enw_fit_opts.md),
[`enw_obs()`](https://package.epinowcast.org/dev/reference/enw_obs.md),
[`enw_reference()`](https://package.epinowcast.org/dev/reference/enw_reference.md),
[`enw_report()`](https://package.epinowcast.org/dev/reference/enw_report.md)

## Examples

``` r
# Missingness model with a fixed intercept only
enw_missing(data = enw_example("preprocessed"))
#> $formula
#> [1] "~1"
#> 
#> $data
#> $data$miss_fintercept
#> [1] 1
#> 
#> $data$miss_fnrow
#> [1] 40
#> 
#> $data$miss_findex
#>  [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
#> [26] 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40
#> 
#> $data$miss_fnindex
#> [1] 40
#> 
#> $data$miss_fncol
#> [1] 0
#> 
#> $data$miss_rncol
#> [1] 0
#> 
#> $data$miss_fdesign
#>   
#> 1 
#> 2 
#> 3 
#> 4 
#> 5 
#> 6 
#> 7 
#> 8 
#> 9 
#> 10
#> 11
#> 12
#> 13
#> 14
#> 15
#> 16
#> 17
#> 18
#> 19
#> 20
#> 21
#> 22
#> 23
#> 24
#> 25
#> 26
#> 27
#> 28
#> 29
#> 30
#> 31
#> 32
#> 33
#> 34
#> 35
#> 36
#> 37
#> 38
#> 39
#> 40
#> 
#> $data$miss_rdesign
#>      (Intercept)
#> attr(,"assign")
#> [1] 0
#> 
#> $data$miss_st
#> [1] 21
#> 
#> $data$miss_cst
#> [1] 21
#> 
#> $data$missing_reference
#>  [1] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
#> 
#> $data$obs_by_report
#>         0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17
#>  [1,] 381 362 343 324 305 286 267 248 229 210 191 172 153 134 115  96  77  58
#>  [2,] 401 382 363 344 325 306 287 268 249 230 211 192 173 154 135 116  97  78
#>  [3,] 421 402 383 364 345 326 307 288 269 250 231 212 193 174 155 136 117  98
#>  [4,] 441 422 403 384 365 346 327 308 289 270 251 232 213 194 175 156 137 118
#>  [5,] 461 442 423 404 385 366 347 328 309 290 271 252 233 214 195 176 157 138
#>  [6,] 481 462 443 424 405 386 367 348 329 310 291 272 253 234 215 196 177 158
#>  [7,] 501 482 463 444 425 406 387 368 349 330 311 292 273 254 235 216 197 178
#>  [8,] 521 502 483 464 445 426 407 388 369 350 331 312 293 274 255 236 217 198
#>  [9,] 541 522 503 484 465 446 427 408 389 370 351 332 313 294 275 256 237 218
#> [10,] 561 542 523 504 485 466 447 428 409 390 371 352 333 314 295 276 257 238
#> [11,] 581 562 543 524 505 486 467 448 429 410 391 372 353 334 315 296 277 258
#> [12,] 601 582 563 544 525 506 487 468 449 430 411 392 373 354 335 316 297 278
#> [13,] 621 602 583 564 545 526 507 488 469 450 431 412 393 374 355 336 317 298
#> [14,] 641 622 603 584 565 546 527 508 489 470 451 432 413 394 375 356 337 318
#> [15,] 661 642 623 604 585 566 547 528 509 490 471 452 433 414 395 376 357 338
#> [16,] 681 662 643 624 605 586 567 548 529 510 491 472 453 434 415 396 377 358
#> [17,] 701 682 663 644 625 606 587 568 549 530 511 492 473 454 435 416 397 378
#> [18,] 721 702 683 664 645 626 607 588 569 550 531 512 493 474 455 436 417 398
#> [19,] 741 722 703 684 665 646 627 608 589 570 551 532 513 494 475 456 437 418
#> [20,] 761 742 723 704 685 666 647 628 609 590 571 552 533 514 495 476 457 438
#> [21,] 781 762 743 724 705 686 667 648 629 610 591 572 553 534 515 496 477 458
#>        18  19
#>  [1,]  39  20
#>  [2,]  59  40
#>  [3,]  79  60
#>  [4,]  99  80
#>  [5,] 119 100
#>  [6,] 139 120
#>  [7,] 159 140
#>  [8,] 179 160
#>  [9,] 199 180
#> [10,] 219 200
#> [11,] 239 220
#> [12,] 259 240
#> [13,] 279 260
#> [14,] 299 280
#> [15,] 319 300
#> [16,] 339 320
#> [17,] 359 340
#> [18,] 379 360
#> [19,] 399 380
#> [20,] 419 400
#> [21,] 439 420
#> 
#> $data$model_miss
#> [1] 1
#> 
#> $data$miss_obs
#> [1] 21
#> 
#> 
#> $priors
#>        variable
#>          <char>
#> 1:     miss_int
#> 2: miss_beta_sd
#>                                                                         description
#>                                                                              <char>
#> 1:          Intercept on the logit scale for the proportion missing reference dates
#> 2: Standard deviation of scaled pooled logit missing reference date\n       effects
#>             distribution  mean    sd
#>                   <char> <num> <num>
#> 1:                Normal     0     1
#> 2: Zero truncated normal     0     1
#> 
#> $inits
#> function (data, priors) 
#> {
#>     priors <- enw_priors_as_data_list(priors)
#>     fn <- function() {
#>         init <- list(miss_int = numeric(0), miss_beta = numeric(0), 
#>             miss_beta_sd = numeric(0))
#>         if (data$model_miss) {
#>             init$miss_int <- array(rnorm(1, priors$miss_int_p[1], 
#>                 priors$miss_int_p[2]))
#>             if (data$miss_fncol > 0) {
#>                 init$miss_beta <- array(rnorm(data$miss_fncol, 
#>                   0, 0.01))
#>             }
#>             if (data$miss_rncol > 0) {
#>                 init$miss_beta_sd <- array(abs(rnorm(data$miss_rncol, 
#>                   priors$miss_beta_sd_p[1], priors$miss_beta_sd_p[2]/10)))
#>             }
#>         }
#>         init
#>     }
#>     fn
#> }
#> <bytecode: 0x56526e2b8950>
#> <environment: 0x56526e2b1150>
#> 

# No missingness model specified
enw_missing(~0, data = enw_example("preprocessed"))
#> $formula
#> [1] "~0"
#> 
#> $data
#> $data$miss_fintercept
#> [1] 0
#> 
#> $data$miss_fnrow
#> [1] 0
#> 
#> $data$miss_findex
#> numeric(0)
#> 
#> $data$miss_fnindex
#> [1] 0
#> 
#> $data$miss_fncol
#> [1] 0
#> 
#> $data$miss_rncol
#> [1] 0
#> 
#> $data$miss_fdesign
#> numeric(0)
#> 
#> $data$miss_rdesign
#> numeric(0)
#> 
#> $data$missing_reference
#> numeric(0)
#> 
#> $data$obs_by_report
#> numeric(0)
#> 
#> $data$miss_st
#> numeric(0)
#> 
#> $data$miss_cst
#> numeric(0)
#> 
#> $data$model_miss
#> [1] 0
#> 
#> $data$miss_obs
#> [1] 0
#> 
#> 
#> $priors
#>        variable
#>          <char>
#> 1:     miss_int
#> 2: miss_beta_sd
#>                                                                         description
#>                                                                              <char>
#> 1:          Intercept on the logit scale for the proportion missing reference dates
#> 2: Standard deviation of scaled pooled logit missing reference date\n       effects
#>             distribution  mean    sd
#>                   <char> <num> <num>
#> 1:                Normal     0     1
#> 2: Zero truncated normal     0     1
#> 
#> $inits
#> function (data, priors) 
#> {
#>     priors <- enw_priors_as_data_list(priors)
#>     fn <- function() {
#>         init <- list(miss_int = numeric(0), miss_beta = numeric(0), 
#>             miss_beta_sd = numeric(0))
#>         if (data$model_miss) {
#>             init$miss_int <- array(rnorm(1, priors$miss_int_p[1], 
#>                 priors$miss_int_p[2]))
#>             if (data$miss_fncol > 0) {
#>                 init$miss_beta <- array(rnorm(data$miss_fncol, 
#>                   0, 0.01))
#>             }
#>             if (data$miss_rncol > 0) {
#>                 init$miss_beta_sd <- array(abs(rnorm(data$miss_rncol, 
#>                   priors$miss_beta_sd_p[1], priors$miss_beta_sd_p[2]/10)))
#>             }
#>         }
#>         init
#>     }
#>     fn
#> }
#> <bytecode: 0x56526e2b8950>
#> <environment: 0x565282bcb198>
#> 
```
