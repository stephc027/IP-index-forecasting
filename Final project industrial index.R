
library(fpp2)
library(gridExtra)
library(readxl)
library(tseries)

#setwd("C:/Users/sscha/Documents/Code")
#To run code: Modify setwd function if needed, otherwise leave commented out.

#Load IP Index Data (100 yr)
industrial_index <- read_excel("industrial index.xlsx", col_types = c("skip", "numeric"))

#Create time series variable of 100 year IP Index (Data is monthly)
iindex<-ts(industrial_index,start=c(1919,4),frequency=12)

#Plot the data
autoplot(iindex) + labs(title="US Total IP Index",y="IP Index (all sectors)")

#Possible seasonality can be seen as well as a general upward trend.  The drop off in March 2020 can be noted at the end.  This data has several distinct periods of differing behavior, the latest of which began around 2000; choosing the past 20 years of data to examine should be sufficient and appropriate to gain insight into the current industrial index mechanisms.  

#Cut to time series variable of 20 year IP Index (100 years is no longer representative of current trends)
ii_20<-window(iindex,start=c(2000,1))

#Plot the 20 year data
autoplot(ii_20) + labs(title="US Total IP Index",y="Industrial Index (all sectors)")
#The upward trend continues in the last 20 years of the index, interrupted by declines including the 2008 market crash and the March 2020 COVID-19 event.  There is more clear seasonality now, and most of the years have about equal variance, excluding 2008 and 2020.


#Some different plots to inspect the data:
ggseasonplot(ii_20) + labs(y="IP Index (all sectors)",title="Seasonal") 

ggsubseriesplot(ii_20) + labs(y="IP Index (all sectors)")

#Most years, the seasonality remains the same, with April as the lowest month and August the highest for IP index.  The steep decline in March 2020 and September 2008 are notable exceptions.  Generally, September and March are among the highest production months.


#12 mo. Moving Average:
ma_ii<-ma(iindex,centre=T,order=12)
autoplot(ma_ii) + labs(title="12-month MA, Industrial index",x="",y="Industrial index (all sectors)")

#It's not clear whether the data needs transformed.  We can inspect some different transformations to see if variance is improved:
lambda_ii<-BoxCox.lambda(ii_20)
BC_ii<-BoxCox(ii_20,lambda=lambda_ii)

p1<-autoplot(BC_ii) + labs(title="Box-Cox")
p2<-autoplot(log(ii_20)) + labs(title="Log")
p3<-autoplot(sqrt(ii_20)) + labs(title="SQRT")
p4<-autoplot(ii_20) + labs(title="No transformation") 

grid.arrange(p1,p2,p3,p4,nrow=2,ncol=2)

#None of the transformations helped to stabilize variance vs. no transformation

#An ARIMA model is the first candidate for forecasting. To achieve this, the data must be made reasonably stationary.  R can recommend degree of differencing.  Starting with seasonal differencing:
nsdiffs(ii_20)
d_ii20<- ii_20 %>% diff(lag=12)
ndiffs(ii_20)

tsdisplay(d_ii20,main="Seasonally differenced data")
kpss.test(d_ii20)

#The data does not look particularly stationary.  It does pass the kpss test, and R is not recommending further differencing.  Exploration of the plots at one more difference at lag one may provide a more stationary-looking series:


diff_ii20<- d_ii20 %>% diff(lag=1)
kpss.test(diff_ii20)
tsdisplay(diff_ii20,main="Differenced data")

#The data looks more stationary now.  There are significant non-seasonal lags at 2,3, and possibly 4-5 in the ACF and 2-3 in the PACF, as well as seasonal lags in both at at 12, and PACF at 24, indicating there will be a seasonal component, likely with an order of 1 or 2. 


#Trying an auto-ARIMA model:
fit_aa20<-auto.arima(ii_20,stepwise=F,approximation=F)
autoplot(fit_aa20)
checkresiduals(fit_aa20)
ii_20



#A custom model can be examined based on the manual examination of the differencing process and resulting ACF and PACF.  Drift will not be included as there is a second order difference already.

fit1<-Arima(ii_20,order=c(3,1,0),seasonal=c(2,1,0))
fit1$aicc
fit2<-Arima(ii_20,order=c(2,1,0),seasonal=c(2,1,0))
fit2$aicc
fit3<-Arima(ii_20,order=c(3,1,1),seasonal=c(2,1,0))
fit3$aicc
fit4<-Arima(ii_20,order=c(1,1,0),seasonal=c(2,1,0))
fit4$aicc
fit5<-Arima(ii_20,order=c(3,1,0),seasonal=c(0,1,1))
fit5$aicc
fit6<-Arima(ii_20,order=c(3,1,0),seasonal=c(0,1,2))
fit6$aicc
fit7<-Arima(ii_20,order=c(3,1,0),seasonal=c(1,1,2))
fit7$aicc
fit8<-Arima(ii_20,order=c(3,1,1),seasonal=c(0,1,1))
fit8$aicc
fit8<-Arima(ii_20,order=c(3,1,2),seasonal=c(0,1,1))
fit8$aicc
fit9<-Arima(ii_20,order=c(3,1,1),seasonal=c(1,1,1))
fit9$aicc
fit10<-Arima(ii_20,order=c(0,1,4),seasonal=c(1,1,1))
fit10$aicc
fit11<-Arima(ii_20,order=c(0,1,3),seasonal=c(1,1,1))
fit11$aicc
fit12<-Arima(ii_20,order=c(0,1,2),seasonal=c(1,1,1))
fit12$aicc
fit13<-Arima(ii_20,order=c(3,1,3),seasonal=c(1,1,1))
fit13$aicc
fit14<-Arima(ii_20,order=c(2,1,3),seasonal=c(1,1,1))
fit14$aicc
fit15<-Arima(ii_20,order=c(3,1,2),seasonal=c(0,1,1))
fit15$aicc

#Fit8 is the best model in terms of minimizing AICc. 

fit_arima<-fit8
checkresiduals(fit_arima,lag=36)
#Residuals look reasonable. There are a few outliers (to be expected based on the data), causing a somewhat right skewed distribution.  Without the outliers, the distribution would be somewhat normal.  There is a minimally significant spike in the negative direction at lag 34.  This could be random.  

accuracy(fit_arima)

#Checking output from auto-arima function.  Trace is set to true so all of the considered models can be viewed:
fit_aa<-auto.arima(ii_20,trace=T)

#The auto-Arima function does not perform the lag 1 differencing step. Therefore, the AICc’s cannot be compared.
#The output from standard auto-Arima settings can be checked against the function using more robust search settings:
fit_aa2<-auto.arima(ii_20,approximation=F,stepwise=F)
fit_aa2
accuracy(fit_aa2)

#Interestingly, the model found from widening the search is the same, except drift is now excluded.  The model is still generated using only 1 seasonal difference on the original data.  The AICc is very slightly lower, so this mode will be used over the other.

checkresiduals(fit_aa2,lag=36)
#Residuals look very similar to those of the manual model.  There is also one significant negative spike in ACF at lag 34, as in the manual model, and the outliers fall in the same place.  The residuals look slightly more normal, and perform a little better in the Ljung-Box test for autocorrelation, though both indicate lack of autocorrelation.
#The AICc’s of this model and the manual ARIMA model cannot be compared as the differencing is not the same.  Both models can be considered in comparing forecast accuracy.

#Next, an ETS model is considered:
fit_ets<-ets(ii_20)
fit_ets
accuracy(fit_ets)
checkresiduals(fit_ets)
autoplot(forecast(fit_ets))
#An ETS(M,Ad,M) model is created with the ets function.  Residuals do not pass the L-B test and are thus more autocorrelated than those from the ARIMA models; the spike at lag 34 persists, and another negative significant spike at lag 10 is seen for this model.



#Next, an ETS model is built using STL decomposition with the stlf function (seasonal and trend decomposition using Loess forecasting). S.window set to 13 accounts for the variations in seasonality from year to year.
fit_stlf<-stlf(ii_20,s.window=13)
fit_stlf$model
#The stlf function generates an ETS(M,Ad,N) model, the same as the ets function but dropping the seasonal term.

checkresiduals(fit_stlf)
#The residuals from STLF are similar in distribution to those of the ARIMA models, but with a significant lag at 24 (indicating a residual seasonal trend not accounted for) instead of 34.  The L-B test results in a pass, but not as high a p-value as either of the ARIMA models.

autoplot(fit_stlf)

#Examining fitted values from each of the models:
autoplot(ii_20) + autolayer(fitted(fit_stlf),series="STL + ETS(M,Ad,N)") + autolayer(fitted(fit_aa2),series="ARIMA, 1 diff") + autolayer(fitted(fit_arima),series="ARIMA, 2 diffs") + autolayer(fitted(fit_ets),series="ETS(M,Ad,M)") + labs(title="US Total Production Index",subtitle="Model Fits",y="Industrial Index (all sectors)")
autoplot(ii_20) + autolayer(fitted(fit_stlf),series="STL + ETS(M,Ad,N)") + autolayer(fitted(fit_aa2),series="ARIMA, 1 diff") + autolayer(fitted(fit_arima),series="ARIMA, 2 diffs") + autolayer(fitted(fit_ets),series="ETS(M,Ad,M)") + labs(title="US Total Production Index",subtitle="Model Fits",y="Industrial Index (all sectors)") + scale_x_continuous(limits=c(2015,2020.25)) + scale_y_continuous(limits=c(99,112))
#Now it is more apparent where each model hits and misses the actual numbers.  Of course, none of the models do well with the March 2020 anomaly but STL seems to handle it best. However, it is still hard to determine visually which model best fits all of the data.  Overall model accuracy can be assessed using cross-validation.


#Creating forecast functions:
fets<-function(y,h) {
  forecast(ets(y),h=h)
}


faa<-function(y,h) {
  forecast(Arima(y,order=c(2,0,2),seasonal=c(0,1,1)),h=h)
}

farima<-function(y,h) {
  forecast(Arima(y,order=c(3,1,2),seasonal=c(0,1,1)),h=h)
}

#Time Series Cross Validations:
e.ets<-tsCV(ii_20,fets,h=1)
e.aa<-tsCV(ii_20,faa,h=1)
e.arima<-tsCV(ii_20,farima,h=1)
e.stlf<-tsCV(ii_20,stlf,h=1)

#RMSE:
sqrt(mean(e.ets^2,na.rm=T))
sqrt(mean(e.aa^2,na.rm=T))
sqrt(mean(e.arima^2,na.rm=T))
sqrt(mean(e.stlf^2,na.rm=T))

#The auto-Arima function has the lowest RMSE, followed by STL + ETS.  These two models will be selected for further comparison of performance. Examining the zoned-in plot of fits again, with the models narrowed down:

autoplot(ii_20) + autolayer(fitted(fit_stlf),series="STL + ETS(M,Ad,N)") + autolayer(fitted(fit_aa2),series="ARIMA, 1 diff") + labs(title="US Total Production Index",subtitle="Model Fits",y="Industrial Index (all sectors)") + scale_x_continuous(limits=c(2015,2020.25)) + scale_y_continuous(limits=c(99,112))
#Each model fits certain events better, though ARIMA is slightly better overall according to RMSE. However, this does not indicate predictive accuracy.  Each model will be re-assessed for how they handle the sudden drops in 2008 and 2020, based on prior information, by changing the training and test sets.  For 2008, a year of forecasts will be examined as this was the approximate period of the recession.  For 2020, 6 month predictions will be made based on information through January 2020 will be compared to the actual data from February and March.


train1<-window(ii_20,end=c(2008,8))
test1<-window(ii_20,start=c(2008,9),end=c(2009,10))
fc1aa<-faa(train1,h=12)
fc1stlf<-stlf(train1,h=12)
#Both models do very poorly with this data.  The training set is relatively small and though there was a slight dip between 2000 and 2002, the drop was unprecedented within the training data.  Also, September is generally a high month for IP index, so it is unsurprising that forecasts do not capture the recession.  It is notable, however, that the actual data is so far out of range that even 95% confidence intervals do not coincide with any of the year’s data.  This illustrates a situation for which confidence intervals are not reliable, because they do not account for un-predictable factors outside of the scope of the model’s training (here, the mortgage crisis).
faa(train1,h=12) %>% autoplot() + autolayer(test1,series="Actual")
stlf(train1,h=12) %>% autoplot() + autolayer(test1,series="Actual")


accuracy(fc1aa,test1)
accuracy(fc1stlf,test1)
#For this time period, it can be observed that the test set errors are quite a bit higher than those for the training set for both models.  The ARIMA model does slightly better at minimizing errors.

test2<-window(ii_20,start=c(2019,4))
train2<-window(ii_20,end=c(2019,3))
fc2aa<-faa(train2,h=12)
fc2stlf<-stlf(train2,h=12)
autoplot(fc2aa) + autolayer(test2, series="Actual")+ scale_x_continuous(limits=c(2015,2020.25)) + scale_y_continuous(limits=c(99,117))

autoplot(fc2stlf) + autolayer(test2, series="Actual") + scale_x_continuous(limits=c(2015,2020.25)) + scale_y_continuous(limits=c(99,118))
#The 12-month forecasts leading up to the 2020 drop are quite good until the drop, where the point forecasts are vastly different, but the prediction intervals do allow for this in terms of range.  This is interesting to note, because even though the drop was the steepest 1-month decline in over 70 years, taken as part of a year-long prediction interval, even this scenario, brought on by extenuating circumstances, is within the prediction limits. In the case of the ARIMA model, it is even within the 80% prediction interval.  The STLF+ETS model point forecast ends up with a higher forecast overall, due to the damped trend component, while the ARIMA model allows for a more sustained continuation of downward trend, which ended up matching the actual occurrence.
accuracy(fc2aa,test2)
accuracy(fc2stlf,test2)
#For this 12 month forecast, the test set errors are much closer to the training errors.  This can be mainly attributed to a relatively “normal” first 11 months of the forecast, the 12th month being mostly of interest.  However, it would also be interesting to view the accuracy measures if the training set is expanded up to February 2020 and March 2020 is used as the test set (or rather, test point).


train3<-window(ii_20,end=c(2020,2))
test3<-window(ii_20,start=c(2020,3))
fc3aa<-faa(train3,h=1)
fc3stlf<-stlf(train3,h=1)
accuracy(fc3aa,test3)
accuracy(fc3stlf,test3)
#In this specific case, the STL+ETS function does better than ARIMA in terms of RMSE and other accuracy measures.  

fc3aa
fc3stlf
#It can be observed that the point forecast for March 2020 is marginally lower for STLF when using data through February 2020 to produce a 1 month forecast, which is opposite the result when using data through March 2019 to produce a 12 month forecast.  However, the difference is not very significant, and using only one point, while interesting to examine, this does not give a very reliable picture of overall model forecasting ability.  Overall, the ARIMA model has performed better for model fit and long-term predictions.


#As the Auto-ARIMA function found the best model in terms of most indicators, this model shall be used to create forecasts and prediction intervals for the future:

p12<-faa(ii_20,h=12) %>% autoplot() + ylab("IP Index(all sectors)")
p24<-faa(ii_20,h=24) %>% autoplot() + ylab("IP Index(all sectors)")

grid.arrange(p12,p24,nrow=2)
#The auto.arima function predictions for the next 12 months are not encouraging, but the 24 month forecast shows a more hopeful indication of a rebound of production within 2 years, though the upward portion of the model shows slow growth as compared to the fast decline.  This does mirror other cycles in the series, and so it should be somewhat reliable as long as the extenuating conditions are not long or impactful enough to cause a long-term change to the underlying process of the model.



#Conclusions:
#Several different models and methods of forecasting were compared in order to analyze predictive capability against the two most recent major declines in IP index.  Overall, the ARIMA(2,0,2)(0,1,1)[12] model found by the automatic ARIMA function had the best fits to the data as well as the best forecasting capability, particularly during the sudden decline events.  At the time of this project, the COVID-19 pandemic is still having a major impact on the US and global economy.  Further research should include review of the forecasts in April 2020, for which there is likely a lower overall IP index (as shut-downs began to be implemented in mid-March and are expected to continue in most regions throughout the month of April, but possibly a lower rate of decline.  In subsequent months, the accuracy of the model can be re-evaluated and new forecasts generated with more current information.  Additionally, it would be helpful to break the time series down by sector, as there have been varying levels of impact.  This can be useful in future industrial planning and relief efforts. 
