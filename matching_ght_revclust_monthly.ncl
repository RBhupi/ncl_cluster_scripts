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

     ; Date stuff
	date  = cd_calendar(day, 0)
	year  = tointeger(date(:,0))
	month = tointeger(date(:,1))
	daycal   = cd_calendar(day, -2)
	etimecal = cd_calendar(etime, -2)
	;print(daycal(0:10))
	;print(etimecal(0:10))
	nRainDays = dimsizes(daycal) ; number of rain days
	nGhtDays = dimsizes(etimecal) ; number of actual calander days

	;print(daycal(0)+"")
	;print(etimecal(0)+"")
	;print(nRainDays+"")
	;print(nRainDays+"")

     ; Prep the data for the new netCDF file
	eghtclust = new((/nclust, 12, nlevels, nlats, nlons/), double)
	eghtclust!0="cluster"
	eghtclust!1="month"
	eghtclust!2="plevel"
	eghtclust!3="lat"
	eghtclust!4="lon"

	eghtclust&cluster = ispan(0,nclust-1,1)
	eghtclust&month = ispan(1,12,1)
	eghtclust&lat = elat
	eghtclust&lon = elon
	eghtclust&plevel = ght&lv_ISBL1
	eghtclust@units = ght@units
	eghtclust@long_name= ght@long_name

	eghtclust(:,:,:,:,:) = 0.0
	
	n = new((/nclust,12/), integer)
	n!0="cluster"
	n!1="month"
	n&cluster = eghtclust&cluster
	n&month   = eghtclust&month
	
	n(:,:) = 0

	;printVarSummary(ght)

     ; Calculate mean geopotential
	do i=0, nGhtDays-1
		print("day "+i+" of "+nGhtDays)
		do j=0, nRainDays-1
			if(daycal(j).eq.etimecal(i)) then
				;print(""+clust(j))
				;eghtclust(clust(j), {month(j)}, :,:,:) = eghtclust(clust(j), {month(j)}, :,:,:)+ght(i, :,:,:)
				n(clust(j),{month(j)}) = n(clust(j),{month(j)})+1
			end if
		end do
	end do

	do iclust=0,nclust-1
	    	do imonth=0,11
			if (n(iclust,imonth) .ne. 0) then
				eghtclust(iclust,imonth,:,:,:) = eghtclust(iclust,imonth,:,:,:)/n(iclust,imonth)  
			else
				eghtclust(iclust,imonth,:,:,:) = eghtclust@_FillValue
			end if
		end do
	end do


	printVarSummary(eghtclust)


     ; Write out the converted data to a netCDF file
	afilo="cluster_monthly_GHT"+tostring(nclust-1)+".nc"
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

