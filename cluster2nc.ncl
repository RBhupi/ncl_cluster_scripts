;________________________________________________________________
;
;   NCL script to read in an ascii output file of the kmeans 
;    fortran code (centroid_0?.asc) and convert it to a 
;    formatted netCDF file.
;
;    Author (Original): Bhupendra Raut 
;________________________________________________________________

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"


begin

nlat=81
nlon=41
do nclust=5,5
;do nclust=7,7
;read latlon file
	flat="lat.dat"
	flon="lon.dat"
	datfn="centroid_0"+tostring(nclust)+".asc"
	print(datfn)
	fdat=datfn
	lat=asciiread(flat, nlat, "float")
	lon=asciiread(flon, nlon, "float")
	dat=asciiread(fdat, (/nclust, nlon*nlat/), "float")
	print(lat)
	print(lon)
	printVarSummary(dat)
	clust=new (nclust, integer)  ;create array of the size of no. of cluster
	do i=0, nclust-1
		clust(i)=i+1    ;initialised
	end do
	data1d=ndtooned(dat)
	data=onedtond(data1d(:), (/nclust, nlat, nlon/))
	;	printVarSummary(data)

	lat@units = "degrees_north"
	lat@long_name = "latitude"
	lon@units = "degrees_east"
	lon@long_name = "longitude"
	data@long_name = "Centroid of the K-means cluster"
	data@units = "mm/day"
	data@_FillValue = 999.99
	;data@_FillValue = -99.99


	data!0="clust"
	data!1="lat"
	data!2="lon"

	;data&clust=clust
	data&lat=lat
	data&lon=lon
	
	;creating output file name 
	filo=fdat
	filo=str_sub_str(filo, ".asc", ".nc")
	print(filo)
        diro = "./"                     ; Output director
	system("/bin/rm -f " + diro + filo)    ; remove if exists
	fout  = addfile (diro + filo, "c")  ; open output file


	dimNames = (/"clust", "lat", "lon"/)  
	dimSizes = (/ -1   ,  nlat,  nlon/) 
	dimUnlim = (/ True , False, False/)   
	filedimdef(fout,dimNames,dimSizes,dimUnlim)






    setfileoption(fout, "DefineMode", True)
    globalAtt=True
    globalAtt@title="AWAP rain:clusters centroid"
    globalAtt@creation_date=systemfunc("date")
	fileattdef(fout, globalAtt)    


	fout->data=data
	delete(dat)
	delete(data1d)
	delete(data)
	delete(clust)

end do

end
