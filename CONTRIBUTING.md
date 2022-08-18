# Contributing

Development is a community effort, and we welcome participation.

## Community

We hold a monthly community call where we discuss package development, research questions, and developments in the literature. We also run a slack community where additional development discussion takes places. We welcome new comers, please contact a package author for an invite.

## Code of Conduct

By participating in this project, you agree to abide by the [code of conduct](https://epiforecasts.io/epinowcast/CODE_OF_CONDUCT.html).

## Discussions

At <https://github.com/epiforecasts/epinowcast/discussions>, you can post general questions, brainstorm ideas, and ask for help.

## Issues

<https://github.com/epiforecasts/epinowcast/issues> is for bug reports, performance issues, maintenance tasks, and feature requests. When you post, please abide by the following guidelines.

* Before posting a new issue, please take a moment to search for existing similar issues in order to avoid duplication.
* For bug reports: if you can, please install the latest GitHub version of `epinowcast` (i.e. `remotes::install_github("epiforecasts/epinowcast")`) and verify that the issue still persists.
* Describe your issue in prose as clearly and concisely as possible.
* For any problem you identify, post a [minimal reproducible example](https://www.tidyverse.org/help/) like [this one](https://github.com/ropensci/targets/issues/256#issuecomment-754229683) so other contributors and authors can troubleshoot. A reproducible example is:
    * **Runnable**: post enough R code and data so any onlooker can create the error on their own computer.
    * **Minimal**: reduce runtime wherever possible and remove complicated details that are irrelevant to the issue at hand.
    * **Readable**: format your code according to the [tidyverse style guide](https://style.tidyverse.org/).

## Development

External code contributions are extremely helpful and appreciated. Here are the recommended steps.

1. Prior to contribution, please propose your idea in a [new issue thread](https://github.com/epiforecasts/epinowcast/issues) so you and the reviewer can define the intent and scope of the work.
2. [Fork the repository](https://help.github.com/articles/fork-a-repo/).
3. Follow the [GitHub flow](https://guides.github.com/introduction/flow/index.html) to create a new branch, add commits, and open a pull request. 
4. Discuss your code with the reviewer in the pull request thread.
5. If everything looks good, the reviewer will merge your code into the project.

Please also follow these additional guidelines.

* We use a `develop`/ `main` workflow so please target major changes to the `develop` branch and minor changes to the `main` branch. If unclear please ask when opening the initial issue proposing the change.
* Respect the architecture and reasoning of the package. Depending on the scope of your work, you may want to read the design documents (package vignettes).
* In general we aim to use `data.table` to manipulate data. However, if this is a barrier to contributing please use tools you are familiar with and raise this in your pull request. The reviewer will then work with you to refactor your contribution or if appropriate add the dependencies you require.
* If possible, keep contributions small enough to easily review manually. It is okay to split up your work into multiple pull requests.
* Format your code according to the [tidyverse style guide](https://style.tidyverse.org/). That formatting can achieved by running `style_pkg()` from [`styler`](https://github.com/r-lib/styler) (which rewrites the files) and `lint_package()` from [`lintr`](https://github.com/jimhester/lintr) (which provides a list of complaints for you to resolve). Note: `styler::style_pkg()` does not examine roxygen content i.e. `@examples` so you will need to check that manually.
* Check code coverage with `covr::package_coverage()`. Automated tests should cover all the new or changed functionality in your pull request.
* Run overall package checks with `devtools::check()` and `goodpractice::gp()`
* Describe your contribution in the project's [`NEWS.md`](https://github.com/epiforecasts/epinowcast/blob/main/NEWS.md) file. Be sure to mention relevant GitHub issue numbers and your GitHub name as done in existing news entries.
* If you feel your contribution is substantial enough for author or contributor status, please add yourself to the `Authors@R` field of the [`DESCRIPTION`](https://github.com/epinowcast/blob/main/blob/main/DESCRIPTION) file. In general, we consider any contribution sufficient for contributor status and several minor or a single major contributions sufficient for author status. If planning on writing a paper or similar about your package extension please note this in your contribution and feel free to suggest how you would like this to be managed.
* Note that when run locally our testing suite only tests R level code. When run in the cloud (i.e when a PR is opened) we also run additional tests on the stan level code. When making stan level changes contributors may want to run these tests manually prior to opening a PR.
