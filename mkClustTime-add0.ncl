;________________________________________________________________
;
;   NCL script to read in an ascii output file of the kmeans 
;    fortran code (cluster_0?.asc) and convert it to a 
;    formatted netCDF file.
;
;    Author (Original): BA Raut 
;    Modifed by: 	MJ Murphy (23 Oct 2012)
;________________________________________________________________

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"


begin

 ; Read in the input file(s)
	PATH1 = "../../rawData/" 
	FILE1 = "arain.1950-2010.daily.grid-wetTropics-cutout4kmeans.nc"
	infile1 = addfile(PATH1+FILE1,"r")

	PATH2 = "./" 
	FILE2 = "arain.1950-2010.daily.grid-wetTropics-cutout4kmeans_raindaysOnly.nc"
	infile2 = addfile(PATH2+FILE2,"r")


 ; Gather the data we need from the input file
	print("Reading file....")
	rawData_full         = infile1->rain
	rawData_raindaysOnly = infile2->rrain
	printVarSummary(rawData_full)
	printVarSummary(rawData_raindaysOnly)


 ; Manipulation of the data
	nlats    = dimsizes(rawData_full&lat)
	nlons    = dimsizes(rawData_full&lon)
	ndays    = dimsizes(rawData_full&time)
	nwetDays = dimsizes(rawData_raindaysOnly&time)
	ndryDays = ndays - nwetDays
	print(ndays +" ~ "+ nwetDays +" ~ "+ ndryDays)
	;printVarSummary(rawData_raindaysOnly&time)


 ; Now carry on with Bhupi's code
	do nclust=5,5  ; # of clusters not counting zero (dry) cluster

	     ; Read in the data
		cfile="cluster_0"+tostring(nclust)+".asc"
		;read time-clust info
		time=asciiread("time.dat", -1, "integer")
		clust=asciiread(cfile, -1, "integer")

             ; Add in the zero (dry) cluster
		finalCluster = new(ndays,integer)
		do iday=0, ndays-1
			if( any(rawData_full&time(iday) .eq. rawData_raindaysOnly&time) ) then
				index = ind(rawData_full&time(iday) .eq. rawData_raindaysOnly&time)
				finalCluster(iday) = clust(index)
				delete(index)
			else
				finalCluster(iday) = 0 
			end if
		end do
		;print(finalCluster)
		;print(num(finalCluster .ne. 0))
		;print(num(ismissing(finalCluster)))

	     ; Add metadata
		finalCluster!0 = "time"
		finalCluster&time = rawData_full&time
		finalCluster@units     = "none"
		finalCluster@long_name = "cluster membership"
		printVarSummary(finalCluster)
		printVarSummary(finalCluster&time)
		
	     ; Create output file 
		filo=cfile
		filo=str_sub_str(filo, ".asc", ".nc")
		print(filo)
		diro = "./"                     ; Output director
		system("/bin/rm -f " + diro + filo)    ; remove if exists
		fout  = addfile (diro + filo, "c")  ; open output file
		fout->clust=finalCluster

	end do

end

exit
