#!/bin/bash

QSD_REPOSITORY=/gpfs/group/jparc_nu_beam_summary/quick_summary_data/t2krun${T2K_RUN}
WAGASCI_QSD_DIR=/hsm/nu/wagasci/data/qsd/t2krun${T2K_RUN}
LOG_FILE=/hsm/nu/wagasci/data/qsd/synchronize_t2krun${T2K_RUN}.log

echo >> ${LOG_FILE} 2>&1
echo "*********************************************************************" >> ${LOG_FILE} 2>&1
echo "*               Synchronize QSD ($(date '+%Y/%m/%d %H:%M:%S'))               *" >> ${LOG_FILE} 2>&1
echo "*********************************************************************" >> ${LOG_FILE} 2>&1

rsync -av --delete ${QSD_REPOSITORY}/  ${WAGASCI_QSD_DIR} >> ${LOG_FILE} 2>&1

