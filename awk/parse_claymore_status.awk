# Fixes for GPU > 10 fans and temps
BEGIN {
	FS = "(: )|(, )"
	ORS = "\n"
	NUM_GPUS=0
	TRACE=0
}

/SHARE FOUND/ {next}
/Share accepted/ {next}
/ got incorrect share/ {next}

/^GPU #/ { 
	#gpu[NUM_GPUS,"MODEL"]=$2
	#gpu[NUM_GPUS,"MEMORY"]=$3
	#sub(/ MB available/,"",gpu[NUM_GPUS,"MEMORY"])	
	#gpu[NUM_GPUS,"PROC"]=$4
	#sub(/ compute units/,"",gpu[NUM_GPUS,"PROC"])
	gpu[NUM_GPUS,"SPECS"]=$2 "," $3 "," $4
	gsub(/ /," ",gpu[NUM_GPUS,"SPECS"])
	gsub(/,/,",",gpu[NUM_GPUS,"SPECS"])
	NUM_GPUS++
}

/^ETH - Total Speed: / { 
	hr=$2
	sub(/ .*/,"",hr)

	valid_shares=$4
	sub(/\([0-9+]+\)/,"",valid_shares)

	_gpu_shares=$4
	gsub(/^[0-9]+\(|\)/,"",_gpu_shares)
	split(_gpu_shares,gpu_shares,"+")
	for ( i = 0; i < NUM_GPUS; i++ ) {
		gpu[i,"VALID_SHARES"]=gpu_shares[i+1]
	}

	invalid_shares+=$6
	_mining_time=$8
	gsub(":+","",_mining_time)
	mining_time=_mining_time"00"
}	

/^  (DCR|SC|LBC|PASC) - Total Speed: / { 
	hr_dcoin=$2
	sub(/ .*/,"",hr_dcoin)

	valid_shares_dcoin+=$4
	sub(/\([0-9+]+\)/,"",valid_shares_dcoin)

	_gpu_shares_dcoin=$4
	gsub(/^[0-9]+\(|\)/,"",_gpu_shares_dcoin)
	split(_gpu_shares_dcoin,gpu_shares_dcoin,"+")
	for ( i = 0; i < NUM_GPUS; i++ ) {
		gpu[i,"VALID_SHARES_DCOIN"]=gpu_shares_dcoin[i+1]
	}

	invalid_shares_dcoin+=$6
}	

/^ETH:/ {
	_index=0
	while ( _index < NUM_GPUS ) {
		gpu_field=_index + 2
		gpu_hr=$gpu_field
	        gsub(/^GPU[0-9]+ | .*/,"",gpu_hr)
		gpu[_index,"HR"]=gpu_hr
		_index++;
	}
}

/^  (DCR|SC|LBC|PASC):/ {
	_index=0
	while ( _index < NUM_GPUS ) {
		gpu_field=_index + 2
		gpu_hr=$gpu_field
	        gsub(/^GPU[0-9]+ | .*/,"",gpu_hr)
		gpu[_index,"HR_DCOIN"]=gpu_hr
		_index++;
	}
}

/^Incorrect ETH shares:/ { 
	gpu_field=2
	while ( gpu_field <= NF ) {
		gpu_index = $gpu_field
		gpu_inc_shares=$gpu_field
		gsub(/GPU| [0-9]+/,"",gpu_index)
		sub(/GPU[0-9 ]+ /,"",gpu_inc_shares)
		gpu[gpu_index,"INVALID_SHARES"] = gpu_inc_shares
		invalid_shares+=gpu_inc_shares
		gpu_field++
	}
}

/^Incorrect (DCR|SC|LBC|PASC) shares:/ { 
	gpu_field=2
	while ( gpu_field <= NF ) {
		gpu_index = substr($gpu_field,4,1)
		gpu_inc_shares=$gpu_field
		sub(/GPU[0-9 ]+/,"",gpu_inc_shares)
		gpu[gpu_index,"INVALID_SHARES_DCOIN"] = gpu_inc_shares
		invalid_shares_dcoin+=gpu_inc_shares
		gpu_field++
	}
}

/^ 1 minute average / { 
	avg_hr_1m = $2 
	sub(/ .*/,"",avg_hr_1m)
}


/^Current ETH share target/ { 
        dag=$4
        dag_size=$4
        gsub(/^epoch |\([0-9A-Z\.]+\)/,"",dag)
        gsub(/^epoch [0-9]+\(|\)/,"",dag_size)
	#print dag
	#print dag_size
	}

/^GPU0 t/ {
        gpu_field = 1
        while ( gpu_field <= NF ) {
		_index=$gpu_field
		temp=$gpu_field
		fan=$gpu_field
                gsub(/^GPU| t=.*/,"",_index)
                gsub(/^GPU[0-9]+ t=|C fan.*/,"",temp)
                gsub(/^GPU[0-9]+ t=[0-9]+C fan=|%/,"",fan)
                gpu[_index,"TEMP"] = temp
                gpu[_index,"FAN"] = fan
                gpu_field++
		pring temp "," fan
        }
}

END {
        print "RIG," time "," rig_name "," NUM_GPUS "," hr ","avg_hr_1m "," valid_shares "," invalid_shares "," hr_dcoin ","avg_hr_1m_dcoin ","  valid_shares_dcoin "," invalid_shares_dcoin "," power_usage "," mining_time

        for ( gpu_id = 0; gpu_id < NUM_GPUS; gpu_id++ ) {
                print "GPU," time "," rig_name "/" gpu_id "," gpu[gpu_id,"HR"] "," gpu[gpu_id,"VALID_SHARES"] "," gpu[gpu_id,"INVALID_SHARES"] "," gpu[gpu_id,"HR_DCOIN"] "," gpu[gpu_id,"SHARES_DCOIN"] ","  gpu[gpu_id,"INVALID_SHARES_DCOIN"] "," gpu[gpu_id,"TEMP"] "," gpu[gpu_id,"FAN"]
        }
	
	if (TRACE != 0) { 
	print "SYSTEM NAME: " rig_name
	print "\tETH CURRENT HASHRATE: " hr
	print "\tETH AVERAGE HASHRATE ETH: " avg_hr_1m
	print "\tETH VALID SHARES: " valid_shares
	print "\tETH INVALID: " invalid_shares
	print "\tDCR/SC/LBC/PASC CURRENT HASHRATE: " hr_dcoin
	print "\tDCR/SC/LBC/PASC AVERAGE HASHRATE: " avg_hr_1m_dcoin
	print "\tDCR/SC/LBC/PASC VALID_SHARES: " valid_shares_dcoin
	print "\tDCR/SC/LBC/PASC INVALID SHARES: " invalid_shares_dcoin
	print "\tETH MINING TIME: " mining_time
	print "\tETH DAG #: " dag ", DAG SIZE: " dag_size

	for ( i = 0; i < NUM_GPUS; i++ ) {
		print "GPU#" i
		print "\tETH HASHRATE: " gpu[i,"HR"]
		print "\tSPECS: " gpu[i,"SPECS"]
		print "\tETH VALID SHARES: " gpu[i,"VALID_SHARES"]
		print "\tETH INVALID SHARES: " gpu[i,"INVALID_SHARES"]
		print "\tDCR/SC/LBC/PASC HASHRATE: " gpu[i,"HR_DCOIN"]
		print "\tDCR/SC/LBC/PASC VALID SHARES: " gpu[i,"VALID_SHARES_DCOIN"]
		print "\tDCR/SC/LBC/PASC INVALID SHARES: " gpu[i,"INVALID_SHARES_DCOIN"]
		print "\tTEMP.(C): " gpu[i,"TEMP"]
		print "\tFAN SPEED: " gpu[i,"FAN"]
	}
	}
}
