import runCreate  # to import eta and energy ranges

def main():

  import os
  import sys
  import argparse

  parser = argparse.ArgumentParser()
  parser.add_argument('--particles', action='store', dest='particles', default='', help='Particles (options: photons, electrons, pions, all)')
  parser.add_argument('--mode', action='store', dest='mode', default='FCS', help='Mode (options: FCS or FCGan)')
  parser.add_argument('--version', action='store', dest='version', default='', help='Unique string that identifies a set of param files (required)')
  parser.add_argument('--predictExtrapWeights', action='store_true', dest='predict_extrap_weights', default=False, help='Use a Neural Network to predict extrapolation weights (default=False)')
  args = parser.parse_args()

  # Protections
  if not args.particles:
    print('--particles not provided, exiting')
    parser.print_help()
    sys.exit(1)
  if args.particles not in ['photons','electrons','pions', 'all']:
    print('particles ({}) not recognized, exiting'.format(args.particles))
    parser.print_help()
    sys.exit(1)
  if not args.version:
    print('--version not provided, exiting')
    parser.print_help()
    sys.exit(1)

  particles = [args.particles] if args.particles != 'all' else ['photons', 'electrons', 'pions']
  mode = args.mode
  version = args.version
  predict_extrap_weights = args.predict_extrap_weights

  in_path = '/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/ParamFiles/{}'.format(mode)
  
  #########################################################################################
  # DO NOT MODIFY (below this line)
  #########################################################################################
  
  particle = 'AND'.join(particles)
  
  # Set input/output path (note: input path is different for the 'all' case
  case = 'Standard' if not predict_extrap_weights else 'PredictExtrapWeights'
  input_path = '{}/{}/{}/{}'.format(in_path, case, particle, version)

  # Protection
  if not os.path.exists(input_path) and Particle != 'photonsANDelectronsANDpions':
    print('ERROR: {} does not exists, exiting'.format(input_path))
    sys.exit(1)

  # Copy inputs to the right folder when using all particles
  if particle == 'photonsANDelectronsANDpions':
    # Create folder if it doesn't exist
    if not os.path.exists(input_path):
      os.makedirs(input_path)
    # Copy particles
    for p in ['photons', 'electrons', 'pions']:
      if p != 'electrons':
        command = 'cp {}/* {}'.format(input_path.replace(Particle, p), input_path+'/')
        os.system(command)
      else:  # electrons
        input_path = input_path.replace(Particle, p)
        command = 'cp {}/* {}'.format(input_path, input_path+'/')
        os.system(command)
  
  photon = int('photons'   in particles)
  ele    = int('electrons' in particles)
  pion   = int('pions'     in particles)
  
  # Output file name
  outFile = '{}/TFCSparam_v010.root'.format(input_path)

  # Prepare command and execute it
  command = 'runTFCSMergeParamEtaSlices --emin {} --emax {} --etamin {} --etamax {} --photon {} --ele {} --pion {} --input {} --bigParamFileName {}'.format(E_MIN, E_MAX, ETA_MIN, ETA_MAX, photon, ele, pion, input_path, outFile)
  os.system(command)

if __name__ == '__main__':
  main()
