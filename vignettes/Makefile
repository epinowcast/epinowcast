
all: $(subst .orig,,$(wildcard *.Rmd.orig))

%.Rmd: %.Rmd.orig
	Rscript knit.R $< $@