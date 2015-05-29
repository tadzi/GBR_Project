# Trend-surface analysis (following Bocard, Gillet & Legendre 2011; Numerical Ecology with R; Chapter 7)
#
# transects to exclude: 10004,10005,10007,10009,14008,15011
# this is a test run on transect 10001
# ******************************************************************************************************

# subset dataset per transect; cdata (=raw data) obtained using import_dat.R script
# aggregate data by image -> mean is calculated for cover estimates per functional group
sdata = aggregate(.~image, data = subset(cdata, trans==10001), mean)
# remove id column (does not carry valuable information anymore after aggregation)
sdata = sdata[,-2]

# extract coordinates and project to UTM coordinate system
xy = sdata[,3:4]
coordinates(xy) = c("lon","lat")
proj4string(xy) = CRS("+proj=longlat +datum=WGS84")
xy = spTransform(xy, CRS("+proj=utm +zone=55 +datum=WGS84"))
xy = xy@coords
xy = data.frame(xy)

# create seperate dataframe for species (excluding catagories Unc (=unclear) and WATE (=water))
sp = sdata[,5:25]

# center coordinates
xy.c = scale(xy, scale=FALSE)
# calculate 3rd degree non-orthogonal polynomial on centered coordinates
xy.poly = poly(as.matrix(xy.c), degree=3, raw=TRUE)
colnames(xy.poly) = c("X", "X2", "X3", "Y", "XY", "X2Y", "Y2", "XY2", "Y3")

# hellinger transformation of cover data
sp.h = decostand(sp, "hellinger")

# RDA with all polynomials
sp.trend.rda = rda(sp.h ~ ., data=as.data.frame(xy.poly))
# output adjusted R^2
(R2adj.poly = RsquareAdj(sp.trend.rda)$adj.r.squared)

# model selection
mod0 = rda(sp.h ~ 1, data=as.data.frame(xy.poly))
mod.sel = ordiR2step(mod0, sp.trend.rda, perm.max=200)
mod.sel$anova #summary anova table -> all terms contribute significantly except X3. Influence of X3 seems large in RDA though??
# select significant terms and pass to RDA
poly.sel = attributes(mod.sel$terms)$term.labels
sp.trend.rda2 = rda(sp.h ~ ., data=as.data.frame(xy.poly)[,poly.sel])

# test for significance of RDA axis
anova.cca(sp.trend.rda2, step=1000, by="axis")

# plot first three (significant) axes
#--------------------------------------------------------------------------------------------------------------------------------------------
# note to self: 
# LC scores = linear contraints: linear combinations of the independent variables. LC scores are in environmental space,
# each axis formed by linear combinations of environmental variables.
# WA scores = weighted averages (sums) of the species scores that are as simimlar to LC scores as possible. WA scores are in species space.
# LC scores show were the site should be; the WA scores show where the site is.
#--------------------------------------------------------------------------------------------------------------------------------------------
sp.trend.fit = scores(sp.trend.rda2, choices=c(1,2,3), display="lc", scaling=1)
par(mfrow=c(1,3))
s.value(xy.c, sp.trend.fit[,1])
s.value(xy.c, sp.trend.fit[,2])
s.value(xy.c, sp.trend.fit[,3])

# data detrending
sp.h.det = resid(lm(as.matrix(sp.h) ~ ., data=as.data.frame(xy.poly)[,poly.sel])) # or only selecting lc scores of significant RDA axis???