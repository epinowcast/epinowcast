# enw_reference supports parametric models

    Code
      ref <- enw_reference(~ 1 + (1 | day_of_week) + rw(week), distribution = "lognormal",
      data = pobs)
      ref$inits <- NULL
      ref
    Output
      $formula
      $formula$parametric
      [1] "~1 + (1 | day_of_week) + rw(week)"
      
      $formula$non_parametric
      [1] "~1"
      
      
      $data
      $data$refp_fintercept
      [1] 1
      
      $data$refp_fnrow
      [1] 41
      
      $data$refp_findex
       [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
      [26] 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41
      
      $data$refp_fnindex
      [1] 41
      
      $data$refp_fncol
      [1] 12
      
      $data$refp_rncol
      [1] 2
      
      $data$refp_fdesign
         day_of_weekFriday day_of_weekMonday day_of_weekSaturday day_of_weekSunday
      1                  0                 0                   0                 0
      2                  0                 0                   0                 0
      3                  0                 0                   0                 0
      4                  1                 0                   0                 0
      5                  0                 0                   1                 0
      6                  0                 0                   0                 1
      7                  0                 1                   0                 0
      8                  0                 0                   0                 0
      9                  0                 0                   0                 0
      10                 0                 0                   0                 0
      11                 1                 0                   0                 0
      12                 0                 0                   1                 0
      13                 0                 0                   0                 1
      14                 0                 1                   0                 0
      15                 0                 0                   0                 0
      16                 0                 0                   0                 0
      17                 0                 0                   0                 0
      18                 1                 0                   0                 0
      19                 0                 0                   1                 0
      20                 0                 0                   0                 1
      21                 0                 1                   0                 0
      22                 0                 0                   0                 0
      23                 0                 0                   0                 0
      24                 0                 0                   0                 0
      25                 1                 0                   0                 0
      26                 0                 0                   1                 0
      27                 0                 0                   0                 1
      28                 0                 1                   0                 0
      29                 0                 0                   0                 0
      30                 0                 0                   0                 0
      31                 0                 0                   0                 0
      32                 1                 0                   0                 0
      33                 0                 0                   1                 0
      34                 0                 0                   0                 1
      35                 0                 1                   0                 0
      36                 0                 0                   0                 0
      37                 0                 0                   0                 0
      38                 0                 0                   0                 0
      39                 1                 0                   0                 0
      40                 0                 0                   1                 0
      41                 0                 0                   0                 1
         day_of_weekThursday day_of_weekTuesday day_of_weekWednesday cweek1 cweek2
      1                    0                  1                    0      0      0
      2                    0                  0                    1      0      0
      3                    1                  0                    0      0      0
      4                    0                  0                    0      0      0
      5                    0                  0                    0      0      0
      6                    0                  0                    0      0      0
      7                    0                  0                    0      0      0
      8                    0                  1                    0      1      0
      9                    0                  0                    1      1      0
      10                   1                  0                    0      1      0
      11                   0                  0                    0      1      0
      12                   0                  0                    0      1      0
      13                   0                  0                    0      1      0
      14                   0                  0                    0      1      0
      15                   0                  1                    0      1      1
      16                   0                  0                    1      1      1
      17                   1                  0                    0      1      1
      18                   0                  0                    0      1      1
      19                   0                  0                    0      1      1
      20                   0                  0                    0      1      1
      21                   0                  0                    0      1      1
      22                   0                  1                    0      1      1
      23                   0                  0                    1      1      1
      24                   1                  0                    0      1      1
      25                   0                  0                    0      1      1
      26                   0                  0                    0      1      1
      27                   0                  0                    0      1      1
      28                   0                  0                    0      1      1
      29                   0                  1                    0      1      1
      30                   0                  0                    1      1      1
      31                   1                  0                    0      1      1
      32                   0                  0                    0      1      1
      33                   0                  0                    0      1      1
      34                   0                  0                    0      1      1
      35                   0                  0                    0      1      1
      36                   0                  1                    0      1      1
      37                   0                  0                    1      1      1
      38                   1                  0                    0      1      1
      39                   0                  0                    0      1      1
      40                   0                  0                    0      1      1
      41                   0                  0                    0      1      1
         cweek3 cweek4 cweek5
      1       0      0      0
      2       0      0      0
      3       0      0      0
      4       0      0      0
      5       0      0      0
      6       0      0      0
      7       0      0      0
      8       0      0      0
      9       0      0      0
      10      0      0      0
      11      0      0      0
      12      0      0      0
      13      0      0      0
      14      0      0      0
      15      0      0      0
      16      0      0      0
      17      0      0      0
      18      0      0      0
      19      0      0      0
      20      0      0      0
      21      0      0      0
      22      1      0      0
      23      1      0      0
      24      1      0      0
      25      1      0      0
      26      1      0      0
      27      1      0      0
      28      1      0      0
      29      1      1      0
      30      1      1      0
      31      1      1      0
      32      1      1      0
      33      1      1      0
      34      1      1      0
      35      1      1      0
      36      1      1      1
      37      1      1      1
      38      1      1      1
      39      1      1      1
      40      1      1      1
      41      1      1      1
      
      $data$refp_rdesign
         fixed day_of_week rw__week
      1      0           1        0
      2      0           1        0
      3      0           1        0
      4      0           1        0
      5      0           1        0
      6      0           1        0
      7      0           1        0
      8      0           0        1
      9      0           0        1
      10     0           0        1
      11     0           0        1
      12     0           0        1
      attr(,"assign")
      [1] 1 2 3
      
      $data$model_refp
      [1] 2
      
      $data$refnp_fintercept
      [1] 1
      
      $data$refnp_fnrow
      [1] 820
      
      $data$refnp_findex
        [1]   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18
       [19]  19  20  21  22  23  24  25  26  27  28  29  30  31  32  33  34  35  36
       [37]  37  38  39  40  41  42  43  44  45  46  47  48  49  50  51  52  53  54
       [55]  55  56  57  58  59  60  61  62  63  64  65  66  67  68  69  70  71  72
       [73]  73  74  75  76  77  78  79  80  81  82  83  84  85  86  87  88  89  90
       [91]  91  92  93  94  95  96  97  98  99 100 101 102 103 104 105 106 107 108
      [109] 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126
      [127] 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144
      [145] 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162
      [163] 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180
      [181] 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198
      [199] 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216
      [217] 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234
      [235] 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252
      [253] 253 254 255 256 257 258 259 260 261 262 263 264 265 266 267 268 269 270
      [271] 271 272 273 274 275 276 277 278 279 280 281 282 283 284 285 286 287 288
      [289] 289 290 291 292 293 294 295 296 297 298 299 300 301 302 303 304 305 306
      [307] 307 308 309 310 311 312 313 314 315 316 317 318 319 320 321 322 323 324
      [325] 325 326 327 328 329 330 331 332 333 334 335 336 337 338 339 340 341 342
      [343] 343 344 345 346 347 348 349 350 351 352 353 354 355 356 357 358 359 360
      [361] 361 362 363 364 365 366 367 368 369 370 371 372 373 374 375 376 377 378
      [379] 379 380 381 382 383 384 385 386 387 388 389 390 391 392 393 394 395 396
      [397] 397 398 399 400 401 402 403 404 405 406 407 408 409 410 411 412 413 414
      [415] 415 416 417 418 419 420 421 422 423 424 425 426 427 428 429 430 431 432
      [433] 433 434 435 436 437 438 439 440 441 442 443 444 445 446 447 448 449 450
      [451] 451 452 453 454 455 456 457 458 459 460 461 462 463 464 465 466 467 468
      [469] 469 470 471 472 473 474 475 476 477 478 479 480 481 482 483 484 485 486
      [487] 487 488 489 490 491 492 493 494 495 496 497 498 499 500 501 502 503 504
      [505] 505 506 507 508 509 510 511 512 513 514 515 516 517 518 519 520 521 522
      [523] 523 524 525 526 527 528 529 530 531 532 533 534 535 536 537 538 539 540
      [541] 541 542 543 544 545 546 547 548 549 550 551 552 553 554 555 556 557 558
      [559] 559 560 561 562 563 564 565 566 567 568 569 570 571 572 573 574 575 576
      [577] 577 578 579 580 581 582 583 584 585 586 587 588 589 590 591 592 593 594
      [595] 595 596 597 598 599 600 601 602 603 604 605 606 607 608 609 610 611 612
      [613] 613 614 615 616 617 618 619 620 621 622 623 624 625 626 627 628 629 630
      [631] 631 632 633 634 635 636 637 638 639 640 641 642 643 644 645 646 647 648
      [649] 649 650 651 652 653 654 655 656 657 658 659 660 661 662 663 664 665 666
      [667] 667 668 669 670 671 672 673 674 675 676 677 678 679 680 681 682 683 684
      [685] 685 686 687 688 689 690 691 692 693 694 695 696 697 698 699 700 701 702
      [703] 703 704 705 706 707 708 709 710 711 712 713 714 715 716 717 718 719 720
      [721] 721 722 723 724 725 726 727 728 729 730 731 732 733 734 735 736 737 738
      [739] 739 740 741 742 743 744 745 746 747 748 749 750 751 752 753 754 755 756
      [757] 757 758 759 760 761 762 763 764 765 766 767 768 769 770 771 772 773 774
      [775] 775 776 777 778 779 780 781 782 783 784 785 786 787 788 789 790 791 792
      [793] 793 794 795 796 797 798 799 800 801 802 803 804 805 806 807 808 809 810
      [811] 811 812 813 814 815 816 817 818 819 820
      
      $data$refnp_fnindex
      [1] 820
      
      $data$refnp_fncol
      [1] 0
      
      $data$refnp_rncol
      [1] 0
      
      $data$refnp_fdesign
         
      1  
      2  
      3  
      4  
      5  
      6  
      7  
      8  
      9  
      10 
      11 
      12 
      13 
      14 
      15 
      16 
      17 
      18 
      19 
      20 
      21 
      22 
      23 
      24 
      25 
      26 
      27 
      28 
      29 
      30 
      31 
      32 
      33 
      34 
      35 
      36 
      37 
      38 
      39 
      40 
      41 
      42 
      43 
      44 
      45 
      46 
      47 
      48 
      49 
      50 
      51 
      52 
      53 
      54 
      55 
      56 
      57 
      58 
      59 
      60 
      61 
      62 
      63 
      64 
      65 
      66 
      67 
      68 
      69 
      70 
      71 
      72 
      73 
      74 
      75 
      76 
      77 
      78 
      79 
      80 
      81 
      82 
      83 
      84 
      85 
      86 
      87 
      88 
      89 
      90 
      91 
      92 
      93 
      94 
      95 
      96 
      97 
      98 
      99 
      100
      101
      102
      103
      104
      105
      106
      107
      108
      109
      110
      111
      112
      113
      114
      115
      116
      117
      118
      119
      120
      121
      122
      123
      124
      125
      126
      127
      128
      129
      130
      131
      132
      133
      134
      135
      136
      137
      138
      139
      140
      141
      142
      143
      144
      145
      146
      147
      148
      149
      150
      151
      152
      153
      154
      155
      156
      157
      158
      159
      160
      161
      162
      163
      164
      165
      166
      167
      168
      169
      170
      171
      172
      173
      174
      175
      176
      177
      178
      179
      180
      181
      182
      183
      184
      185
      186
      187
      188
      189
      190
      191
      192
      193
      194
      195
      196
      197
      198
      199
      200
      201
      202
      203
      204
      205
      206
      207
      208
      209
      210
      211
      212
      213
      214
      215
      216
      217
      218
      219
      220
      221
      222
      223
      224
      225
      226
      227
      228
      229
      230
      231
      232
      233
      234
      235
      236
      237
      238
      239
      240
      241
      242
      243
      244
      245
      246
      247
      248
      249
      250
      251
      252
      253
      254
      255
      256
      257
      258
      259
      260
      261
      262
      263
      264
      265
      266
      267
      268
      269
      270
      271
      272
      273
      274
      275
      276
      277
      278
      279
      280
      281
      282
      283
      284
      285
      286
      287
      288
      289
      290
      291
      292
      293
      294
      295
      296
      297
      298
      299
      300
      301
      302
      303
      304
      305
      306
      307
      308
      309
      310
      311
      312
      313
      314
      315
      316
      317
      318
      319
      320
      321
      322
      323
      324
      325
      326
      327
      328
      329
      330
      331
      332
      333
      334
      335
      336
      337
      338
      339
      340
      341
      342
      343
      344
      345
      346
      347
      348
      349
      350
      351
      352
      353
      354
      355
      356
      357
      358
      359
      360
      361
      362
      363
      364
      365
      366
      367
      368
      369
      370
      371
      372
      373
      374
      375
      376
      377
      378
      379
      380
      381
      382
      383
      384
      385
      386
      387
      388
      389
      390
      391
      392
      393
      394
      395
      396
      397
      398
      399
      400
      401
      402
      403
      404
      405
      406
      407
      408
      409
      410
      411
      412
      413
      414
      415
      416
      417
      418
      419
      420
      421
      422
      423
      424
      425
      426
      427
      428
      429
      430
      431
      432
      433
      434
      435
      436
      437
      438
      439
      440
      441
      442
      443
      444
      445
      446
      447
      448
      449
      450
      451
      452
      453
      454
      455
      456
      457
      458
      459
      460
      461
      462
      463
      464
      465
      466
      467
      468
      469
      470
      471
      472
      473
      474
      475
      476
      477
      478
      479
      480
      481
      482
      483
      484
      485
      486
      487
      488
      489
      490
      491
      492
      493
      494
      495
      496
      497
      498
      499
      500
      501
      502
      503
      504
      505
      506
      507
      508
      509
      510
      511
      512
      513
      514
      515
      516
      517
      518
      519
      520
      521
      522
      523
      524
      525
      526
      527
      528
      529
      530
      531
      532
      533
      534
      535
      536
      537
      538
      539
      540
      541
      542
      543
      544
      545
      546
      547
      548
      549
      550
      551
      552
      553
      554
      555
      556
      557
      558
      559
      560
      561
      562
      563
      564
      565
      566
      567
      568
      569
      570
      571
      572
      573
      574
      575
      576
      577
      578
      579
      580
      581
      582
      583
      584
      585
      586
      587
      588
      589
      590
      591
      592
      593
      594
      595
      596
      597
      598
      599
      600
      601
      602
      603
      604
      605
      606
      607
      608
      609
      610
      611
      612
      613
      614
      615
      616
      617
      618
      619
      620
      621
      622
      623
      624
      625
      626
      627
      628
      629
      630
      631
      632
      633
      634
      635
      636
      637
      638
      639
      640
      641
      642
      643
      644
      645
      646
      647
      648
      649
      650
      651
      652
      653
      654
      655
      656
      657
      658
      659
      660
      661
      662
      663
      664
      665
      666
      667
      668
      669
      670
      671
      672
      673
      674
      675
      676
      677
      678
      679
      680
      681
      682
      683
      684
      685
      686
      687
      688
      689
      690
      691
      692
      693
      694
      695
      696
      697
      698
      699
      700
      701
      702
      703
      704
      705
      706
      707
      708
      709
      710
      711
      712
      713
      714
      715
      716
      717
      718
      719
      720
      721
      722
      723
      724
      725
      726
      727
      728
      729
      730
      731
      732
      733
      734
      735
      736
      737
      738
      739
      740
      741
      742
      743
      744
      745
      746
      747
      748
      749
      750
      751
      752
      753
      754
      755
      756
      757
      758
      759
      760
      761
      762
      763
      764
      765
      766
      767
      768
      769
      770
      771
      772
      773
      774
      775
      776
      777
      778
      779
      780
      781
      782
      783
      784
      785
      786
      787
      788
      789
      790
      791
      792
      793
      794
      795
      796
      797
      798
      799
      800
      801
      802
      803
      804
      805
      806
      807
      808
      809
      810
      811
      812
      813
      814
      815
      816
      817
      818
      819
      820
      
      $data$refnp_rdesign
           (Intercept)
      attr(,"assign")
      [1] 0
      
      $data$model_refnp
      [1] 0
      
      
      $priors
                  variable
      1:     refp_mean_int
      2:       refp_sd_int
      3: refp_mean_beta_sd
      4:   refp_sd_beta_sd
      5:         refnp_int
      6:     refnp_beta_sd
                                                            description
      1:         Log mean intercept for parametric reference date delay
      2: Log standard deviation for the parametric reference date delay
      3:    Standard deviation of scaled pooled parametric mean effects
      4:      Standard deviation of scaled pooled parametric sd effects
      5:              Intercept for non-parametric reference date delay
      6:     Standard deviation of scaled pooled non-parametric effects
                  distribution mean sd
      1:                Normal  1.0  1
      2: Zero truncated normal  0.5  1
      3: Zero truncated normal  0.0  1
      4: Zero truncated normal  0.0  1
      5:                Normal  0.0  1
      6: Zero truncated normal  0.0  1
      

# enw_reference supports non-parametric models

    Code
      ref <- enw_reference(parametric = ~0, distribution = "none", non_parametric = ~
        1 + (1 | delay) + rw(week), data = pobs_filt)
      ref$inits <- NULL
      ref
    Output
      $formula
      $formula$parametric
      [1] "~1"
      
      $formula$non_parametric
      [1] "~1 + (1 | delay) + rw(week)"
      
      
      $data
      $data$refp_fintercept
      [1] 1
      
      $data$refp_fnrow
      [1] 1
      
      $data$refp_findex
      [1] 1 1 1 1 1 1 1 1
      
      $data$refp_fnindex
      [1] 8
      
      $data$refp_fncol
      [1] 0
      
      $data$refp_rncol
      [1] 0
      
      $data$refp_fdesign
      numeric(0)
      
      $data$refp_rdesign
           (Intercept)
      attr(,"assign")
      [1] 0
      
      $data$model_refp
      [1] 0
      
      $data$refnp_fintercept
      [1] 1
      
      $data$refnp_fnrow
      [1] 16
      
      $data$refnp_findex
       [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16
      
      $data$refnp_fnindex
      [1] 16
      
      $data$refnp_fncol
      [1] 3
      
      $data$refnp_rncol
      [1] 2
      
      $data$refnp_fdesign
         delay0 delay1 cweek1
      1       1      0      0
      2       0      1      0
      3       1      0      0
      4       0      1      0
      5       1      0      0
      6       0      1      0
      7       1      0      0
      8       0      1      0
      9       1      0      0
      10      0      1      0
      11      1      0      0
      12      0      1      0
      13      1      0      0
      14      0      1      0
      15      1      0      1
      16      0      1      1
      
      $data$refnp_rdesign
        fixed delay rw__week
      1     0     1        0
      2     0     1        0
      3     0     0        1
      attr(,"assign")
      [1] 1 2 3
      
      $data$model_refnp
      [1] 1
      
      
      $priors
                  variable
      1:     refp_mean_int
      2:       refp_sd_int
      3: refp_mean_beta_sd
      4:   refp_sd_beta_sd
      5:         refnp_int
      6:     refnp_beta_sd
                                                            description
      1:         Log mean intercept for parametric reference date delay
      2: Log standard deviation for the parametric reference date delay
      3:    Standard deviation of scaled pooled parametric mean effects
      4:      Standard deviation of scaled pooled parametric sd effects
      5:              Intercept for non-parametric reference date delay
      6:     Standard deviation of scaled pooled non-parametric effects
                  distribution mean sd
      1:                Normal  1.0  1
      2: Zero truncated normal  0.5  1
      3: Zero truncated normal  0.0  1
      4: Zero truncated normal  0.0  1
      5:                Normal  0.0  1
      6: Zero truncated normal  0.0  1
      

# Parametric and non-parametric models can be jointly specified

    Code
      ref <- enw_reference(parametric = ~1, non_parametric = ~ 0 + (1 | delay_cat),
      data = pobs_filt)
      ref$inits <- NULL
      ref
    Output
      $formula
      $formula$parametric
      [1] "~1"
      
      $formula$non_parametric
      [1] "~0 + (1 | delay_cat)"
      
      
      $data
      $data$refp_fintercept
      [1] 1
      
      $data$refp_fnrow
      [1] 1
      
      $data$refp_findex
      [1] 1 1 1 1 1 1 1 1
      
      $data$refp_fnindex
      [1] 8
      
      $data$refp_fncol
      [1] 0
      
      $data$refp_rncol
      [1] 0
      
      $data$refp_fdesign
      numeric(0)
      
      $data$refp_rdesign
           (Intercept)
      attr(,"assign")
      [1] 0
      
      $data$model_refp
      [1] 2
      
      $data$refnp_fintercept
      [1] 0
      
      $data$refnp_fnrow
      [1] 16
      
      $data$refnp_findex
       [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16
      
      $data$refnp_fnindex
      [1] 16
      
      $data$refnp_fncol
      [1] 2
      
      $data$refnp_rncol
      [1] 1
      
      $data$refnp_fdesign
         delay_cat[0,1) delay_cat[1,2)
      1               1              0
      2               0              1
      3               1              0
      4               0              1
      5               1              0
      6               0              1
      7               1              0
      8               0              1
      9               1              0
      10              0              1
      11              1              0
      12              0              1
      13              1              0
      14              0              1
      15              1              0
      16              0              1
      attr(,"assign")
      [1] 1 1
      attr(,"contrasts")
      attr(,"contrasts")$delay_cat
            [0,1) [1,2)
      [0,1)     1     0
      [1,2)     0     1
      
      
      $data$refnp_rdesign
        fixed delay_cat
      1     0         1
      2     0         1
      attr(,"assign")
      [1] 1 2
      
      $data$model_refnp
      [1] 1
      
      
      $priors
                  variable
      1:     refp_mean_int
      2:       refp_sd_int
      3: refp_mean_beta_sd
      4:   refp_sd_beta_sd
      5:         refnp_int
      6:     refnp_beta_sd
                                                            description
      1:         Log mean intercept for parametric reference date delay
      2: Log standard deviation for the parametric reference date delay
      3:    Standard deviation of scaled pooled parametric mean effects
      4:      Standard deviation of scaled pooled parametric sd effects
      5:              Intercept for non-parametric reference date delay
      6:     Standard deviation of scaled pooled non-parametric effects
                  distribution mean sd
      1:                Normal  1.0  1
      2: Zero truncated normal  0.5  1
      3: Zero truncated normal  0.0  1
      4: Zero truncated normal  0.0  1
      5:                Normal  0.0  1
      6: Zero truncated normal  0.0  1
      

