
# Base path
BasePATH = '/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/R22/xAODs/FCS/'
#BasePATH = '/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/R22/xAODs/FCGan/'

Cases = {
# FCS
  'Standard' : {
    'photons' : {
      'inpath'  : '19082022/user.jbossios.mc20_13TeV.Run3_FullG4MT_Sim_pid22_E65536_65536_disj_eta_m25_m20_20_25_zv_0_Std_18_08_2022_34_EXT0/',
      'outfile' : '19082022/Standard_photons_FCS_E65536_eta_20_25_19082022.root',
    },
  #  'electrons' : {
  #    'inpath'  : '16122021/user.jbossios.mc16_13TeV.432704.FCS_NTUP_G4FastCalo_Sim_pid11_E65536_eta_m25_m20_20_25_zv_0_Std_16122021_05_EXT0/',
  #    'outfile' : '16122021/Standard_electrons_16122021.root',
  #  },
  #  'pions' : {
  #    'inpath'  : '27012022/user.jbossios.mc16_13TeV.434404.FCS_NTUP_G4FastCalo_Sim_pid211_E65536_eta_m25_m20_20_25_zv_0_Std_26012022_53_EXT0/',
  #    'outfile' : '27012022/Standard_pions_27012022.root',
  #  },
  }
  #'PredictExtrapWeights' : {
  #  'electrons' : {
  #    'inpath'  : '17022022/user.jbossios.mc16_13TeV.432704.FCS_NTUP_G4FastCalo_Sim_pid11_E65536_eta_m25_m20_20_25_zv_0_Predict_17022022_45_EXT0/',
  #    'outfile' : '17022022/PredictExtrapWeights_electrons_v26_17022022.root',
  #  },
  #}
# FCGan
  #'Standard' : {
  #  'photons' : {
  #    'inpath'  : '19082022/user.jbossios.mc20_13TeV.Run3_FullG4MT_Sim_pid22_E65536_65536_disj_eta_m25_m20_20_25_zv_0_StdGAN_18_08_2022_01_EXT0/',
  #    'outfile' : '19082022/Standard_photons_FCGan_E65536_eta_20_25_19082022.root',
  #  },
  #  'pions' : {
  #    'inpath'  : '19012022/user.jbossios.mc16_13TeV.434404.FCS_NTUP_G4FastCalo_Sim_pid211_E65536_eta_m25_m20_20_25_zv_0_FCGan_19012022_46_EXT0/',
  #    'outfile' : '19012022/Standard_FCGan_pions_19012022.root',
  #  },
  #},
  #'PredictExtrapWeights' : {
  #  'photons' : {
  #    'inpath'  : '19082022_18082022/user.jbossios.mc20_13TeV.Run3_FullG4MT_Sim_pid22_E65536_65536_disj_eta_m25_m20_20_25_zv_0_PredGAN_18_08_2022_00_EXT0/',
  #    'outfile' : '19082022_18082022/PredictExtrapWeights_photons_FCGan_E65536_eta_20_25_19082022_18082022.root',
  #  },
  #  'pions' : {
  #    'inpath'  : '21012022/user.jbossios.mc16_13TeV.434404.FCS_NTUP_G4FastCalo_Sim_pid211_E65536_eta_m25_m20_20_25_zv_0_Predict_21012022_35_EXT0/',
  #    'outfile' : '21012022/PredictExtrapWeights_pions_FCGan_21012022.root',
  #  },
  #}
}

##################################
# DO NOT MODIFY (below this line)
##################################

import os

def main():

  def getPath(base,case,pid):
    return '{}{}/{}/'.format(base,case,pid)

  def getFileNames(case,pid,Dict):
    return ','.join([getPath(BasePATH,case,pid)+Dict['inpath']+f for f in os.listdir(getPath(BasePATH,case,pid)+Dict['inpath'])])

  # Get list of commmands
  commands = ['python customMerge_Run3.py --inputfileList {} --outputfile {}'.format(getFileNames(case,pid,Dict),getPath(BasePATH,case,pid)+Dict['outfile']) for case,Dicts in Cases.items() for pid,Dict in Dicts.items()]

  # Prepare final command and execute it
  command = ' && '.join(commands)+' & '
  os.system(command)
  
if __name__ == '__main__':
  main()
