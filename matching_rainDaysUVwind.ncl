;________________________________________________________________
;
;   NCL script to build a netCDF file with ERAI daily mean 
;    U & V winds on each of the rain days used in the k-means 
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

	ePATH = "/home/mjmurphy/Documents/work/ncls/erai/wind10m/processedData/"
	eFILE = "erai_10UV_1979-2010_dailymean_cutout4kmeans.nc"
	efile=addfile(ePATH+eFILE,"r")

     ; Gather the data we need from the input file(s)
	u=efile->10U_GDS0_SFC
	v=efile->10V_GDS0_SFC
	etime=efile->time
	elat=efile->g0_lat_1
	elon=efile->g0_lon_2
	clust=cfile->clust
	day=cfile->time
	printVarSummary(clust)
	printVarSummary(u)
	;print(clust)

     ; Manipulation of the data
	nlats = dimsizes(u(0,:,0))
	nlons = dimsizes(u(0,0,:))
	;######change awap date to previous day
	do x=0,dimsizes(day)-1
		day(x)=day(x)-1
	end do
	;############################

	daycal   = ut_calendar(day, 2)
	etimecal = ut_calendar(etime,2)
	print(daycal(0:10))
	print(etimecal(0:10))
	nRainDays = dimsizes(daycal) ; number of rain days
	nMslpDays = dimsizes(etimecal) ; number of actual calander days
	print(nRainDays)
	print(nMslpDays)

	uclust=new((/nRainDays, nlats, nlons /), float, u@_FillValue)
	vclust=new((/nRainDays, nlats, nlons /), float, v@_FillValue)
	uclust(:,:,:) = u@_FillValue
	vclust(:,:,:) = v@_FillValue
	printVarSummary(uclust)

	do i=0, nMslpDays-1
		do j=0, nRainDays-1
			if(daycal(j).eq.etimecal(i)) then
				;print(i+"  -  "+j)
				;print(tostring(daycal(j))+"  -  "+tostring(etimecal(i)) )
				uclust(j-1, :,:)=u(i, :,:)
				vclust(j-1, :,:)=v(i, :,:)
			end if
		end do
	end do


     ; Prep the data for the new netCDF file
	uclust!0="time"
	uclust!1="lat"
	uclust!2="lon"
	uclust&lat=elat
	uclust&lon=elon
	copy_VarAtts(u,uclust)
	printVarSummary(uclust)

	vclust!0="time"
	vclust!1="lat"
	vclust!2="lon"
	vclust&lat=elat
	vclust&lon=elon
	copy_VarAtts(v,vclust)
	printVarSummary(vclust)


     ; Write out the converted data to a netCDF file
	afilo="rainDays-uvWind.nc"
	diro = "./"                     ; Output director
	system("/bin/rm -f " + diro + afilo)    ; remove if exists
	afout  = addfile (diro + afilo, "c")  ; open output file
	afout->uclust=uclust
	afout->vclust=vclust


     ; Cleaning up
	delete(u)
	delete(v)
	delete(etime)
	delete(clust)
	delete(uclust)
	delete(elat)
	delete(elon)
	delete(day)

	print("Cluster no.  "+tostring(nclust)+" done!")

end do

end
exit

