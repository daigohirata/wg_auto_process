#!/bin/bash

#################################################
# Slack notification script for LSF
#################################################

cd /hsm/nu/wagasci/wg_auto_process
source ./const.sh

EXIT_CODE=$1
LOG_FILE=$2
RUN_NUMBER=$3
DIF_NUMBER=$4
OUTPUT=$5
START_TIME=$6
END_TIME=$7
ELAPSED=$8

if [ "$DIF_NUMBER" -eq 0 ]; then
  DETECTOR="WallMRD north top"
elif [ "$DIF_NUMBER" -eq 1 ]; then
  DETECTOR="WallMRD north bottom"
elif [ "$DIF_NUMBER" -eq 2 ]; then
  DETECTOR="WallMRD south top"
elif [ "$DIF_NUMBER" -eq 3 ]; then
  DETECTOR="WallMRD south bottom"
elif [ "$DIF_NUMBER" -eq 4 ]; then
  DETECTOR="WAGASCI upstream top"
elif [ "$DIF_NUMBER" -eq 5 ]; then
  DETECTOR="WAGASCI upstream side"
elif [ "$DIF_NUMBER" -eq 6 ]; then
  DETECTOR="WAGASCI downstream top"
elif [ "$DIF_NUMBER" -eq 7 ]; then
  DETECTOR="WAGASCI downstream side"
else
  echo "[Error]: Unknown DIF_NUMBER=$DIF_NUMBER" >&2
  exit 1
fi

########################################
# Status message
########################################

if [ "$EXIT_CODE" -eq 0 ]; then
  EMOJI="✅"
  TEXT="*[Process finished. Run: \`${RUN_NUMBER}\` DIF: \`${DIF_NUMBER}\` (${DETECTOR})]*
\`wgDecoder\`, \`wgMakeHist\`, \`wgADC\`, \`wgBCID\`, \`wgAdcCalib\`, \`wgTdcApply\` were successfully done."
else
  EMOJI="❌"
  TEXT="*[Process failed. Run: \`${RUN_NUMBER}\` DIF: \`${DIF_NUMBER}\`]*"
fi

########################################
# Slack message
########################################

ELAPSED_HMS=$(printf "%02dh%02dm%02ds" \
  $((ELAPSED/3600)) \
  $(((ELAPSED%3600)/60)) \
  $((ELAPSED%60)))

MESSAGE="${EMOJI} ${TEXT}
>*Start:* ${START_TIME}
>*End:*   ${END_TIME}
>*Elapsed:* ${ELAPSED_HMS}
>
>*Output:*
>\`${OUTPUT}\`
>*Log:*
>\`${LOG_FILE}\`
>*Host:* $(hostname)"

########################################
# Send
########################################

curl -s -X POST \
     -H "Content-type: application/json" \
     --data "{\"text\":\"${MESSAGE}\"}" \
     ${WEBHOOK_URL}

########################################
# Check remaining jobs for this run
########################################

if [ -f /opt/lsf/conf/profile.lsf ]; then
  source /opt/lsf/conf/profile.lsf
fi

REMAINING_JOBS=$(bjobs -u "$USER" -o job_name -noheader 2>/dev/null | grep "^r${RUN_NUMBER}_")

if [ -z "$REMAINING_JOBS" ]; then
  ALL_DONE_MSG="🎉 *All jobs for run ${RUN_NUMBER} finished!*"
  curl -s -X POST \
      -H "Content-type: application/json" \
      --data "{\"text\":\"${ALL_DONE_MSG}\"}" \
      ${WEBHOOK_URL}
fi
