# BART
BART: BAckward Regression Trimming. A variable selection procedure which aims at finding the most compact yet well performing analytical model

'''{r}
# Load data ---------------------------------------------------------------------------------------
hmeq <- read.csv("hmeq.csv")

# Since we're going to fit logistic regression models, we remove rows with NA values:
hmeq <- hmeq[complete.cases(hmeq), ]

X_data<-hmeq[,-1]
Y_data<-unlist(hmeq[,1])
# Load packages -----------------------------------------------------------------------------------
library(caret)

# Split data in training, validation and test set -------------------------------------------------
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

BART(X_train,Y_train,X_validate,Y_validate,X_test,Y_test,'auc')$testSetPerformance
BART(X_train,Y_train,X_validate,Y_validate,X_test,Y_test,'auc',numPredictors=5)$testSetPerformance



'''
