#!/bin/bash

set -euo pipefail

source /hsm/nu/wagasci/wg_auto_process/const.sh
source /home/nu/dhirata/.wagasci/wg_container_env.sh

RUN_NAME=$1

FLAG_DIR=/hsm/nu/wagasci/wg_auto_process/process_flags/run${T2K_RUN}/${RUN_NAME}
EXPECTED_DIF=6

if [ ! -d "$FLAG_DIR" ]; then
  echo "No flag directory yet."
  exit 0
fi

DONE_COUNT=$(find "$FLAG_DIR" -maxdepth 1 -name "dif_*.done" | wc -l)

echo "Done count: $DONE_COUNT / $EXPECTED_DIF"

if [ "$DONE_COUNT" -ne "$EXPECTED_DIF" ]; then
  echo "Not all DIF finished yet."
  exit 0
fi

echo "All DIF completed. Starting spill number fixer..."

START_TIME=$(date "+%F %T")

# --- 実行（失敗しても通知は送るため set -e を一時解除）
set +e
wgAna /opt/wagasci_data_handling/WagasciCalibration/bin/wgSpillNumberFixer \
  -f ${DECODED_DIR}/${RUN_NAME}/
EXIT_CODE=$?
set -e
# ---

END_TIME=$(date "+%F %T")

if [ "$EXIT_CODE" -eq 0 ]; then
  EMOJI="👌"
  STATUS="SUCCESS"
  COLOR="#36a64f"
else
  EMOJI="❌"
  STATUS="FAILED"
  COLOR="#ff0000"
fi

MESSAGE="${EMOJI} *[SpillNumberFixer ${STATUS}]*  
>Run: \`${RUN_NAME}\`  
>DIF completed: ${DONE_COUNT}/${EXPECTED_DIF}  
>Start: ${START_TIME}  
>End: ${END_TIME}"

curl -s -X POST \
  -H "Content-type: application/json" \
  --data "$(printf '{"attachments":[{"color":"%s","text":"%s"}]}' \
    "$COLOR" "$MESSAGE")" \
  "${WEBHOOK_URL}" >/dev/null 2>&1

exit "$EXIT_CODE"