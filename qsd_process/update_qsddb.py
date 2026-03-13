#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import argparse
from wagascianpy.database.bsddb import BsdDataBase

def main():
  parser = argparse.ArgumentParser(description="Update BSD database")
  parser.add_argument("t2k_run", type=int, help="T2K run number")

  args = parser.parse_args()
  t2k_run = args.t2k_run

  db_file = f"/hsm/nu/wagasci/data/run{t2k_run}/database/qsddb.db"
  repository = f"/hsm/nu/wagasci/data/qsd/t2krun{t2k_run}"

  if not os.path.exists(repository):
    raise RuntimeError(f"Repository not found: {repository}")

  print("Updating BSD database...")
  print(f"Repository: {repository}")

  db = BsdDataBase(
    bsd_database_location=db_file,
    bsd_repository_location=repository,
    update_db=True
  )

  print("")
  print("Database update completed!")
  print(f"DB saved at: {db_file}")


if __name__ == "__main__":
  main()