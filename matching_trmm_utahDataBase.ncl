;this matches cluster dates with erai and radar days
;awap date is shifted one day backward as it is accumulation of previouse day


load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"


begin 

do nclust=5,5
	print("Cluster no.  "+tostring(nclust)+" started")

     ; Read in the input file(s)
	PATH1 = "./"
	FILE1 = "cluster_0"+tostring(nclust)+".nc"
	infileCluster = addfile(PATH1+FILE1, "r")

	PATH2 = "/home/mjmurphy/Documents/work/ncls/utahTRMM/level2/processedData/"
	FILE2 = "trmm-utahDataBase_level2_rpf_subsetWetTropics_1998-2012.nc"
	FILE2 = "trmm-utahDataBase_level2_rppf_subsetWetTropics_1998-2011.nc"
	;FILE2 = "trmm-utahDataBase_level2_rtpf_subsetWetTropics_1998-2012.nc"
	infileTRMM = addfile(PATH2+FILE2,"r")


     ; Gather the data we need from the input file(s)
	rawCluster = infileCluster->clust
	timeTRMM   = infileTRMM->time
	rawMAXNSZ  = infileTRMM->MAXNSZ
	rawMAXHT   = infileTRMM->MAXHT
	rawMAXDBZ  = infileTRMM->MAXDBZ
	rawN20DBZ  = infileTRMM->N20DBZ

	rawMAXHT30 = infileTRMM->MAXHT30
	rawMAXHT20 = infileTRMM->MAXHT20
	rawFLASHCOUNT = infileTRMM->FLASHCOUNT
	rawMAXNSRAIN  = infileTRMM->MAXNSRAIN
	rawNPIXELS_PR = infileTRMM->NPIXELS_PR
	rawNCH4LT273  = infileTRMM->NCH4LT273
	rawELEV  = infileTRMM->ELEV
	rawLANDOCEAN  = infileTRMM->LANDOCEAN
	rawHour  = infileTRMM->HOUR
	;raw  = infileTRMM->


     ; Manipulation of the data

      ; Clean up messy variables
	rawMAXDBZ@_FillValue = toshort(-8888)
	theMAXDBZ = rawMAXDBZ * 0.01
	copy_VarMeta(rawMAXDBZ,theMAXDBZ)
	nlevels = dimsizes(theMAXDBZ(0,:))
	do ilevel=0,nlevels-1
		print(ilevel+"")
		if ( any( theMAXDBZ(:,ilevel) .lt. 0 ) ) then
			theMAXDBZ( ind(theMAXDBZ(:,ilevel) .lt. 0), ilevel ) = theMAXDBZ@_FillValue
		end if
	end do
	printVarSummary(theMAXDBZ)

      ; Time Manipulation
	nclust = nclust +1 ; KLUDGE to accomadate the zero cluster
	startYear = 1998 ; TRMM start year
	endYear   = 2010 ; AWAP end year
	startDate = cd_inv_calendar(startYear,1,1,0,0,0,rawCluster&time@units, 0)
	endDate   = cd_inv_calendar(endYear,12,31,0,0,0,rawCluster&time@units, 0)

        ;######change awap date to previous day
	newTime = rawCluster&time - 1
	copy_VarMeta(rawCluster&time,newTime)
	rawCluster&time = newTime
	printVarSummary(rawCluster)
	theCluster = rawCluster({startDate:})
	printVarSummary(theCluster)
	;print(theCluster)
	;############################
	printVarSummary(timeTRMM)

	timeTRMM_epochAWAP = toint(cd_convert(timeTRMM, theCluster&time@units)) ; change to integer because only interested in day
	timeTRMM_epochAWAP!0 = "time"
	timeTRMM_epochAWAP&time = timeTRMM_epochAWAP
	;print(timeTRMM_epochAWAP)
printVarSummary(timeTRMM_epochAWAP)
printVarSummary(rawCluster&time)

	
	ntimesTRMM = dimsizes(timeTRMM)
	ntimesAWAP = dimsizes(theCluster)
	trmmClustMemb = new(ntimesTRMM,integer)
	do itime=0,ntimesTRMM-1
		if (timeTRMM_epochAWAP(itime) .lt. endDate ) then
			;print(timeTRMM_epochAWAP(itime)+"")
			trmmClustMemb(itime) = theCluster({timeTRMM_epochAWAP(itime)}) 
		else
			;print(timeTRMM_epochAWAP(itime) + "  SKIPPED!!")
		end if
	end do

print( num(rawELEV .eq. 0) +" / "+ ntimesTRMM)
print( num(rawELEV .gt. 0) +" / "+ ntimesTRMM)
print( num(rawELEV .gt. 100) +" / "+ ntimesTRMM)
print( num(rawELEV .gt. 500) +" / "+ ntimesTRMM)
print( num(rawELEV .gt. 900) +" / "+ ntimesTRMM)
print( max(rawELEV))

	;index = get1Dindex_Collapse(theCluster&time,timeTRMM_epochAWAP)
	;print( num(theCluster&time(index)) )
	;print( num(theCluster&time) )
;;;;;;;;;;;;;;;;;;;
	;count = 0
	;do itime=0,ntimesAWAP-1
	;	if ( .not.ismissing( ind(timeTRMM_epochAWAP({theCluster&time(itime)}) ) ) ) then
	;		count = count +1
	;	end if
	;end do
	;print(count+" / "+ ntimesAWAP)
;exit


	;do iclust=0,5
		
	;end do
	index_trmm_c0 = ind(trmmClustMemb .eq. 0)
	index_trmm_c1 = ind(trmmClustMemb .eq. 1)
	index_trmm_c2 = ind(trmmClustMemb .eq. 2)
	index_trmm_c3 = ind(trmmClustMemb .eq. 3)
	index_trmm_c4 = ind(trmmClustMemb .eq. 4)
	index_trmm_c5 = ind(trmmClustMemb .eq. 5)

	ntimes_trmm_c0 = dimsizes(index_trmm_c0)
	ntimes_trmm_c1 = dimsizes(index_trmm_c1)
	ntimes_trmm_c2 = dimsizes(index_trmm_c2)
	ntimes_trmm_c3 = dimsizes(index_trmm_c3)
	ntimes_trmm_c4 = dimsizes(index_trmm_c4)
	ntimes_trmm_c5 = dimsizes(index_trmm_c5)
	
	index_awap_c0 = ind(theCluster .eq. 0)
	index_awap_c1 = ind(theCluster .eq. 1)
	index_awap_c2 = ind(theCluster .eq. 2)
	index_awap_c3 = ind(theCluster .eq. 3)
	index_awap_c4 = ind(theCluster .eq. 4)
	index_awap_c5 = ind(theCluster .eq. 5)
	
	ntimes_awap_c0 = dimsizes(index_awap_c0)
	ntimes_awap_c1 = dimsizes(index_awap_c1)
	ntimes_awap_c2 = dimsizes(index_awap_c2)
	ntimes_awap_c3 = dimsizes(index_awap_c3)
	ntimes_awap_c4 = dimsizes(index_awap_c4)
	ntimes_awap_c5 = dimsizes(index_awap_c5)

	index_trmm_days_c0 = get1Dindex_Collapse(theCluster&time(index_awap_c0),timeTRMM_epochAWAP(index_trmm_c0))
	index_trmm_days_c1 = get1Dindex_Collapse(theCluster&time(index_awap_c1),timeTRMM_epochAWAP(index_trmm_c1))
	index_trmm_days_c2 = get1Dindex_Collapse(theCluster&time(index_awap_c2),timeTRMM_epochAWAP(index_trmm_c2))
	index_trmm_days_c3 = get1Dindex_Collapse(theCluster&time(index_awap_c3),timeTRMM_epochAWAP(index_trmm_c3))
	index_trmm_days_c4 = get1Dindex_Collapse(theCluster&time(index_awap_c4),timeTRMM_epochAWAP(index_trmm_c4))
	index_trmm_days_c5 = get1Dindex_Collapse(theCluster&time(index_awap_c5),timeTRMM_epochAWAP(index_trmm_c5))

	ndays_pfDetected_c0 = num(theCluster&time(index_trmm_days_c0))
	ndays_pfDetected_c1 = num(theCluster&time(index_trmm_days_c1))
	ndays_pfDetected_c2 = num(theCluster&time(index_trmm_days_c2))
	ndays_pfDetected_c3 = num(theCluster&time(index_trmm_days_c3))
	ndays_pfDetected_c4 = num(theCluster&time(index_trmm_days_c4))
	ndays_pfDetected_c5 = num(theCluster&time(index_trmm_days_c5))
	;print( num(theCluster&time(index_trmm_days_c5)) +" / "+ num(theCluster&time(index_awap_c5)) )


	freqPF_trmm_c0 = (tofloat(ndays_pfDetected_c0) / tofloat(ntimes_awap_c0) ) * 100
	freqPF_trmm_c1 = (tofloat(ndays_pfDetected_c1) / tofloat(ntimes_awap_c1) ) * 100
	freqPF_trmm_c2 = (tofloat(ndays_pfDetected_c2) / tofloat(ntimes_awap_c2) ) * 100
	freqPF_trmm_c3 = (tofloat(ndays_pfDetected_c3) / tofloat(ntimes_awap_c3) ) * 100
	freqPF_trmm_c4 = (tofloat(ndays_pfDetected_c4) / tofloat(ntimes_awap_c4) ) * 100
	freqPF_trmm_c5 = (tofloat(ndays_pfDetected_c5) / tofloat(ntimes_awap_c5) ) * 100


	print("")
	print("  Days with PF detected")
	print("------------------------")
	print("    PFdays/days ---> Freq")
	print("c0  "+ndays_pfDetected_c0+" / "+ntimes_awap_c0+ " ---> " +freqPF_trmm_c0+ " %")
	print("c1  "+ndays_pfDetected_c1+" / "+ntimes_awap_c1+ " ---> " +freqPF_trmm_c1+ " %")
	print("c2  "+ndays_pfDetected_c2+" / "+ntimes_awap_c2+ " ---> " +freqPF_trmm_c2+ " %")
	print("c3  "+ndays_pfDetected_c3+" / "+ntimes_awap_c3+ " ---> " +freqPF_trmm_c3+ " %")
	print("c4  "+ndays_pfDetected_c4+" / "+ntimes_awap_c4+ " ---> " +freqPF_trmm_c4+ " %")
	print("c5  "+ndays_pfDetected_c5+" / "+ntimes_awap_c5+ " ---> " +freqPF_trmm_c5+ " %")
	print("------------------------")
	print("")


	pfPerPFday_trmm_c0 = (tofloat(ntimes_trmm_c0) / tofloat(ndays_pfDetected_c0) )
	pfPerPFday_trmm_c1 = (tofloat(ntimes_trmm_c1) / tofloat(ndays_pfDetected_c1) )
	pfPerPFday_trmm_c2 = (tofloat(ntimes_trmm_c2) / tofloat(ndays_pfDetected_c2) )
	pfPerPFday_trmm_c3 = (tofloat(ntimes_trmm_c3) / tofloat(ndays_pfDetected_c3) )
	pfPerPFday_trmm_c4 = (tofloat(ntimes_trmm_c4) / tofloat(ndays_pfDetected_c4) )
	pfPerPFday_trmm_c5 = (tofloat(ntimes_trmm_c5) / tofloat(ndays_pfDetected_c5) )

	print("")
	print("      PFs per PF day")
	print("------------------------")
	print("    #PFs /PFdays ---> #/PFday")
	print("c0  "+ntimes_trmm_c0+" / "+ndays_pfDetected_c0+ " ---> " +pfPerPFday_trmm_c0)
	print("c1  "+ntimes_trmm_c1+" / "+ndays_pfDetected_c1+ " ---> " +pfPerPFday_trmm_c1)
	print("c2  "+ntimes_trmm_c2+" / "+ndays_pfDetected_c2+ " ---> " +pfPerPFday_trmm_c2)
	print("c3  "+ntimes_trmm_c3+" / "+ndays_pfDetected_c3+ " ---> " +pfPerPFday_trmm_c3)
	print("c4  "+ntimes_trmm_c4+" / "+ndays_pfDetected_c4+ " ---> " +pfPerPFday_trmm_c4)
	print("c5  "+ntimes_trmm_c5+" / "+ndays_pfDetected_c5+ " ---> " +pfPerPFday_trmm_c5)
	print("------------------------")
	print("")


	pfPerDay_trmm_c0 = (tofloat(ntimes_trmm_c0) / tofloat(ntimes_awap_c0) )
	pfPerDay_trmm_c1 = (tofloat(ntimes_trmm_c1) / tofloat(ntimes_awap_c1) )
	pfPerDay_trmm_c2 = (tofloat(ntimes_trmm_c2) / tofloat(ntimes_awap_c2) )
	pfPerDay_trmm_c3 = (tofloat(ntimes_trmm_c3) / tofloat(ntimes_awap_c3) )
	pfPerDay_trmm_c4 = (tofloat(ntimes_trmm_c4) / tofloat(ntimes_awap_c4) )
	pfPerDay_trmm_c5 = (tofloat(ntimes_trmm_c5) / tofloat(ntimes_awap_c5) )

	print("")
	print("      PFs per day")
	print("------------------------")
	print("    # PFs / days ---> #/day")
	print("c0  "+ntimes_trmm_c0+" / "+ntimes_awap_c0+ " ---> " +pfPerDay_trmm_c0)
	print("c1  "+ntimes_trmm_c1+" / "+ntimes_awap_c1+ " ---> " +pfPerDay_trmm_c1)
	print("c2  "+ntimes_trmm_c2+" / "+ntimes_awap_c2+ " ---> " +pfPerDay_trmm_c2)
	print("c3  "+ntimes_trmm_c3+" / "+ntimes_awap_c3+ " ---> " +pfPerDay_trmm_c3)
	print("c4  "+ntimes_trmm_c4+" / "+ntimes_awap_c4+ " ---> " +pfPerDay_trmm_c4)
	print("c5  "+ntimes_trmm_c5+" / "+ntimes_awap_c5+ " ---> " +pfPerDay_trmm_c5)
	print("------------------------")
	print("")


	print("")
	print("      Diurnal")
	offsetUTC = 10
	theHour_c0 = toint(rawHour(index_trmm_c0)+offsetUTC)
	theHour_c1 = toint(rawHour(index_trmm_c1)+offsetUTC)
	theHour_c2 = toint(rawHour(index_trmm_c2)+offsetUTC)
	theHour_c3 = toint(rawHour(index_trmm_c3)+offsetUTC)
	theHour_c4 = toint(rawHour(index_trmm_c4)+offsetUTC)
	theHour_c5 = toint(rawHour(index_trmm_c5)+offsetUTC)

	occPF_diurnal_c0 = new((/8/),integer)
	occPF_diurnal_c0(0) = num( theHour_c0 .eq. 23) + num( theHour_c0 .eq. 0) + num( theHour_c0 .eq. 1)
	occPF_diurnal_c0(1) = num( theHour_c0 .eq. 2)  + num( theHour_c0 .eq. 3) + num( theHour_c0 .eq. 4)
	occPF_diurnal_c0(2) = num( theHour_c0 .eq. 5)  + num( theHour_c0 .eq. 6) + num( theHour_c0 .eq. 7)
	occPF_diurnal_c0(3) = num( theHour_c0 .eq. 8)  + num( theHour_c0 .eq. 9) + num( theHour_c0 .eq. 10)
	occPF_diurnal_c0(4) = num( theHour_c0 .eq. 11) + num( theHour_c0 .eq. 12) + num( theHour_c0 .eq. 13)
	occPF_diurnal_c0(5) = num( theHour_c0 .eq. 14) + num( theHour_c0 .eq. 15) + num( theHour_c0 .eq. 16)
	occPF_diurnal_c0(6) = num( theHour_c0 .eq. 17) + num( theHour_c0 .eq. 18) + num( theHour_c0 .eq. 19)
	occPF_diurnal_c0(7) = num( theHour_c0 .eq. 20) + num( theHour_c0 .eq. 21) + num( theHour_c0 .eq. 22)
	occPF_total_c0 = sum(occPF_diurnal_c0)
	freqPF_diurnal_c0 = new((/8/),float)
	do idiurnal=0,7
		freqPF_diurnal_c0(idiurnal) = ( tofloat(occPF_diurnal_c0(idiurnal)) / tofloat(occPF_total_c0) ) *100
	end do

	occPF_diurnal_c1 = new((/8/),integer)
	occPF_diurnal_c1(0) = num( theHour_c1 .eq. 23) + num( theHour_c1 .eq. 0) + num( theHour_c1 .eq. 1)
	occPF_diurnal_c1(1) = num( theHour_c1 .eq. 2)  + num( theHour_c1 .eq. 3) + num( theHour_c1 .eq. 4)
	occPF_diurnal_c1(2) = num( theHour_c1 .eq. 5)  + num( theHour_c1 .eq. 6) + num( theHour_c1 .eq. 7)
	occPF_diurnal_c1(3) = num( theHour_c1 .eq. 8)  + num( theHour_c1 .eq. 9) + num( theHour_c1 .eq. 10)
	occPF_diurnal_c1(4) = num( theHour_c1 .eq. 11) + num( theHour_c1 .eq. 12) + num( theHour_c1 .eq. 13)
	occPF_diurnal_c1(5) = num( theHour_c1 .eq. 14) + num( theHour_c1 .eq. 15) + num( theHour_c1 .eq. 16)
	occPF_diurnal_c1(6) = num( theHour_c1 .eq. 17) + num( theHour_c1 .eq. 18) + num( theHour_c1 .eq. 19)
	occPF_diurnal_c1(7) = num( theHour_c1 .eq. 20) + num( theHour_c1 .eq. 21) + num( theHour_c1 .eq. 22)
	occPF_total_c1 = sum(occPF_diurnal_c1)
	freqPF_diurnal_c1 = new((/8/),float)
	do idiurnal=0,7
		freqPF_diurnal_c1(idiurnal) = ( tofloat(occPF_diurnal_c1(idiurnal)) / tofloat(occPF_total_c1) ) *100
	end do

	occPF_diurnal_c2 = new((/8/),integer)
	occPF_diurnal_c2(0) = num( theHour_c2 .eq. 23) + num( theHour_c2 .eq. 0) + num( theHour_c2 .eq. 1)
	occPF_diurnal_c2(1) = num( theHour_c2 .eq. 2)  + num( theHour_c2 .eq. 3) + num( theHour_c2 .eq. 4)
	occPF_diurnal_c2(2) = num( theHour_c2 .eq. 5)  + num( theHour_c2 .eq. 6) + num( theHour_c2 .eq. 7)
	occPF_diurnal_c2(3) = num( theHour_c2 .eq. 8)  + num( theHour_c2 .eq. 9) + num( theHour_c2 .eq. 10)
	occPF_diurnal_c2(4) = num( theHour_c2 .eq. 11) + num( theHour_c2 .eq. 12) + num( theHour_c2 .eq. 13)
	occPF_diurnal_c2(5) = num( theHour_c2 .eq. 14) + num( theHour_c2 .eq. 15) + num( theHour_c2 .eq. 16)
	occPF_diurnal_c2(6) = num( theHour_c2 .eq. 17) + num( theHour_c2 .eq. 18) + num( theHour_c2 .eq. 19)
	occPF_diurnal_c2(7) = num( theHour_c2 .eq. 20) + num( theHour_c2 .eq. 21) + num( theHour_c2 .eq. 22)
	occPF_total_c2 = sum(occPF_diurnal_c2)
	freqPF_diurnal_c2 = new((/8/),float)
	do idiurnal=0,7
		freqPF_diurnal_c2(idiurnal) = ( tofloat(occPF_diurnal_c2(idiurnal)) / tofloat(occPF_total_c2) ) *100
	end do

	occPF_diurnal_c3 = new((/8/),integer)
	occPF_diurnal_c3(0) = num( theHour_c3 .eq. 23) + num( theHour_c3 .eq. 0) + num( theHour_c3 .eq. 1)
	occPF_diurnal_c3(1) = num( theHour_c3 .eq. 2)  + num( theHour_c3 .eq. 3) + num( theHour_c3 .eq. 4)
	occPF_diurnal_c3(2) = num( theHour_c3 .eq. 5)  + num( theHour_c3 .eq. 6) + num( theHour_c3 .eq. 7)
	occPF_diurnal_c3(3) = num( theHour_c3 .eq. 8)  + num( theHour_c3 .eq. 9) + num( theHour_c3 .eq. 10)
	occPF_diurnal_c3(4) = num( theHour_c3 .eq. 11) + num( theHour_c3 .eq. 12) + num( theHour_c3 .eq. 13)
	occPF_diurnal_c3(5) = num( theHour_c3 .eq. 14) + num( theHour_c3 .eq. 15) + num( theHour_c3 .eq. 16)
	occPF_diurnal_c3(6) = num( theHour_c3 .eq. 17) + num( theHour_c3 .eq. 18) + num( theHour_c3 .eq. 19)
	occPF_diurnal_c3(7) = num( theHour_c3 .eq. 20) + num( theHour_c3 .eq. 21) + num( theHour_c3 .eq. 22)
	occPF_total_c3 = sum(occPF_diurnal_c3)
	freqPF_diurnal_c3 = new((/8/),float)
	do idiurnal=0,7
		freqPF_diurnal_c3(idiurnal) = ( tofloat(occPF_diurnal_c3(idiurnal)) / tofloat(occPF_total_c3) ) *100
	end do

	occPF_diurnal_c4 = new((/8/),integer)
	occPF_diurnal_c4(0) = num( theHour_c4 .eq. 23) + num( theHour_c4 .eq. 0) + num( theHour_c4 .eq. 1)
	occPF_diurnal_c4(1) = num( theHour_c4 .eq. 2)  + num( theHour_c4 .eq. 3) + num( theHour_c4 .eq. 4)
	occPF_diurnal_c4(2) = num( theHour_c4 .eq. 5)  + num( theHour_c4 .eq. 6) + num( theHour_c4 .eq. 7)
	occPF_diurnal_c4(3) = num( theHour_c4 .eq. 8)  + num( theHour_c4 .eq. 9) + num( theHour_c4 .eq. 10)
	occPF_diurnal_c4(4) = num( theHour_c4 .eq. 11) + num( theHour_c4 .eq. 12) + num( theHour_c4 .eq. 13)
	occPF_diurnal_c4(5) = num( theHour_c4 .eq. 14) + num( theHour_c4 .eq. 15) + num( theHour_c4 .eq. 16)
	occPF_diurnal_c4(6) = num( theHour_c4 .eq. 17) + num( theHour_c4 .eq. 18) + num( theHour_c4 .eq. 19)
	occPF_diurnal_c4(7) = num( theHour_c4 .eq. 20) + num( theHour_c4 .eq. 21) + num( theHour_c4 .eq. 22)
	occPF_total_c4 = sum(occPF_diurnal_c4)
	freqPF_diurnal_c4 = new((/8/),float)
	do idiurnal=0,7
		freqPF_diurnal_c4(idiurnal) = ( tofloat(occPF_diurnal_c4(idiurnal)) / tofloat(occPF_total_c4) ) *100
	end do

	occPF_diurnal_c5 = new((/8/),integer)
	occPF_diurnal_c5(0) = num( theHour_c5 .eq. 23) + num( theHour_c5 .eq. 0) + num( theHour_c5 .eq. 1)
	occPF_diurnal_c5(1) = num( theHour_c5 .eq. 2)  + num( theHour_c5 .eq. 3) + num( theHour_c5 .eq. 4)
	occPF_diurnal_c5(2) = num( theHour_c5 .eq. 5)  + num( theHour_c5 .eq. 6) + num( theHour_c5 .eq. 7)
	occPF_diurnal_c5(3) = num( theHour_c5 .eq. 8)  + num( theHour_c5 .eq. 9) + num( theHour_c5 .eq. 10)
	occPF_diurnal_c5(4) = num( theHour_c5 .eq. 11) + num( theHour_c5 .eq. 12) + num( theHour_c5 .eq. 13)
	occPF_diurnal_c5(5) = num( theHour_c5 .eq. 14) + num( theHour_c5 .eq. 15) + num( theHour_c5 .eq. 16)
	occPF_diurnal_c5(6) = num( theHour_c5 .eq. 17) + num( theHour_c5 .eq. 18) + num( theHour_c5 .eq. 19)
	occPF_diurnal_c5(7) = num( theHour_c5 .eq. 20) + num( theHour_c5 .eq. 21) + num( theHour_c5 .eq. 22)
	occPF_total_c5 = sum(occPF_diurnal_c5)
	freqPF_diurnal_c5 = new((/8/),float)
	do idiurnal=0,7
		freqPF_diurnal_c5(idiurnal) = ( tofloat(occPF_diurnal_c5(idiurnal)) / tofloat(occPF_total_c5) ) *100
	end do

	print("-----------------------------------------------------")
	print("    00     03  06   09     12     15   18   21")
	print("c0  "+decimalPlaces(freqPF_diurnal_c0(0),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c0(1),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c0(2),1,True)+"%  "+ \
		decimalPlaces(freqPF_diurnal_c0(3),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c0(4),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c0(5),1,True)+"%  "+ \
		decimalPlaces(freqPF_diurnal_c0(0),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c0(1),1,True)+"%")
	print("c1  "+decimalPlaces(freqPF_diurnal_c1(0),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c1(1),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c1(2),1,True)+"%  "+ \
		decimalPlaces(freqPF_diurnal_c1(3),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c1(4),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c1(5),1,True)+"%  "+ \
		decimalPlaces(freqPF_diurnal_c0(6),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c0(7),1,True)+"%")
	print("c2  "+decimalPlaces(freqPF_diurnal_c2(0),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c2(1),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c2(2),1,True)+"%  "+ \
		decimalPlaces(freqPF_diurnal_c2(3),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c2(4),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c2(5),1,True)+"%  "+ \
		decimalPlaces(freqPF_diurnal_c0(0),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c0(1),1,True)+"%")
	print("c3  "+decimalPlaces(freqPF_diurnal_c3(0),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c3(1),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c3(2),1,True)+"%  "+ \
		decimalPlaces(freqPF_diurnal_c3(3),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c3(4),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c3(5),1,True)+"%  "+ \
		decimalPlaces(freqPF_diurnal_c0(0),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c0(1),1,True)+"%")
	print("c4  "+decimalPlaces(freqPF_diurnal_c4(0),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c4(1),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c4(2),1,True)+"%  "+ \
		decimalPlaces(freqPF_diurnal_c4(3),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c4(4),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c4(5),1,True)+"%  "+ \
		decimalPlaces(freqPF_diurnal_c0(0),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c0(1),1,True)+"%")
	print("c5  "+decimalPlaces(freqPF_diurnal_c5(0),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c5(1),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c5(2),1,True)+"%  "+ \
		decimalPlaces(freqPF_diurnal_c5(3),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c5(4),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c5(5),1,True)+"%  "+ \
		decimalPlaces(freqPF_diurnal_c0(0),1,True)+"%  "+decimalPlaces(freqPF_diurnal_c0(1),1,True)+"%")
	print("-----------------------------------------------------")
	print("")


	print("")
	print("      ELEV")
	print("------------------------")
	statsELEV_c0 = stat_dispersion(rawELEV(index_trmm_c0),0)
	statsELEV_c1 = stat_dispersion(rawELEV(index_trmm_c1),0)
	statsELEV_c2 = stat_dispersion(rawELEV(index_trmm_c2),0)
	statsELEV_c3 = stat_dispersion(rawELEV(index_trmm_c3),0)
	statsELEV_c4 = stat_dispersion(rawELEV(index_trmm_c4),0)
	statsELEV_c5 = stat_dispersion(rawELEV(index_trmm_c5),0)
	print("    LowQ -- Median -- UpQ")
	print("c0  "+statsELEV_c0(6)+" -- "+decimalPlaces(statsELEV_c0(8),2,True)+" -- "+statsELEV_c0(10))
	print("c1  "+statsELEV_c1(6)+" -- "+decimalPlaces(statsELEV_c1(8),2,True)+" -- "+statsELEV_c1(10))
	print("c2  "+statsELEV_c2(6)+" -- "+decimalPlaces(statsELEV_c2(8),2,True)+" -- "+statsELEV_c2(10))
	print("c3  "+statsELEV_c3(6)+" -- "+decimalPlaces(statsELEV_c3(8),2,True)+" -- "+statsELEV_c3(10))
	print("c4  "+statsELEV_c4(6)+" -- "+decimalPlaces(statsELEV_c4(8),2,True)+" -- "+statsELEV_c4(10))
	print("c5  "+statsELEV_c5(6)+" -- "+decimalPlaces(statsELEV_c5(8),2,True)+" -- "+statsELEV_c5(10))
	print("------------------------")
	print("")


	print("")
	print("      LANDOCEAN")
	print("------------------------")
	statsLANDOCEAN_c0 = stat_dispersion(rawLANDOCEAN(index_trmm_c0),0)
	statsLANDOCEAN_c1 = stat_dispersion(rawLANDOCEAN(index_trmm_c1),0)
	statsLANDOCEAN_c2 = stat_dispersion(rawLANDOCEAN(index_trmm_c2),0)
	statsLANDOCEAN_c3 = stat_dispersion(rawLANDOCEAN(index_trmm_c3),0)
	statsLANDOCEAN_c4 = stat_dispersion(rawLANDOCEAN(index_trmm_c4),0)
	statsLANDOCEAN_c5 = stat_dispersion(rawLANDOCEAN(index_trmm_c5),0)
	print("     Average -- Sigma")
	print("c0  "+statsLANDOCEAN_c0(0)+" -- "+statsLANDOCEAN_c0(1))
	print("c1  "+statsLANDOCEAN_c1(0)+" -- "+statsLANDOCEAN_c1(1))
	print("c2  "+statsLANDOCEAN_c2(0)+" -- "+statsLANDOCEAN_c2(1))
	print("c3  "+statsLANDOCEAN_c3(0)+" -- "+statsLANDOCEAN_c3(1))
	print("c4  "+statsLANDOCEAN_c4(0)+" -- "+statsLANDOCEAN_c4(1))
	print("c5  "+statsLANDOCEAN_c5(0)+" -- "+statsLANDOCEAN_c5(1))
	print("------------------------")
	print("")


	print("")
	print("      MAXNSZ")
	print("------------------------")
	statsMAXNSZ_c0 = stat_dispersion(rawMAXNSZ(index_trmm_c0),0)
	statsMAXNSZ_c1 = stat_dispersion(rawMAXNSZ(index_trmm_c1),0)
	statsMAXNSZ_c2 = stat_dispersion(rawMAXNSZ(index_trmm_c2),0)
	statsMAXNSZ_c3 = stat_dispersion(rawMAXNSZ(index_trmm_c3),0)
	statsMAXNSZ_c4 = stat_dispersion(rawMAXNSZ(index_trmm_c4),0)
	statsMAXNSZ_c5 = stat_dispersion(rawMAXNSZ(index_trmm_c5),0)
	print("    LowQ -- Median -- UpQ")
	print("c0  "+statsMAXNSZ_c0(6)+" -- "+decimalPlaces(statsMAXNSZ_c0(8),2,True)+" -- "+statsMAXNSZ_c0(10))
	print("c1  "+statsMAXNSZ_c1(6)+" -- "+decimalPlaces(statsMAXNSZ_c1(8),2,True)+" -- "+statsMAXNSZ_c1(10))
	print("c2  "+statsMAXNSZ_c2(6)+" -- "+decimalPlaces(statsMAXNSZ_c2(8),2,True)+" -- "+statsMAXNSZ_c2(10))
	print("c3  "+statsMAXNSZ_c3(6)+" -- "+decimalPlaces(statsMAXNSZ_c3(8),2,True)+" -- "+statsMAXNSZ_c3(10))
	print("c4  "+statsMAXNSZ_c4(6)+" -- "+decimalPlaces(statsMAXNSZ_c4(8),2,True)+" -- "+statsMAXNSZ_c4(10))
	print("c5  "+statsMAXNSZ_c5(6)+" -- "+decimalPlaces(statsMAXNSZ_c5(8),2,True)+" -- "+statsMAXNSZ_c5(10))
	print("------------------------")
	print("")


	print("")
	print("        MAXNSRAIN")
	print("------------------------")
	statsMAXNSRAIN_c0 = stat_dispersion(rawMAXNSRAIN(index_trmm_c0),0)
	statsMAXNSRAIN_c1 = stat_dispersion(rawMAXNSRAIN(index_trmm_c1),0)
	statsMAXNSRAIN_c2 = stat_dispersion(rawMAXNSRAIN(index_trmm_c2),0)
	statsMAXNSRAIN_c3 = stat_dispersion(rawMAXNSRAIN(index_trmm_c3),0)
	statsMAXNSRAIN_c4 = stat_dispersion(rawMAXNSRAIN(index_trmm_c4),0)
	statsMAXNSRAIN_c5 = stat_dispersion(rawMAXNSRAIN(index_trmm_c5),0)
	print("    LowQ -- Median -- UpQ")
	print("c0  "+statsMAXNSRAIN_c0(6)+" -- "+decimalPlaces(statsMAXNSRAIN_c0(8),2,True)+" -- "+statsMAXNSRAIN_c0(10))
	print("c1  "+statsMAXNSRAIN_c1(6)+" -- "+decimalPlaces(statsMAXNSRAIN_c1(8),2,True)+" -- "+statsMAXNSRAIN_c1(10))
	print("c2  "+statsMAXNSRAIN_c2(6)+" -- "+decimalPlaces(statsMAXNSRAIN_c2(8),2,True)+" -- "+statsMAXNSRAIN_c2(10))
	print("c3  "+statsMAXNSRAIN_c3(6)+" -- "+decimalPlaces(statsMAXNSRAIN_c3(8),2,True)+" -- "+statsMAXNSRAIN_c3(10))
	print("c4  "+statsMAXNSRAIN_c4(6)+" -- "+decimalPlaces(statsMAXNSRAIN_c4(8),2,True)+" -- "+statsMAXNSRAIN_c4(10))
	print("c5  "+statsMAXNSRAIN_c5(6)+" -- "+decimalPlaces(statsMAXNSRAIN_c5(8),2,True)+" -- "+statsMAXNSRAIN_c5(10))
	print("------------------------")
	print("")


	print("")
	print("        MAXHT")
	print("------------------------")
	statsMAXHT_c0 = stat_dispersion(rawMAXHT(index_trmm_c0),0)
	statsMAXHT_c1 = stat_dispersion(rawMAXHT(index_trmm_c1),0)
	statsMAXHT_c2 = stat_dispersion(rawMAXHT(index_trmm_c2),0)
	statsMAXHT_c3 = stat_dispersion(rawMAXHT(index_trmm_c3),0)
	statsMAXHT_c4 = stat_dispersion(rawMAXHT(index_trmm_c4),0)
	statsMAXHT_c5 = stat_dispersion(rawMAXHT(index_trmm_c5),0)
	print("    LowQ -- Median -- UpQ")
	print("c0  "+statsMAXHT_c0(6)+" -- "+decimalPlaces(statsMAXHT_c0(8),2,True)+" -- "+statsMAXHT_c0(10))
	print("c1  "+statsMAXHT_c1(6)+" -- "+decimalPlaces(statsMAXHT_c1(8),2,True)+" -- "+statsMAXHT_c1(10))
	print("c2  "+statsMAXHT_c2(6)+" -- "+decimalPlaces(statsMAXHT_c2(8),2,True)+" -- "+statsMAXHT_c2(10))
	print("c3  "+statsMAXHT_c3(6)+" -- "+decimalPlaces(statsMAXHT_c3(8),2,True)+" -- "+statsMAXHT_c3(10))
	print("c4  "+statsMAXHT_c4(6)+" -- "+decimalPlaces(statsMAXHT_c4(8),2,True)+" -- "+statsMAXHT_c4(10))
	print("c5  "+statsMAXHT_c5(6)+" -- "+decimalPlaces(statsMAXHT_c5(8),2,True)+" -- "+statsMAXHT_c5(10))
	print("------------------------")
	print("")


	print("")
	print("        MAXHT30")
	print("------------------------")
	statsMAXHT30_c0 = stat_dispersion(rawMAXHT30(index_trmm_c0),0)
	statsMAXHT30_c1 = stat_dispersion(rawMAXHT30(index_trmm_c1),0)
	statsMAXHT30_c2 = stat_dispersion(rawMAXHT30(index_trmm_c2),0)
	statsMAXHT30_c3 = stat_dispersion(rawMAXHT30(index_trmm_c3),0)
	statsMAXHT30_c4 = stat_dispersion(rawMAXHT30(index_trmm_c4),0)
	statsMAXHT30_c5 = stat_dispersion(rawMAXHT30(index_trmm_c5),0)
	print("    LowQ -- Median -- UpQ")
	print("c0  "+statsMAXHT30_c0(6)+" -- "+decimalPlaces(statsMAXHT30_c0(8),2,True)+" -- "+statsMAXHT30_c0(10))
	print("c1  "+statsMAXHT30_c1(6)+" -- "+decimalPlaces(statsMAXHT30_c1(8),2,True)+" -- "+statsMAXHT30_c1(10))
	print("c2  "+statsMAXHT30_c2(6)+" -- "+decimalPlaces(statsMAXHT30_c2(8),2,True)+" -- "+statsMAXHT30_c2(10))
	print("c3  "+statsMAXHT30_c3(6)+" -- "+decimalPlaces(statsMAXHT30_c3(8),2,True)+" -- "+statsMAXHT30_c3(10))
	print("c4  "+statsMAXHT30_c4(6)+" -- "+decimalPlaces(statsMAXHT30_c4(8),2,True)+" -- "+statsMAXHT30_c4(10))
	print("c5  "+statsMAXHT30_c5(6)+" -- "+decimalPlaces(statsMAXHT30_c5(8),2,True)+" -- "+statsMAXHT30_c5(10))
	print("------------------------")
	print("")


	print("")
	print("        MAXHT20")
	print("------------------------")
	statsMAXHT20_c0 = stat_dispersion(rawMAXHT20(index_trmm_c0),0)
	statsMAXHT20_c1 = stat_dispersion(rawMAXHT20(index_trmm_c1),0)
	statsMAXHT20_c2 = stat_dispersion(rawMAXHT20(index_trmm_c2),0)
	statsMAXHT20_c3 = stat_dispersion(rawMAXHT20(index_trmm_c3),0)
	statsMAXHT20_c4 = stat_dispersion(rawMAXHT20(index_trmm_c4),0)
	statsMAXHT20_c5 = stat_dispersion(rawMAXHT20(index_trmm_c5),0)
	print("    LowQ -- Median -- UpQ")
	print("c0  "+statsMAXHT20_c0(6)+" -- "+decimalPlaces(statsMAXHT20_c0(8),2,True)+" -- "+statsMAXHT20_c0(10))
	print("c1  "+statsMAXHT20_c1(6)+" -- "+decimalPlaces(statsMAXHT20_c1(8),2,True)+" -- "+statsMAXHT20_c1(10))
	print("c2  "+statsMAXHT20_c2(6)+" -- "+decimalPlaces(statsMAXHT20_c2(8),2,True)+" -- "+statsMAXHT20_c2(10))
	print("c3  "+statsMAXHT20_c3(6)+" -- "+decimalPlaces(statsMAXHT20_c3(8),2,True)+" -- "+statsMAXHT20_c3(10))
	print("c4  "+statsMAXHT20_c4(6)+" -- "+decimalPlaces(statsMAXHT20_c4(8),2,True)+" -- "+statsMAXHT20_c4(10))
	print("c5  "+statsMAXHT20_c5(6)+" -- "+decimalPlaces(statsMAXHT20_c5(8),2,True)+" -- "+statsMAXHT20_c5(10))
	print("------------------------")
	print("")


	print("")
	print("        NPIXELS_PR")
	print("------------------------")
	statsNPIXELS_PR_c0 = stat_dispersion(rawNPIXELS_PR(index_trmm_c0),0)
	statsNPIXELS_PR_c1 = stat_dispersion(rawNPIXELS_PR(index_trmm_c1),0)
	statsNPIXELS_PR_c2 = stat_dispersion(rawNPIXELS_PR(index_trmm_c2),0)
	statsNPIXELS_PR_c3 = stat_dispersion(rawNPIXELS_PR(index_trmm_c3),0)
	statsNPIXELS_PR_c4 = stat_dispersion(rawNPIXELS_PR(index_trmm_c4),0)
	statsNPIXELS_PR_c5 = stat_dispersion(rawNPIXELS_PR(index_trmm_c5),0)
	print("    LowQ -- Median -- UpQ")
	print("c0  "+statsNPIXELS_PR_c0(6)+" -- "+decimalPlaces(statsNPIXELS_PR_c0(8),2,True)+" -- "+statsNPIXELS_PR_c0(10))
	print("c1  "+statsNPIXELS_PR_c1(6)+" -- "+decimalPlaces(statsNPIXELS_PR_c1(8),2,True)+" -- "+statsNPIXELS_PR_c1(10))
	print("c2  "+statsNPIXELS_PR_c2(6)+" -- "+decimalPlaces(statsNPIXELS_PR_c2(8),2,True)+" -- "+statsNPIXELS_PR_c2(10))
	print("c3  "+statsNPIXELS_PR_c3(6)+" -- "+decimalPlaces(statsNPIXELS_PR_c3(8),2,True)+" -- "+statsNPIXELS_PR_c3(10))
	print("c4  "+statsNPIXELS_PR_c4(6)+" -- "+decimalPlaces(statsNPIXELS_PR_c4(8),2,True)+" -- "+statsNPIXELS_PR_c4(10))
	print("c5  "+statsNPIXELS_PR_c5(6)+" -- "+decimalPlaces(statsNPIXELS_PR_c5(8),2,True)+" -- "+statsNPIXELS_PR_c5(10))
	print("------------------------")
	print("")


	print("")
	print("        NCH4LT273")
	print("------------------------")
	statsNCH4LT273_c0 = stat_dispersion(rawNCH4LT273(index_trmm_c0),0)
	statsNCH4LT273_c1 = stat_dispersion(rawNCH4LT273(index_trmm_c1),0)
	statsNCH4LT273_c2 = stat_dispersion(rawNCH4LT273(index_trmm_c2),0)
	statsNCH4LT273_c3 = stat_dispersion(rawNCH4LT273(index_trmm_c3),0)
	statsNCH4LT273_c4 = stat_dispersion(rawNCH4LT273(index_trmm_c4),0)
	statsNCH4LT273_c5 = stat_dispersion(rawNCH4LT273(index_trmm_c5),0)
	print("    LowQ -- Median -- UpQ")
	print("c0  "+statsNCH4LT273_c0(6)+" -- "+decimalPlaces(statsNCH4LT273_c0(8),2,True)+" -- "+statsNCH4LT273_c0(10))
	print("c1  "+statsNCH4LT273_c1(6)+" -- "+decimalPlaces(statsNCH4LT273_c1(8),2,True)+" -- "+statsNCH4LT273_c1(10))
	print("c2  "+statsNCH4LT273_c2(6)+" -- "+decimalPlaces(statsNCH4LT273_c2(8),2,True)+" -- "+statsNCH4LT273_c2(10))
	print("c3  "+statsNCH4LT273_c3(6)+" -- "+decimalPlaces(statsNCH4LT273_c3(8),2,True)+" -- "+statsNCH4LT273_c3(10))
	print("c4  "+statsNCH4LT273_c4(6)+" -- "+decimalPlaces(statsNCH4LT273_c4(8),2,True)+" -- "+statsNCH4LT273_c4(10))
	print("c5  "+statsNCH4LT273_c5(6)+" -- "+decimalPlaces(statsNCH4LT273_c5(8),2,True)+" -- "+statsNCH4LT273_c5(10))
	print("------------------------")
	print("")


	print("")
	print("        RATIOLT273")
	print("------------------------")
	statsRATIOLT273_c0 = stat_dispersion(rawNCH4LT273(index_trmm_c0) / rawNPIXELS_PR(index_trmm_c0),0)
	statsRATIOLT273_c1 = stat_dispersion(rawNCH4LT273(index_trmm_c1) / rawNPIXELS_PR(index_trmm_c1),0)
	statsRATIOLT273_c2 = stat_dispersion(rawNCH4LT273(index_trmm_c2) / rawNPIXELS_PR(index_trmm_c2),0)
	statsRATIOLT273_c3 = stat_dispersion(rawNCH4LT273(index_trmm_c3) / rawNPIXELS_PR(index_trmm_c3),0)
	statsRATIOLT273_c4 = stat_dispersion(rawNCH4LT273(index_trmm_c4) / rawNPIXELS_PR(index_trmm_c4),0)
	statsRATIOLT273_c5 = stat_dispersion(rawNCH4LT273(index_trmm_c5) / rawNPIXELS_PR(index_trmm_c5),0)
	print("    LowQ -- Median -- UpQ")
	print("c0  "+statsRATIOLT273_c0(6)+" -- "+decimalPlaces(statsRATIOLT273_c0(8),2,True)+" -- "+statsRATIOLT273_c0(10))
	print("c1  "+statsRATIOLT273_c1(6)+" -- "+decimalPlaces(statsRATIOLT273_c1(8),2,True)+" -- "+statsRATIOLT273_c1(10))
	print("c2  "+statsRATIOLT273_c2(6)+" -- "+decimalPlaces(statsRATIOLT273_c2(8),2,True)+" -- "+statsRATIOLT273_c2(10))
	print("c3  "+statsRATIOLT273_c3(6)+" -- "+decimalPlaces(statsRATIOLT273_c3(8),2,True)+" -- "+statsRATIOLT273_c3(10))
	print("c4  "+statsRATIOLT273_c4(6)+" -- "+decimalPlaces(statsRATIOLT273_c4(8),2,True)+" -- "+statsRATIOLT273_c4(10))
	print("c5  "+statsRATIOLT273_c5(6)+" -- "+decimalPlaces(statsRATIOLT273_c5(8),2,True)+" -- "+statsRATIOLT273_c5(10))
	print("------------------------")
	print("")
exit


	print("")
	print("      FLASHCOUNT")
	print("------------------------")
	statsFLASHCOUNT_c0 = stat_dispersion(rawFLASHCOUNT(index_trmm_c0),0)
	statsFLASHCOUNT_c1 = stat_dispersion(rawFLASHCOUNT(index_trmm_c1),0)
	statsFLASHCOUNT_c2 = stat_dispersion(rawFLASHCOUNT(index_trmm_c2),0)
	statsFLASHCOUNT_c3 = stat_dispersion(rawFLASHCOUNT(index_trmm_c3),0)
	statsFLASHCOUNT_c4 = stat_dispersion(rawFLASHCOUNT(index_trmm_c4),0)
	statsFLASHCOUNT_c5 = stat_dispersion(rawFLASHCOUNT(index_trmm_c5),0)
	print("    LowQ -- Median -- UpQ")
	print("c0  "+statsFLASHCOUNT_c0(6)+" -- "+decimalPlaces(statsFLASHCOUNT_c0(8),2,True)+" -- "+statsFLASHCOUNT_c0(10))
	print("c1  "+statsFLASHCOUNT_c1(6)+" -- "+decimalPlaces(statsFLASHCOUNT_c1(8),2,True)+" -- "+statsFLASHCOUNT_c1(10))
	print("c2  "+statsFLASHCOUNT_c2(6)+" -- "+decimalPlaces(statsFLASHCOUNT_c2(8),2,True)+" -- "+statsFLASHCOUNT_c2(10))
	print("c3  "+statsFLASHCOUNT_c3(6)+" -- "+decimalPlaces(statsFLASHCOUNT_c3(8),2,True)+" -- "+statsFLASHCOUNT_c3(10))
	print("c4  "+statsFLASHCOUNT_c4(6)+" -- "+decimalPlaces(statsFLASHCOUNT_c4(8),2,True)+" -- "+statsFLASHCOUNT_c4(10))
	print("c5  "+statsFLASHCOUNT_c5(6)+" -- "+decimalPlaces(statsFLASHCOUNT_c5(8),2,True)+" -- "+statsFLASHCOUNT_c5(10))
	print("------------------------")
	print("")


	print("")
	print("     MAX FLASHCOUNT")
	print("------------------------")
	maxFLASHCOUNT_c0 = dim_max_n(rawFLASHCOUNT(index_trmm_c0),0)
	maxFLASHCOUNT_c1 = dim_max_n(rawFLASHCOUNT(index_trmm_c1),0)
	maxFLASHCOUNT_c2 = dim_max_n(rawFLASHCOUNT(index_trmm_c2),0)
	maxFLASHCOUNT_c3 = dim_max_n(rawFLASHCOUNT(index_trmm_c3),0)
	maxFLASHCOUNT_c4 = dim_max_n(rawFLASHCOUNT(index_trmm_c4),0)
	maxFLASHCOUNT_c5 = dim_max_n(rawFLASHCOUNT(index_trmm_c5),0)
	print(maxFLASHCOUNT_c0+"")
	print(maxFLASHCOUNT_c1+"")
	print(maxFLASHCOUNT_c2+"")
	print(maxFLASHCOUNT_c3+"")
	print(maxFLASHCOUNT_c4+"")
	print(maxFLASHCOUNT_c5+"")
	print("------------------------")
	print("")


	print("")
	print("     FREQ FLASHCOUNT")
	print("------------------------")
	freqFLASHCOUNT_c0 = ( tofloat(num(rawFLASHCOUNT(index_trmm_c0) .gt. 0)) / ntimes_trmm_c0 ) * 100
	freqFLASHCOUNT_c1 = ( tofloat(num(rawFLASHCOUNT(index_trmm_c1) .gt. 0)) / ntimes_trmm_c1 ) * 100
	freqFLASHCOUNT_c2 = ( tofloat(num(rawFLASHCOUNT(index_trmm_c2) .gt. 0)) / ntimes_trmm_c2 ) * 100
	freqFLASHCOUNT_c3 = ( tofloat(num(rawFLASHCOUNT(index_trmm_c3) .gt. 0)) / ntimes_trmm_c3 ) * 100
	freqFLASHCOUNT_c4 = ( tofloat(num(rawFLASHCOUNT(index_trmm_c4) .gt. 0)) / ntimes_trmm_c4 ) * 100
	freqFLASHCOUNT_c5 = ( tofloat(num(rawFLASHCOUNT(index_trmm_c5) .gt. 0)) / ntimes_trmm_c5 ) * 100
	print(freqFLASHCOUNT_c0+" %")
	print(freqFLASHCOUNT_c1+" %")
	print(freqFLASHCOUNT_c2+" %")
	print(freqFLASHCOUNT_c3+" %")
	print(freqFLASHCOUNT_c4+" %")
	print(freqFLASHCOUNT_c5+" %")
	print("------------------------")
	print("")
exit


;	do ilevel=0,39
;		print("------------------------")
;		print(ilevel+"")
;		print("------------------------")
;		print( num(theMAXDBZ(index_trmm_c0,ilevel) .lt. 0) )
;		print( num(theMAXDBZ(index_trmm_c1,ilevel) .lt. 0) )
;		print( num(theMAXDBZ(index_trmm_c2,ilevel) .lt. 0) )
;		print( num(theMAXDBZ(index_trmm_c3,ilevel) .lt. 0) )
;		print( num(theMAXDBZ(index_trmm_c4,ilevel) .lt. 0) )
;		print( num(theMAXDBZ(index_trmm_c5,ilevel) .lt. 0) )
;		print("")
;	end do


	print("")
	print("------------------------")
	print("      MAXDBZ")
	print("------------------------")
	medianMAXDBZ_c0 = dim_median_n(theMAXDBZ(index_trmm_c0,:),0)
	medianMAXDBZ_c1 = dim_median_n(theMAXDBZ(index_trmm_c1,:),0)
	medianMAXDBZ_c2 = dim_median_n(theMAXDBZ(index_trmm_c2,:),0)
	medianMAXDBZ_c3 = dim_median_n(theMAXDBZ(index_trmm_c3,:),0)
	medianMAXDBZ_c4 = dim_median_n(theMAXDBZ(index_trmm_c4,:),0)
	medianMAXDBZ_c5 = dim_median_n(theMAXDBZ(index_trmm_c5,:),0)
	print("Cluster 0 ")
	print("------------------------")
	print(medianMAXDBZ_c0(0:15)+"")
	print("")
	print("------------------------")
	print("Cluster 1 ")
	print("------------------------")
	print(medianMAXDBZ_c1(0:15)+"")
	print("")
	print("------------------------")
	print("Cluster 2 ")
	print("------------------------")
	print(medianMAXDBZ_c2(0:15)+"")
	print("")
	print("------------------------")
	print("Cluster 3 ")
	print("------------------------")
	print(medianMAXDBZ_c3(0:15)+"")
	print("")
	print("------------------------")
	print("Cluster 4 ")
	print("------------------------")
	print(medianMAXDBZ_c4(0:15)+"")
	print("")
	print("------------------------")
	print("Cluster 5 ")
	print("------------------------")
	print(medianMAXDBZ_c5(0:15)+"")
	print("")
	print("")
	print("")



exit

	calDayCluster = cd_calendar(theCluster&time, -2)
	calDayTRMM    = cd_calendar(timeTRMM, -2)
	;printVarSummary(calDayCluster)
	;print(calDayCluster)
	;print(calDayTRMM)
	
exit

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

