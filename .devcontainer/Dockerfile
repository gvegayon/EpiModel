FROM rocker/tidyverse:4.4.1

# RUN \
#   echo 'options(repos=c(CRAN="https://packagemanager.posit.co/cran/__linux__/bookworm/latest"))' >> ~/.Rprofile && \
#   Rscript --vanilla -e 'getOption("repos")'

# Adding R packages
RUN install2.r cpp11 roxygen2 tinytest data.table netplot \
  devtools decor DiagrammeR

RUN install2.r languageserver httpgd doParallel deSolve ape

RUN apt-get update && apt-get install --no-install-recommends -y valgrind gdb \
  libglpk-dev

RUN installGithub.r statnet/tergm@4.2.1 ManuelHentschel/vscDebugger

CMD ["bash"]
