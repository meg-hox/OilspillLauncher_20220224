#!/bin/bash
#
# === OilspillLauncher.sh ===
# 
# Required parameters are:
# - the queryID (through -i)
# - the submission string (through -s)
# - the callback url (through -c)
#
# Code refactoring for Zeus performed on: 2020/08/03
# Last change: 2022/02/03, 13.28 by Fabio Viola

APPNAME=$(basename $0)


# Load configuration file
echo -e "\n[$APPNAME] ========== READING CONFIGURATION =========="
echo "[$APPNAME] -- Reading $HOME/OilspillLauncher/oilspillLauncher.conf"
source $HOME/OilspillLauncher/oilspillLauncher.conf
echo "[$APPNAME] -- Reading ${WITOIL_ROOT}/witoil.conf"
source ${WITOIL_ROOT}/witoil.conf

# Set paths
WITOIL_UTILS_PATH=$UTILS_PATH

# Switch from witoil.conf to oilspillLauncher.conf telegram config
TELEGRAM_ENABLED=${TELEGRAM_SIM_ENABLED}
TELEGRAM_CHANNEL=${TELEGRAM_SIM_CHANNEL}
TELEGRAM_TOKEN=${TELEGRAM_SIM_TOKEN}


####################################################
#
# Initial setup
#
####################################################

echo $(date) > lastCall.log

# Set the path for common scripts
source ${WITOIL_UTILS_PATH}/utils.sh


####################################################
#
# send_to_callback
#
####################################################

function send_to_callback {
    f_outcode=$1
    f_callback=$2
    f_message=$3
    curl -F "outcode=${f_outcode}" -F "message=${f_message}" ${f_callback}
    ret_value=$?
    if [ $ret_value -eq 6 ]; then
        #DNS error
        counter=1
        while [ $counter -lt 4 ]; do
            sleep 2
            echo -e "[$APPNAME] -- `date`\tERROR\tDNS error; attempt #${counter}" 1>&2
			if [[ $test == 0 ]] ; then
                curl -F "outcode=${f_outcode}" ${f_callback}
			fi
            ret_value=$?
            if [ $ret_value -ne 6 ]; then
                break;
            fi
            let counter=counter+1
        done
        if [ $counter -eq 4 ]; then
            echo -e "[$APPNAME] -- `date`\tERROR\tDNS error; unable to contact ${f_callback}" 1>&2
                fi
    fi
    return $ret_value
}


####################################################
#
# main
#
####################################################

#Notify 2 "SIM" "Start new simulation..."


queryID=''
subm_string=''
callback_url=''
start_time=`date +'%F %T'`
userName=`whoami`

# set test to 1 to run out of a test environment
test=1

# parse command line arguments
echo -e "\n[$APPNAME] ========== COMMAND LINE ARGUMENTS =========="
echo "[$APPNAME] -- Parsing command line arguments"
while getopts  "i:s:c:" flag
do
  case "$flag" in
        i) queryID=$OPTARG
           ;;
        s) subm_string=$OPTARG
           ;;
        c) callback_url=$OPTARG
           ;;
        :) exit 1
           ;;
        ?) exit 1
           ;;
  esac
done

# Parse submission string.. Values can contain also :., and -
echo "[$APPNAME] -- Parsing submission string"
subm_string=$(echo "${subm_string}" | sed 's/[^A-Za-z0-9_:.,;=\^§-]//g')
echo $subm_string

# Check if callback url is valid
if [ "$callback_url" == "" ]; then
        message=$(echo -e "[$APPNAME] -- `date`\tERROR\tError in retrieving callback URL")
        end_time=`date +'%F %T'`
        echo -e $message
        exit 1
fi

# Check if the query ID is valid
if [ "$queryID" == "" ]; then
        message=$(echo -e "[$APPNAME] -- `date`\tERROR\tError in retrieving queryID")
        end_time=`date +'%F %T'`
        echo -e $message
	if [[ $test == 1 ]] ; then	    
	    send_to_callback -1 ${callback_url} "Error in retrieving queryID"
	fi
        exit 2
fi

# Check if the submission string is valid
if [ "$subm_string" == "" ]; then
        message=$(echo -e "[$APPNAME] -- `date`\tERROR\tError in retrieving submission string")
        end_time=`date +'%F %T'`
        echo -e $message
	if [[ $test == 1 ]] ; then
	    send_to_callback -1 ${callback_url} "Error in submission string"
	fi
        exit 3
fi

# Set work variables
export Id_Dir=$queryID
export DST_HOME_MEDSLIK=/work/opa/${userName}/OILSPILL_DA/out/${Id_Dir}
export MEDSLIK=$DST_HOME_MEDSLIK/witoil
export NCARG_USRRESFILE=$DST_HOME_MEDSLIK/.hluresfile

# BLACK paths
export SRC_HOME_MEDSLIK_BLACK=/users_home/opa/${userName}/witoil/MEDSLIK_II_2.01/
export SRC_MEDSLIK_DATA_BLACK=/work/opa/witoil/witoil-black/DATA

# BALTIC paths
export SRC_HOME_MEDSLIK_BALTIC=/users_home/opa/${userName}/witoil/MEDSLIK_II_2.01/
export SRC_MEDSLIK_DATA_BALTIC=/work/opa/witoil/witoil-baltic/DATA

# GOFS paths
export SRC_HOME_MEDSLIK_GOFS=/users_home/opa/${userName}/witoil/MEDSLIK_II_2.01/
export SRC_MEDSLIK_DATA_GOFS=/work/opa/witoil/witoil-gofs/DATA

# IBI paths
export SRC_HOME_MEDSLIK_IBI=/users_home/opa/${userName}/witoil/MEDSLIK_II_2.01/
export SRC_MEDSLIK_DATA_IBI=/work/opa/witoil/witoil-ibi/DATA

# MED paths
export SRC_HOME_MEDSLIK_MED=/users_home/opa/${userName}/witoil/MEDSLIK_II_2.01/
export SRC_MEDSLIK_DATA_MED=/work/opa/witoil/witoil-med/DATA

# SANIFS paths
export SRC_HOME_MEDSLIK_SANIFS=/users_home/opa/${userName}/witoil/MEDSLIK_II_2.01/
export SRC_MEDSLIK_DATA_SANIFS=/work/opa/witoil/witoil-sanifs/DATA

# GLOB paths
export SRC_HOME_MEDSLIK_GLOB=/users_home/opa/${userName}/witoil/MEDSLIK_II_2.01/
export SRC_MEDSLIK_DATA_GLOB=/work/opa/witoil/witoil-glob/DATA

# DUBAI paths
export SRC_HOME_MEDSLIK_DUBAI=/users_home/opa/${userName}/witoil/MEDSLIK_II_2.01/
export SRC_MEDSLIK_DATA_DUBAI=/work/opa/witoil/witoil-dubai/DATA

# Load modules
echo "[$APPNAME] -- Loading modules"
module load intel19.5/19.5.281 intel19.5/szip/2.1.1 intel19.5/hdf5/1.10.5 intel19.5/netcdf/C_4.7.2-F_4.5.2_CXX_4.3.1


#####################################################
#
# Prepare the environment
#
#####################################################

echo -e "\n[$APPNAME] ========== PREPARING THE ENVIRONMENT =========="

# Clean medslik home before starting
echo "[$APPNAME] -- Creating for $DST_HOME_MEDSLIK"
if [ -d  $DST_HOME_MEDSLIK ];then
  echo "[$APPNAME] -- An old dir already exist I'm deleting old files inside it!"
  rm -rf ${DST_HOME_MEDSLIK}/*
fi
mkdir -p ${DST_HOME_MEDSLIK}

# Read the model requested by the simulation

MODEL=$(echo $subm_string | grep -e "model=[a-zA-Z]*" -o | cut -d "=" -f 2)

if [ $MODEL == "SANIFS" ]; then    
    export SRC_HOME_MEDSLIK=$SRC_HOME_MEDSLIK_SANIFS
    export SRC_MEDSLIK_DATA=$SRC_MEDSLIK_DATA_SANIFS
elif [ $MODEL == "MED" ]; then
    export SRC_HOME_MEDSLIK=$SRC_HOME_MEDSLIK_MED
    export SRC_MEDSLIK_DATA=$SRC_MEDSLIK_DATA_MED
elif [ $MODEL == "BLACKSEA" ]; then
    export SRC_HOME_MEDSLIK=$SRC_HOME_MEDSLIK_BLACK
    export SRC_MEDSLIK_DATA=$SRC_MEDSLIK_DATA_BLACK
elif [ $MODEL == "BALTIC" ]; then
    export SRC_HOME_MEDSLIK=$SRC_HOME_MEDSLIK_BALTIC
    export SRC_MEDSLIK_DATA=$SRC_MEDSLIK_DATA_BALTIC
elif [ $MODEL == "GOFS" ]; then
    export SRC_HOME_MEDSLIK=$SRC_HOME_MEDSLIK_GOFS
    export SRC_MEDSLIK_DATA=$SRC_MEDSLIK_DATA_GOFS
elif [ $MODEL == "IBI" ]; then
    export SRC_HOME_MEDSLIK=$SRC_HOME_MEDSLIK_IBI
    export SRC_MEDSLIK_DATA=$SRC_MEDSLIK_DATA_IBI    
elif [ $MODEL == "GLOB" ]; then
    export SRC_HOME_MEDSLIK=$SRC_HOME_MEDSLIK_GLOB
    export SRC_MEDSLIK_DATA=$SRC_MEDSLIK_DATA_GLOB
elif [ $MODEL == "DUBAI" ]; then
    export SRC_HOME_MEDSLIK=$SRC_HOME_MEDSLIK_DUBAI
    export SRC_MEDSLIK_DATA=$SRC_MEDSLIK_DATA_DUBAI
else
    echo "[$APPNAME] -- Model $MODEL not supported! Exiting..."
    #[MH] Notify error
    Notify 0 "SIM"  "[QueryID: ${queryID:5:4}] ERROR: Model $MODEL not supported!" 
    exit
fi

# Create a copy of medslik folder and create its configuration file
echo "[$APPNAME] -- Requested a simulation with model $MODEL"
cp -r $SRC_HOME_MEDSLIK ${DST_HOME_MEDSLIK}/witoil

echo "MEDSLIK_BASEDIR=$DST_HOME_MEDSLIK/witoil" > $DST_HOME_MEDSLIK/witoil/RUN/mdk2.conf
echo "MEDSLIK_DATA=\${MEDSLIK_BASEDIR}/METOCE_INP" >> $DST_HOME_MEDSLIK/witoil/RUN/mdk2.conf
echo "MEDSLIK_EXE=\${MEDSLIK_BASEDIR}/RUN" >> $DST_HOME_MEDSLIK/witoil/RUN/mdk2.conf

# link currents and winds
echo "[$APPNAME] -- Data will be copied from: $SRC_MEDSLIK_DATA"

for NCFILE in $(ls $SRC_MEDSLIK_DATA/fcst_data/H3k/*.nc) ; do
    ln -s $NCFILE $DST_HOME_MEDSLIK/witoil/METOCE_INP/PREPROC/OCE/
done

for NCFILE in $(ls $SRC_MEDSLIK_DATA/fcst_data/SK1/*.nc) ; do
    ln -s $NCFILE $DST_HOME_MEDSLIK/witoil/METOCE_INP/PREPROC/MET/
done

# Invoking jsonToInput to parse the input
echo "[$APPNAME] -- Invoking jsonToInput.sh..."
bash /users_home/opa/witoil/OilspillLauncher/jsonToInput.sh ${subm_string}
cp env.sh $DST_HOME_MEDSLIK/witoil/

cd $DST_HOME_MEDSLIK
echo "[$APPNAME] -- \$OPTARG value is: $OPTARG"


#####################################################
#
# Start the simulation
#
#####################################################

echo -e "\n[$APPNAME] ========== PREPROCESSING =========="

echo "[$APPNAME] -- Starting the pre-processing phase"

# invoke preproc if the model is glob
if [ $MODEL == "GLOB" ]; then

    # preproc
    # bash $DST_HOME_MEDSLIK/witoil/RUN/preproc.sh $DST_HOME_MEDSLIK/witoil
    bsub -R "span[ptile=1]" -sla SC_SERIAL_witoil -Is -q s_short -app SERIAL_witoil -P 0372 -J globPreproc "/bin/bash  $WITOIL_UTILS_PATH/preproc/preproc-glob.sh $DST_HOME_MEDSLIK/witoil"
    lastCmd=$?
    if [ $lastCmd != 0 ]; then
	#[MH] Notify error
	Notify 0 "SIM"  "[QueryID: ${queryID:5:4}][Model: ${MODEL}] PREPROCESS ERROR: Missing input NetCDF file" 
        send_to_callback -1 $callback_url "Missing input NetCDF file!"
        exit
    fi
    
elif [ $MODEL == "DUBAI" ]; then

    # preproc
    # bash $DST_HOME_MEDSLIK/witoil/RUN/preproc.sh $DST_HOME_MEDSLIK/witoil
    bsub -R "span[ptile=1]" -sla SC_SERIAL_witoil -Is -q s_short -app SERIAL_witoil -P 0372 -J dubaiPreproc "/bin/bash  $WITOIL_UTILS_PATH/preproc/preproc-dubai.sh $DST_HOME_MEDSLIK/witoil"
    lastCmd=$?
    if [ $lastCmd != 0 ]; then
	#[MH] Notify error
	Notify 0 "SIM"  "[QueryID: ${queryID:5:4}][Model: ${MODEL}] PREPROCESS ERROR: Missing input NetCDF file" 
        send_to_callback -1 $callback_url "Missing input NetCDF file!"
        exit
    fi
    
elif [ $MODEL == "MED" ]; then

    # preproc
    # bash $WITOIL_UTILS_PATH/preproc/preproc-med.sh $DST_HOME_MEDSLIK/witoil
    bsub -R "span[ptile=1]" -sla SC_SERIAL_witoil -Is -q s_short -app SERIAL_witoil -P 0372 -J medPreproc "/bin/bash $WITOIL_UTILS_PATH/preproc/preproc-med.sh $DST_HOME_MEDSLIK/witoil"

    lastCmd=$?
    echo $lastCmd
    if [ $lastCmd != 0 ]; then
        echo $lastCmd 
        if [ $MODEL == "MED" ]; then
	    #[MH] Notify error
	    Notify 0 "SIM"  "[QueryID: ${queryID:5:4}][Model: ${MODEL}] PREPROCESS ERROR: Missing input NetCDF file"
            send_to_callback -1 $callback_url "Missing input NetCDF file!"
        fi
        exit
    fi

elif [ $MODEL == "BALTIC" ]; then

    # preproc
    # bash $WITOIL_UTILS_PATH/preproc/preproc-sani.sh $DST_HOME_MEDSLIK/witoil 
    bsub -R "span[ptile=1]" -sla SC_SERIAL_witoil -Is -q s_short -app SERIAL_witoil -P 0372 -J balticPreproc "/bin/bash $WITOIL_UTILS_PATH/preproc/preproc-baltic.sh $DST_HOME_MEDSLIK/witoil"
    lastCmd=$?
    if [ $lastCmd != 0 ]; then
	#[MH] Notify error
        Notify 0 "SIM"  "[QueryID: ${queryID:5:4}][Model: ${MODEL}] PREPROCESS ERROR: Missing input NetCDF file"
        send_to_callback -1 $callback_url "Missing input NetCDF file!"
        exit
    fi
elif [ $MODEL == "GOFS" ]; then

    # preproc
    # bash $WITOIL_UTILS_PATH/preproc/preproc-sani.sh $DST_HOME_MEDSLIK/witoil 
    bsub -R "span[ptile=1]" -sla SC_SERIAL_witoil -Is -q s_short -app SERIAL_witoil -P 0372 -J gofsPreproc "/bin/bash $WITOIL_UTILS_PATH/preproc/preproc-gofs.sh $DST_HOME_MEDSLIK/witoil"
    lastCmd=$?
    if [ $lastCmd != 0 ]; then
	#[MH] Notify error
        Notify 0 "SIM"  "[QueryID: ${queryID:5:4}][Model: ${MODEL}] PREPROCESS ERROR: Missing input NetCDF file"
        send_to_callback -1 $callback_url "Missing input NetCDF file!"
        exit
    fi
    
elif [ $MODEL == "IBI" ]; then

    # preproc
    # bash $WITOIL_UTILS_PATH/preproc/preproc-sani.sh $DST_HOME_MEDSLIK/witoil 
    bsub -R "span[ptile=1]" -sla SC_SERIAL_witoil -Is -q s_short -app SERIAL_witoil -P 0372 -J ibiPreproc "/bin/bash $WITOIL_UTILS_PATH/preproc/preproc-ibi.sh $DST_HOME_MEDSLIK/witoil"
    lastCmd=$?
    if [ $lastCmd != 0 ]; then
	#[MH] Notify error
	Notify 0 "SIM"  "[QueryID: ${queryID:5:4}][Model: ${MODEL}] PREPROCESS ERROR: Missing input NetCDF file"
        send_to_callback -1 $callback_url "Missing input NetCDF file!"
        exit
    fi

elif [ $MODEL == "SANIFS" ]; then

    # preproc
    # bash $WITOIL_UTILS_PATH/preproc/preproc-sani.sh $DST_HOME_MEDSLIK/witoil 
    bsub -R "span[ptile=1]" -sla SC_SERIAL_witoil -Is -q s_short -app SERIAL_witoil -P 0372 -J saniPreproc "/bin/bash $WITOIL_UTILS_PATH/preproc/preproc-sani.sh $DST_HOME_MEDSLIK/witoil"
    lastCmd=$?
    if [ $lastCmd != 0 ]; then
	#[MH] Notify error
	Notify 0 "SIM"  "[QueryID: ${queryID:5:4}][Model: ${MODEL}] PREPROCESS ERROR: Missing input NetCDF file"
        send_to_callback -1 $callback_url "Missing input NetCDF file!"
        exit
    fi    

elif [ $MODEL == "BLACKSEA" ]; then

    # preproc
    # bash $WITOIL_UTILS_PATH/preproc/preproc-sani.sh $DST_HOME_MEDSLIK/witoil 
    bsub -R "span[ptile=1]" -sla SC_SERIAL_witoil -Is -q s_short -app SERIAL_witoil -P 0372 -J blackPreproc "/bin/bash $WITOIL_UTILS_PATH/preproc/preproc-black.sh $DST_HOME_MEDSLIK/witoil"
    lastCmd=$?
    if [ $lastCmd != 0 ]; then
	#[MH] Notify error
	Notify 0 "SIM"  "[QueryID: ${queryID:5:4}][Model: ${MODEL}] PREPROCESS ERROR: Missing input NetCDF file"
        send_to_callback -1 $callback_url "Missing input NetCDF file!"
        exit
    fi
       
else

    cd $DST_HOME_MEDSLIK/witoil/RUN
    sh run_bsub.sh mdk$queryID

fi


echo -e "\n[$APPNAME] ========== SIMULATION! =========="
echo "[$APPNAME] -- Starting the simulation..."

cd $DST_HOME_MEDSLIK/witoil/RUN
sh run_bsub.sh mdk$queryID


#####################################################
#
# Copy/generate output files
#
#####################################################

# Copying output file spill_properties.nc
echo -e "\n[$APPNAME] ========== COPY OF SPILL_PROPERTIES.NC =========="
echo "[$APPNAME] -- Copying spill_properties.nc to $DST_HOME_MEDSLIK"
cp $DST_HOME_MEDSLIK/witoil/OUT/final/spill_properties.nc $DST_HOME_MEDSLIK
echo "[$APPNAME] -- Copying spill_properties.nc to /data/opa/witoil/$queryID/"
mkdir /data/opa/witoil/$queryID
cp $DST_HOME_MEDSLIK/witoil/OUT/final/spill_properties.nc /data/opa/witoil/$queryID/

# Get the information required to build conf.ini file
echo -e "\n[$APPNAME] ========== GENERATING CONF.INI =========="
LON_MIN=$(cat $DST_HOME_MEDSLIK/witoil/OUT/final/medslik.tmp | grep Longitudes | tr -s " " | cut -f 2 -d " ")
LON_MAX=$(cat $DST_HOME_MEDSLIK/witoil/OUT/final/medslik.tmp | grep Longitudes | tr -s " " | cut -f 3 -d " ")
LAT_MIN=$(cat $DST_HOME_MEDSLIK/witoil/OUT/final/medslik.tmp | grep Latitudes | tr -s " " | cut -f 2 -d " ")
LAT_MAX=$(cat $DST_HOME_MEDSLIK/witoil/OUT/final/medslik.tmp | grep Latitudes | tr -s " " | cut -f 3 -d " ")
DURATION=$(cat $DST_HOME_MEDSLIK/witoil/OUT/final/config1.txt | grep -e "length=[0-9]\{4\}" -o | cut -d "=" -f 2)
SIM_NAME=$(cat $DST_HOME_MEDSLIK/witoil/OUT/final/config1.txt | grep -e "SIM_NAME" | cut -d "=" -f 2)
MODEL=$(echo $subm_string | grep -e "model=[a-zA-Z]*" -o | cut -f 2 -d "=")
DAY=$(grep Date medslik5.inp | tr -s " " | cut -d " " -f 1)
MONTH=$(grep Date medslik5.inp | tr -s " " | cut -d " " -f 2)
YEAR=$(grep Date medslik5.inp | tr -s " " | cut -d " " -f 3)
HOUR=$(grep "Hour of Spill" medslik5.inp | tr -s " " | cut -f 1 -d " ")

HOUR_CHARCOUNT=$(echo -n $HOUR | wc -c)
if [[ $HOUR_CHARCOUNT = 3 ]]; then
    START_DATETIME="$YEAR-$MONTH-${DAY}T0${HOUR:0:1}:${HOUR:1:2}Z"
else
    START_DATETIME="$YEAR-$MONTH-${DAY}T${HOUR:0:2}:${HOUR:2:2}Z"
fi
PROD_DATE="$YEAR/$MONTH/$DAY"
#spill duration, in hours (4 characters). if the spill is instantaneous type it is 0000
SPILL_DURATION=$(cat $DST_HOME_MEDSLIK/witoil/OUT/final/config1.txt | grep -e "duration=[0-9]\{4\}" -o | cut -d "=" -f 2)
# setting spill type based on SPILL_DURATION
if [[ "$SPILL_DURATION" == "0000" ]]; then 
    SPILL_TYPE="Instantaneous"
else 
    SPILL_TYPE="Continuous"
fi
#spill rate, in tons/hours. If the spill is instantaneous it is the total tons spilled
SPILL_RATE=$(cat $DST_HOME_MEDSLIK/witoil/OUT/final/config1.txt| grep -e "spillrate=[0-9]\{4\}" -o | cut -d "=" -f 2)

# Notify Simulation configurations
if [[ "$SPILL_TYPE" == "Continuous" ]]; then 
    #Continuos case" - show duration[hours] and spillrate[tons/hours]
    Notify 2 "SIM"  "[QueryID: ${queryID:5:4}][Model:${MODEL}] Requested a simulation with: DURATION=${DURATION}; LAT_MIN=$LAT_MIN; LAT_MAX=$LAT_MAX; LON_MIN=$LON_MIN; LON_MAX=$LON_MAX; NAME=${SIM_NAME}; SPILL_TYPE=${SPILL_TYPE}; DURATION_SPILL[hours]=${SPILL_DURATION}; SPILL_RATE[tons/hours]=${SPILL_RATE}."
else 
    # instantaneous case - show total_volume[tons]
    Notify 2 "SIM"  "[QueryID: ${queryID:5:4}][Model:${MODEL}] Requested a simulation with: DURATION=${DURATION}; LAT_MIN=$LAT_MIN; LAT_MAX=$LAT_MAX; LON_MIN=$LON_MIN; LON_MAX=$LON_MAX; NAME=${SIM_NAME}; SPILL_TYPE=${SPILL_TYPE}; TOTAL_VOLUME[tons]=${SPILL_RATE}."
fi 


# Generating output file conf.ini
echo "###Configuration File" > $DST_HOME_MEDSLIK/conf.ini
echo "[GENERAL]" >> $DST_HOME_MEDSLIK/conf.ini
echo "name=${SIM_NAME}" >> $DST_HOME_MEDSLIK/conf.ini
echo "simID=${queryID}" >> $DST_HOME_MEDSLIK/conf.ini
echo "dss=witoil" >> $DST_HOME_MEDSLIK/conf.ini
echo "user=witoil" >> $DST_HOME_MEDSLIK/conf.ini
echo "host=$(hostname)" >> $DST_HOME_MEDSLIK/conf.ini
echo "model=$MODEL" >> $DST_HOME_MEDSLIK/conf.ini
echo "production_date=$PROD_DATE" >> $DST_HOME_MEDSLIK/conf.ini
echo "start_date_time=$START_DATETIME" >> $DST_HOME_MEDSLIK/conf.ini
echo "duration=$DURATION" >> $DST_HOME_MEDSLIK/conf.ini
echo "" >> $DST_HOME_MEDSLIK/conf.ini
echo "[WITOIL_BOUNDING_BOX] # mandatory for WITOIL" >> $DST_HOME_MEDSLIK/conf.ini
echo "bbox_lat_min=$LAT_MIN" >> $DST_HOME_MEDSLIK/conf.ini
echo "bbox_lon_min=$LON_MIN" >> $DST_HOME_MEDSLIK/conf.ini
echo "bbox_lat_max=$LAT_MAX" >> $DST_HOME_MEDSLIK/conf.ini
echo "bbox_lon_max=$LON_MAX" >> $DST_HOME_MEDSLIK/conf.ini
if [[ -e $DST_HOME_MEDSLIK/conf.ini ]]; then
    echo "[$APPNAME] -- Generated file $DST_HOME_MEDSLIK/conf.ini"
fi

# copy conf.ini
cp $DST_HOME_MEDSLIK/conf.ini /data/opa/witoil/$queryID/

echo -e "\n[$APPNAME] ========== OILTRACK TO NETCDF =========="
source $CONDA_OILSPILL_SRC
conda activate $CONDA_OILSPILL_ENV
PLOTSTEP=$(echo $subm_string | grep -e "plotStep=[0-9]*" -o | cut -d "=" -f 2)
mkdir $DST_HOME_MEDSLIK/nc
echo "[$APPNAME] -- python $DST_HOME_MEDSLIK/witoil/RUN/oil_track_toNetcdf_102020.py -i $DST_HOME_MEDSLIK/spill_properties.nc -o $DST_HOME_MEDSLIK/nc/ -p $PLOTSTEP -s $START_DATETIME"
python $DST_HOME_MEDSLIK/witoil/RUN/oil_track_toNetcdf_102020.py -i $DST_HOME_MEDSLIK/spill_properties.nc -o $DST_HOME_MEDSLIK/nc/ -p $PLOTSTEP -s $START_DATETIME


###################################################################
#
# Finalize
#
###################################################################

# finalize
if [[ $test == 1 ]] ; then
    
    # invoke the finalize script to send files
    echo -e "\n[$APPNAME] ========== FINALIZE OV-MATTEO =========="
    echo "[$APPNAME] -- python $OILSPILL_ROOT/finalize.py ${queryID}"
    python $OILSPILL_ROOT/finalize.py $queryID

    # invoke finalize on ov-matteo
    echo -e "\n[$APPNAME] ========== FINALIZE OV-MATTEO =========="
    echo "ssh ov-prod /srv/ov/backend/support/witoil/finalize.sh $queryID $START_DATETIME"
    ssh ov-prod /srv/ov/backend/support/witoil/finalize.sh $queryID $START_DATETIME
        
    # contact the callback url
    echo -e "\n[$APPNAME] ========== CALLBACK URL =========="

    # check if error should be
    if $(grep -q "Fortran runtime error: End of file" $DST_HOME_MEDSLIK/witoil/RUN/bsub_log); then
        send_to_callback -1 $callback_url "Fortran runtime error: End of file"
        
    elif $(grep -q "forrtl: severe (154): array index out of bounds:" $DST_HOME_MEDSLIK/witoil/RUN/bsub_log); then
        send_to_callback -1 $callback_url "Fortran runtime error: array index out of bounds"

    elif $(grep -q "Fortran runtime error: Bad real number" $DST_HOME_MEDSLIK/witoil/RUN/bsub_log); then
        send_to_callback -1 $callback_url "Fortran runtime error: Bad real number"        
        
    elif [[ -e $DST_HOME_MEDSLIK/spill_properties.nc ]]; then
        
        FILESIZE=$(du $DST_HOME_MEDSLIK/spill_properties.nc | cut -f 1)
        if [[ $FILESIZE -le 4 ]]; then
            #[MH] Notify error
            Notify 0 "SIM"  "[QueryID: ${queryID:5:4}][Model:${MODEL}] ERROR: Zero-sized spill_properties.nc" 
            send_to_callback -1 $callback_url "Zero-sized spill_properties.nc"
        else
            #[MH] Notify OK
	        Notify 1 "SIM"  "[QueryID: ${queryID:5:4}][Model:${MODEL}] Simulation completed with status SUCCESS."

	        echo -e "\n[$APPNAME] ========== SPILLVIEWER =========="
            echo "python $HOME/spillViewer/spillViewer.py --inputFile=$DST_HOME_MEDSLIK/spill_properties.nc --confInputFile=$DST_HOME_MEDSLIK/conf.ini --outputFile=$queryID --outputDirectory=$DST_HOME_MEDSLIK"
            python $HOME/spillViewer/spillViewer.py --inputFile=$DST_HOME_MEDSLIK/spill_properties.nc --confInputFile=$DST_HOME_MEDSLIK/conf.ini --outputFile=$queryID --outputDirectory=$DST_HOME_MEDSLIK
            SendFile $DST_HOME_MEDSLIK/$queryID.gif
            
            send_to_callback 0 $callback_url ""
        fi
    else
	    #[MH] Notify error
	    Notify 0 "SIM"  "[QueryID: ${queryID:5:4}][Model: ${MODEL}] ERROR: Missing file spill_properties.nc" 
        send_to_callback -1 $callback_url "Missing file spill_properties.nc"
    fi
fi

# deactivate conda
conda deactivate
conda deactivate

#####################################################
#
# exit!
#
#####################################################

# clean
# rm -rf $DST_HOME_MEDSLIK/witoil

# exit gracefully
echo "[$APPNAME] -- Elaboration completed!"
exit 0

