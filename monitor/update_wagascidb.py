#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
from wagascianpy.database.wagascidb import WagasciDataBase

def main():
  # =====  Settings  =====
  
  db_file = "/hsm/nu/wagasci/data/run15/database/wagascidb.db"
  
  repository = "/hsm/nu/wagasci/data/run15/wagasci/rawdata"
  
  wagasci_libdir = "/home/nu/dhirata/wg_app/WagasciCL/lib/wagasci/calibration/"
  
  # ===============================

  print("=================================")
  print("Updating WAGASCI database")
  print(f"Repository : {repository}")
  print(f"Output DB  : {db_file}")
  print("=================================")

  if not os.path.exists(repository):
    raise RuntimeError(f"Repository not found: {repository}")

  db = WagasciDataBase(
    db_location=db_file,
    repo_location=repository,
    is_borg_repo=False,
    rebuild_db=True,
    update_db=True,
    wagasci_libdir=wagasci_libdir
  )

  print("")
  print("Database update completed!")
  print(f"DB saved at: {db_file}")


if __name__ == "__main__":
  main()