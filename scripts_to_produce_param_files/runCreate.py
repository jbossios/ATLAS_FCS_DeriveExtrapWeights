# Full detector
ETA_MIN   = 0
ETA_MAX   = 5.0

# Full energy range
E_MIN     = 64
E_MAX     = 4194304

def main():

  import os
  import sys
  import argparse

  parser = argparse.ArgumentParser()
  parser.add_argument('--particles', action='store', dest='particles', default='',    help='Particles (options: photons, electrons, pions)')
  parser.add_argument('--mode', action='store', dest='mode', default='FCS', help='Mode (options: FCS or FCGan)')
  parser.add_argument('--version', action='store', dest='version', default='', help='Unique string that identifies a set of param files (required)')
  parser.add_argument('--predictExtrapWeights', action='store_true', dest='predict_extrap_weights', default=False, help='Use a Neural Network to predict extrapolation weights (default=False)')
  args = parser.parse_args()

  # Protections
  if not args.particles:
    print('--particles not provided, exiting')
    parser.print_help()
    sys.exit(1)
  if args.particles not in ['photons','electrons','pions']:
    print('particles ({}) not recognized, exiting'.format(args.particles))
    parser.print_help()
    sys.exit(1)
  if not args.version:
    print('--version not provided, exiting')
    parser.print_help()
    sys.exit(1)

  particles = args.particles
  mode = args.mode
  version = args.version
  predict_extrap_weights = args.predict_extrap_weights
  
  output_path = '/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/ParamFiles/{}'.format(mode)
  
  ########################################################################################
  # DO NOT MODIFY (below this line)
  ########################################################################################
  
  # Protection
  if mode != 'FCGan' and mode != 'FCS':
    print('ERROR: Mode not recognized, should be FCGan or FCS, exiting')
    sys.exit(1)
  
  # Create output folder
  case = 'Standard' if not predict_extrap_weights else 'PredictExtrapWeights'
  output = '{}/{}/{}/{}'.format(output_path, case, particles, version)
  if not os.path.exists(output):
    os.makedirs(output)
  
  pdgId = {'photons': 22, 'electrons': 11, 'pions': 211}[particles]
  nBins = int(round(( ETA_MAX - ETA_MIN ) / 0.05))
  print('nBins = {}'.format(nBins))
  
  for ibin in range(nBins): # loop over eta bins
    eta_min = ETA_MIN + 0.05*ibin
    extra = ' --useWeightedHits 203' if mode == 'FCGan' else ''
    useNN = ' --predictExtrapWeights' if predict_extrap_weights else ''
    command = 'runTFCSCreateParamEtaSlice --pdgId {} --emin {} --emax {} --etamin {} --output {}{}{}'.format(pdgId, E_MIN, E_MAX, eta_min, output, extra, useNN)
    os.system(command)

if __name__ == '__main__':
  main()
