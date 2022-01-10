;this matches cluster dates with erai and radar days
;awap date is shifted one day backward as it is accumulation of previouse day


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
	mslp = efile->MSL_GDS0_SFC
	printVarSummary(mslp)
	etime = efile->time
	elat  = efile->g0_lat_1
	elon  = efile->g0_lon_2
	rawClust = cfile->clust
	;printVarSummary(day)
	;printVarSummary(rain)
	;print(clust)

     ; Manipulation of the data
	nclust = nclust +1 ; KLUDGE to accomadate the zero cluster
	startYear = 1979
	startDate = cd_inv_calendar(startYear,1,1,0,0,0,rawClust&time@units, 0)

	clust = rawClust({startDate:})
	day = clust&time
	printVarSummary(clust)

	nlats = dimsizes(mslp(0,:,0))
	nlons = dimsizes(mslp(0,0,:))
	;######change awap date to previous day
	do x=0,dimsizes(day)-1
		day(x)=day(x)-1
	end do
	;############################

	daycal   = ut_calendar(day, -2)
	etimecal = ut_calendar(etime, -2)
	;print(daycal(0:10))
	;print(etimecal(0:10))
	nRainDays = dimsizes(daycal) ; number of rain days
	nMslpDays = dimsizes(etimecal) ; number of actual calander days

	;print(daycal(0)+"")
	;print(etimecal(0)+"")
	;print(nRainDays+"")
	;print(nRainDays+"")

	emslpclust = new((/nclust, nlats, nlons/), double)
	n = new((/nclust/), integer)
	emslpclust(:,:,:) = 0.0
	n(:) = 0

	do i=0, nMslpDays-1
		do j=0, nRainDays-1
			if(daycal(j).eq.etimecal(i)) then
				;print(""+clust(j))
				emslpclust(clust(j), :,:) = emslpclust(clust(j), :,:)+mslp(i, :,:)
				n(clust(j)) = (n(clust(j)))+1
			end if
		end do
	end do

	do k=0, nclust-1
		;if (n(k).ne.0) then
		emslpclust(k,:,:) = emslpclust(k,:,:)/n(k)  
		;else
			;emslpclust(k,:,:)=emslpclust@_FillValue
		;end if
	end do

	emslpclust = emslpclust/100 ; convert from Pa to hPa (mb)


     ; Prep the data for the new netCDF file
	emslpclust!0="cluster"
	emslpclust!1="lat"
	emslpclust!2="lon"
	emslpclust&cluster = ispan(0,nclust-1,1)
	emslpclust&lat = elat
	emslpclust&lon = elon
	emslpclust@units="hPa"
	emslpclust@long_name="Sea Level Pressure"
	;emslpclust&lat@units = "degrees_north"
	;emslpclust&lon@units = "degrees_east"
	;delete(emslpclust&lat@axis)
	;delete(emslpclust&lon@axis)
	printVarSummary(emslpclust)
	;creating output file name


     ; Write out the converted data to a netCDF file
	afilo="cluster_MSLP"+tostring(nclust-1)+".nc"
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
	delete(n)

	print("Cluster no.  "+tostring(nclust-1)+" done!")

end do

end
exit

