
R = $(strip $(R_HOME)/bin/Rscript $^ $(1) $@)

all: knit.R
	$(call R)
	# ls *.Rmd.orig | sed s/.orig// | xargs make

%.Rmd: knit.R %.Rmd.orig
	$(call R)