

## Step 1: Clear the memory
cat('\f')
rm(list = ls())

print(Sys.time())

## Step 2: set the loading path
library(SparkR)
sparkR.session(appName="SparkR-FannnieMae")

## Step 3: read txt data files

Acquisition_all <- read.df("/user/admin/all/Acquisition_all.txt", "csv", header="false", inferSchema="true", sep="|", na.strings="")
Performance_all <- read.df("/user/admin/all/Performance_all.txt", "csv", header="false", inferSchema="true", sep="|", na.strings="")

print("load data done")
print(Sys.time())

## Step 4: Define the variables and data classes of the acquisition and performance files.
Acquisitions_Variables = c("LOAN_ID", "ORIG_CHN", "Seller.Name", "ORIG_RT", "ORIG_AMT", "ORIG_TRM", "ORIG_DTE"
                           ,"FRST_DTE", "OLTV", "OCLTV", "NUM_BO", "DTI", "CSCORE_B", "FTHB_FLG", "PURPOSE", "PROP_TYP"
                           ,"NUM_UNIT", "OCC_STAT", "STATE", "ZIP_3", "MI_PCT", "Product.Type", "CSCORE_C", "MI_TYPE", "RELOCATION_FLG")

Performance_Variables = c("LOAN_ID", "Monthly.Rpt.Prd", "Servicer.Name", "LAST_RT", "LAST_UPB", "Loan.Age", "Months.To.Legal.Mat"
                          , "Adj.Month.To.Mat", "Maturity.Date", "MSA", "Delq.Status", "MOD_FLAG", "Zero_Bal_Code",
                          "ZB_DTE", "LPI_DTE", "FCC_DTE","DISP_DT", "FCC_COST", "PP_COST", "AR_COST", "IE_COST", "TAX_COST", "NS_PROCS",
                          "CE_PROCS", "RMW_PROCS", "O_PROCS", "NON_INT_UPB", "PRIN_FORG_UPB_FHFA", "REPCH_FLAG", "PRIN_FORG_UPB_OTH", "TRANSFER_FLAG")

## Step 5: setting the colnames for the 2 txt datasets
colnames(Acquisition_all) = Acquisitions_Variables
colnames(Performance_all) = Performance_Variables


## Step 6: Selected sample variables for OLS and Logistic Regression
Acquisition_all_reg = Acquisition_all[,c("LOAN_ID", "OLTV","CSCORE_B","FTHB_FLG")]
Performance_all_reg = Performance_all[,c("LOAN_ID", "LAST_RT","Zero_Bal_Code")]


## Step 7: merge these 2 datasets by "LOAN_ID"

Combined_reg = merge(Performance_all_reg, Acquisition_all_reg, by = "LOAN_ID", all.x=TRUE, all.y=FALSE)

## Step 9: Set up prepayment flag in column names "Zero.Bal.Code"
#          If "Zero.Bal.Code" == 1:   set "Zero.Bal.Code" -> 1   (flag for prepayment);
#                Otherwise:           set "Zero.Bal.Code" -> 0  (flag for non-prepayment).
#Combined_reg[is.na(Combined_reg[,"Zero_Bal_Code"]),"Zero_Bal_Code"] = 0
#Combined_reg[Combined_reg[,"Zero_Bal_Code"]!=1,"Zero_Bal_Code"] = 0
Combined_reg = fillna(Combined_reg,list("Zero_Bal_Code"=0))
Combined_reg$Zero_Bal_Code=ifelse(Combined_reg$Zero_Bal_Code != 1,0,1)

## Step 10: Set up First Time House Buyer flag in colnum names "FTHB_FLG"
#          create 2 new columns named "isunknow" and "isfirsttime" and set all values in these 2 columns to zero;
#          If "FTHB_FLG" == U:   set "isunknow" = 1     (flag for unknow);
#          If "FTHB_FLG" == Y:   set "isfirsttime" = 1  (flag for unknow);

#Combined_reg[,c("isunknow","isfirsttime")] = 0
Combined_reg$isunknow=ifelse(TRUE,0,0)
Combined_reg$isfirsttime=ifelse(TRUE,0,0)

#Combined_reg[Combined_reg[,"FTHB_FLG"] == "U","isunknow"] = 1
Combined_reg$isunknow=ifelse(Combined_reg$FTHB_FLG == "U",1,0)

#Combined_reg[Combined_reg[,"FTHB_FLG"] == "Y","isfirsttime"] = 1
Combined_reg$isfirsttime=ifelse(Combined_reg$FTHB_FLG == "Y",1,0)

#Combined_reg = Combined_reg[,!names(Combined_reg) %in% "FTHB_FLG"]      # delete the "FTHB_FLG" after creating the 2 dummy variables above
Combined_reg$FTHB_FLG=NULL

## Step 11: Delete the missing value in colnum "CSCORE_B": 332116 NA records of 13267548 total observations
##          Delete the missing value in colnum "OLTV": 58 NA records of 13267548 total observations
#Combined_reg = Combined_reg[!is.na(Combined_reg[,"CSCORE_B"]) & !is.na(Combined_reg[,"OLTV"]) ,]
Combined_reg=dropna(Combined_reg,how="any",cols="CSCORE_B")
Combined_reg=dropna(Combined_reg,how="any",cols="OLTV")
Combined_reg=dropna(Combined_reg,how="any",cols="Zero_Bal_Code")
Combined_reg=dropna(Combined_reg,how="any",cols="Intercept")
Combined_reg=dropna(Combined_reg,how="any",cols="LAST_RT")

#Combined_reg[,"Intercept"] = 1  # Create one column as intercept for OLS and logistic regressions (all values equal to one)
Combined_reg$Intercept=ifelse(TRUE,1,1)

print("preprocess data done")
print(Sys.time())

## step 12: obtian the final OLS regression data set and estimate the coefficients (beta1 to beta 4)
# OLS Function:    OLTV = beta1*intercept + beta2*CSCORE_B + beta3*isunknow + beta4*isfirsttime + residuals
#Y_ols = as.matrix(Combined_reg[,"OLTV"])   # set up Y for OLS regression
#X_ols = as.matrix(Combined_reg[,c("Intercept","CSCORE_B","isunknow", "isfirsttime")])  # set up X for OLS regression
# estimatate covariance matrix of X_ols
# cov(X_ols)

cov11 = cov(Combined_reg, "Intercept","Intercept")
cov12 = cov(Combined_reg, "Intercept","CSCORE_B")
cov13 = cov(Combined_reg, "Intercept","isunknow")
cov14 = cov(Combined_reg, "Intercept","isfirsttime")
cov21 = cov(Combined_reg, "CSCORE_B","Intercept")
cov22 = cov(Combined_reg, "CSCORE_B","CSCORE_B")
cov23 = cov(Combined_reg, "CSCORE_B","isunknow")
cov24 = cov(Combined_reg, "CSCORE_B","isfirsttime")
cov31 = cov(Combined_reg, "isunknow","Intercept")
cov32 = cov(Combined_reg, "isunknow","CSCORE_B")
cov33 = cov(Combined_reg, "isunknow","isunknow")
cov34 = cov(Combined_reg, "isunknow","isfirsttime")
cov41 = cov(Combined_reg, "isfirsttime","Intercept")
cov42 = cov(Combined_reg, "isfirsttime","CSCORE_B")
cov43 = cov(Combined_reg, "isfirsttime","isunknow")
cov44 = cov(Combined_reg, "isfirsttime","isfirsttime")

print(cov11)
print(cov12)
print(cov13)
print(cov14)
print(cov21)
print(cov22)
print(cov23)
print(cov24)
print(cov31)
print(cov32)
print(cov33)
print(cov34)
print(cov41)
print(cov42)
print(cov43)
print(cov44)
print("cov calculate done")
print(Sys.time())

## Step 13: estimate logistic regression
# step 1: set up likelihood function
#Y_logic = as.matrix(Combined_reg[,"Zero.Bal.Code"])
#X_logic = as.matrix(Combined_reg[,c("Intercept","LAST_RT","CSCORE_B","OLTV")])
#Y = Y_logic[1:10000,]
#X = X_logic[1:10000,]
# Beta_Logic = glm(Y ~ 0 + X, family = "binomial" )

Beta_Logic = glm(Zero_Bal_Code ~ Intercept + LAST_RT + CSCORE_B + OLTV, Combined_reg, family = "binomial" )
summary(Beta_Logic)
print("glm calculate done")
print(Sys.time())
