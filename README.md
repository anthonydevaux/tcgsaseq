
<!-- README.md is generated from README.Rmd. Please edit that file -->
`tcgsaseq`
==========

[![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/tcgsaseq)](https://cran.r-project.org/package=tcgsaseq) [![Travis-CI Build Status](https://travis-ci.org/denisagniel/tcgsaseq.svg?branch=master)](https://travis-ci.org/denisagniel/tcgsaseq)

Overview
--------

`tcgsaseq` is a package for analyzing RNA-seq data. The 2 main functions of the package are `varseq` and `tcgsa_seq`:

-   **Gene-wise Differential Analysis of RNA-seq data** can be performed using the function `varseq`.
-   **Gene Set Analysis of RNA-seq data** can be performed using the function `tcgsa_seq`.

The method implemented in this package is detailed in the following article:

-   D Agniel, BP Hejblum, Variance component score test for time-course gene set analysis of longitudinal RNA-seq data, 2017, Biostatistics. [arXiv:1605.02351](https://arxiv.org/abs/1605.02351v4).

Installation
------------

``` r
# The easiest way to get tcgsaseq is to install it from CRAN:
install.packages("tcgsaseq")

# Or to getthe development version from GitHub:
#install.packages("devtools")
devtools::install_github("denisagniel/tcgsaseq")
```

-- Denis Agniel and Boris Hejblum