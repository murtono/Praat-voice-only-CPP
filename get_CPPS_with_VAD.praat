# OLIVIA MURTON 10_13_22
# HOW TO USE
# 1. Identify:
#	(a) the path of the folder containing the sound files to be analyzed
#	(b) the path of the folder where you want the result file to go
#	(c) the name you want the result file to have
#	(d) whether you would like the TextGrids (labeling the voiced intervals) to be saved
# 2. Open this script in Praat
# 3. Click "Run", or type ctrl + R
# 4. Copy the paths/filenames you identified in Step 1 into the form
# 5. Click "ok". The script may take a few minutes (or longer) to run, depending on the number of files. 
# 6. The result file will appear in the folder you specified in step (1b). 

#####

form Get average CPP with VAD
	comment Folder with sound files
	sentence wavpath 
	comment Folder for result file
	sentence resultpath 
	comment Name of result file (include .txt)
	sentence resultfile 
	comment Save TextGrids for future reference?
	boolean saveme	1
endform

# identify list and quantity of sound files 
wavlist$ = wavpath$ + "/*.wav"
allwav = Create Strings as file list: "allwav", wavlist$
numwav = Get number of strings

# initialize the result file & write out headers into it
resultfile$ = resultpath$ + "/" + resultfile$
titleline$ = "Filename	Intervals	CPPS"
writeFileLine: resultfile$, "'titleline$'"

# loop through sound files
for i to numwav

	# load & select the next sound file
	selectObject: allwav
	filename$ = Get string: i
	fullwavpath$ = wavpath$ + "/" + filename$
	wav = Read from file: fullwavpath$
	selectObject: wav

	# identify the voiced & unvoiced regions
	vad_grid = To TextGrid (voice activity): 0, 0.3, 0.1, 70, 6000, -10, -15, 0.02, 0.02, "silent", "sounding"

	# find out how many intervals there are in the first (voiced/unvoiced) tier
	selectObject: vad_grid
	numIntervals = Get number of intervals: 1

	# set up lists for CPP values and interval durations
	cppslist# = zero#(numIntervals)
	durationlist# = zero#(numIntervals)
	soundcount = 0

	# loop through voiced & unvoiced intervals 
	for j to numIntervals

		# get duration & label of next interval
		selectObject: vad_grid
		starttime = Get start time of interval: 1, j
		endtime = Get end time of interval: 1, j
		duration = endtime - starttime
		label$ = Get label of interval: 1, j

		# if this is a voiced interval
		if label$ = "sounding"
	
			# extract the voiced interval for analysis		
			soundcount = soundcount + 1
			selectObject: wav
			extracted = Extract part: starttime, endtime, "rectangular", 1.0, "no"
	
			# high pass filter following Meike (Brockmann-Bauser et al 2019)
			band = Filter (stop Hann band): 0, 34, 0.01
			selectObject: band

			# get CPPS using settings from Delgado-Hernandez 2018
			pcgram = To PowerCepstrogram: 60, 0.002, 5000, 50
			cpps = Get CPPS: "no", 0.01, 0.001, 60, 330, 0.05, "Parabolic", 0.001, 0, "Straight", "Robust"
			
			# add this interval's CPPS and duration to the running list
			cppslist#[j] = cpps
			durationlist#[j] = duration

			# clear objects used to find CPP
			removeObject: band, pcgram, extracted
		endif

	endfor

	# voice-only CPP is the time-weighted average of the interval CPP values
	totalCPPS = sum(cppslist# * durationlist#)/sum(durationlist#)

	# add this file's data to the result file
	resultline$ = "'filename$'	'soundcount'	'totalCPPS'"
	appendFileLine: resultfile$, resultline$

	# save the TextGrid if desired
	if saveme
		selectObject: vad_grid
		grid_name$ = selected$("TextGrid", 1)
		fullgridpath$ = wavpath$ + "/" + grid_name$ + ".TextGrid"
		Save as text file: fullgridpath$ 
	endif

	# remove this sound file and TextGrid
	removeObject: wav, vad_grid

endfor

