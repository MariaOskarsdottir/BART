##################################################################
# BART: BAckward Regression Trimming
# Written by Sebastian H??ppner and Mar??a ??skarsd??ttir, June 2019
# Based on Bart's favorite feature selection method
#################################################################

#--------------------------------------
# BART function
# Inputs:
#  - X_train: Predictors of the train set 
#  - Y_train: Target of the train set 
#  - X_validate: Predictors of the validation set 
#  - Y_validate: Target of the validation set
#  - X_test: Predictors of the test set 
#  - Y_test: Target of the test set
#  - measure: the performance meausure to use. The available options are 'auc','pr','emp_credit' and 'emp_churn'
#  - numPredictors: The optimal number of predicotrs used in final model. Defautl is the number of predictors in X_train
# Outputs: 
#  - df: dataframe with three columns
#     - PERF: the performance value
#     - nPredictors: the number of predictors when computing the performance
#     - removedPredictors: The predictor removed in each step
#  - testSetPerformance: The peformance on the test set with numFeatures predictors
# In addition, the function plots the performance as a function of number of predictors
BART<-function(X_train,Y_train,X_validate,Y_validate,X_test,Y_test,measure,numPredictors=ncol(X_train)){
  require(caret, PRROC,EMP,ggplot2)
  
  # Backward variable selection based on AUC --------------------------------------------------------
  logit <- glm(Y_train~., data=cbind(X_train,Y_train), family = "binomial")
  predictions <- predict(logit, newdata = X_validate, type = "response")
  
  if(measure=='auc'){PERF <- roc.curve(scores.class0=predictions,weights.class0 = Y_validate)$auc}
  if(measure=='pr'){PERF <- pr.curve(scores.class0=predictions,weights.class0 = Y_validate)$auc.integral}
  if(measure=='emp_credit'){PERF<-empCreditScoring(predictions,Y_validate)$EMPC}
  if(measure=='emp_churn'){PERF<-empChurn(predictions,Y_validate)$EMP}
  
  removed_predictors <- c()
  best_PERF <- c()
  best_PERF <- c(best_PERF, PERF)
  
  X_train_old <- X_train
  X_validate_old <- X_validate
  
  while (NCOL(X_train_old) > 1) {
    nPredictors <- NCOL(X_train_old)
    PERF_temp_vec <- c()
    
    for (j in 1:nPredictors) {
      X_train_new <- X_train_old[, -j]
      X_validate_new <- X_validate_old[, -j]
      
      logit <- glm(Y_train ~ ., data = cbind(X_train_new,Y_train), family = "binomial")
      predictions <- predict(logit, newdata = X_validate_new, type = "response")
      if(measure=='auc'){PERF <- roc.curve(scores.class0=predictions,weights.class0 = Y_validate)$auc}
      if(measure=='pr'){PERF <- pr.curve(scores.class0=predictions,weights.class0 = Y_validate)$auc.integral}
      if(measure=='emp_credit'){PERF<-empCreditScoring(predictions,Y_validate)$EMPC}
      if(measure=='emp_churn'){PERF<-empChurn(predictions,Y_validate)$EMP}
      
      PERF_temp_vec <- c(PERF_temp_vec, PERF)
    }
    
    best_index <- which.max(PERF_temp_vec)
    removed_predictors <- c(removed_predictors, colnames(X_train_old)[best_index])
    best_PERF <- c(best_PERF, PERF_temp_vec[best_index])
    
    remaining_predictors <- colnames(X_train_old)[-best_index]
    X_train_old <- X_train_old[, -best_index]
    X_validate_old <- X_validate_old[, -best_index]
    
  }
  removed_predictors <- c(removed_predictors, remaining_predictors)
  
  logit <- glm(Y_train~1, data=cbind(X_train,Y_train), family = "binomial")
  predictions <- predict(logit, newdata = X_validate, type = "response")
  if(measure=='auc'){PERF <- roc.curve(scores.class0=predictions,weights.class0 = Y_validate)$auc}
  if(measure=='pr'){PERF <- pr.curve(scores.class0=predictions,weights.class0 = Y_validate)$auc.integral}
  if(measure=='emp_credit'){PERF<-empCreditScoring(predictions,Y_validate)$EMPC}
  if(measure=='emp_churn'){PERF<-empChurn(predictions,Y_validate)$EMP}
  
  best_PERF <- c(best_PERF, PERF)
  removed_predictors <- c(removed_predictors, NA)
  
  # Plot results ------------------------------------------------------------------------------------
  df <- data.frame(PERF = best_PERF, nPredictors = (ncol(X_train)):0,removedPredictors=removed_predictors)
  
  breaks <- seq(ncol(train)-1, 0, -2)
  xlabels <- paste(breaks, "Vars")
  xlabels[2:length(xlabels)] <- paste0(xlabels[2:length(xlabels)],
                                       "\n(", removed_predictors[seq(2, ncol(train)-1, 2)], " out)")
  y_lab<-ifelse(measure=='auc','AUC value', ifelse(measure=='pr','PR value',ifelse(measure=='emp_credit','EMP value',ifelse(measure=='emp_churn','EMP value', NA) ) ))
  
  p<-ggplot(data = df, mapping = aes(x = nPredictors, y = PERF)) +
    geom_point(shape = 17, size = 5, color = "dodgerblue") +
    geom_line(size = 2, color = "dodgerblue") +
    ylab(y_lab) + xlab("Variables") +
    theme_bw() + theme(text = element_text(size = 22), legend.position = "none") +
    geom_text(data = df, mapping = aes(x = nPredictors, y = PERF),
              label = round(df$PERF, 3), size = 7, nudge_y = 0.015) +
    scale_x_reverse(breaks = breaks,
                    labels = xlabels)
  print(p)
  
  # Combine train and validation sets
  X_train<-rbind(X_train,X_validate)
  Y_train<-c(Y_train,Y_validate)
  
  # Model performance on test set with numPredictors predictors
  reducedFormula<-as.formula(paste('Y_train~',paste(df$removedPredictors[ (nrow(df)-1):(nrow(df)-numPredictors)],collapse = '+'),sep=''))
  logit <- glm(reducedFormula, data=cbind(X_train,Y_train), family = "binomial")
  predictions <- predict(logit, newdata = X_test, type = "response")
  if(measure=='auc'){PERF_test <- roc.curve(scores.class0=predictions,weights.class0 = Y_test)$auc}
  if(measure=='pr'){PERF_test <- pr.curve(scores.class0=predictions,weights.class0 = Y_test)$auc.integral}
  if(measure=='emp_credit'){PERF_test<-empCreditScoring(predictions,Y_test)$EMPC}
  if(measure=='emp_churn'){PERF_test<-empChurn(predictions,Y_test)$EMP}
  
  return(list(df=df,testSetPerformance=PERF_test))
}

