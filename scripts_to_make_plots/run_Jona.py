import argparse
import os
import sys

from CompareSimulations import readxAOD, plotConfig
from CompareSimulations.compare_simulations import plot, ROOT
from CompareSimulations import hutils

parser = argparse.ArgumentParser()
parser.add_argument('--config', action='store', dest='config', default = '', help='Python config file')
args = parser.parse_args()

if not args.config:
  print('ERROR: no config file was provided, exiting')
  sys.exit(1)

plot_set = 'all'

##############################################################################
# DO NOT MODIFY (below this line)
##############################################################################

# import config
sys.path.append('Configs/')
cfg = __import__(args.config.replace('.py',''))

particles = cfg.Particles.split(' ')
energies = cfg.Energies.split(' ')
etas = cfg.Etas.split(' ')

# Loop over particles
for particle in particles:

  # Protection
  plural_particle = particle if particle.endswith('s') else particle + 's'

  # Loop over energies
  for energy in energies:
    # Loop over etas
    for eta in etas:
      eta = int(eta)
      eta_up = eta + 5

      # Need a DSID of the form <particle>_E<energy>_eta_<eta_range>_z<zv>
      DSID = hutils.dsid.make_DSID(
        plural_particle,
        energy,
        eta_range=(eta, eta_up),
        zv = 0,
      )
      print('INFO: running on DID: {}'.format(DSID))

      # Protection
      nKeys = len(cfg.Simulations2Compare.keys())
      if nKeys < 2 or nKeys > 3:
        print('ERROR: only 2 or 3 can be compared, a comparison with {} simulation(s) is not supported, exiting'.format(nKeys))
        sys.exit(1)

      # Base path to write to
      base_dir = cfg.OutputPATH + args.config.replace('config_Jona', '').replace('.py', '')

      for sim_name, sim_dict in cfg.Simulations2Compare.items():

        # get the location of the xAOD now
        filepath = os.path.join(sim_dict['InputPath'], sim_dict['FileName'])
        # not strictly needed, you can run ProcessFile without it,
        # but useful to prevent mixups later
        smetadata = hutils.metadata.SampleMetadata(
          particle_content = plural_particle,
          simulation_type = sim_name,
          simulation_release = cfg.Version,
          energy = energy,
          eta_range = (eta, eta_up),
          xAOD_location = filepath,
          base_dir = base_dir,
          notes = [sim_dict['Legend']],
        )
        # it will appear on a canvas in the flatTTree.root file
        sim_dict["metadata"] = smetadata

        # This takes the xAOD and writes the flatTTree to disk.
        # if you have multiple xAOD's then filepath should be a list of strings,
        # they will all be put into one flatTTree
        # padding value gets used if for some reason an event produced no data
        # (say an event with 0 jets)
        readxAOD.ProcessFile(
          filepath,
          sample_type = plural_particle,
          padding_value = ROOT.TMath.QuietNaN(),
          sample_metadata = smetadata,
        )

      # Create an enviroment object
      plotEnv = plotConfig.PlotConfEnv(
        plural_particle,
        base_dir,
        DSID = DSID,
        outputDir = os.path.join(base_dir, "images"),
        ShowMeanInLegend = cfg.ShowMeanInLegend,
        ShowUnderOverflowInLegend = False,
        Autoscale = True,
      )

      for sim_name, sim_dict in cfg.Simulations2Compare.items():
        # will add Legend, Color, LineStyle, LineWidth, MarkerStyle, and MarkerSize
        # addtional values in sim_dict will be stored, but are ignored
        # if not given, a default range would be used
        plotEnv.add_simulation(
          simulation_name = sim_name,
          FilePath = sim_dict['metadata']['flatTTree_location'],
          **sim_dict,
        )

      plotEnv.global_inputs['Filter'] = plot_set

      # the second argument can be a list of strings if multiple formats are wanted.
      # see https://gitlab.cern.ch/hdayhall/CompareSimulations21/-/blob/henry-rel22-dev/CompareSimulations/compare_simulations.py#L882
      # for all possibilities
      plot(plotEnv, 'pdf')
