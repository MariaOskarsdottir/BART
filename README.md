# BART: BAckward Regression Trimming.
A variable selection procedure which aims at finding the most compact yet well performing analytical model

This is how BART works in a classification setting:
1. Split the data in training, validation and test set
2. Estimate a logistic regression model with all n variables on the training set and measure the performance (e.g. AUC, profit) on the validation set
3. Estimate n logistic regression models with n-1 variables and proceed with best one in terms of performance on the validation set
4. Estimate all n-1 logistic regression models with n-2 variables and proceed with the best one in terms of performance on the validation set.  Continue doing this until no variables left in model.
5. Choose the best model based on the validation set performance and measure the performance on the independent test set

## How to use
The function BART in the file ```BART.R``` can be use on any classification dataset to find the optimal set of predictors based on a backwards selection using a specific performance measure.
The implemented performance measures are 
 - AUC: Area under the receiver operating characteristic curve. 
    - Argument ```measure='auc'. 
 - PR: Area under the precision recall curve. 
    - Argument ```measure='pr'. 
 - EMP: Expected maximum profit measure for churn and credit scoring. 
    - Argument ```measure='emp_churn'``` or ```measure='emp_credit'```. 

BART is used to find the optimal set of predictors in a classifcation task but requires user input to select the optimal number.  Therefore it should be run twice. First using all predictors. The function call renders a plot with performance as a function of number of predictors. This plot is used to decide the optimal number of features which is given as an argument to the function when it is called the second time.

## Example
With the provided ```hmeq.csv``` dataset, use the following code 

Load data
```
hmeq <- read.csv("hmeq.csv")
```
Since we're going to fit logistic regression models, we remove rows with NA values:
```
hmeq <- hmeq[complete.cases(hmeq), ]
``` 
Seperate the predictors from the target
```
X_data<-hmeq[,-1]
Y_data<-unlist(hmeq[,1])
```
Split data in training, validation and test set 
```
library(caret)
set.seed(2019)
index_test  <- createDataPartition(y = Y_data, times = 1, p = 0.2, list = FALSE)
set.seed(2019)
index_train <- createDataPartition(y = Y_data[-index_test], times = 1, p = 0.8, list = FALSE)
X_test  <-  X_data[ index_test, ]
X_train <-  X_data[-index_test, ]
X_validate <- X_train[-index_train, ]
X_train <- X_train[ index_train, ]

Y_test  <-  Y_data[ index_test]
Y_train <-  Y_data[-index_test]
Y_validate <- Y_train[-index_train]
Y_train <- Y_train[ index_train]
```
Source the function
```
source('BART>.R')
```
Apply BART once with default number of predictors. The performance measure here is AUC.
```
BART(X_train,Y_train,X_validate,Y_validate,X_test,Y_test,'auc')$testSetPerformance
```
The function call returns the performance of the full model on the test set.
```
[1] 0.8321103
```
The function call also generates a plot with performance as a function of number of features
![Model performance in AUC](iamges/AUC.png)

Use the plot do decide the optimal number of predictors and assign this value to ```numPredictors```.  In this case we go for 5 predictors.

Call the function again  
```
BART(X_train,Y_train,X_validate,Y_validate,X_test,Y_test,'auc',numPredictors=5)$testSetPerformance
```
This time the function will return the performance of the reduced model on the test set.
```
[1] 0.8213816
```

## BART with the EMP measure
We use the same data but in the function call we use the meausre EMP for credit scoring, ```measure='emp_credit'```
Apply BART once with default number of predictors. The performance measure here is AUC.
```
BART(X_train,Y_train,X_validate,Y_validate,X_test,Y_test,'emp_credit')$testSetPerformance
```
The function call returns the performance of the full model on the test set.
```
[1] 0.01213743
```
The function call also generates a plot with performance as a function of number of features
[Model performance in EMP](iamges/EMP.png)

Use the plot do decide the optimal number of predictors and assign this value to ```numPredictors```.  We again go for 5 predictors and call the function.
```
BART(X_train,Y_train,X_validate,Y_validate,X_test,Y_test,'emp_credit',numPredictors=5)$testSetPerformance
```
This time the function will return the performance of the reduced model on the test set.
```
[1] 0.01135954
```

