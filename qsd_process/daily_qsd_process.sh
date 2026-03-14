#!/bin/bash

readonly SCRIPT_DIR="/hsm/nu/wagasci/wg_auto_process/qsd_process"

${SCRIPT_DIR}/synchronize_qsd.sh
${SCRIPT_DIR}/update_qsddb.py ${T2K_RUN}
