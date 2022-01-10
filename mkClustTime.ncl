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

	     ; Format data
		clust!0="time"
		clust&time=time
		clust&time@units="days since 1900-01-01 00:00:00"
		printVarSummary(clust)

	     ; Create output file 
		filo=cfile
		filo=str_sub_str(filo, ".asc", ".nc")
		print(filo)
		diro = "./"                     ; Output director
		system("/bin/rm -f " + diro + filo)    ; remove if exists
		fout  = addfile (diro + filo, "c")  ; open output file
		fout->clust=clust
		fout->time=time
	end do

end

exit
