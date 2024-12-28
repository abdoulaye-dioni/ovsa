
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Title and Package description

## Title

**ovsa**: (ordinal variable sensitivity analysis)

## Description

The goal of *ovsa* package is to perform sensitivity analysis for
ordinal variable when specific catégories of ordinal variable tend to be
missing (Missing Not At Random).

Our sensitivity analysis containes three step

1.  Performing MI under MAR

2.  Modifying the imputed data to reflect plausible scenarios under MNAR

3.  Analyzing the modified data and combining the results according to
    Rubin’s rule.

<!-- badges: start -->
<!-- badges: end -->

The goal of ovsa is to …

## Installation

You can install the development version of ovsa from
[GitHub](https://github.com/) with:

    # install.packages("pak")
    pak::pak("abdoulaye-dioni/ovsa")

    # install.packages("devtools")  # Uncomment if you don't have devtools installed
    devtools::install_github("abdoulaye-dioni/ovsa")

## Example

``` r
library(ovsa)
```

Below is a minimal working example demonstrating the usage of the ovsa
package.

``` r
head(simdaNA)
#>   id X2 X1 Y X1.mis
#> 1  1  3  5 0      5
#> 2  2  1  4 0   <NA>
#> 3  3  3  5 0      5
#> 4  4  1  1 0      1
#> 5  5  1  1 0      1
#> 6  6  2  1 0      1
str(simdaNA)
#> 'data.frame':    1000 obs. of  5 variables:
#>  $ id    : int  1 2 3 4 5 6 7 8 9 10 ...
#>  $ X2    : Factor w/ 4 levels "1","2","3","4": 3 1 3 1 1 2 4 1 4 3 ...
#>  $ X1    : Ord.factor w/ 5 levels "1"<"2"<"3"<"4"<..: 5 4 5 1 1 1 3 3 5 1 ...
#>  $ Y     : Factor w/ 2 levels "0","1": 1 1 1 1 1 1 2 2 2 1 ...
#>  $ X1.mis: Ord.factor w/ 5 levels "1"<"2"<"3"<"4"<..: 5 NA 5 1 1 1 3 3 5 1 ...
imputed_mice <- firststep(simdaNA[, c("Y","X1.mis","X2")], mi = "mice",
method = c("logreg", "polr", "polyreg"), m = 10,printFlag = FALSE)
```

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
#>  0:576   1:306   1:248  
#>  1:424   2:109   2:247  
#>          3:148   3:260  
#>          4: 54   4:245  
#>          5:383
formula <- "X1.mis.mar ~ Y + X2"
manydelta <- data.frame( delta1 = c(0,0,0,0), delta2 = c(0,-1,2,0),
delta3 = c(0,0.5,0,0.5), delta4 = c(-1,0.5,0,1))
level_ord_var = 5
seed = 123
```

``` r
# Execution of the complete function
out <- secondstep( data = simdaNA, mardata = imputed_mice,
level_ord_var = level_ord_var, formula = formula, manydelta = manydelta,
seed = seed)
```

``` r
summary(out$mnardata[[2]])
#>  Y       X1.mis.mar X2       X1.mis         eta              etanew       
#>  0:576   1:305      1:248   1   :272   Min.   :-0.1014   Min.   :-3.1493  
#>  1:424   2:105      2:247   2   : 89   1st Qu.: 0.0000   1st Qu.:-0.2689  
#>          3:145      3:260   3   :131   Median : 0.1995   Median : 0.5053  
#>          4: 56      4:245   4   : 49   Mean   : 0.4500   Mean   : 0.4924  
#>          5:389              5   :352   3rd Qu.: 0.9472   3rd Qu.: 1.2914  
#>                             NA's:107   Max.   : 1.1467   Max.   : 3.6124  
#>  mnar1   mnar2   mnar3   mnar4  
#>  1:308   1:284   1:308   1:277  
#>  2:100   2: 89   2:114   2:145  
#>  3:145   3:186   3:131   3:131  
#>  4: 55   4: 49   4: 75   4: 85  
#>  5:392   5:392   5:372   5:362  
#> 
```
