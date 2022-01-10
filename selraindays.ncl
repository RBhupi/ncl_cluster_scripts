;________________________________________________________________
;
;   NCL script to read in an AWAP netCDF file and seperate
;    out the days with precip below a given threshold.  The
;    result is written out in both ascii and netCDF format. 
;
;    Author (Original): Bhupendra Raut 
;    Modifed by: 	MJ Murphy (23 Oct 2012)
;________________________________________________________________

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;This is for awap rawData 	
;ONLY RAINY DAYS ARE WRITEN IN ASCII FILE

begin

 ; Read in the input file
	PATH="/home/mjmurphy/Documents/work/ncls/awap/kmeans/rawData/" 
	FILE= "arain.1950-2010.daily.grid-wetTropics-extendedCutout4kmeans.nc"
	infile = addfile(PATH+FILE,"r")


 ; Gather the data we need from the input file
	print("Reading file....")
	rawData=infile->rain
	ntimes=dimsizes(rawData&time)
	nlats=dimsizes(rawData&lat)
	nlons=dimsizes(rawData&lon)

	rawData@_FillValue = 999.99 ; very important because kmeans fortran code is picky
	;rawData@_FillValue = 99999.99
	printVarSummary(rawData)
	;printVarSummary(rawData&lat)


 ; Manipulation of the data
	clustData=rawData(:,:,:)			; rawData(:, lat_min:lat_max, lon_min:lon_max)
	x1d=ndtooned(clustData)
	npoints=nlats*nlons
	x2d=onedtond(x1d, (/ntimes, npoints/))

	print("separating rainy days...")
	threshold = 0.1 ; mm
	;--------------------------
	;to count # of rany days
	rcount=0
	do itime=0, ntimes-1
		if(avg(x2d(itime,:)).gt.(threshold)) then ; definition of rainy day critera
			rcount=rcount+1
		end if
	end do
	;---------------------------
	;toseparate rainy days
	raindat=new((/rcount,npoints/), float)
	rtime=new((/rcount/), integer)
	rrain=new((/rcount, nlats, nlons/), float)  ;to stored rainy days rawData in netcdf
	;rtime@units=time@units
	tcount=0
	do itime=0, ntimes-1
		if(avg(x2d(itime,:)).gt.(threshold)) then; definition of rainy day critera
			raindat(tcount,:)=x2d(itime, :)
			rtime(tcount)=toint(rawData&time(itime))
			rrain(tcount,:,:)=rawData(itime, :, :)
			tcount=tcount+1
		end if
	end do


 ; Generate output files
	;--------------------------
	;crreat file for writing 
	print("creating output files...")
	outfile=FILE
	opt  = True
	opt@fout = str_sub_str(outfile, ".nc", "_raindaysOnly.dat")
	system("rm -vf "+opt@fout)
	frmt=npoints+"f10.2"
	timefout="time.dat"
	latfout="lat.dat"
	lonfout="lon.dat"
	asciiwrite(latfout, rawData&lat)
	asciiwrite(lonfout, rawData&lon)
	write_matrix (raindat, frmt, opt)
	;writing  time file
	asciiwrite(timefout, rtime)
	;###################################


	;For nc file
	;################### attributes ###########
	; no atts needed, aleady came across the vars
	printVarSummary(rawData)
	;print(typeof(rrain&time))
	;print(default_fillvalue(typeof(rrain&time)))
	printVarSummary(rrain)
	;print( rrain&time + " --- " + rtime)

	;#######creating output file name 
	filo=str_sub_str(outfile, ".nc", "_raindaysOnly.nc")
	;filo=str_sub_str(filo, "arain", "rrain")
	system("rm -rv "+ filo)
	print(filo)
	print("writing file....")
	diro = "./"                     ; Output director
	;system("/bin/rm -f " + diro + filo)    ; remove if exists
	fout  = addfile (diro + filo, "c")  ; open output file
	dimNames = (/"time", "lat", "lon"/)  
	dimSizes = (/ -1   ,  nlats,  nlons/) 
	dimUnlim = (/ True , False, False/)   

	filedimdef(fout,dimNames,dimSizes,dimUnlim)
	setfileoption(fout, "DefineMode", True)
	 globalAtt=True
	 globalAtt@title="Daily Gridded Rainfall Accumulations ONLY FOR RAINY DAYS"
	 globalAtt@source             = "created by the Australian Bureau of Meteorology for the Australian Water Availability Project (AWAP)"
	 globalAtt@detailed_documentation = "www.bom.gov.au/amm/docs/2009/jones.pdf"
	 globalAtt@creation_date=systemfunc("date")
	 fileattdef(fout, globalAtt)    
	 fout->rrain=rrain
	print("file closed")
	;######################################### end NC





	print("********************************")
	print(rcount)
	print("% of rainy days")
	print((tofloat(tcount)/tofloat(ntimes))*100)
	print("********************************")
	print("DONE!  :-)")
end

