# eudist function
#****************************************************************************************************************************
# function calculates euclidian distance between coordinates. Estimates should be ok for short distances between coordinates.
# function takes geographical coodinates and projects these to UTMs
# function does not assume curvature of the earth
# function needs "lon" and "lat" columns
#****************************************************************************************************************************

eudist = function(dat)
{
  library("sp")
  library("rgdal")
  
  # declare output as df
  len = length(dat[,1])
  d = data.frame(image = numeric(len),
                 dist = numeric(len))
  
  # project coordinates to utm
  coordinates(dat) = c("lon","lat")
  proj4string(dat) = CRS("+proj=longlat +datum=WGS84")
  tdata = spTransform(dat,CRS("+proj=utm +zone=55 +datum=WGS84"))
  as(tdata,"SpatialPoints")
  
  # iterate over the utm coordinates and calculate euclidian distance
  for (i in 2:len)
  {
    d[i,1] = tdata$image[i]
    d[i,2] = sqrt((tdata$lat[i]-tdata$lat[i-1])^2 + (tdata$lon[i]-tdata$lon[i-1])^2)
  }
  # remove first row (contains to information) and rownames
  d = d[-1,]
  rownames(d) = NULL
  
  #return distances
  return(d)
}
