###


#Logistic regression to tell if this affects results#
glm(is.na(Back_Gross_Profit) ~ Date, data = KDAt, family = 'binomial')

ggplot(KDARaw,aes(x = Date, y = is.na(Back_Gross_Profit))) + geom_point()
ggplot(KDARaw,aes(x = Date, y = is.na(Cash_Price))) + geom_point()
# How well does all the data we  have predict cash Price?
full.m<-lm(Cash_Price ~ Make + Model + Year + NU, data = KDAt)
summary(full.m)

full.m.1<-lm(totalg ~ ., data = rogue)
summary(full.m.1)            
GGally::ggcorr(KDAt)
