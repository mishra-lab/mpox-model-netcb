#!/bin/bash
#SBATCH --job-name mpox-netcb
#SBATCH --nodes=1
#SBATCH --cpus-per-task=40
#SBATCH --time=1:00:00

module load gcc/9.2.0
module load r/3.6.3
Rscript scinet/main.py

# using this script on scinet:
# sbatch submit.sh