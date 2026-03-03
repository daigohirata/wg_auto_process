#!/bin/bash

# ### dif_process.sh ###

###########################################
#         Define clean up process         #
###########################################

set -euo pipefail

START_TIME=$(date +%s)
START_STR=$(date "+%F %T")

cleanup() {
  EXIT_CODE=$?
  set +e
  END_TIME=$(date +%s)
  END_STR=$(date "+%F %T")
  ELAPSED=$((END_TIME - START_TIME))

  if [ "$EXIT_CODE" -eq 0 ]; then
    DONE_DIR=/hsm/nu/wagasci/wg_auto_process/process_flags/run15/${run_name:-unknown}
    mkdir -p "$DONE_DIR"
    touch "${DONE_DIR}/dif_${DIF_NUMBER}.done"

    python /hsm/nu/wagasci/wg_auto_process/monitor/database_converter.py || true
    python /hsm/nu/wagasci/wg_auto_process/monitor/generate_index.py || true
  fi

  /hsm/nu/wagasci/wg_auto_process/notify_slack.sh \
    "$EXIT_CODE" \
    "$LOG_FILE" \
    "$WG_RUN_NUMBER" \
    "$DIF_NUMBER" \
    "${decoded_file:-unknown}" \
    "$START_STR" \
    "$END_STR" \
    "$ELAPSED"
  
  if [ "$EXIT_CODE" -eq 0 ] && [ -n "${run_name:-}" ]; then
    /hsm/nu/wagasci/wg_auto_process/run_spill_number_fixer.sh ${run_name}
  fi
}

trap cleanup EXIT

###########################################
#                Constants                #
###########################################

cd /hsm/nu/wagasci/wg_auto_process
source ./wg_container_env.sh
source ./const.sh

WG_RUN_NUMBER=$1
DIF_NUMBER=$2
LOG_FILE=$3

###########################################
#                 Process                 #
###########################################

raw_file=( ${RAWDATA_DIR}/physics_run_*-*-*_*-*-*_${WG_RUN_NUMBER}/physics_run_*-*-*_*-*-*_${WG_RUN_NUMBER}_ecal_dif_${DIF_NUMBER}.raw )
raw_file=${raw_file[0]}

run_name=$(basename $raw_file)
run_name=${run_name%_ecal_dif_*.raw}

rawdata_run_dir=${RAWDATA_DIR}/${run_name}
decoded_run_dir=${DECODED_DIR}/${run_name}
data_quality_run_dir=${DATA_QUALITY_DIR}/${run_name}

pyrame_config=( ${rawdata_run_dir}/${run_name}.xml )
pyrame_config=${pyrame_config[0]}

make_hist_dir=( ${decoded_run_dir}/make_hist )
make_hist_dir=${make_hist_dir[0]}

adc_dist_dir=( ${data_quality_run_dir}/ADC )
adc_dist_dir=${adc_dist_dir[0]}

bcid_dist_dir=( ${data_quality_run_dir}/BCID )
bcid_dist_dir=${bcid_dist_dir[0]}

history_dir=( ${decoded_run_dir}/adc_history )
history_dir=${history_dir[0]}

decoded_file=( ${decoded_run_dir}/${run_name}_ecal_dif_${DIF_NUMBER}_tree.root )
makehist_file=( ${make_hist_dir}/${run_name}_ecal_dif_${DIF_NUMBER}_hist.root )

mkdir -p "${make_hist_dir}" "${adc_dist_dir}" "${bcid_dist_dir}" "${history_dir}"

if [ ${DIF_NUMBER} -le 3 ]; then
  num_of_asu=3
else
  num_of_asu=20
fi

echo ""
echo "**********************************************************"
echo "*                      wgDecoder                         *"
echo "**********************************************************"
echo ""

if [ ! -f ${decoded_run_dir}/${run_name}_ecal_dif_${DIF_NUMBER}_tree.root ]; then
  wgAna /opt/wagasci_data_handling/WagasciCalibration/bin/wgDecoder \
    -f ${raw_file} \
    -c ${CARIB_FILE_DIR} \
    -o ${DECODED_DIR}/${run_name} \
    -n ${DIF_NUMBER} \
    -x ${num_of_asu}
else
  echo "--> Exist: ${decoded_run_dir}/${run_name}_ecal_dif_${DIF_NUMBER}_tree.root"
  echo "--> Skip wgDecoder"
fi

echo ""
echo "**********************************************************"
echo "*                     wgMakeHist                         *"
echo "**********************************************************"
echo ""

wgAna /opt/wagasci_data_handling/WagasciCalibration/bin/wgMakeHist \
  -f ${decoded_file} \
  -p ${pyrame_config} \
  -o ${make_hist_dir} \
  -n ${DIF_NUMBER} \
  -m 10

echo ""
echo "**********************************************************"
echo "*                       wgADC                            *"
echo "**********************************************************"
echo ""

wgAna /opt/wagasci_data_handling/WagasciCalibration/bin/wgADC \
  -f ${makehist_file} \
  -x ${pyrame_config} \
  -i ${adc_dist_dir} \
  -c

echo ""
echo "**********************************************************"
echo "*                       wgBCID                           *"
echo "**********************************************************"
echo ""

wgAna /opt/wagasci_data_handling/WagasciCalibration/bin/wgBCID \
  -f ${makehist_file} \
  -x ${pyrame_config} \
  -i ${bcid_dist_dir} \
  -c

# echo ""
# echo "**********************************************************"
# echo "*                 wgSpillNumberFixer                     *"
# echo "**********************************************************"
# echo ""

# wgAna /opt/wagasci_data_handling/WagasciCalibration/bin/wgSpillNumberFixer \
#   -f ${DECODED_DIR}/${run_name}/

echo ""
echo "**********************************************************"
echo "*                     wgAdcCalib                         *"
echo "**********************************************************"
echo ""

export WAGASCI_CONFDIR=/hsm/nu/wagasci/data/run14/wagasci/cards

wgAna /opt/wagasci_data_handling/WagasciCalibration/bin/wgAdcCalib \
  -f ${decoded_file} \
  -u ${pyrame_config} \
  -c ${CARIB_FILE_DIR} \
  -o ${history_dir} \
  -n ${DIF_NUMBER}

echo ""
echo "**********************************************************"
echo "*                     wgTdcApply                         *"
echo "**********************************************************"
echo ""

export WAGASCI_CONFDIR=/hsm/nu/wagasci/data/run13/wagasci/cards

wgAna /opt/wagasci_data_handling/WagasciCalibration/bin/wgTdcApply \
  -f ${decoded_file} \
  -p ${pyrame_config} \
  -n ${DIF_NUMBER}

echo ""
echo "**********************************************************"
echo "*                   Process finish                       *"
echo "**********************************************************"
echo ""
