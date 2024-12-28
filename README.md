
<!-- README.md is generated from README.Rmd. Please edit that file -->

# **ovsa**: (ordinal variable sensitivity analysis)

## Title

**ovsa**: (ordinal variable sensitivity analysis)

## Description

The goal of the `ovsa` package is to perform sensitivity analysis for
ordinal variables when specific categories of the ordinal variable are
prone to missingness (Missing Not At Random).

Our sensitivity analysis containes three step

1.  Performing MI under MAR

2.  Modifying the imputed data to reflect plausible scenarios under MNAR

3.  Analyzing the modified data and combining the results according to
    Rubin’s rule.

<!-- badges: start -->
<!-- badges: end -->

# Installation

You can install the development version of ovsa from
[GitHub](https://github.com/) with:

    # install.packages("pak")
    pak::pak("abdoulaye-dioni/ovsa")

    # install.packages("devtools")  # Uncomment if you don't have devtools installed
    devtools::install_github("abdoulaye-dioni/ovsa")

# Example

``` r
library(ovsa)
```

``` r
data("simda") # non hierarchical data
head(simda)
#>   id X2 X1 Y
#> 1  1  3  5 0
#> 2  2  1  4 0
#> 3  3  3  5 0
#> 4  4  1  1 0
#> 5  5  1  1 0
#> 6  6  2  1 0
```

Use the `simmnar` function from the `ovsa` package to simulate a Missing
Not At Random (MNAR) mechanism in ordinal variables with specified
probabilities for missing values.

``` r
set.seed(321) # for reproducibility
simdaNA <- simmnar( data = simda, Y = "Y",  id = "id",
ord_var = "X1", A = 2,  probA = 0.5, B = 4,  probB = 0.8) # use simmnar
```

``` r
head(simdaNA)
#>   id X2 X1 Y X1.mis
#> 1  1  3  5 0      5
#> 2  2  1  4 0   <NA>
#> 3  3  3  5 0      5
#> 4  4  1  1 0      1
#> 5  5  1  1 0      1
#> 6  6  2  1 0      1
summary(simdaNA)
#>        id         X2      X1      Y        X1.mis   
#>  Min.   :   1.0   1:248   1:272   0:576   1   :272  
#>  1st Qu.: 250.8   2:247   2:118   1:424   2   : 89  
#>  Median : 500.5   3:260   3:131           3   :131  
#>  Mean   : 500.5   4:245   4:127           4   : 49  
#>  3rd Qu.: 750.2           5:352           5   :352  
#>  Max.   :1000.0                           NA's:107
str(simdaNA)
#> 'data.frame':    1000 obs. of  5 variables:
#>  $ id    : int  1 2 3 4 5 6 7 8 9 10 ...
#>  $ X2    : Factor w/ 4 levels "1","2","3","4": 3 1 3 1 1 2 4 1 4 3 ...
#>  $ X1    : Ord.factor w/ 5 levels "1"<"2"<"3"<"4"<..: 5 4 5 1 1 1 3 3 5 1 ...
#>  $ Y     : Factor w/ 2 levels "0","1": 1 1 1 1 1 1 2 2 2 1 ...
#>  $ X1.mis: Ord.factor w/ 5 levels "1"<"2"<"3"<"4"<..: 5 NA 5 1 1 1 3 3 5 1 ...
```

Use the `firststep` function from the `ovsa` package to impute missing
values in a non-hierarchical context. This function performs the first
step of our sensitivity analysis for ordinal variables under a Missing
Not At Random (MNAR) mechanism.

``` r
imputed_mice <- firststep(simdaNA[, c("Y","X1.mis","X2")], mi = "mice",
method = c("logreg", "polr", "polyreg"), m = 10,printFlag = FALSE)
```

Use the `secondstep` function from the `ovsa` package to modifie imputed
values in a non-hierarchical context. This function performs the second
step of our sensitivity analysis for ordinal variables under a Missing
Not At Random (MNAR) mechanism.

``` r
library(mice)
#> 
#> Attachement du package : 'mice'
#> L'objet suivant est masqué depuis 'package:stats':
#> 
#>     filter
#> Les objets suivants sont masqués depuis 'package:base':
#> 
#>     cbind, rbind

summary(complete(imputed_mice,1))
#>  Y       X1.mis  X2     
#>  0:576   1:316   1:248  
#>  1:424   2:105   2:247  
#>          3:144   3:260  
#>          4: 55   4:245  
#>          5:380
formula <- "X1.mis.mar ~ Y + X2"
manydelta <- data.frame( delta1 = c(0,0,0,0), delta2 = c(0,-1,2,0),
delta3 = c(0,0.5,0,0.5), delta4 = c(-1,0.5,0,1))
level_ord_var = 5
seed = 123
```

``` r
# Execution of the complete function
out <- secondstep(data = simdaNA, mardata = imputed_mice,
level_ord_var = level_ord_var, formula = formula, manydelta = manydelta,
seed = seed)
```

``` r
summary(out$mnardata[[2]])
#>  Y       X1.mis.mar X2       X1.mis         eta               etanew       
#>  0:576   1:314      1:248   1   :272   Min.   :-0.01683   Min.   :-3.0647  
#>  1:424   2:100      2:247   2   : 89   1st Qu.: 0.00000   1st Qu.:-0.2196  
#>          3:145      3:260   3   :131   Median : 0.27528   Median : 0.5475  
#>          4: 53      4:245   4   : 49   Mean   : 0.49501   Mean   : 0.5375  
#>          5:388              5   :352   3rd Qu.: 0.90447   3rd Qu.: 1.3276  
#>                             NA's:107   Max.   : 1.17975   Max.   : 3.6617  
#>  mnar1   mnar2   mnar3   mnar4  
#>  1:309   1:288   1:309   1:280  
#>  2: 97   2: 89   2:111   2:140  
#>  3:145   3:179   3:131   3:131  
#>  4: 54   4: 49   4: 77   4: 87  
#>  5:395   5:395   5:372   5:362  
#> 
```

Use the `checkprop` function from the `ovsa` package to assess the
plausibility of imputed data under the MAR mechanism and the
modifications made under MNAR mechanisms.

``` r
checkprop(data = out$mnardata, ord_mar = "X1.mis.mar",
ord_mis = "X1.mis", manydelta = manydelta)
#> $table
#>         mar     mnar1    mnar2    mnar3     mnar4
#> 1 36.448598 35.981308 16.35514 35.98131  9.813084
#> 2 12.242991 12.523364  0.00000 25.42056 51.588785
#> 3 14.485981 12.897196 49.90654  0.00000  0.000000
#> 4  4.859813  4.859813  0.00000 21.86916 31.308411
#> 5 31.962617 33.738318 33.73832 16.72897  7.289720
#> 
#> $plot
```

<img src="man/figures/README-unnamed-chunk-9-1.png" width="100%" />
