#!/bin/bash

cd /hsm/nu/wagasci/wg_auto_process/qsd_process

source ~/.bashrc

./synchronize_qsd.sh
./update_qsddb.py ${T2K_RUN}
