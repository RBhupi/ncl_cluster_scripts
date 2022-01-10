;________________________________________________________________
;
;   NCL script to build a netCDF file with ERAI daily mean 
;    MSLP on each of the rain days used in the k-means 
;    clustering.
;________________________________________________________________


load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
begin 

do nclust=5,5
	print("Cluster no.  "+tostring(nclust)+" started")

     ; Read in the input file(s)
	datfn="cluster_0"+tostring(nclust)+".nc"
	cfile=addfile(datfn, "r")

	ePATH = "/home/mjmurphy/Documents/work/ncls/erai/msl/processedData/"
	eFILE = "erai_MSL_1979-2010_dailymean_cutout4kmeans.nc"
	efile=addfile(ePATH+eFILE,"r")

     ; Gather the data we need from the input file(s)
	mslp=efile->MSL_GDS0_SFC
	etime=efile->time
	elat=efile->g0_lat_1
	elon=efile->g0_lon_2
	clust=cfile->clust ; I dont think we need this at all!
	day=cfile->time
	printVarSummary(clust)
	printVarSummary(mslp)
	;print(clust)

     ; Manipulation of the data
	nlats = dimsizes(mslp(0,:,0))
	nlons = dimsizes(mslp(0,0,:))
	;######change awap date to previous day
	do x=0,dimsizes(day)-1
		day(x)=day(x)-1
	end do
	;############################

	daycal=ut_calendar(day, 2)
	etimecal=ut_calendar(etime,2)
	print(daycal(0:10))
	print(etimecal(0:10))
	nRainDays=dimsizes(daycal) ; number of rain days
	nMslpDays=dimsizes(etimecal) ; number of actual calander days
	print(nRainDays)
	print(nMslpDays)


	emslpclust=new((/nRainDays, nlats, nlons/), typeof(mslp),mslp@_FillValue)
	emslpclust(:,:,:)= emslpclust@_FillValue
	printVarSummary(emslpclust)

	do i=0, nMslpDays-1
		do j=0, nRainDays-1
			if(daycal(j).eq.etimecal(i)) then
				;print(i+"  -  "+j)
				;print(tostring(daycal(j))+"  -  "+tostring(etimecal(i)) )
				emslpclust(j-1, :,:)=mslp(i, :,:)
			end if
		end do
	end do
	emslpclust = emslpclust/100 ; convert from Pa to hPa (mb)


     ; Prep the data for the new netCDF file
	emslpclust!0="time"
	emslpclust!1="lat"
	emslpclust!2="lon"
	emslpclust&lat=elat
	emslpclust&lon=elon
	copy_VarAtts(mslp,emslpclust)
	printVarSummary(emslpclust)


     ; Write out the converted data to a netCDF file
	afilo="rainDays-MSLP.nc"
	diro = "./"                     ; Output director
	system("/bin/rm -f " + diro + afilo)    ; remove if exists
	afout  = addfile (diro + afilo, "c")  ; open output file
	afout->emslpclust=emslpclust


     ; Cleaning up
	delete(mslp)
	delete(etime)
	delete(clust)
	delete(emslpclust)
	delete(elat)
	delete(elon)
	delete(day)

	print("Cluster no.  "+tostring(nclust)+" done!")

end do

end
exit

