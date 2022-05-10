# <div align='center'>Instructions for deriving extrapolation weights and produce validation plots</div>

This readme outlines the steps needed for training a network for predicting the extrapolation weights on each layer of the calorimeter, and to produce validation plots.

## Produce inputs for the training of the network

The network to be trained expects a set of TXT and CSV files, the former containing information needed to normalize the input data (mean and std dev values) and the latter containing the energy per layer and total energy. These inputs are produced from ROOT files and instructions and codes can be found in [ATLAS_FCS_PrepareCSVFiles](https://github.com/jbossios/ATLAS_FCS_PrepareCSVFiles).

The produced TXT files need to be copied over here (to the appropriate folder therein):

```
/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/lwtnn_inputs/txt
```

Those TXT files will be used within athena to do inference.

## Train the network

Instructions on how to perform an hyperparameter optimization and the final training are outlined in [ATLAS_FCS_RegressionWithKeras](https://github.com/jbossios/ATLAS_FCS_RegressionWithKeras).

## Produce lwtnn inputs

Once networks were trained, in order to be able to perform inference within athena, one needs to produce lwtnn inputs. For producing such inputs, please follow instructions in [ATLAS_FCS_keras2lwtnn](https://github.com/jbossios/ATLAS_FCS_keras2lwtnn)

## Produce parametrization files

Follow instructions from [FCSParametrization](https://gitlab.cern.ch/atlas-simulation-fastcalosim/FCSParametrization) to produce param files.

NOTE: Use submission scripts available in this repository under ```scripts_to_produce_param_files/```. First run ```runCreate.py``` to produce param files for each particle individually, then run ```runMerge.py``` to merge all particles into a single param file. Even if only one particle is needed, the second script needs to be run since it will merge param files for each eta bin to a single param file.

NOTE: If you need to, for a given particle, update the version of the network to be used or the eta range in which it should be used, please update the appropriate lines in TFCSAnalyzerHelpers.cxx which can be found in the [FastCaloSimAnalyzer](https://gitlab.cern.ch/atlas-simulation-fastcalosim/FastCaloSimAnalyzer/) package.

## Produce validation plots

Usually, one would like to compare the performance of FCS/FCGan using the derived extrapolation weights to a FCS/FCGan version where those extrapolation weights were not used (or even Geant4). For that, one needs first to produce xAODs (on the grid) to then produce some comparison plots.

### Produce xAODs

Please clone the [FCS-sample-production](https://gitlab.cern.ch/jbeirer/FCS-sample-production) repository. We will be needed what is located within the ```GridProduction/``` folder.

If planning to use a local copy of athena, please run the following lines from the build directory associated to such a locally compiled athena version:

```
export DESTDIR=/afs/cern.ch/user/j/jbossios/work/public/FastCaloSim/Simulate/GridProduction/FCS-sample-production/LocalAthenaDir/usr/WorkDir/21.0.130
make && make -k install/fast
```

Then, copy the following scripts available under the ```scripts_to_produce_or_merge_xAODs/``` folder within this repository to the ```run/``` folder within the ```GridProduction/``` folder of the FCS-sample-production package:

runSimGrid.py
launchSimGrid.py
Setup.sh

Then, copy the ```runGrid_FCS_NTUP_G4FastCalo.sh``` to the ```GridProduction/FCS-sample-production/GridProduction/simFlavours/``` folder of the FCS-sample-production package.

Run the setup script:

```
Setup.sh
```

Finally, in the ```launchSimGrid.py``` script, provide your CERN username with the ```USER``` variable and the corresponding information in the ```PARAM_FILES``` dict, and run it:

```
python launchSimGrid.py
```

### Make plots

Clone the [CompareSimulations21](https://gitlab.cern.ch/atlas-simulation-fastcalosim/CompareSimulations21) repository and follow instructions therein.

Copy the following files from the ```scripts_to_make_plots/``` folder in this repository to the ```run/``` directory of the ```CompareSimulations21``` package.

From the ```run/``` directory, create the necessary configuration files with the ```create_configs.py``` script and produce plots with the ```run_Jona.py``` script.
