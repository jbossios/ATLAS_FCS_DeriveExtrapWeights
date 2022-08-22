
import os
import sys

PATH = '/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/R22/xAODs/'

COLORS = [1, 633, 865]
LINE_STYLES = [7, 1, 7]
MARKER_STYLES = [24, 20, 1]
LINE_WIDTHS = [1, 2, 2]
MARKER_SIZES = [4, 4, 1]

def create_config(version, option_dict):
  # Create output config
  output_file_name = 'Configs/config_Jona{}.py'.format(version)
  print('Creating {}...'.format(output_file_name))
  with open(output_file_name, 'w') as out_file:
    out_file.write('Simulations2Compare = {\n')
    particle = option_dict['Particle']
    particles = option_dict['Particle'] + 's'
    energy = 'E{}'.format(option_dict['Energy'])
    eta = option_dict['EtaBin']
    for counter, (input_case, input_version) in enumerate(option_dict['Inputs'].items()):
      if input_case == 'FullSim':
        in_path = input_version
	# Look for merged file
        in_file_name = os.listdir(in_path)[0]
      else:
        # Find input path and filename
        sim_case = {
          'FCS_Standard': 'FCS/Standard/',
          'FCS_PredictExtrapWeights': 'FCS/PredictExtrapWeights/',
          'FCGan_Standard': 'FCGan/Standard/',
          'FCGan_PredictExtrapWeights': 'FCGan/PredictExtrapWeights/',
        }[input_case]
        path = '{}{}{}/{}/'.format(PATH, sim_case, particles, input_version)
        if not os.path.exists(path):
          print('ERROR: {} does not exists, exiting'.format(path))
          sys.exit(1)
        sim_type = input_case.split('_')[0] # FCS or FCGan
        if sim_type == 'FCGan': sim_type = 'GAN'
        case = input_case.split('_')[1]  # Standard or PredictExtrapWeihts
        in_path = ''
        in_file_name = ''
        # Look first for a merged file
        merged_file_name = '{}_{}_{}_{}_{}.root'.format(case, particles, energy, eta, input_version)
        if os.path.exists(path+merged_file_name):
          in_path = path
          in_file_name = merged_file_name
        else:  # no merged file found
          for folder in os.listdir(path):
            if 'user' not in folder: continue
            #if sim_type not in folder: continue
            if 'Pred' in case and 'Pred' not in folder: continue
            if energy not in folder: continue
            if eta.replace('eta_', '') not in folder: continue
            in_path = '{}{}/'.format(path, folder)
            in_file_name = os.listdir(in_path)[0]
            break
      if not in_path:
        print('ERROR: No InputPath was found, exiting')
        sys.exit(1)
      if not in_file_name:
        print('ERROR: No InputPath was found, exiting')
        sys.exit(1)
      out_file.write("  '"+input_case+"': {\n")
      out_file.write("    'Legend': '{}',\n".format(input_case))
      out_file.write("    'InputPath': '{}',\n".format(in_path))
      out_file.write("    'FileName': '{}',\n".format(in_file_name))
      out_file.write("    'Color': {},\n".format(COLORS[counter]))
      out_file.write("    'LineStyle': {},\n".format(LINE_STYLES[counter]))
      out_file.write("    'MarkerStyle': {},\n".format(MARKER_STYLES[counter]))
      out_file.write("    'LineWidth': {},\n".format(LINE_WIDTHS[counter]))
      out_file.write("    'MarkerSize': {}\n".format(MARKER_SIZES[counter]))
      out_file.write("  },\n")
    out_file.write("}\n")
    out_file.write("Particles = '{}'\n".format(particle))
    out_file.write("Energies = '{}'\n".format(option_dict['Energy']))
    out_file.write("Etas = '{}'\n".format(eta.split('_')[1]))
    out_file.write("Version = 'Jona{}'\n".format(version))
    out_file.write("OutputPATH = '/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/R22/ComparisonSimulation21_outputs/'\n")
    out_file.write("HistoDefinitionXML = 'histoDefinition_PARTICLE.xml'\n")
    out_file.write("ShowMeanInLegend = False\n")
    out_file.write("UseTreeInputs = True\n")
    out_file.write("SaveHisto = True\n")
    out_file.write("IsFSProduction = False\n")


if __name__ == '__main__':
  initial_counter = 4  # will start w/ JonaV{initial_counter}
  options = [
    {
      'Particle': 'photon',
      'Energy': '65536',
      'EtaBin': 'eta_20_25',
      'Inputs': {
                  'FCS_Standard': '19082022',
                  'FCGan_Standard': '19082022',
                  'FCGan_PredictExtrapWeights': '19082022_17082022',
                },
    },
    {
      'Particle': 'photon',
      'Energy': '65536',
      'EtaBin': 'eta_20_25',
      'Inputs': {
                  'FCS_Standard': '19082022',
                  'FCGan_Standard': '19082022',
                  'FCGan_PredictExtrapWeights': '19082022_18082022',
                },
    },
  ]
  for option_i, option_dict in enumerate(options):
    version_n = initial_counter + option_i
    if version_n < 10:
      version = 'V00{}'.format(version_n)
    elif version_n < 100:
      version = 'V0{}'.format(version_n)
    else:
      version = 'V{}'.format(version_n)
    create_config(version, option_dict)
  print('>>> ALL DONE <<<')
