#!/usr/bin/env python

import argparse
import subprocess
import os
import sys
import math

parser = argparse.ArgumentParser(description='Config file for single particle simulation on the grid')
parser.add_argument('-p',     		'--pid',         		type=int, 	help = 'Choose the particle',             				default = 22)
parser.add_argument('-minE',  		'--minEnergy',   		type=int, 	help = 'Choose minimum energy in MeV',    				default = 65536) # Jona
parser.add_argument('-maxE',  		'--maxEnergy',   		type=int, 	help = 'Choose maximum energy in MeV',    				default = 65536) # Jona
parser.add_argument('-minEta',		'--minEta',      		type=float, help = 'Choose minimum pseudorapidity',  				default = 0.20) # Jona
parser.add_argument('-maxEta',		'--maxEta',      		type=float, help = 'Choose maximum pseudorapidity',  				default = 0.25) # Jona
parser.add_argument('-locP',		'--pathToLocalParam', 	type=str, 	help = 'Choose local path to param file',   			default = '')
parser.add_argument('-binDir', 		'--pathToBinDir',  		type=str, 	help = 'Set path to local binaries to use on the grid', default = '')
parser.add_argument('-nEvents', 	'--nEvents',  	  		type=int, 	help = 'Set number of events to simulate', 				default = 10000) # Jona
parser.add_argument('-nJobs', 		'--nJobs', 		  		type=int, 	help = 'Set number of subjobs to use', 					default = 10)
parser.add_argument('-sim', 		'--simulator', 		  	type=str, 	help = 'Set simulator to use',					 		default = 'FCS_NTUP_G4FastCalo')
parser.add_argument('-user', 		'--user', 		  		type=str, 	help = 'Set grid user name',					 		default = 'jbossios') # Jona
parser.add_argument('-addOutDS',	'--addOutDS', 		  	type=str, 	help = 'Additional string to set to the outDS',			default = '_TEST')
parser.add_argument('-standardReco','--standardReco',		type=str,   help = 'Use standard reconstruction with noice etc.',	default = False)
parser.add_argument('-pileUp',		'--pileUp',				type=str,   help = 'Activate Pile-up.',								default = False)
parser.add_argument('-randomSeed',  '--randomSeed',			type=str,   help = 'Set a random seed.', 							default = '$RANDOM')
parser.add_argument('-symEtaRange', '--symEtaRange',		type=str,   help = 'Symmetrice eta range for simulation.', 			default = True)
parser.add_argument('-tuneVersion', '--tuneVersion',		type=str,   help = 'Version of data tune. 0 for no tune.', 			default = 0)


args = parser.parse_args()

def find_between( s, first, last ):
	try:
		start = s.index( first ) + len( first )
		end = s.index( last, start )
		return s[start:end]
	except ValueError:
		return ""

def get_dsid_from_DB(pid, eta, energy):
	#current working direcotry
	cwd = os.getcwd() 
	pathToDB = os.path.dirname(cwd) + "/data/DSID_DB.txt"
	f = open(pathToDB, "r")
	for line in f:
		pid_search = line.split(" ")[0]
		energy_search = line.split(" ")[1]
		eta_search = line.split(" ")[2]
		if (str(pid)==pid_search and str(eta)==eta_search and str(energy)==energy_search):
			return line.split(" ")[4]


###Global config######

#User name of grid user
user = args.user  
#Simulation type: FCS_NTUP for G4, FCS_NTUP_G4FastCalo for FCS
simulation = args.simulator
#Number of events to be simulated 
nEvents = args.nEvents
#Number of jobs task will be split into
nJobs = args.nJobs

if(args.pileUp and nEvents/nJobs != 2000):
	print('When running with pile-up should simulate ~2000 events per job! Exiting...')
	sys.exit()

if(args.pathToLocalParam != ''):
	#This is used if you want to submit your own param file to the grid
	pathToParamFile = args.pathToLocalParam	#../../../FCS-data-tuning/output/paramFiles/TFCSParam_pid22_E65536_m25_m20_20_25_dev_DataTune_RScale.root
	#paramName = os.path.splitext(os.path.basename(pathToParamFile))[0] #(e.g. TFCSParam_pid22_E65536.rooot)
	paramName = 'TFCSparam_v010' # Jona

else:
	#This is used if you want to run with an offical official param files on CVMFS
	basePath = '/cvmfs/atlas.cern.ch/repo/sw/database/GroupData/FastCaloSim/MC16/'
	paramName = 'TFCSparam_run2_reprocessing' #no .root here!
	pathToParamFile = basePath + paramName + '.root' 

intEtaMin = math.trunc(args.minEta*100)
intEtaMax = math.trunc(args.maxEta*100)

# Jona
if intEtaMax == 254:
  intEtaMax = 255

#Try finding the dsid in the database if it exist
if(args.minEnergy == args.maxEnergy and (intEtaMax - intEtaMin)) == 5: 
	dsid = get_dsid_from_DB(args.pid, intEtaMin, args.minEnergy)
else:
	dsid = None

if dsid == None:
	print "DSID not in database! Setting to 999999 ..."
	dsid = 999999

#Create the simulation command
cmdSim = ["../simFlavours/runGrid_{}.sh".format(simulation), user, str(args.pid), str(args.minEnergy), str(args.maxEnergy), str(intEtaMin), str(intEtaMax), str(nEvents), str(nJobs), str(dsid), args.pathToBinDir, args.addOutDS, str(args.standardReco), str(args.pileUp), str(args.randomSeed), str(args.symEtaRange)]

if simulation == "FCS_NTUP_G4FastCalo":
	cmdSim.append(paramName)
	cmdSim.append(pathToParamFile)
	if(args.pathToLocalParam != ''):
		cmdSim.append('True')
	else:
		cmdSim.append('False')
	cmdSim.append(str(args.tuneVersion))

print "Registered simulation comand " + str(cmdSim)

#call the simulation command
subprocess.call(cmdSim)


