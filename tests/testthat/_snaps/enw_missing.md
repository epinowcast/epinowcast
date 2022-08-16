# enw_missing produces the expected model components

    Code
      miss <- enw_missing(formula = ~ 1 + rw(week), data = pobs)
      miss$inits <- NULL
      miss
    Output
      $formula
      [1] "~1 + rw(week)"
      
      $data
      $data$miss_fdesign
         (Intercept) cweek1 cweek2 cweek3 cweek4 cweek5
      1            1      0      0      0      0      0
      2            1      0      0      0      0      0
      3            1      0      0      0      0      0
      4            1      0      0      0      0      0
      5            1      0      0      0      0      0
      6            1      0      0      0      0      0
      7            1      0      0      0      0      0
      8            1      1      0      0      0      0
      9            1      1      0      0      0      0
      10           1      1      0      0      0      0
      11           1      1      0      0      0      0
      12           1      1      0      0      0      0
      13           1      1      0      0      0      0
      14           1      1      0      0      0      0
      15           1      1      1      0      0      0
      16           1      1      1      0      0      0
      17           1      1      1      0      0      0
      18           1      1      1      0      0      0
      19           1      1      1      0      0      0
      20           1      1      1      0      0      0
      21           1      1      1      0      0      0
      22           1      1      1      1      0      0
      23           1      1      1      1      0      0
      24           1      1      1      1      0      0
      25           1      1      1      1      0      0
      26           1      1      1      1      0      0
      27           1      1      1      1      0      0
      28           1      1      1      1      0      0
      29           1      1      1      1      1      0
      30           1      1      1      1      1      0
      31           1      1      1      1      1      0
      32           1      1      1      1      1      0
      33           1      1      1      1      1      0
      34           1      1      1      1      1      0
      35           1      1      1      1      1      0
      36           1      1      1      1      1      1
      37           1      1      1      1      1      1
      38           1      1      1      1      1      1
      39           1      1      1      1      1      1
      40           1      1      1      1      1      1
      41           1      1      1      1      1      1
      attr(,"assign")
      [1] 0 1 2 3 4 5
      
      $data$miss_fnrow
      [1] 41
      
      $data$miss_findex
       [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
      [26] 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41
      
      $data$miss_fnindex
      [1] 41
      
      $data$miss_fncol
      [1] 5
      
      $data$miss_rdesign
        fixed week
      1     0    1
      2     0    1
      3     0    1
      4     0    1
      5     0    1
      attr(,"assign")
      [1] 1 2
      
      $data$miss_rncol
      [1] 1
      
      $data$missing_reference
       [1] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
      
      $data$obs_by_report
              0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17
       [1,] 571 552 533 514 495 476 457 438 419 400 381 362 343 324 305 286 267 248
       [2,] 591 572 553 534 515 496 477 458 439 420 401 382 363 344 325 306 287 268
       [3,] 611 592 573 554 535 516 497 478 459 440 421 402 383 364 345 326 307 288
       [4,] 631 612 593 574 555 536 517 498 479 460 441 422 403 384 365 346 327 308
       [5,] 650 632 613 594 575 556 537 518 499 480 461 442 423 404 385 366 347 328
       [6,] 668 651 633 614 595 576 557 538 519 500 481 462 443 424 405 386 367 348
       [7,] 685 669 652 634 615 596 577 558 539 520 501 482 463 444 425 406 387 368
       [8,] 701 686 670 653 635 616 597 578 559 540 521 502 483 464 445 426 407 388
       [9,] 716 702 687 671 654 636 617 598 579 560 541 522 503 484 465 446 427 408
      [10,] 730 717 703 688 672 655 637 618 599 580 561 542 523 504 485 466 447 428
      [11,] 743 731 718 704 689 673 656 638 619 600 581 562 543 524 505 486 467 448
      [12,] 755 744 732 719 705 690 674 657 639 620 601 582 563 544 525 506 487 468
      [13,] 766 756 745 733 720 706 691 675 658 640 621 602 583 564 545 526 507 488
      [14,] 776 767 757 746 734 721 707 692 676 659 641 622 603 584 565 546 527 508
      [15,] 785 777 768 758 747 735 722 708 693 677 660 642 623 604 585 566 547 528
      [16,] 793 786 778 769 759 748 736 723 709 694 678 661 643 624 605 586 567 548
      [17,] 800 794 787 779 770 760 749 737 724 710 695 679 662 644 625 606 587 568
      [18,] 806 801 795 788 780 771 761 750 738 725 711 696 680 663 645 626 607 588
      [19,] 811 807 802 796 789 781 772 762 751 739 726 712 697 681 664 646 627 608
      [20,] 815 812 808 803 797 790 782 773 763 752 740 727 713 698 682 665 647 628
      [21,] 818 816 813 809 804 798 791 783 774 764 753 741 728 714 699 683 666 648
      [22,] 820 819 817 814 810 805 799 792 784 775 765 754 742 729 715 700 684 667
             18  19
       [1,] 229 210
       [2,] 249 230
       [3,] 269 250
       [4,] 289 270
       [5,] 309 290
       [6,] 329 310
       [7,] 349 330
       [8,] 369 350
       [9,] 389 370
      [10,] 409 390
      [11,] 429 410
      [12,] 449 430
      [13,] 469 450
      [14,] 489 470
      [15,] 509 490
      [16,] 529 510
      [17,] 549 530
      [18,] 569 550
      [19,] 589 570
      [20,] 609 590
      [21,] 629 610
      [22,] 649 630
      
      $data$model_miss
      [1] 1
      
      $data$miss_obs
      [1] 22
      
      
      $priors
             variable
      1:     miss_int
      2: miss_beta_sd
                                                                              description
      1:          Intercept on the logit scale for the proportion missing reference dates
      2: Standard deviation of scaled pooled logit missing reference date\n       effects
                  distribution mean sd
      1:                Normal    0  1
      2: Zero truncated normal    0  1
      

# enw_missing returns an empty model when required

    Code
      miss <- enw_missing(formula = ~0, data = pobs)
      miss$inits <- NULL
      miss
    Output
      $formula
      [1] "~0"
      
      $data
      $data$miss_fdesign
      numeric(0)
      
      $data$miss_fnrow
      [1] 0
      
      $data$miss_findex
      numeric(0)
      
      $data$miss_fnindex
      [1] 0
      
      $data$miss_fncol
      [1] 0
      
      $data$miss_rdesign
      numeric(0)
      
      $data$miss_rncol
      [1] 0
      
      $data$missing_reference
      numeric(0)
      
      $data$obs_by_report
      numeric(0)
      
      $data$model_miss
      [1] 0
      
      $data$miss_obs
      [1] 0
      
      
      $priors
             variable
      1:     miss_int
      2: miss_beta_sd
                                                                              description
      1:          Intercept on the logit scale for the proportion missing reference dates
      2: Standard deviation of scaled pooled logit missing reference date\n       effects
                  distribution mean sd
      1:                Normal    0  1
      2: Zero truncated normal    0  1
      
