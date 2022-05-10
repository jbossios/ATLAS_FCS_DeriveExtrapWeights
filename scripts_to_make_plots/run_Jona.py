import argparse
import os
import sys
parser = argparse.ArgumentParser()
parser.add_argument('--config', action='store', dest='config', default = '', help='Python config file')
args = parser.parse_args()

if not args.config:
  print('ERROR: no config file was provided, exiting')
  sys.exit(1)

LargeJetCollectionName = 'AntiKt10LCTopoJets2'
JetCollectionName      = 'AntiKt4EMPFlowJets AntiKt4LCTopoJets'

##############################################################################
# DO NOT MODIFY (below this line)
##############################################################################

# import config
sys.path.append('Configs/')
cfg = __import__(args.config.replace('.py',''))

Version   = cfg.Version
Particles = cfg.Particles.split(' ')
Energies  = cfg.Energies.split(' ')
Etas      = cfg.Etas.split(' ')

commands = []
# Loop over particles
for particle in Particles:
  # Loop over energies
  for energy in Energies:
    # Loop over etas
    for eta in Etas:
      etaUp               = int(eta) + 5
      DSID                = '{}_E{}_eta{}_z0'.format(particle,energy,eta)
      print('INFO: running on DID: {}'.format(DSID))
      flatTTreeFolderName = '{}/TTrees/{}'.format(cfg.OutputPATH,Version)
      # Protection
      nKeys = len(cfg.Simulations2Compare.keys())
      if nKeys < 2 or nKeys > 3:
        print('ERROR: only 2 or 3 can be compared, a comparison with {} simulation(s) is not supported, exiting'.format(nKeys))
	sys.exit(1)
      # Loop over simulations to compare
      commands.append('export release="{}"'.format(Version))
      commands.append('export largeJetCollectionName="{}"'.format(LargeJetCollectionName))
      commands.append('export jetCollectionName="{}"'.format(JetCollectionName))
      for SimName, Dict in cfg.Simulations2Compare.items():
        inputFiles = '{}{}'.format(Dict['InputPath'], Dict['FileName'])
	outdir     = '{}/{}'.format(SimName,DSID)
	commands.append('mkdir -p {}'.format(outdir))
	outdir     = '{}/{}/{}/data-comparisonInput'.format(flatTTreeFolderName,SimName,DSID)
	commands.append('mkdir -p {}'.format(outdir))
        commands.append('export inputFiles={}{}'.format(Dict['InputPath'], Dict['FileName']))
        commands.append('export outdir={}/{}'.format(SimName,DSID))
	commands.append('. ./run.sh')
	commands.append('cp {0}/{1}/data-comparisonInput/{2}.root {3}/{1}.root'.format(SimName,DSID,Dict['InputPath'].split('/')[-2],outdir))
      # Create .env file
      envName = '{}/config_{}.env'.format(os.getcwd(),Version)
      envFile = open(envName,'w')
      counter = 1
      for SimName, Dict in cfg.Simulations2Compare.items():
        SimIndex = {1 : 'First', 2 : 'Second', 3 : 'Third'}[counter]
        envFile.write('{}SimName: {}\n'.format(SimIndex,SimName))
        for key, value in Dict.items():
          if key != 'InputPath' and key != 'FileName':
            envFile.write('{}Sim_{}: {}\n'.format(SimIndex, key, value))
        counter += 1
      envFile.write('outputDir: {}/Plots/{}/\n'.format(cfg.OutputPATH,Version))
      envFile.write('inputDir: {}/TTrees/{}/\n'.format(cfg.OutputPATH,Version))
      envFile.write('HistoDefinitionXML: {}\n'.format(cfg.HistoDefinitionXML.replace('PARTICLE',particle)))
      envFile.write('ShowMeanInLegend: {}\n'.format('True' if cfg.ShowMeanInLegend else 'False'))
      useThirdSim    = 'True' if nKeys == 3         else 'False'
      useTreeInputs  = 'True' if cfg.UseTreeInputs  else 'False'
      saveHisto      = 'True' if cfg.SaveHisto      else 'False'
      isFSProduction = 'True' if cfg.IsFSProduction else 'False'
      commands.append('runCompare_Simulations {} {} {} {} {} {} output.root'.format(DSID,envName,useThirdSim,useTreeInputs,saveHisto,isFSProduction))
command = ' && '.join(commands)+' &'
print(command)
os.system(command)
