#!/bin/bash

USER=$1
PID=$2
MIN_ENERGY=$3
MAX_ENERGY=$4
MIN_ETA=$5
MAX_ETA=$6
nEVENTS=$7
nJOBS=$8
DSID=${9}
BASE_PATH_TO_LOCAL_BINARIES=${10}
ADD_STRING=${11}
STANDARD_RECO=${12}
PILE_UP=${13}
RANDOM_SEED=${14}
SYMMETRIC_ETA=${15}
NUMBER_CORES=${16}
REQUESTED_MEMORY=${17}
PARAM_NAME=${18}
PATH_TO_PARAM_FILE=${19}
zv=0

if [[ $STANDARD_RECO == 'True' && $PILE_UP == 'True' ]]; then
	echo "Error: Standard reco and pile up can not be activated at the same time."
	exit 1
fi

#Here you should set the base directory of the grid production
#BASEDIR=$HOME/FastCaloSim/FCS-sample-production/GridProduction
BASEDIR=/afs/cern.ch/user/j/jbossios/work/public/FastCaloSim/R22_xAODproduction/FCS-sample-production/GridProduction # Jona

#time stamp ensures unique name
now=$(date +'%d_%m_%Y_%S') 


if [[ $MIN_ENERGY == $MAX_ENERGY ]]; then
	ENERGY_STRING=E${MIN_ENERGY}
else
	ENERGY_STRING=E${MIN_ENERGY}_${MAX_ENERGY}
fi

if [[ ${MAX_ETA} < ${MIN_ETA} ]]; then
	echo "Error. MAX_ETA < MIN_ETA"
	exit 1
fi

# For RUN 3, the unofficial evgen job config names should start with mcXX, else you will
# run into problems (see https://gitlab.cern.ch/atlas/athena/-/blob/22.0/Generators/EvgenJobTransforms/share/skel.GENtoEVGEN.py)

if [[ $SYMMETRIC_ETA == 'True' ]]; then
	JOB_CONFIG_NAME="mcXX.PG_pid${PID}_E${MIN_ENERGY}_${MAX_ENERGY}_disj_eta_m${MAX_ETA}_m${MIN_ETA}_${MIN_ETA}_${MAX_ETA}_zv_${zv}.py"
	outDS="user.${USER}.mc20_13TeV.Run3_FullG4MT_Sim_pid${PID}_E${MIN_ENERGY}_${MAX_ENERGY}_disj_eta_m${MAX_ETA}_m${MIN_ETA}_${MIN_ETA}_${MAX_ETA}_zv_${zv}${ADD_STRING}_${now}"
	retrievalFolderName="pid${PID}_${ENERGY_STRING}_eta_m${MAX_ETA}_m${MIN_ETA}_${MIN_ETA}_${MAX_ETA}"
elif [[ ${MIN_ETA} < 0 && ${MAX_ETA} < 0 ]]; then
    JOB_CONFIG_NAME="mcXX.PG_pid${PID}_E${MIN_ENERGY}_${MAX_ENERGY}_eta_m${MIN_ETA#-}_m${MAX_ETA#-}_zv_${zv}.py"
	outDS="user.${USER}.mc20_13TeV.Run3_FullG4MT_Sim_pid${PID}_${ENERGY_STRING}_eta_m${MIN_ETA#-}_m${MAX_ETA#-}_zv_${zv}${ADD_STRING}_${now}"
	retrievalFolderName="pid${PID}_${ENERGY_STRING}_eta_m${MIN_ETA#-}_m${MAX_ETA#-}"
elif [[ ${MIN_ETA} < 0 && ${MAX_ETA} > 0 ]]; then
    JOB_CONFIG_NAME="mcXX.PG_pid${PID}_E${MIN_ENERGY}_${MAX_ENERGY}_eta_m${MIN_ETA#-}_${MAX_ETA}_zv_${zv}.py"
	outDS="user.${USER}.mc20_13TeV.Run3_FullG4MT_Sim_pid${PID}_${ENERGY_STRING}_eta_m${MIN_ETA#-}_${MAX_ETA}_zv_${zv}${ADD_STRING}_${now}"
	retrievalFolderName="pid${PID}_${ENERGY_STRING}_eta_m${MIN_ETA#-}_${MAX_ETA}"
elif [[ ${MIN_ETA} > 0 && ${MAX_ETA} > 0 ]]; then
	JOB_CONFIG_NAME="mcXX.PG_pid${PID}_E${MIN_ENERGY}_${MAX_ENERGY}_eta_${MIN_ETA}_${MAX_ETA}_zv_${zv}.py"
	outDS="user.${USER}.mc20_13TeV.Run3_FullG4MT_Sim_pid${PID}_${ENERGY_STRING}_eta_${MIN_ETA}_${MAX_ETA}_zv_${zv}${ADD_STRING}_${now}"
	retrievalFolderName="pid${PID}_${ENERGY_STRING}_eta_${MIN_ETA}_${MAX_ETA}"
fi


echo "Running G4 param input sample configuration! "
echo " "
echo "Splitting up task over ${nEVENTS} events in ${nJOBS} jobs with $((nEVENTS / nJOBS)) events each! Running with the following parameters:"
echo "Number of cores: ${NUMBER_CORES}"
echo "Requested memory: ${REQUESTED_MEMORY}"
echo "PID: ${PID}"
echo "energy: $ENERGY_STRING"
echo "eta: m${MAX_ETA}_m${MIN_ETA}_${MIN_ETA}_${MAX_ETA}"
echo "Using seed: ${RANDOM_SEED}"
echo "outDS will be: "
echo $outDS

# Create files to retrieve output once jobs are done
mkdir -p ../sampleRetrieval/Run3_FullG4MT && mkdir -p ../sampleRetrieval/Run3_FullG4MT/$(date +'%Y-%m-%d') && cd ../sampleRetrieval/Run3_FullG4MT/$(date +'%Y-%m-%d')

# Saves all rucio download commands in downloadOutput.sh
echo "rucio download ${outDS}_EXT0" >> downloadOutput.sh
echo "rucio download ${outDS}_EXT1" >> downloadOutput.sh
echo " " >> downloadOutput.sh

# Saves commands to organize xAODs and Ntuples in cleaner directory structure to createDirStructure.sh
echo "mkdir -p ${retrievalFolderName} && mkdir -p ${retrievalFolderName}/NTUP && mkdir -p ${retrievalFolderName}/xAOD && mv ${outDS}_EXT0/* ${retrievalFolderName}/xAOD && mv ${outDS}_EXT1/* ${retrievalFolderName}/NTUP" >> createDirStructure.sh
echo "rm -rf ${outDS}_EXT0 && rm -rf ${outDS}_EXT1" >> createDirStructure.sh
echo " " >> createDirStructure.sh

# Note: we split the commands into downloadOutput and createDirStructure, so that we can run downloadOutput.sh multiple files and some files already exist locally, they do not need to be re-downloaded. This is useful in case you submit a large batch of jobs and want to download the results before all jobs are done.

cd $BASEDIR/run
echo "To retrieve output container source Run3_FullG4MT/retrieveOutput.sh"

#create job option file to upload to the grid (will be deleted once job is submitted)
echo "include(\"ParticleGun_FastCalo_Config_RUN3.py\")" > ${JOB_CONFIG_NAME}

#do not use the MC15JobOptions directory here as this will take the standard config file!!!
BASE_PATH_TO_JOB_OPTION_FILE=$BASEDIR/ParticleGunJOs/customJO/
BASE_PATH_TO_CUSTOM_MERGE_FILE=$BASEDIR/helperScripts/



printf "\n ********************* Creating a TAR ball for uploading to the grid with the following files: ********************* \n"

#Create submission TAR ball with files rqeuired for running on grid
#Initial TAR ball is uncompressed so that we can still ADD_STRING files later
TAR_BALL_NAME=inputFiles.tar
tar -cvf ${TAR_BALL_NAME}  ${JOB_CONFIG_NAME} -C ${BASE_PATH_TO_JOB_OPTION_FILE} ParticleGun_FastCalo_Config_RUN3.py -C ${BASE_PATH_TO_CUSTOM_MERGE_FILE} customMerge_Run3.py 

if [[ $BASE_PATH_TO_LOCAL_BINARIES != '' ]]; then
	#Add binaries to TAR ball
	tar rvf ${TAR_BALL_NAME} -C ${BASE_PATH_TO_LOCAL_BINARIES} .
	COMP_COMMAND=--noCompile
else 
	COMP_COMMAND=''
fi

## TemporaryJona
#echo "PATH_TO_PARAM_FILE:"
#echo $PATH_TO_PARAM_FILE # OK
#echo "PARAM_NAME"
#echo $PARAM_NAME

# Jona
#Add param file to TAR ball
BASE_PATH_TO_LOCAL_PARAM_FILE=${PATH_TO_PARAM_FILE%"${PARAM_NAME}.root"}
tar rvf $TAR_BALL_NAME -C $BASE_PATH_TO_LOCAL_PARAM_FILE ${PARAM_NAME}.root
#Overwrite path to param file to simply name.root for grid submission
PATH_TO_PARAM_FILE=${PARAM_NAME}.root

## Jona
EVNT_FILE_NAME='mc16_13TeV.pid'${PID}'.E'${MIN_ENERGY}'.eta_m'${MAX_ETA}'_m'${MIN_ETA}'_'${MIN_ETA}'_'${MAX_ETA}'_zv_'${zv}'.merged_default.EVNT.pool'
BASE_PATH_TO_LOCAL_EVNT_FILE="/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/Simulate/EVNT_Files/pid_${PID}/E${MIN_ENERGY}/eta_m"${MAX_ETA}"_m"${MIN_ETA}"_"${MIN_ETA}"_"${MAX_ETA}"/zv_0/"
tar rvf $TAR_BALL_NAME -C $BASE_PATH_TO_LOCAL_EVNT_FILE ${EVNT_FILE_NAME}.root

## Temporary Jona
#echo "BASE_PATH_TO_LOCAL_EVNT_FILE:"
#echo $BASE_PATH_TO_LOCAL_EVNT_FILE
#echo "PATH_TO_PARAM_FILE"
#echo $PATH_TO_PARAM_FILE # OK
#echo "EVNT_FILE_NAME:"
#echo $EVNT_FILE_NAME  # NOT OK

#echo "nEVENTS:"
#echo $nEVENTS
#echo "nJOBS:"
#echo $nJOBS

#echo "RANDOM_SEED:"
#echo $RANDOM_SEED

#Compress TAR ball
gzip inputFiles.tar

export ALRB_CONT_SETUPFILE=/srv/setup.sh

#Use standard reco to activate noise, cross talk and activate vertex smearing in simulation
#To remove vertex smearing: add --preExec "EVNTtoHITS:from G4AtlasApps.SimFlags import simFlags;simFlags.VertexFromCondDB.set_Value_and_Lock(False)" to Sim_tf
#WARNING: Running with pile-up has not been tested for Run3

if [[ $STANDARD_RECO == 'True' ]]; then

	pathena $COMP_COMMAND --nCore $NCORES --inTarBall $TAR_BALL_NAME.gz --split $nJOBS --skipScout --mergeOutput --mergeScript="customMerge_Run3.py -o %OUT -i %IN" --trf '

	Gen_tf.py \
	--ecmEnergy=13000 					\
	--firstEvent=1 						\
	--maxEvents='$((nEVENTS / nJOBS))' 	\
	--outputEVNTFile=tmp.EVNT.pool.root \
	--randomSeed='${RANDOM_SEED}' 		\
	--jobConfig .						\

	Sim_tf.py \
	--simulator="FullG4MT"	 			\
	--randomSeed='${RANDOM_SEED}' 		\
	--inputEVNTFile=tmp.EVNT.pool.root 	\
	--maxEvents='$((nEVENTS / nJOBS))' 	\
	--preInclude "EVNTtoHITS:SimulationJobOptions/preInclude.BeamPipeKill.py" "EVNTtoHITS:ISF_FastCaloSimParametrization/ISF_FastCaloSimParametrization_SimPreInclude.py" \
	--postInclude "all:PyJobTransforms/UseFrontier.py" "EVNTtoHITS:ISF_FastCaloSimParametrization/ISF_FastCaloSimParametrization_SimPostInclude_1mm.py" \
	--postExec "topSeq.BeamEffectsAlg.GenEventManipulators = [getPublicTool(\"GenEventValidityChecker\")];from AthenaCommon.CfgGetter import getPublicTool;validTruthStrat=getPublicTool(\"ISF_ValidationTruthStrategy\");validTruthStrat.Regions=[3];validTruthStrat.ParentMinP=150;ServiceMgr.ISF_MC15aPlusTruthService.TruthStrategies = [ validTruthStrat ];from AthenaCommon.AppMgr import ToolSvc;ToolSvc.ISF_EntryLayerToolMT.ParticleFilters=[]" \
	--outputHITSFile=tmp.HITS.pool.root \
	--physicsList="FTFP_BERT_ATL_VALIDATION" 		\
	--truthStrategy="MC15aPlus" 		\
	--conditionsTag "default:OFLCOND-MC21-SDR-RUN3-05" 		\
	--geometryVersion="default:ATLAS-R3S-2021-03-00-00_VALIDATION" 	\
	--DataRunNumber="410000"; 							\

	Reco_tf.py \
	--inputHITSFile=tmp.HITS.pool.root  \
	--outputESDFile=tmp.ESD.pool.root	\
	--outputAODFile=%OUT.xAOD.pool.root	\
	--maxEvents='$((nEVENTS / nJOBS))' 	\
	--preExec "rec.doTrigger=False;"	\
	--autoConfiguration="everything";	\

	FCS_Ntup_tf.py \
	--maxEvents='$((nEVENTS / nJOBS))' 	\
	--inputESDFile=tmp.ESD.pool.root 	\
	--outputNTUP_FCSFile=%OUT.calohit.FCS_NTUP.root \
	--doG4Hits="true" \
	--doClusterInfo="true" \
	--NTruthParticles=-1' \
	--outDS $outDS 

elif [[ $PILE_UP == 'True' ]]; then

	#Pile-up input 
	INMINBIASLOW="mc16_13TeV:mc16_13TeV.361238.Pythia8EvtGen_A3NNPDF23LO_minbias_inelastic_low.simul.HITS.e4981_s3087_s3111"
	INMINBIASHIGH="mc16_13TeV:mc16_13TeV.361239.Pythia8EvtGen_A3NNPDF23LO_minbias_inelastic_high.simul.HITS.e4981_s3087_s3111"

	pathena $COMP_COMMAND --nCore $NUMBER_CORES --memory $REQUESTED_MEMORY --inTarBall $TAR_BALL_NAME.gz --split $nJOBS --skipScout --mergeOutput --mergeScript="customMerge_Run3.py -o %OUT -i %IN" --trf '

	Gen_tf.py \
	--ecmEnergy=13000 					\
	--firstEvent=1 						\
	--maxEvents='$((nEVENTS / nJOBS))' 	\
	--outputEVNTFile=tmp.EVNT.pool.root \
	--randomSeed='${RANDOM_SEED}' 		\
	--jobConfig .						\

	Sim_tf.py \
	--simulator="FullG4MT"	 			\
	--randomSeed='${RANDOM_SEED}' 		\
	--inputEVNTFile=tmp.EVNT.pool.root 	\
	--maxEvents='$((nEVENTS / nJOBS))' 	\
	--preInclude "EVNTtoHITS:SimulationJobOptions/preInclude.BeamPipeKill.py" "EVNTtoHITS:ISF_FastCaloSimParametrization/ISF_FastCaloSimParametrization_SimPreInclude.py" \
	--postInclude "all:PyJobTransforms/UseFrontier.py" "EVNTtoHITS:ISF_FastCaloSimParametrization/ISF_FastCaloSimParametrization_SimPostInclude_1mm.py" \
	--postExec "topSeq.BeamEffectsAlg.GenEventManipulators = [getPublicTool(\"GenEventValidityChecker\")];from AthenaCommon.CfgGetter import getPublicTool;validTruthStrat=getPublicTool(\"ISF_ValidationTruthStrategy\");validTruthStrat.Regions=[3];validTruthStrat.ParentMinP=150;ServiceMgr.ISF_MC15aPlusTruthService.TruthStrategies = [ validTruthStrat ];from AthenaCommon.AppMgr import ToolSvc;ToolSvc.ISF_EntryLayerToolMT.ParticleFilters=[]" \
	--outputHITSFile=tmp.HITS.pool.root \
	--physicsList="FTFP_BERT_ATL_VALIDATION" 		\
	--truthStrategy="MC15aPlus" 		\
	--conditionsTag "default:OFLCOND-MC21-SDR-RUN3-05" 		\
	--geometryVersion="default:ATLAS-R3S-2021-03-00-00_VALIDATION" 	\
	--DataRunNumber="410000"; 						\

	Reco_tf.py \
	--inputHITSFile=tmp.HITS.pool.root   \
	--inputLowPtMinbiasHitsFile=%LOMBIN  \
	--inputHighPtMinbiasHitsFile=%HIMBIN \
	--outputESDFile=tmp.ESD.pool.root	 \
	--outputAODFile=%OUT.xAOD.pool.root	 \
	--maxEvents='$((nEVENTS / nJOBS))' 	 \
	--digiSteeringConf="StandardSignalOnlyTruth" \
	--numberOfCavernBkg=0 \
	--numberOfHighPtMinBias=0.2595392 \
	--numberOfLowPtMinBias=99.2404608 \
	--pileupFinalBunch=6 \
	--digiSeedOffset1 %RNDM:100 \
	--digiSeedOffset2 %RNDM:100 \
	--jobNumber %RNDM:0 \
	--preInclude "HITtoRDO:Digitization/ForceUseOfPileUpTools.py,SimulationJobOptions/preInlcude.PileUpBunchTrainsMC16c_2017_Config1.py,RunDependentSimData/configLumi_run310000.py" \
	--postInclude "default:PyJobTransforms/UseFrontier.py" \
	--preExec "all:rec.Commissioning.set_Value_and_Lock(True);from AthenaCommon.BeamFlags import jobproperties;jobproperties.Beam.numberOfCollisions.set_Value_and_Lock(20.0);from LArROD.LArRODFlags import larRODFlags;larRODFlags.NumberOfCollisions.set_Value_and_Lock(20);larRODFlags.nSamples.set_Value_and_Lock(4);larRODFlags.doOFCPileupOptimization.set_Value_and_Lock(True);larRODFlags.firstSample.set_Value_and_Lock(0);larRODFlags.useHighestGainAutoCorr.set_Value_and_Lock(True); from LArDigitization.LArDigitizationFlags import jobproperties;jobproperties.LArDigitizationFlags.useEmecIwHighGain.set_Value_and_Lock(False)" "all:from InDetRecExample.InDetJobProperties import InDetFlags; InDetFlags.doSlimming.set_Value_and_Lock(False)" "ESDtoAOD:from TriggerJobOpts.TriggerFlags import TriggerFlags;TriggerFlags.AODEDMSet.set_Value_and_Lock(\"AODSLIM\");" \
	--postExec "all:CfgMgr.MessageSvc().setError+=[\"HepMcParticleLink\"]" "ESDtoAOD:fixedAttrib=[s if \"CONTAINER_SPLITLEVEL = "99"\" not in s else \"\" for s in svcMgr.AthenaPoolCnvSvc.PoolAttributes];svcMgr.AthenaPoolCnvSvc.PoolAttributes=fixedAttrib" \
	--runNumber=410000 \
	--steering="doRDO_TRIG" \
	--triggerConfig="RDOtoRDOTrigger=MCRECO:DBF:TRIGGERDBMC:2232,86,278"  \
	--autoConfiguration="everything";	 \

	FCS_Ntup_tf.py \
	--maxEvents='$((nEVENTS / nJOBS))' 	\
	--inputESDFile=tmp.ESD.pool.root 	\
	--outputNTUP_FCSFile=%OUT.calohit.FCS_NTUP.root \
	--doG4Hits="true" \
	--doClusterInfo="true" \
	--NTruthParticles=-1' \
	--outDS $outDS --lowMinDS $INMINBIASLOW --highMinDS $INMINBIASHIGH --nFiles 50 --nLowMin 5 --nHighMin 5 

else

	pathena $COMP_COMMAND --nCore $NUMBER_CORES --memory $REQUESTED_MEMORY --inTarBall $TAR_BALL_NAME.gz --split $nJOBS --skipScout --mergeOutput --mergeScript="customMerge_Run3.py -o %OUT -i %IN" --trf '

	Sim_tf.py \
	--simulator="ATLFAST3MT"	 	\
	--randomSeed='${RANDOM_SEED}' 		\
	--inputEVNTFile='${EVNT_FILE_NAME}'.root 	\
	--maxEvents='$((nEVENTS / nJOBS))' 	\
	--preInclude "EVNTtoHITS:SimulationJobOptions/preInclude.BeamPipeKill.py" \
	--postInclude "default:PyJobTransforms/UseFrontier.py" \
	--preExec "sim:simFlags.TightMuonStepping=True; simFlags.VertexFromCondDB.set_Value_and_Lock(True); from ISF_FastCaloSimServices.ISF_FastCaloSimJobProperties import ISF_FastCaloSimFlags; ISF_FastCaloSimFlags.ParamsInputFilename=\"'${PATH_TO_PARAM_FILE}'\"" \
	--outputHITSFile=tmp.HITS.pool.root     \
	--physicsList="FTFP_BERT_ATL" 		\
	--truthStrategy="MC15aPlus" 		\
	--conditionsTag "default:OFLCOND-MC21-SDR-RUN3-07"      \
	--geometryVersion="default:ATLAS-R3S-2021-03-00-00" 	\
	--DataRunNumber="410000"; 				\

	Reco_tf.py \
	--inputHITSFile=tmp.HITS.pool.root 	\
	--outputESDFile=tmp.ESD.pool.root 	\
	--outputAODFile=%OUT.xAOD.pool.root     \
	--maxEvents='$((nEVENTS / nJOBS))' 	\
	--conditionsTag "default:OFLCOND-MC21-SDR-RUN3-05"      \
	--geometryVersion="default:ATLAS-R3S-2021-03-00-00" 	\
	--DataRunNumber="410000" 				\
	--preExec "from RecExConfig.RecFlags import rec;rec.doTrigger=False" \
	--autoConfiguration="everything";' \
	--outDS $outDS 

fi

#Clean up temporary files used to generate TAR ball and TAR ball itself
rm ${JOB_CONFIG_NAME}
rm inputFiles.tar.gz

