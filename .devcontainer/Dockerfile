# R version: latest, ... ,4.0.1 , 4.0.0
ARG VARIANT="latest"
FROM rocker/r-ver:${VARIANT}

# Use the [Option] comment to specify true/false arguments that should appear in VS Code UX
#
# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
COPY .devcontainer/library-scripts/*.sh /tmp/library-scripts/
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    && usermod -a -G staff ${USERNAME} \
    && apt-get -y install \
        python3-pip \
        libgit2-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        libxt-dev \
        pandoc \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts \
    && python3 -m pip --no-cache-dir install radian pre-commit \
    && install2.r --error --skipinstalled --repos ${CRAN} --ncpus -1 \
        devtools \
        languageserver \
        git2r \
        precommit \
        tinytex \
        httpgd \
    && rm -rf /tmp/downloaded_packages


RUN apt-get update \
     && export DEBIAN_FRONTEND=noninteractive \
     && apt-get -y install --no-install-recommends libglpk-dev libv8-dev \
            pandoc-citeproc libpng-dev

# install vscode dev deps
RUN Rscript -e 'devtools::install_github("mdlincoln/docthis")'
RUN Rscript -e 'devtools::install_github("lorenzwalthert/precommit")'
RUN Rscript -e 'devtools::install_github("milesmcbain/fnmate")'

# install dependencies
COPY DESCRIPTION /tmp/package/DESCRIPTION
RUN Rscript -e "devtools::install_deps('/tmp/package', dependencies = TRUE)"

# install cmdstan
RUN Rscript -e "cmdstanr::install_cmdstan()"
