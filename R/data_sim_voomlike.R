#'Data simulation function
#'
#'Adapted from the supplementary material from Law \emph{et al}.
#'
#'@references Law, C. W., Chen, Y., Shi, W., & Smyth, G. K. (2014). voom: Precision
#'weights unlock linear model analysis tools for RNA-seq read counts. \emph{Genome
#'Biology}, 15(2), R29.
#'
#'
#'@examples
#'\dontrun{
#'set.seed(123)
#'data_sims <- data_sim_voomlike(maxGSsize = 300)
#'data_sims <- data_sim_voomlike(maxGSsize = 300, beta = 1.8)
#'}
#'@keywords internal
#'@importFrom utils data
#'@importFrom stats cor rchisq rgamma rnorm rpois model.matrix runif
#'@export
data_sim_voomlike <- function(seed = NULL, maxGSsize = 400, minGSsize = 30, beta = 0, do_gs = TRUE,
                              longitudinal = TRUE, mixed_hypothesis = FALSE,
                              n = 18, nindiv = 6, ntime = 3, propH1=0.1){


  ############################################################################
  # Get distribution function of abundance proportions
  # This distribution was generated from a real dataset
  utils::data("qAbundanceDist", envir = environment())
  qAbundanceDist <- get("qAbundanceDist")

  # Generate baseline proportions for desired number of genes -----
  ngenes <- 10000
  baselineprop <- qAbundanceDist( (1:ngenes)/(ngenes+1) )
  baselineprop <- baselineprop/sum(baselineprop)

  # Design ----
  #n <- 18#128
  n1 <- n/2
  n2 <- n1
  #nindiv <- 6#32
  ngroup <- 2

  if(!longitudinal){
    ntime <- 1
  }
  #ntime <- 3#4
  group <- rep(0:1, each = n/ngroup)
  indiv <- factor(rep(1:nindiv, each = n/nindiv))
  if(ntime > 1 & longitudinal){
    time <- rep(1:ntime, nindiv)
    design <- stats::model.matrix(~ group + time)
  }else{
    design <- stats::model.matrix(~ group)
  }
  #design <- design[, 1, drop = FALSE]
  nlibs <- n

  # Library size ----
  # Use equal or unequal library sizes
  equal <- FALSE
  if(equal){
    expected.lib.size <- rep(11e6, nlibs)
  } else {
    expected.lib.size <- 20e6 * rep(c(1, 0.1), n1)
  }

  # Set seed ----
  if(!is.null(seed)){set.seed(seed)}
  u <- stats::runif(100)

  # Expected counts, group basis ----
  i <- sample(1:ngenes, 200)
  i1 <- i[1:100]
  i2 <- i[101:200]
  fc <- 1
  baselineprop1 <- baselineprop
  baselineprop2 <- baselineprop
  baselineprop1[i1] <- baselineprop1[i1]*fc
  baselineprop2[i2] <- baselineprop2[i2]*fc
  mu0.1 <- matrix(baselineprop1, ngenes, 1) %*% matrix(expected.lib.size[1:n1], 1, n1)
  mu0.2 <- matrix(baselineprop2, ngenes, 1) %*% matrix(expected.lib.size[(n1+1):(n1+n2)], 1, n2)
  mu0 <- cbind(mu0.1, mu0.2)

  # Biological variation ----
  mu0_null <- mu0
  if(longitudinal){
    mu0 <- exp(log(mu0) + matrix(beta*time, ncol = n, nrow = ngenes, byrow = TRUE))
  }else{
    mu0 <- exp(log(mu0) + matrix(beta*group, ncol = n, nrow = ngenes, byrow = TRUE))
  }

  BCV0 <- 0.2+1/sqrt(mu0)
  BCV0_null <- 0.2+1/sqrt(mu0_null)


  # Use inverse chi-square or log-normal dispersion
  invChisq <- TRUE

  if(invChisq){
    df.BCV <- 40
    BCV_null <- BCV0_null*sqrt(df.BCV/stats::rchisq(ngenes, df = df.BCV))
    BCV <- BCV0*sqrt(df.BCV/stats::rchisq(ngenes, df = df.BCV))
  } else {
    BCV <- BCV0*exp(stats::rnorm(ngenes, mean = 0, sd = 0.25)/2)
  }
  if(NCOL(BCV) == 1){
    BCV <- matrix(BCV, ngenes, nlibs)
  }
  shape_null <- 1/BCV_null^2
  shape <- 1/BCV^2
  scale_null <- mu0_null/shape_null
  scale <- mu0/shape
  mu_null <- matrix(stats::rgamma(ngenes*nlibs, shape = shape_null, scale = scale_null), ngenes, nlibs)
  mu <- matrix(stats::rgamma(ngenes*nlibs, shape = shape, scale = scale), ngenes, nlibs)
  if(length(which(mu>10E8))>0){
    mu[which(mu>10E8)] <- 10E8
  }

  # Technical variation
  counts_null <- matrix(stats::rpois(ngenes*nlibs, lambda = mu_null), ngenes, nlibs)
  counts <- matrix(stats::rpois(ngenes*nlibs, lambda = mu), ngenes, nlibs)


  # Filter
  keep <- rowSums(counts) >= 10
  nkeep <- sum(keep)
  counts2 <- counts[keep, ]
  counts2_null <- counts_null[keep, ]

  rownames(counts2_null) <- as.character(1:nkeep)
  rownames(counts2) <- as.character(1:nkeep)
  #browser()

  # Gene sets
  if(do_gs){
    S_temp <- stats::cor(t(counts2_null))
    rownames(S_temp) <- as.character(1:nkeep)
    colnames(S_temp) <- as.character(1:nkeep)

    GS <- list()
    for(i in 1:ncol(S_temp)){
      GS[[i]] <- which(abs(S_temp[, 1])>0.8)
      #if(inherits(GS[[i]], "try-error")){browser()}
      S_temp <- S_temp[-GS[[i]], -GS[[i]]]
      if(is.null(dim(S_temp)) || nrow(S_temp) == 0){
        break()
      }
    }
    gs_keep <- lapply(GS[sapply(GS, length)<maxGSsize & sapply(GS, length)>minGSsize], names)
  }else{
    gs_keep <- NULL
  }

  # Adding 90% null hypotheses under H0 (beta = 0)
  if(mixed_hypothesis){
    select_alt <- sample(x = 1:nrow(counts2), size = floor(ngenes*propH1))
    countsfin <- rbind(counts2[select_alt, ], counts2_null[!(1:nrow(counts2_null) %in% select_alt), ])
    H1_ind <- 1:length(select_alt)
  }else{
    select_alt <- NULL
    countsfin <- counts2
    H1_ind <- NULL
  }

  return(list("counts" = countsfin, "design" = design, "gs_keep" = gs_keep, "indiv" = indiv, "H1_index" = H1_ind))
}

