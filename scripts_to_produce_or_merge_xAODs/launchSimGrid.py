import os

CASES = {
  65536: [[0.20, 0.25]],
  #262144: [[0.40, 0.45], [1.40, 1.45]],
  #1048576: [[0.40, 0.45], [1.40, 1.45], [2.40, 2.45]],
  #1048576: [[0.40, 0.45], [1.40, 1.45]],
}

SIM_TYPES = ['FCS', 'FCGan']
#SIM_TYPES = ['FCGan']
#SIM_TYPES = ['FCS']
PARTICLES = {
  #'22': ['Std', 'Pred'],
  #'11': ['Std', 'Pred'],
  #'211': ['Std', 'Pred'],
  '211': ['Pred'],
}

PARAM_FILES = {
  'FCS': {
    'Std' : { # w/o predicting extrapolation weights
      '22'  : {'pathParamFile':'/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/ParamFiles/FCS/Standard/photons/25022022/', 'pathBinDir':''}, # photons
      ##'11'  : {'pathParamFile':'/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/ParamFiles/FCS/Standard/electrons/24012022/', 'pathBinDir':''}, # electrons
      '211' : {'pathParamFile':'/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/ParamFiles/FCS/Standard/pions/25022022/', 'pathBinDir':''}, # pions
    },
    'Pred' : { # predicting extrapolation weights (individual param files)
      '22'  : {'pathParamFile':'/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/ParamFiles/FCS/PredictExtrapWeights/photons/14042022/', 'pathBinDir':'/afs/cern.ch/user/j/jbossios/work/public/FastCaloSim/Simulate/GridProduction/FCS-sample-production/LocalAthenaDir'}, # photons
      ##'11'  : {'pathParamFile':'/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/ParamFiles/FCS/PredictExtrapWeights/electrons/24012022/', 'pathBinDir':'/afs/cern.ch/user/j/jbossios/work/public/FastCaloSim/Simulate/GridProduction/FCS-sample-production/LocalAthenaDir'}, # electrons
      #'211' : {'pathParamFile':'/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/ParamFiles/FCS/PredictExtrapWeights/pions/23042022_v36/', 'pathBinDir':'/afs/cern.ch/user/j/jbossios/work/public/FastCaloSim/Simulate/GridProduction/FCS-sample-production/LocalAthenaDir'}, # pions
      '211' : {'pathParamFile':'/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/ParamFiles/FCS/PredictExtrapWeights/photonsANDelectronsANDpions/06052022_v2/', 'pathBinDir':'/afs/cern.ch/user/j/jbossios/work/public/FastCaloSim/Simulate/GridProduction/FCS-sample-production/LocalAthenaDir'}, # pions
    },
  },
  'FCGan': {
    'Std' : { # w/o predicting extrapolation weights
      '22'  : {'pathParamFile':'/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/ParamFiles/FCGan/Standard/photons/25022022/', 'pathBinDir':''}, # photons
      ##'11'  : {'pathParamFile':'/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/ParamFiles/FCGan/Standard/electrons/18012022/', 'pathBinDir':''}, # electrons
      '211' : {'pathParamFile':'/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/ParamFiles/FCGan/Standard/pions/25022022/', 'pathBinDir':''}, # pions
    },
    'Pred' : { # predicting extrapolation weights
      '22'  : {'pathParamFile':'/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/ParamFiles/FCGan/PredictExtrapWeights/photons/14042022/', 'pathBinDir':'/afs/cern.ch/user/j/jbossios/work/public/FastCaloSim/Simulate/GridProduction/FCS-sample-production/LocalAthenaDir'}, # photons
      ##'11'  : {'pathParamFile':'/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/ParamFiles/FCGan/PredictExtrapWeights/electrons/18012022/', 'pathBinDir':'/afs/cern.ch/user/j/jbossios/work/public/FastCaloSim/Simulate/GridProduction/FCS-sample-production/LocalAthenaDir'}, # electrons
      '211' : {'pathParamFile':'/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/ParamFiles/FCGan/PredictExtrapWeights/photonsANDelectronsANDpions/06052022_v2/', 'pathBinDir':'/afs/cern.ch/user/j/jbossios/work/public/FastCaloSim/Simulate/GridProduction/FCS-sample-production/LocalAthenaDir'}, # pions
    },
  },
}

###################################
# DO NOT MODIFY (below this line)
###################################

def main():
  command = ''
  # Loop over FCS/FCGan
  for sim_type in SIM_TYPES:
    # Loop over particles
    for pid, extrap_cases in PARTICLES.items():
      # Loop over Std/Pred
      for case in extrap_cases:
        # Loop over energy values
	for energy, eta_bins in CASES.items():
	  # Loop over eta bins
          for eta_bin in eta_bins:
            min_eta = eta_bin[0]
            max_eta = eta_bin[1]
	    info_dict = PARAM_FILES[sim_type][case][pid]
            command += 'python runSimGrid.py -p {}'.format(pid)
            command += ' -minEta {}'.format(min_eta)
            command += ' -maxEta {}'.format(max_eta)
            command += ' -minE {}'.format(energy)
            command += ' -maxE {}'.format(energy)
            if info_dict['pathParamFile']:
              command += ' -locP {}'.format(info_dict['pathParamFile'])
            if info_dict['pathBinDir']:
              command += ' -binDir {}'.format(info_dict['pathBinDir'])
            outDS = '_{}'.format(case)
            if sim_type == 'FCGan':
              outDS += 'GAN'
            command += ' -addOutDS {}'.format(outDS)
            command += ' -randomSeed 42 && '
  command = command[:-2]
  print(command)
  os.system(command)

if __name__ == '__main__':
  main()
