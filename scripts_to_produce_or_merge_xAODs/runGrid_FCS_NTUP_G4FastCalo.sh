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
PARAM_NAME=${16}
PATH_TO_PARAM_FILE=${17}
LOCAL_PARAM_BOOL=${18}
TUNE_VERSION=${19} #data tune stuff
zv=0

if [[ $STANDARD_RECO == 'True' && $PILE_UP == 'True' ]]; then
	echo "Error: Standard reco and pile up can not be activated at the same time."
	exit 1
fi

#Here you should set the base directory of the grid production
#BASEDIR=$HOME/FastCaloSim/FCS-sample-production/GridProduction
BASEDIR=/afs/cern.ch/user/j/jbossios/work/public/FastCaloSim/Simulate/GridProduction/FCS-sample-production/GridProduction # Jona

#time stamp ensures unique name
now=$(date +'%d%m%Y_%S') 

if [[ $MIN_ENERGY == $MAX_ENERGY ]]; then
	outDS="user.${USER}.mc16_13TeV.${DSID}.FCS_NTUP_G4FastCalo_Sim_pid${PID}_E${MIN_ENERGY}_eta_m${MAX_ETA}_m${MIN_ETA}_${MIN_ETA}_${MAX_ETA}_zv_${zv}${ADD_STRING}_${now}"
	retrievalFolderName="pid${PID}_E${MIN_ENERGY}_eta_m${MAX_ETA}_m${MIN_ETA}_${MIN_ETA}_${MAX_ETA}"

else
	outDS="user.${USER}.mc16_13TeV.${DSID}.FCS_NTUP_G4FastCalo_Sim_pid${PID}_E${MIN_ENERGY}_${MAX_ENERGY}_eta_m${MAX_ETA}_m${MIN_ETA}_${MIN_ETA}_${MAX_ETA}_zv_${zv}${ADD_STRING}_${now}"
	retrievalFolderName="pid${PID}_E${MIN_ENERGY}_${MAX_ENERGY}_eta_m${MAX_ETA}_m${MIN_ETA}_${MIN_ETA}_${MAX_ETA}"
fi


if [[ ${MAX_ETA} < ${MIN_ETA} ]]; then
	echo "Error. MAX_ETA < MIN_ETA"
	exit 1
fi

if [[ $SYMMETRIC_ETA == 'True' ]]; then
	JOB_CONFIG_NAME="MC15.${DSID}.PG_pid${PID}_E${MIN_ENERGY}_${MAX_ENERGY}_disj_eta_m${MAX_ETA}_m${MIN_ETA}_${MIN_ETA}_${MAX_ETA}_zv_${zv}.py"
elif [[ ${MIN_ETA} < 0 && ${MAX_ETA} < 0 ]]; then
    JOB_CONFIG_NAME="MC15.${DSID}.PG_pid${PID}_E${MIN_ENERGY}_${MAX_ENERGY}_eta_m${MIN_ETA#-}_m${MAX_ETA#-}_zv_${zv}.py"
elif [[ ${MIN_ETA} < 0 && ${MAX_ETA} > 0 ]]; then
    JOB_CONFIG_NAME="MC15.${DSID}.PG_pid${PID}_E${MIN_ENERGY}_${MAX_ENERGY}_eta_m${MIN_ETA#-}_${MAX_ETA}_zv_${zv}.py"
elif [[ ${MIN_ETA} > 0 && ${MAX_ETA} > 0 ]]; then
	JOB_CONFIG_NAME="MC15.${DSID}.PG_pid${PID}_E${MIN_ENERGY}_${MAX_ENERGY}_eta_${MIN_ETA}_${MAX_ETA}_zv_${zv}.py"
fi


echo "Running FCSV2 with G4 param input sample configuration! "
echo " "
echo "Splitting up task over ${nEVENTS} events in ${nJOBS} jobs with $((nEVENTS / nJOBS)) events each! Running with the following parameters:"
echo "PID: ${PID}"
echo "energy: E${MIN_ENERGY}_${MAX_ENERGY}"
echo "eta: m${MAX_ETA}_m${MIN_ETA}_${MIN_ETA}_${MAX_ETA}"
echo "DSID: ${DSID}"
echo "Using seed: ${RANDOM_SEED}"
echo "outDS will be: "
echo $outDS

#create file to retrieve output once jobs are done
mkdir -p ../sampleRetrieval/FCS_NTUP_G4FastCalo && mkdir -p ../sampleRetrieval/FCS_NTUP_G4FastCalo/$(date +'%Y-%m-%d') && cd ../sampleRetrieval/FCS_NTUP_G4FastCalo/$(date +'%Y-%m-%d')
echo "rucio download ${outDS}_EXT0" >> retrieveOutput.sh
echo "rucio download ${outDS}_EXT1" >> retrieveOutput.sh
echo "mkdir -p ${retrievalFolderName} && mkdir -p ${retrievalFolderName}/NTUP && mkdir -p ${retrievalFolderName}/xAOD && mv ${outDS}_EXT0/* ${retrievalFolderName}/xAOD && mv ${outDS}_EXT1/* ${retrievalFolderName}/NTUP" >> retrieveOutput.sh
echo "rm -rf ${outDS}_EXT0 && rm -rf ${outDS}_EXT1" >> retrieveOutput.sh
echo " " >> retrieveOutput.sh


#hard-coded data tuning stuff
if [[ $STANDARD_RECO == 'True' ]]; then
	echo "source data/PhotonTuning/NTuples/createNTuple.sh ${outDS}_EXT0 FCSV2 withNoise ${PID} m${MAX_ETA}_m${MIN_ETA}_${MIN_ETA}_${MAX_ETA} ${MIN_ENERGY} ${TUNE_VERSION} origin noPileUp" >> retrieveDataTuningJobs.sh
elif [[ $PILE_UP == 'True' ]]; then
	echo "source data/PhotonTuning/NTuples/createNTuple.sh ${outDS}_EXT0 FCSV2 withNoise ${PID} m${MAX_ETA}_m${MIN_ETA}_${MIN_ETA}_${MAX_ETA} ${MIN_ENERGY} ${TUNE_VERSION} origin pileUp" >> retrieveDataTuningJobs.sh
else
	echo "source data/PhotonTuning/NTuples/createNTuple.sh ${outDS}_EXT0 FCSV2 noNoise ${PID} m${MAX_ETA}_m${MIN_ETA}_${MIN_ETA}_${MAX_ETA} ${MIN_ENERGY} ${TUNE_VERSION} origin noPileUp" >>retrieveDataTuningJobs.sh
fi

cd $BASEDIR/run
echo "To retrieve output container source FCS_NTUP_G4FastCalo/retrieveOutput.sh"

#create job option file to upload to the grid (will be deleted once job is submitted)
echo "include(\"ParticleGun_FastCalo_Config.py\")" > ${JOB_CONFIG_NAME}

#do not use the MC15JobOptions directory here as this will take the standard config file!!!
BASE_PATH_TO_JOB_OPTION_FILE=$BASEDIR/ParticleGunJOs/customJO/
BASE_PATH_TO_CUSTOM_MERGE_FILE=$BASEDIR/helperScripts/



printf "\n ********************* Creating a TAR ball for uploading to the grid with the following files: ********************* \n"

#Create submission TAR ball with files rqeuired for running on grid
#Initial TAR ball is uncompressed so that we can still ADD_STRING files later
TAR_BALL_NAME=inputFiles.tar
tar -cvf ${TAR_BALL_NAME}  ${JOB_CONFIG_NAME} -C ${BASE_PATH_TO_JOB_OPTION_FILE} ParticleGun_FastCalo_Config.py -C ${BASE_PATH_TO_CUSTOM_MERGE_FILE} customMerge.py 

if [[ $BASE_PATH_TO_LOCAL_BINARIES != '' ]]; then
	#Add binaries to TAR ball
	tar rvf ${TAR_BALL_NAME} -C ${BASE_PATH_TO_LOCAL_BINARIES} .
	COMP_COMMAND=--noCompile
else 
	COMP_COMMAND=''
fi

if [[ $LOCAL_PARAM_BOOL == 'True' ]]; then
	#Add param file to TAR ball
	#BASE_PATH_TO_LOCAL_PARAM_FILE=${PATH_TO_PARAM_FILE%"${PARAM_NAME}.root"}
	BASE_PATH_TO_LOCAL_PARAM_FILE=${PATH_TO_PARAM_FILE} # Jona
	tar rvf $TAR_BALL_NAME -C $BASE_PATH_TO_LOCAL_PARAM_FILE ${PARAM_NAME}.root
	#Overwrite path to param file to simply name.root for grid submission
	PATH_TO_PARAM_FILE=${PARAM_NAME}.root
fi

## Jona
EVNT_FILE_NAME='mc16_13TeV.pid'${PID}'.E'${MIN_ENERGY}'.eta_m'${MAX_ETA}'_m'${MIN_ETA}'_'${MIN_ETA}'_'${MAX_ETA}'_zv_'${zv}'.merged_default.EVNT.pool'
BASE_PATH_TO_LOCAL_EVNT_FILE="/eos/atlas/atlascerngroupdisk/proj-simul/AF3_Run3/Jona/Simulate/EVNT_Files/pid_${PID}/E${MIN_ENERGY}/eta_m"${MAX_ETA}"_m"${MIN_ETA}"_"${MIN_ETA}"_"${MAX_ETA}"/zv_0/"
tar rvf $TAR_BALL_NAME -C $BASE_PATH_TO_LOCAL_EVNT_FILE ${EVNT_FILE_NAME}.root

echo "LOCAL_PARAM_BOOL"
echo $LOCAL_PARAM_BOOL
echo "PATH_TO_PARAM_FILE"
echo $PATH_TO_PARAM_FILE

#Compress TAR ball
gzip inputFiles.tar

export ALRB_CONT_SETUPFILE=/srv/setup.sh


#Use standard reco to activate noise, cross talk etc.
#Use pile-up to additionally activate pile-up
#To remove vertex smearing: add --preExec "EVNTtoHITS:from G4AtlasApps.SimFlags import simFlags;simFlags.VertexFromCondDB.set_Value_and_Lock(False)" to Sim_tf
#-Sim debug: -postExec "from AthenaCommon.AppMgr import ServiceMgr; ServiceMgr.ISF_FastCaloSimSvcV2.OutputLevel=VERBOSE; ServiceMgr.ISF_FastCaloSimV2ParamSvc.OutputLevel=VERBOSE; ServiceMgr.ToolSvc.FastCaloSimCaloExtrapolation.OutputLevel=DEBUG; ServiceMgr.MessageSvc.debugLimit = 20000000;ServiceMgr.MessageSvc.verboseLimit = 20000000; ServiceMgr.MessageSvc.infoLimit = 10000000;" for  \
#Note to myself: spaces after \ are forbidden and will result in crashes
#Tadej: Pile-up should be run with 
if [[ $STANDARD_RECO == 'True' ]]; then

	pathena $COMP_COMMAND --inTarBall $TAR_BALL_NAME.gz --split $nJOBS --skipScout --mergeOutput --mergeScript="customMerge.py -o %OUT -i %IN" --trf '
		Generate_tf.py \
		--jobConfig='${JOB_CONFIG_NAME}' 	\
		--ecmEnergy=13000 					\
		--firstEvent=1 						\
		--maxEvents='$((nEVENTS / nJOBS))' 	\
		--outputEVNTFile=tmp.EVNT.pool.root \
		--randomSeed='${RANDOM_SEED}' 		\
		--runNumber='${DSID}' 				\

		Sim_tf.py \
		--simulator="G4FastCalo" 			\
		--randomSeed='${RANDOM_SEED}'		\
		--inputEVNTFile=tmp.EVNT.pool.root 	\
		--maxEvents='$((nEVENTS / nJOBS))' 	\
		--preExec "from ISF_FastCaloSimServices.ISF_FastCaloSimJobProperties import ISF_FastCaloSimFlags;ISF_FastCaloSimFlags.ParamsInputFilename=\"'${PATH_TO_PARAM_FILE}'\"" \
		--preInclude "EVNTtoHITS:SimulationJobOptions/preInclude.BeamPipeKill.py" \
		--outputHITSFile=tmp.HITS.pool.root \
		--physicsList="FTFP_BERT_ATL" 		\
		--truthStrategy="MC15aPlus" 		\
		--conditionsTag "default:OFLCOND-MC16-SDR-14" 		\
		--geometryVersion="default:ATLAS-R2-2016-01-00-01" 	\
		--DataRunNumber="284500"; 							\

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
		--outputNTUP_FCSFile=%OUT.calohit.FCS_NTUP_G4FastCalo.root \
		--doG4Hits="true"' \
		--outDS $outDS 

elif [[ $PILE_UP == 'True' ]]; then

	#Pile-up input 
	INMINBIASLOW="mc16_13TeV:mc16_13TeV.361238.Pythia8EvtGen_A3NNPDF23LO_minbias_inelastic_low.simul.HITS.e4981_s3087_s3111"
	INMINBIASHIGH="mc16_13TeV:mc16_13TeV.361239.Pythia8EvtGen_A3NNPDF23LO_minbias_inelastic_high.simul.HITS.e4981_s3087_s3111"

	pathena $COMP_COMMAND --inTarBall $TAR_BALL_NAME.gz --split $nJOBS --skipScout --mergeOutput --mergeScript="customMerge.py -o %OUT -i %IN" --trf '
		Generate_tf.py \
		--jobConfig='${JOB_CONFIG_NAME}' 	\
		--ecmEnergy=13000 					\
		--firstEvent=1 						\
		--maxEvents='$((nEVENTS / nJOBS))' 	\
		--outputEVNTFile=tmp.EVNT.pool.root \
		--randomSeed='${RANDOM_SEED}' 		\
		--runNumber='${DSID}' 				\

		Sim_tf.py \
		--simulator="G4FastCalo" 			\
		--randomSeed='${RANDOM_SEED}'		\
		--inputEVNTFile=tmp.EVNT.pool.root 	\
		--maxEvents='$((nEVENTS / nJOBS))' 	\
		--preExec "from ISF_FastCaloSimServices.ISF_FastCaloSimJobProperties import ISF_FastCaloSimFlags;ISF_FastCaloSimFlags.ParamsInputFilename=\"'${PATH_TO_PARAM_FILE}'\"" \
		--preInclude "EVNTtoHITS:SimulationJobOptions/preInclude.BeamPipeKill.py" \
		--outputHITSFile=tmp.HITS.pool.root \
		--physicsList="FTFP_BERT_ATL" 		\
		--truthStrategy="MC15aPlus" 		\
		--conditionsTag "default:OFLCOND-MC16-SDR-14" 		\
		--geometryVersion="default:ATLAS-R2-2016-01-00-01" 	\
		--DataRunNumber="284500"; 							\

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
		--outputNTUP_FCSFile=%OUT.calohit.FCS_NTUP_G4FastCalo.root \
		--doG4Hits="true"' \
		--outDS $outDS --lowMinDS $INMINBIASLOW --highMinDS $INMINBIASHIGH --nFiles 50 --nLowMin 5 --nHighMin 5 

else

	pathena $COMP_COMMAND --inTarBall $TAR_BALL_NAME.gz --split $nJOBS --skipScout --mergeOutput --mergeScript="customMerge.py -o %OUT -i %IN" --trf '
		Sim_tf.py \
		--simulator="G4FastCalo" 			\
		--randomSeed='${RANDOM_SEED}'		\
		--inputEVNTFile='${EVNT_FILE_NAME}'.root \
		--maxEvents='$((nEVENTS / nJOBS))' 	\
		--preExec "EVNTtoHITS:from G4AtlasApps.SimFlags import simFlags;simFlags.VertexFromCondDB.set_Value_and_Lock(True);" "from ISF_FastCaloSimServices.ISF_FastCaloSimJobProperties import ISF_FastCaloSimFlags;ISF_FastCaloSimFlags.ParamsInputFilename=\"'${PATH_TO_PARAM_FILE}'\"" \
		--preInclude "EVNTtoHITS:SimulationJobOptions/preInclude.BeamPipeKill.py" \
		--outputHITSFile=tmp.HITS.pool.root \
		--physicsList="FTFP_BERT_ATL" 		\
		--truthStrategy="MC15aPlus" 		\
		--conditionsTag "default:OFLCOND-MC16-SDR-14" 		\
		--geometryVersion="default:ATLAS-R2-2016-01-00-01" 	\
		--DataRunNumber="284500"; 							\

		Reco_tf.py \
		--inputHITSFile=tmp.HITS.pool.root 	\
		--outputESDFile=tmp.ESD.pool.root 	\
		--outputAODFile=%OUT.xAOD.pool.root \
		--maxEvents='$((nEVENTS / nJOBS))' 	\
		--conditionsTag "default:OFLCOND-MC16-SDR-14" \
		--geometryVersion="default:ATLAS-R2-2016-01-00-01" \
		--DataRunNumber="284500" \
		--preExec "from RecExConfig.RecFlags import rec;rec.doTrigger=False"\
		--autoConfiguration="everything";' \
		--outDS $outDS 

fi


#Clean up temporary files used to generate TAR ball and TAR ball itself
rm ${JOB_CONFIG_NAME}
rm inputFiles.tar.gz
