;________________________________________________________________
;
;   NCL script to read in an ascii output file of the kmeans 
;    fortran code (cluster_0?.asc) and convert it to a 
;    formatted netCDF file.
;
;    Author (Original): Bhupendra Raut 
;________________________________________________________________

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"


begin
	do nclust=5,5
	     ; Read in the data
		cfile="cluster_0"+tostring(nclust)+".asc"
		;read time-clust info
		time=asciiread("time.dat", -1, "integer")
		clust=asciiread(cfile, -1, "integer")

	     ; Reorder the clusters to the way we want.
		finalCluster = new(dimsizes(clust),typeof(clust),clust@_FillValue)
		orderClust = (/ 1,5,2,3,4 /) ; desired order of clusters based on raw ordering
		do iclust=0,nclust-1
			holdIndex = ind( clust .eq. orderClust(iclust) )
			holdvalues = new(dimsizes(holdIndex),integer)
			holdvalues(:) = iclust +1
			finalCluster(holdIndex) = holdvalues(:)
			delete( [/ holdIndex,holdvalues /] )
		end do
		printVarSummary(finalCluster)
		

	     ; Add metadata
		finalCluster!0 = "time"
		finalCluster&time = time
		finalCluster&time@units="days since 1900-01-01 00:00:00"
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

