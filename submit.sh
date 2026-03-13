#!/bin/bash

shopt -s nullglob

cd /hsm/nu/wagasci/wg_auto_process
source ./const.sh
WG_RUN_NUMBER=$1

#################################################
#                    Process                    #
#################################################

raw_dirs=( ${RAWDATA_DIR}/physics_run_*-*-*_*-*-*_${WG_RUN_NUMBER} )

if [ ${#raw_dirs[@]} -eq 0 ]; then
  echo "[Error]: No rawdata directory found!"
  exit 1
fi

raw_files=( ${RAWDATA_DIR}/physics_run_*-*-*_*-*-*_${WG_RUN_NUMBER}/physics_run_*-*-*_*-*-*_${WG_RUN_NUMBER}_ecal_dif_*.raw )

if [ ${#raw_files[@]} -eq 0 ]; then
  echo "[Error]: No raw files found"
  exit 1
fi

first_file=${raw_files[0]}
run_name=$(basename "$first_file")
run_name=${run_name%_ecal_dif_*\.raw}

## --> Rename files because wagasci upstream is OFF
if [[ ! -f ${RAWDATA_DIR}/${run_name}/${run_name}_ecal_dif_6.raw &&
     ! -f ${RAWDATA_DIR}/${run_name}/${run_name}_ecal_dif_7.raw ]]; then
  echo "Rename DIF4,5 --> DIF6,7"
  mv ${RAWDATA_DIR}/${run_name}/${run_name}_ecal_dif_4.raw \
     ${RAWDATA_DIR}/${run_name}/${run_name}_ecal_dif_6.raw
  mv ${RAWDATA_DIR}/${run_name}/${run_name}_ecal_dif_5.raw \
     ${RAWDATA_DIR}/${run_name}/${run_name}_ecal_dif_7.raw
fi
## <-- Rename files because wagasci upstream is OFF

# Get DIF file list
process_raw_files=( ${RAWDATA_DIR}/${run_name}/${run_name}_ecal_dif_*.raw )

mkdir -p ${DECODED_DIR}/${run_name}/

for raw_file in "${process_raw_files[@]}"; do
  dif_number=$(basename $raw_file)
  dif_number=${dif_number##*_ecal_dif_}
  dif_number=${dif_number%.raw}

  log_path=${DECODED_DIR}/${run_name}/process_dif_${dif_number}.log

  echo "--> Submit job: $raw_file"
  bsub -q l \
      -u "${MY_YNU_MAIL}" \
      -o "${log_path}" \
      -J "r${WG_RUN_NUMBER}_d${dif_number}" \
      /hsm/nu/wagasci/wg_auto_process/dif_process.sh \
      "${WG_RUN_NUMBER}" "${dif_number}" \
      "${log_path}"
done

#################################################
#              Slack notification               #
#################################################

source /opt/lsf/conf/profile.lsf

MESSAGE=$(cat <<EOF
🔔 *[WAGASCI process start]*
>${#process_raw_files[@]} jobs were submitted.
>*Run:* \`${run_name}\`
>\`\`\`
$(bjobs 2>&1)
\`\`\`
EOF
)

curl -s -X POST \
  -H "Content-type: application/json" \
  --data "$(jq -n --arg text "$MESSAGE" '{text: $text}')" \
  "$WEBHOOK_URL"

# Update wagascidb.db
/usr/bin/python3.9 /hsm/nu/wagasci/wg_auto_process/monitor/update_wagascidb.py >> /hsm/nu/wagasci/data/run15/database/process_wagascidb.log 2>&1
