;this matches cluster dates with erai and radar days
;awap date is shifted one day backward as it is accumulation of previouse day

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"


begin 

do nclust=5,5
	print("cluster   "+tostring(nclust)+"  started..." )

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
	rawClust=cfile->clust

     ; Manipulation of the data
	nclust = nclust +1 ; KLUDGE to accomadate the zero cluster
	startYear = 1979
	startDate = cd_inv_calendar(startYear,1,1,0,0,0,rawClust&time@units, 0)

	clust = rawClust({startDate:})
	day = clust&time
	printVarSummary(clust)

	nlats = dimsizes(u(0,:,0))
	nlons = dimsizes(u(0,0,:))
	;######change awap date to previous day
	do x=0, dimsizes(day)-1
		day(x)=day(x)-1
	end do
	;############################

	print("finished reading files..")
	daycal=ut_calendar(day, -2)
	etimecal=ut_calendar(etime, -2)
	;print(daycal)
	;print(timecal)
	dn = dimsizes(daycal)
	ta = dimsizes(etimecal)
	
	uclust=new((/nclust, nlats, nlons /), double)
	vclust=new((/nclust, nlats, nlons /), double)
	n=new((/nclust/), integer)
	uclust(:,:,:)=0.0
	vclust(:,:,:)=0.0
	n(:)=0


	do i=0, ta-1
		do j=0, dn-1
			if(daycal(j).eq.etimecal(i)) then
				uclust(clust(j), :,:) = uclust(clust(j), :,:)+u(i, :,:)
				vclust(clust(j), :,:) = vclust(clust(j), :,:)+v(i, :,:)
				n(clust(j))=(n(clust(j)))+1
			end if
		end do
	end do

	print("finished matching...")
	do k=0, nclust-1
		;if (n(k).ne.0) then
		uclust(k,:,:)=uclust(k,:,:)/n(k)
		vclust(k,:,:)=vclust(k,:,:)/n(k)
		;else
			;emslpclust(k,:,:)=emslpclust@_FillValue
		;end if
	end do


     ; Prep the data for the new netCDF file
	uclust!0 = "cluster"
	uclust!1 = "lat"
	uclust!2 = "lon"
	uclust&cluster = ispan(0,nclust-1,1)
	uclust&lat = elat
	uclust&lon = elon
	uclust@units = "m/s"
	uclust@long_name = "10 meter wind"

	vclust!0 = "cluster"
	vclust!1 = "lat"
	vclust!2 = "lon"
	vclust&cluster = ispan(0,nclust-1,1)
	vclust&lat = elat
	vclust&lon = elon
	vclust@units = "m/s"
	vclust@long_name = "10 meter wind"
	;printVarSummary(rainclust)
	;print(n)
	;creating output file name
	print("finished averaging ... File writing started..")


     ; Write out the converted data to a netCDF file
	afilo="cluster_wind"+tostring(nclust-1)+".nc"
	diro = "./"                     ; Output director
	system("/bin/rm -f " + diro + afilo)    ; remove if exists
	afout  = addfile (diro + afilo, "c")  ; open output file
	afout->uclust=uclust
	afout->vclust=vclust


     ; Cleaning up
	delete(u)
	delete(v)
	delete(etime)
	delete(elon)
	delete(elat)
	delete(clust)
	delete(day)
	delete(uclust)
	delete(vclust)
	delete(n)
	print("cluster   "+tostring(nclust-1)+"   done!")

end do

end
exit

