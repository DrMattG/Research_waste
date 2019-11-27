#Load libraries
# List of packages for session
.packages = c("readr", "data.table", "scales", "cowplot", "metafor",
"nlme", "MuMIn", "effects", "tidyverse", "ggsci", "gganimate", "ggrepel")

# Install CRAN packages (if not already installed)
.inst <- .packages %in% installed.packages()
if(length(.packages[!.inst]) > 0) install.packages(.packages[!.inst])

# Load packages into session 
lapply(.packages, require, character.only=TRUE)

#################################################################################################################
################################Code from the original paper (Darras et al. 2018)################################
#################################################################################################################
#Prepare data and Run metaanalysis

#standard error function
se <- function(x) sqrt(var(x,na.rm=TRUE)/length(na.omit(x)))
#Get data
meta0=fread("data/meta-analysis - data.csv")
#give ID to all studies
meta0[,study_ID:=1:nrow(meta0)]
#remove Acevedo due to unequal sampling
meta0=meta0[first_author!="Acevedo"]
#convert to numeric
meta0=meta0[,total_time_min:=as.numeric(total_time_min)]
#format column headers
meta.studies=meta0[,.(Publication=paste(first_author,year),`Sampling time (min)`=total_time_min,Microphone=microphone,`Signal to noise ratio (minimum, dB)`=signal_to_noise,`Height (cm)`=height_cm,`Number of Microphones`=number_microphones)]
# community differences ---------------------------------------------------
#compute total richness with both methods combined
meta0[,c("gamma_total_unlimited","gamma_total_identical")
      :=.(gamma_point_unlimited+unique_sound_unlimited,gamma_point_identical+unique_sound_identical)]

meta0[simultaneous_methods==1,.(common_species_unlimited=mean((gamma_point_unlimited-unique_point_unlimited)/gamma_total_unlimited,na.rm=T)
                                ,unique_point_unlimited=mean(unique_point_unlimited/gamma_total_unlimited,na.rm=T)
                                ,unique_sound_unlimited=mean(unique_sound_unlimited/gamma_total_unlimited,na.rm=T)
                                ,common_species_identical=mean((gamma_point_identical-unique_point_identical)/gamma_total_identical,na.rm=T)
                                ,unique_point_identical=mean(unique_point_identical/gamma_total_identical,na.rm=T)
                                ,unique_sound_identical=mean(unique_sound_identical/gamma_total_identical,na.rm=T))]

# calculate ROM ----------------------------------------------------------

#calculate log transformed ratio of means for alpha and gamma richness
#alpha richness identical
alpha.identical=data.table(summary(escalc(measure="ROM"
                                          ,m1i=alpha_sound_identical,m2i=alpha_point_identical
                                          ,sd1i=alpha_sound_sd_identical,sd2i=alpha_point_sd_identical
                                          ,n1i=alpha_sound_n_identical,n2i=alpha_point_n_identical
                                          ,data=meta0[!is.na(alpha_point_n_identical)])))

#alpha richness unlimited
alpha.unlimited=data.table(summary(escalc(measure="ROM"
                                          ,m1i=alpha_sound_unlimited,m2i=alpha_point_unlimited
                                          ,sd1i=alpha_sound_sd_unlimited,sd2i=alpha_point_sd_unlimited
                                          ,n1i=alpha_sound_n_unlimited,n2i=alpha_point_n_unlimited
                                          ,data=meta0[!is.na(alpha_point_n_unlimited)])))
#gamma richness identical
gamma.identical=data.table(summary(escalc(measure="ROM"
                                          ,m1i=gamma_sound_identical,m2i=gamma_point_identical
                                          ,sd1i=rep(0,nrow(meta0[!is.na(gamma_total_identical)])),sd2i=rep(0,nrow(meta0[!is.na(gamma_total_identical)]))
                                          ,n1i=total_time_min,n2i=total_time_min
                                          ,data=meta0[!is.na(gamma_total_identical)])))

#gamma richness unlimited
gamma.unlimited=data.table(summary(escalc(measure="ROM"
                                          ,m1i=gamma_sound_unlimited,m2i=gamma_point_unlimited
                                          ,sd1i=rep(0,nrow(meta0[!is.na(gamma_total_unlimited)])),sd2i=rep(0,nrow(meta0[!is.na(gamma_total_unlimited)]))
                                          ,n1i=total_time_min,n2i=total_time_min
                                          ,data=meta0[!is.na(gamma_total_unlimited)])))

#merge all ROM data together
meta1=merge(meta0,merge(alpha.identical[,.(study_ID,alpha_ROM_identical=yi,alpha_variance_ROM_identical=vi,alpha_ci.lb_identical=ci.lb,alpha_ci.ub_identical=ci.ub)]
                        ,merge(alpha.unlimited[,.(study_ID,alpha_ROM_unlimited=yi,alpha_variance_ROM_unlimited=vi,alpha_ci.lb_unlimited=ci.lb,alpha_ci.ub_unlimited=ci.ub)]
                               ,merge(gamma.unlimited[,.(study_ID,gamma_ROM_unlimited=yi,gamma_variance_ROM_unlimited=vi)]
                                      ,gamma.identical[,.(study_ID,gamma_ROM_identical=yi,gamma_variance_ROM_identical=vi)]
                                      ,all=T,by="study_ID"),all=T,by="study_ID"),all=T,by="study_ID"),all=T,by="study_ID")


# identical range (alpha) --------------------------------------------------------------

#create publication=level column for random effect
meta1[,publication:=paste(first_author,year)]

#models for identical ranges
RMA_alpha_identical=rma.mv(yi=alpha_ROM_identical,V=alpha_variance_ROM_identical
                           ,data=meta1,random=list(~1|publication))

#################################################################################################################
#################################################################################################################

### Add cumulative meta-analysis
res <- rma(RMA_alpha_identical$yi, RMA_alpha_identical$vi, data=meta1, slab=paste(meta1$first_author, meta1$year, sep=", "))
cres<-cumul(res, order=order(meta1$year))

meta1$IF<-c(2.27,0.967,0.967,0.967,1.29,0.41,0.967,0.967,0.967,0,0.538,2.055,2.53,2.53,0.622,1.92,1.895,0.94,1.895,0,0.967,1.75,6.36,0,0.41,0,0.41)
cres2<-cumul(res, order=order(meta1$IF))

#plot.cumul.rma(cres)


#Figure1
png("Figures/Figure1.png", width=850, height =400)
forest(cres, col="blue")
dev.off()

forest(cres2, col="blue")
#Cumulative data frame
cumzval<-cumsum(cres$zval)
cum_sample<-cumsum(meta1$alpha_point_n_identical)  
Year=meta1$year

Year=gsub("a","",Year)
Year=gsub("b","",Year)
Year<-as.integer(Year)
Year<-Year[order(Year)]

cum_df<-data.frame("z-score"=cumzval, "Cumulative n"=cum_sample, "Year"=Year)
#Labelling dataframe
cum_df2<-cum_df[c(1,18,27),]
png("Figures/Figure2.png", width=850, height =400)
cum_df %>% 
  ggplot(aes(cum_sample,z.score, colour=as.factor(Year)))+
  scale_fill_npg()+
  labs(y="Cumulative z score", x="Cumulative sample size")+
  geom_point(size=6)+
  geom_line(colour="blue", linetype="dashed", size=1)+
  ylim(c(-20,20))+
  xlim(c(0,2000))+
  geom_text(data=cum_df2, aes(Cumulative.n,z.score,label=as.factor(Year)),hjust=1.3, vjust=1, colour="black")+
  geom_hline(yintercept = 2, colour="red",linetype="dotted", size=1.6)+
  geom_hline(yintercept = -2, colour="red",linetype="dotted", size=1.6)+
  theme_classic() +
  theme(axis.line = element_line(size = 1.6, color = rgb(0,0,0,max=255)))+
  theme(legend.position = "none")+
  theme(text=element_text(size=16,  family="serif"))
  
dev.off()
#Animated Figure 2
cum_df %>% 
  rowid_to_column() %>% 
  ggplot(aes(cum_sample,z.score, colour=as.factor(Year)))+
  scale_fill_npg()+
  labs(y="Cumulative z score", x="Cumulative sample size")+
  geom_point(size=6)+
  geom_line(colour="blue", linetype="dashed", size=1)+
  ylim(c(-20,20))+
  xlim(c(0,2000))+
  geom_text(aes(label=as.factor(Year)),hjust=1.3, vjust=1)+
  geom_hline(yintercept = 2, colour="red",linetype="dotted", size=1.6)+
  geom_hline(yintercept = -2, colour="red",linetype="dotted", size=1.6)+
  theme_classic() +
  theme(axis.line = element_line(size = 1.6, color = rgb(0,0,0,max=255)))+
  theme(legend.position = "none")+
  theme(text=element_text(size=16,  family="serif"))+
  transition_reveal(rowid)

anim_save("Figures/Fig2animation.gif")



