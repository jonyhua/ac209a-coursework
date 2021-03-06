## Clear Workspace
rm(list=ls())

## Load libraries
library(caret)
library(xgboost)
library(readr)
library(dplyr)
library(tidyr)

## Data
df_x <- read_csv("data/train_predictors.txt", col_names = FALSE)
df_y <- read_csv("data/train_labels.txt", col_names = FALSE)
df_x_final <- read_csv("data/test_predictors.txt", col_names = FALSE)

df_sub <- data.frame(read_csv("data/sample_submission.txt", col_names = TRUE))

df_x <- data.frame(df_x)
df_y <- data.frame(df_y)
df_x_final <- data.frame(df_x_final)
names(df_y) <- "Y"

# Bind together
df <- cbind(df_y, df_x)

rm(df_x, df_y)

## Split dataset into test and train
set.seed(123)
sample_id <- sample(row.names(df), size = nrow(df) * 0.5, replace = FALSE)

df_train <- df[row.names(df) %in% sample_id, ]
df_test <- df[!row.names(df) %in% sample_id, ]

# Omit missings
df_train <- na.omit(df_train)

## Tuning

# num.class = length(unique(y))
# xgboost parameters
param <- list("objective" = "binary:logistic",    # multiclass classification 
              "max_depth" = 6,    # maximum depth of tree 
              "eta" = 0.5,    # step size shrinkage 
              "gamma" = 2,    # minimum loss reduction 
              "subsample" = 1,    # part of data instances to grow tree 
              "colsample_bytree" = 1,  # subsample ratio of columns when constructing each tree 
              "min_child_weight" = 0.8,  # minimum sum of instance weight needed in a child
              "scale_pos_weight" = 45,
              "max_delta_step" = 0
)

# Testing
#--------
min.error.idx <- 40

param <- list("objective" = "binary:logistic",    # multiclass classification 
              "max_depth" = 6,    # maximum depth of tree 
              "eta" = 0.5,    # step size shrinkage 
              "gamma" = 2,    # minimum loss reduction 
              "subsample" = 1,    # part of data instances to grow tree 
              "colsample_bytree" = 1,  # subsample ratio of columns when constructing each tree 
              "min_child_weight" = 0.8,  # minimum sum of instance weight needed in a child
              "scale_pos_weight" = 45,
              "max_delta_step" = 0
)


bst <- xgboost(param=param,
               data=as.matrix(df_train %>% select(-Y)),
               label=df_train$Y, 
               nrounds=min.error.idx,
               verbose=0)

# Predictions
preds = predict(bst, data.matrix(df_test[, 2:length(df_test)]))
label = round(preds)
conf_matr <- table(df_test$Y, label)
# Evaluation
p <- conf_matr[4] / (conf_matr[4] + conf_matr[3])
r <- conf_matr[4] / (conf_matr[4] + conf_matr[2])

F1 <- 2 * (p * r) / (p + r)
F1


# New resampling
df_test$prediction1 <- label
set.seed(123)
sample_id <- sample(row.names(df_test), size = nrow(df_test) * 0.8, replace = FALSE)

df_train2 <- df_test[row.names(df_test) %in% sample_id, ]
df_test2 <- df_test[!row.names(df_test) %in% sample_id, ]

min.error.idx <- 40

param <- list("objective" = "binary:logistic",    # multiclass classification 
              "max_depth" = 6,    # maximum depth of tree 
              "eta" = 0.5,    # step size shrinkage 
              "gamma" = 2,    # minimum loss reduction 
              "subsample" = 1,    # part of data instances to grow tree 
              "colsample_bytree" = 1,  # subsample ratio of columns when constructing each tree 
              "min_child_weight" = 0.8,  # minimum sum of instance weight needed in a child
              "scale_pos_weight" = 45,
              "max_delta_step" = 0
)


bst <- xgboost(param=param,
               data=as.matrix(df_train2 %>% select(-Y)),
               label=df_train2$Y, 
               nrounds=min.error.idx,
               verbose=0)

# Predictions
preds = predict(bst, data.matrix(df_test2[, 2:length(df_test2)]))
label = round(preds)
conf_matr <- table(df_test2$Y, label)
# Evaluation
p <- conf_matr[4] / (conf_matr[4] + conf_matr[3])
r <- conf_matr[4] / (conf_matr[4] + conf_matr[2])

F1 <- 2 * (p * r) / (p + r)
F1
