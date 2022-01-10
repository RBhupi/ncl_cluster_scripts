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

	ePATH = "/home/mjmurphy/Documents/work/ncls/erai/geopot/processedData/"
	eFILE = "erai_Z_1979-2010_dailymean_selectedLevels_cutout4kmeans.nc"
	efile=addfile(ePATH+eFILE,"r")

     ; Gather the data we need from the input file(s)
	ght = efile->Z_GDS0_ISBL
	;ght = rawGht(:,2:3,:,:)
	printVarSummary(ght)
	etime = efile->time
	elat  = efile->g0_lat_2
	elon  = efile->g0_lon_3
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

	nlevels = dimsizes(ght(0,:,0,0))
	nlats = dimsizes(ght(0,0,:,0))
	nlons = dimsizes(ght(0,0,0,:))
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
	nGhtDays = dimsizes(etimecal) ; number of actual calander days

	;print(daycal(0)+"")
	;print(etimecal(0)+"")
	;print(nRainDays+"")
	;print(nRainDays+"")

	eghtclust = new((/nclust, nlevels, nlats, nlons/), double)
	n = new((/nclust/), integer)
	eghtclust(:,:,:,:) = 0.0
	n(:) = 0

	do i=0, nGhtDays-1
		do j=0, nRainDays-1
			if(daycal(j).eq.etimecal(i)) then
				;print(""+clust(j))
				eghtclust(clust(j), :,:,:) = eghtclust(clust(j), :,:,:)+ght(i, :,:,:)
				n(clust(j)) = (n(clust(j)))+1
			end if
		end do
	end do

	do k=0, nclust-1
		;if (n(k).ne.0) then
		eghtclust(k,:,:,:) = eghtclust(k,:,:,:)/n(k)  
		;else
			;eghtclust(k,:,:)=eghtclust@_FillValue
		;end if
	end do

	;eghtclust = eghtclust/100 ; convert from Pa to hPa (mb)

     ; Prep the data for the new netCDF file
	eghtclust!0="cluster"
	eghtclust!1="plevel"
	eghtclust!2="lat"
	eghtclust!3="lon"
	eghtclust&cluster = ispan(0,nclust-1,1)
	eghtclust&lat = elat
	eghtclust&lon = elon
	eghtclust&plevel = ght&lv_ISBL1
	eghtclust@units = ght@units
	eghtclust@long_name="Geopotential Height"
	;eghtclust&lat@units = "degrees_north"
	;eghtclust&lon@units = "degrees_east"
	;delete(eghtclust&lat@axis)
	;delete(eghtclust&lon@axis)
	printVarSummary(eghtclust)
	;creating output file name


     ; Write out the converted data to a netCDF file
	afilo="cluster_GHT"+tostring(nclust-1)+".nc"
	diro = "./"                     ; Output director
	system("/bin/rm -f " + diro + afilo)    ; remove if exists
	afout  = addfile (diro + afilo, "c")  ; open output file
	afout->eghtclust=eghtclust


     ; Cleaning up
	delete(ght)
	delete(etime)
	delete(clust)
	delete(eghtclust)
	delete(elat)
	delete(elon)
	delete(day)
	delete(n)

	print("Cluster no.  "+tostring(nclust-1)+" done!")

end do

end
exit

