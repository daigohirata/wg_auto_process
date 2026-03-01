#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
from wagascianpy.database.bsddb import BsdDataBase

def main():
  t2k_run = 15
  
  db_file = f"/hsm/nu/wagasci/data/run{t2k_run}/database/qsddb.db"
  repository = "/hsm/nu/wagasci/data/qsd"

  if not os.path.exists(repository):
    raise RuntimeError(f"Repository not found: {repository}")

  print("Updating BSD database...")
  print(f"Repository: {repository}")

  db = BsdDataBase(
    bsd_database_location=db_file,
    bsd_repository_location=repository,
    t2kruns=t2k_run,
    update_db=True
  )

  print("")
  print("Database update completed!")
  print(f"DB saved at: {db_file}")


if __name__ == "__main__":
  main()