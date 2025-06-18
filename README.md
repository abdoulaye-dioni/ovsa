
<!-- README.md is generated from README.Rmd. Please edit that file -->

# **ovsa**: ordinal variable sensitivity analysis

## Description

The goal of the ovsa package is to perform sensitivity analysis for
ordinal variables when specific categories are prone to missingness
under a Missing Not At Random (MNAR) mechanism.

1.  Our sensitivity analysis procedure involves three main steps:

2.  Performing multiple imputation (MI) under the MAR assumption and

Modifying the imputed values to reflect plausible MNAR scenarios

3.  Analyzing the modified datasets and combining the results using
    Rubin’s rules

# Installation

You can install the development version of ovsa from GitHub using either
\*\**pak*

or **devtools**

``` r
# install.packages("pak")
pak::pak("abdoulaye-dioni/ovsa")
```

``` r
# install.packages("devtools")
devtools::install_github("abdoulaye-dioni/ovsa")
```

# Example

Below is a simple workflow illustrating the main steps of the ovsa
package for

non hierarchical data.

``` r
library(ovsa)
```

## Non hierarchical data from the `ovsa` package

``` r
data("simda") 
head(simda)
#>   id X2 X1 Y
#> 1  1  c  5 1
#> 2  2  c  3 0
#> 3  3  c  5 1
#> 4  4  b  2 0
#> 5  5  c  2 0
#> 6  6  b  4 0
```

## Simulating MNAR with **simmnar()**

Use the simmnar() function to simulate a Missing Not At Random (MNAR)
mechanism for ordinal variables:

``` r
set.seed(321)
simdaNA <- simmnar(data = simda, Y = "Y",
                   ord_var = "X1", A = 1, probA = 0.6,
                   B = 5, probB = 0.4, verbose = TRUE)
#> 50 missing values introduced into X1.mis.
head(simdaNA)
#>   id X2 X1 Y X1.mis
#> 1  1  c  5 1      5
#> 2  2  c  3 0      3
#> 3  3  c  5 1      5
#> 4  4  b  2 0      2
#> 5  5  c  2 0      2
#> 6  6  b  4 0      4
summary(simdaNA)
#>        id         X2      X1      Y        X1.mis   
#>  Min.   :   1.0   a:249   1:126   0:607   1   :103  
#>  1st Qu.: 250.8   b:248   2:162   1:393   2   :162  
#>  Median : 500.5   c:257   3:178           3   :178  
#>  Mean   : 500.5   d:246   4:254           4   :254  
#>  3rd Qu.: 750.2           5:280           5   :253  
#>  Max.   :1000.0                           NA's: 50
```

## Step 1: Imputation under MAR with `firststep()`

Use the `firststep` function from the `ovsa` package to impute missing
values in a non-hierarchical context. This function performs the first
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
imputed_mice <- firststep(simdaNA[, c("Y", "X1.mis", "X2")],
                          mi = "mice",
                          method = c("logreg", "polr", "polyreg"),
                          m = 10,
                          printFlag = FALSE,verbose = FALSE)

summary(complete(imputed_mice, 1))
#>  Y       X1.mis  X2     
#>  0:607   1:105   a:249  
#>  1:393   2:168   b:248  
#>          3:183   c:257  
#>          4:275   d:246  
#>          5:269
```

``` r
summary(complete(imputed_mice,1))
#>  Y       X1.mis  X2     
#>  0:607   1:105   a:249  
#>  1:393   2:168   b:248  
#>          3:183   c:257  
#>          4:275   d:246  
#>          5:269
```

## Step 2: Modify imputed values with `secondstep()`

``` r
formula <- "X1.mis.mar ~ Y + X2"
manydelta <- data.frame(
  delta1 = c(0, 0, 0, 0),
  delta2 = c(0, 1, -2, 0),
  delta3 = c(0, -0.5, 0, 0.5),
  delta4 = c(1, 0.5, 0, -1)
)

level_ord_var <- 5
```

``` r
seed <- 123
out <- secondstep_mice(data = simdaNA, mardata = imputed_mice,
                  level_ord_var = level_ord_var,
                  formula = formula,
                  manydelta = manydelta,
                  seed = seed)
#> Preparing imputed datasets...
#> Fitting ordinal regression models...
#> Extracting and adjusting thresholds...
#> Constructing latent variables and MNAR columns...
#> Done. Returning modified datasets.

summary(out$mnardata[[2]])
#>  Y       X1.mis.mar X2       X1.mis         eta             etanew       
#>  0:607   1:111      a:249   1   :103   Min.   :0.0000   Min.   :-3.0479  
#>  1:393   2:169      b:248   2   :162   1st Qu.:0.1263   1st Qu.:-0.1804  
#>          3:188      c:257   3   :178   Median :0.2907   Median : 0.5869  
#>          4:265      d:246   4   :254   Mean   :0.5477   Mean   : 0.5902  
#>          5:267              5   :253   3rd Qu.:1.1296   3rd Qu.: 1.3777  
#>                             NA's: 50   Max.   :1.2940   Max.   : 4.5845  
#>  mnar1   mnar2   mnar3   mnar4  
#>  1:109   1:109   1:109   1:119  
#>  2:170   2:189   2:164   2:166  
#>  3:186   3:178   3:192   3:180  
#>  4:270   4:259   4:275   4:254  
#>  5:265   5:265   5:260   5:281  
#> 
```

``` r
summary(out$mnardata[[2]])
#>  Y       X1.mis.mar X2       X1.mis         eta             etanew       
#>  0:607   1:111      a:249   1   :103   Min.   :0.0000   Min.   :-3.0479  
#>  1:393   2:169      b:248   2   :162   1st Qu.:0.1263   1st Qu.:-0.1804  
#>          3:188      c:257   3   :178   Median :0.2907   Median : 0.5869  
#>          4:265      d:246   4   :254   Mean   :0.5477   Mean   : 0.5902  
#>          5:267              5   :253   3rd Qu.:1.1296   3rd Qu.: 1.3777  
#>                             NA's: 50   Max.   :1.2940   Max.   : 4.5845  
#>  mnar1   mnar2   mnar3   mnar4  
#>  1:109   1:109   1:109   1:119  
#>  2:170   2:189   2:164   2:166  
#>  3:186   3:178   3:192   3:180  
#>  4:270   4:259   4:275   4:254  
#>  5:265   5:265   5:260   5:281  
#> 
```

## Check plausibility with `checkprop()`

En résumé, parmi les quatre scénarios explorés à l’aide du vecteur de
paramètres de sensibilité, seuls le scénario `MNAR4` permet de refléter
correctement les causes plausibles des données manquantes.

``` r
checkprop(data = out$mnardata,
          ord_mar = "X1.mis.mar",
          ord_mis = "X1.mis",
          manydelta = manydelta)
#> $table
#>    mar mnar1 mnar2 mnar3 mnar4
#> 1 12.0  12.8  12.8  12.8  34.6
#> 2 13.2  13.0  48.4   2.4   6.6
#> 3 16.4  17.2   0.0  27.8   1.8
#> 4 28.6  30.2  12.0  42.2   0.0
#> 5 29.8  26.8  26.8  14.8  57.0
#> 
#> $plot
```

<img src="man/figures/README-unnamed-chunk-11-1.png" width="100%" />

## Step 4: Final analysis with `thirdstep_mice()`

``` r
formula <- "Y ~ X1.mis.mar + X2"

# Analysis for MAR
thirdstep_mice(data = out$mnardata, formula = formula)
#>           term   estimate std.error statistic       df      p.value      2.5 %
#> 1  (Intercept) -1.3275547 0.1813522 -7.320311 926.1892 5.366412e-13 -1.6834637
#> 2 X1.mis.mar.L  1.9096327 0.2360606  8.089588 269.7971 2.047538e-14  1.4448777
#> 3 X1.mis.mar.Q  1.0003713 0.2117767  4.723709 496.9288 3.017974e-06  0.5842833
#> 4 X1.mis.mar.C  1.2794045 0.1958654  6.532061 533.8962 1.514215e-10  0.8946432
#> 5 X1.mis.mar^4  1.0068195 0.1731628  5.814294 579.8199 1.006313e-08  0.6667167
#> 6          X2b  0.9061304 0.2400229  3.775183 876.6643 1.706604e-04  0.4350437
#> 7          X2c  0.8177132 0.2363148  3.460271 930.1502 5.641551e-04  0.3539413
#> 8          X2d  0.7785595 0.2387134  3.261483 972.9962 1.146822e-03  0.3101072
#>       97.5 %   conf.low  conf.high
#> 1 -0.9716458 -1.6834637 -0.9716458
#> 2  2.3743877  1.4448777  2.3743877
#> 3  1.4164594  0.5842833  1.4164594
#> 4  1.6641659  0.8946432  1.6641659
#> 5  1.3469223  0.6667167  1.3469223
#> 6  1.3772170  0.4350437  1.3772170
#> 7  1.2814850  0.3539413  1.2814850
#> 8  1.2470119  0.3101072  1.2470119
```

``` r
# Analysis for MNAR
thirdstep_mice(data = out$mnardata, manydelta = manydelta)
#> $mnar1
#>          term   estimate std.error statistic       df      p.value      2.5 %
#> 1 (Intercept) -1.3017247 0.1806819 -7.204511 933.3894 1.200047e-12 -1.6563146
#> 2     mnar1.L  1.9226339 0.2209149  8.703054 935.3380 1.439301e-17  1.4890877
#> 3     mnar1.Q  0.9859175 0.2072384  4.757408 785.4169 2.333523e-06  0.5791109
#> 4     mnar1.C  1.3151004 0.1896505  6.934338 933.7103 7.613369e-12  0.9429099
#> 5     mnar1^4  1.0267241 0.1750603  5.864975 459.7879 8.592534e-09  0.6827067
#> 6         X2b  0.8766824 0.2390954  3.666664 922.2936 2.597834e-04  0.4074483
#> 7         X2c  0.7895290 0.2364122  3.339630 924.1564 8.724634e-04  0.3255621
#> 8         X2d  0.7483919 0.2388742  3.132996 967.7419 1.782358e-03  0.2796208
#>       97.5 %   conf.low  conf.high
#> 1 -0.9471349 -1.6563146 -0.9471349
#> 2  2.3561801  1.4890877  2.3561801
#> 3  1.3927241  0.5791109  1.3927241
#> 4  1.6872910  0.9429099  1.6872910
#> 5  1.3707416  0.6827067  1.3707416
#> 6  1.3459166  0.4074483  1.3459166
#> 7  1.2534960  0.3255621  1.2534960
#> 8  1.2171631  0.2796208  1.2171631
#> 
#> $mnar2
#>          term   estimate std.error statistic       df      p.value      2.5 %
#> 1 (Intercept) -1.2988329 0.1804587 -7.197396 940.9682 1.253826e-12 -1.6529810
#> 2     mnar2.L  1.8645486 0.2216114  8.413596 879.8250 1.596841e-16  1.4295999
#> 3     mnar2.Q  0.9805103 0.2073435  4.728918 804.9667 2.664699e-06  0.5735126
#> 4     mnar2.C  1.4305110 0.1971630  7.255475 387.5311 2.199369e-12  1.0428680
#> 5     mnar2^4  1.0196033 0.1692754  6.023341 860.3072 2.529774e-09  0.6873622
#> 6         X2b  0.8814439 0.2400274  3.672263 889.6085 2.547545e-04  0.4103578
#> 7         X2c  0.7832443 0.2363763  3.313548 922.6263 9.570451e-04  0.3193467
#> 8         X2d  0.7555163 0.2396982  3.151948 953.7204 1.672471e-03  0.2851195
#>       97.5 %   conf.low  conf.high
#> 1 -0.9446848 -1.6529810 -0.9446848
#> 2  2.2994972  1.4295999  2.2994972
#> 3  1.3875079  0.5735126  1.3875079
#> 4  1.8181539  1.0428680  1.8181539
#> 5  1.3518444  0.6873622  1.3518444
#> 6  1.3525299  0.4103578  1.3525299
#> 7  1.2471420  0.3193467  1.2471420
#> 8  1.2259131  0.2851195  1.2259131
#> 
#> $mnar3
#>          term   estimate std.error statistic       df      p.value      2.5 %
#> 1 (Intercept) -1.2791668 0.1788983 -7.150246 971.1684 1.702277e-12 -1.6302386
#> 2     mnar3.L  1.9620922 0.2213680  8.863485 943.4801 3.801750e-18  1.5276615
#> 3     mnar3.Q  0.9823152 0.2068103  4.749837 819.9435 2.402820e-06  0.5763753
#> 4     mnar3.C  1.2647825 0.1878595  6.732596 971.6631 2.846597e-11  0.8961253
#> 5     mnar3^4  0.9761919 0.1692971  5.766147 730.6127 1.196866e-08  0.6438251
#> 6         X2b  0.8785710 0.2366224  3.712967 957.7625 2.166684e-04  0.4142129
#> 7         X2c  0.7838715 0.2343522  3.344844 957.9369 8.552373e-04  0.3239686
#> 8         X2d  0.7335923 0.2368901  3.096763 981.7995 2.012006e-03  0.2687232
#>       97.5 %   conf.low  conf.high
#> 1 -0.9280951 -1.6302386 -0.9280951
#> 2  2.3965229  1.5276615  2.3965229
#> 3  1.3882551  0.5763753  1.3882551
#> 4  1.6334396  0.8961253  1.6334396
#> 5  1.3085587  0.6438251  1.3085587
#> 6  1.3429291  0.4142129  1.3429291
#> 7  1.2437744  0.3239686  1.2437744
#> 8  1.1984614  0.2687232  1.1984614
#> 
#> $mnar4
#>          term   estimate std.error statistic       df      p.value      2.5 %
#> 1 (Intercept) -1.3598903 0.1820905 -7.468211 795.5200 2.139677e-13 -1.7173249
#> 2     mnar4.L  1.7291115 0.2141263  8.075195 578.7889 3.925221e-15  1.3085522
#> 3     mnar4.Q  0.9879701 0.1951116  5.063614 943.3833 4.946511e-07  0.6050670
#> 4     mnar4.C  1.3410134 0.1908336  7.027133 931.4862 4.069972e-12  0.9664997
#> 5     mnar4^4  1.0724007 0.1715063  6.252836 959.1468 6.059476e-10  0.7358298
#> 6         X2b  0.9004999 0.2434712  3.698589 677.9932 2.343527e-04  0.4224517
#> 7         X2c  0.8063695 0.2379776  3.388426 795.6372 7.375221e-04  0.3392313
#> 8         X2d  0.8024017 0.2417121  3.319659 819.8670 9.410684e-04  0.3279543
#>      97.5 %   conf.low conf.high
#> 1 -1.002456 -1.7173249 -1.002456
#> 2  2.149671  1.3085522  2.149671
#> 3  1.370873  0.6050670  1.370873
#> 4  1.715527  0.9664997  1.715527
#> 5  1.408972  0.7358298  1.408972
#> 6  1.378548  0.4224517  1.378548
#> 7  1.273508  0.3392313  1.273508
#> 8  1.276849  0.3279543  1.276849
```
