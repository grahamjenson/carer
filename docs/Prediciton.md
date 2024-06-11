# Predictions

This document describes some different ways in which we can predict the upcoming bgl readings

# NightGuard


NightGuard uses multiple regressions to predict an hour in front to alert for low and high

1. 1 degree polynomial (linear)
1. 2 degree polynomial (quadratic)
1. Log Regression (logx) 
1. Log Regression (logx AND logy)
1. SQRT Regression
1. Exponential Regression

Each of these models are given the last 2-3 consecutive values from the last 10-12 minutes and ranked based on error variance, where the one with the least is selected as the prediction to use.

Each of these is calculated using the "ordinary least squares estimation" (https://en.wikipedia.org/wiki/Ordinary_least_squares).
By just modifying the X matrix.  

The value is `B = (X^T.X)^-1·X^T.Y` however instead of calculting the in



Smart Snooze uses this prediction that will snooze the alarm if it predicts that it will be out of the alert zone in 30 minutes

Links:
1. Hand done long form https://people.stfx.ca/bliengme/exceltips/Regression%20Analysis%20using%20Matrix%20Algebra.htm
1. explinatino of LU decomposition https://zief0002.github.io/matrix-algebra/statistical-application-estimating-regression-coefficients-with-lu-decomposition.html



Source:
1. https://github.com/nightscout/nightguard/blob/ab4a3878cf68b58d504b0bd5456151a7532dc4db/nightguard/external/PredictionService.swift#L184
2. https://github.com/nightscout/nightguard/blob/ab4a3878cf68b58d504b0bd5456151a7532dc4db/nightguard/AlarmRule.swift#L192
3. https://github.com/nightscout/nightguard/blob/ab4a3878cf68b58d504b0bd5456151a7532dc4db/nightguard/external/PredictionService.swift#L13



# Matrix multiplication in Dart

LU solution
1. ALGORITHMS https://courses.physics.illinois.edu/cs357/sp2020/notes/ref-9-linsys.html
1. https://en.wikipedia.org/wiki/LU_decomposition
1. examples https://byjus.com/maths/lu-decomposition/
1. code https://github.com/moluopro/matrices/blob/master/lib/src/utils/lu_decomposition.dart
1. for regression https://zief0002.github.io/matrix-algebra/statistical-application-estimating-regression-coefficients-with-lu-decomposition.html


# Matrix multiplication in SQL

https://therightjoin.wordpress.com/2014/07/18/matrix-multiplication-using-sql/

This is a pretty good description of each mathmatical operation


`B = (X^T.X)^-1·X^T.Y`

1 1 1
1 2 4
1 3 9
1 4 16
1 5 25
1 6 36

We have the Matrix `(X^T.X)^-1·X^T`

1.5	0.3	-0.4	-0.6	-0.3	0.5
-0.7678571429	0.03928571429	0.4714285714	0.5285714286	0.2107142857	-0.4821428571
0.08928571429	-0.01785714286	-0.07142857143	-0.07142857143	-0.01785714286	0.08928571429

So we hard code that 


```
WITH X(row_num, col_num, value) AS (
  values (1, 1, 1.5),
(1, 2, 0.3),
(1, 3, -0.4),
(1, 4, -0.6),
(1, 5, -0.3),
(1, 6, 0.5),
(2, 1, -0.7678571429),
(2, 2, 0.03928571429),
(2, 3, 0.4714285714),
(2, 4, 0.5285714286),
(2, 5, 0.2107142857),
(2, 6, -0.4821428571),
(3, 1, 0.08928571429),
(3, 2, -0.01785714286),
(3, 3, -0.07142857143),
(3, 4, -0.07142857143),
(3, 5, -0.01785714286),
(3, 6, 0.08928571429)
),
Y(row_num, col_num, value) AS (
  values (1, 1, 0.5),(2, 1, 2.0),(3, 1, 7.5),(4, 1, 17.0),(5, 1, 30.5),(6, 1, 48.0)
  )
SELECT X.row_num,
   Y.col_num,
   SUM(X.value * Y.value) AS value
FROM  X
INNER JOIN  Y
ON X.col_num = Y.row_num
GROUP BY X.row_num, Y.col_num;```