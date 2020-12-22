# Replication Package for
# "Friends Don't Let Friends Free Ride"
# By Nicholas Eubank and Dorothy Eubank

This package contains all code use to complete the analyses in
"Friends Don't Let Friends Free Ride".

Unfortunately, however, while all of our code is available here,
the data used in this paper are *extremely* sensitive, and so we are only able
to release our final analysis datasets in this replication package. These
data are individual level records (though they do not contain identifying
information), and for each individual report network summary statistics
(e.g. Communication Centrality) and demographic features of each users'
neighborhood (parroquia). While not as rich as the identified source data,
this dataset is enough to replicate all the major tables and figures in our
paper using the directions below.

Organization
============

All code for this project is meant to be run in the sequence implied by file and
folder name prefixes in a depth first manner (i.e. begin by running all the files
in folder `00_code_for_illustrative_figures` in the implied sequence, then all
the files in folder `10_network_summary_stats`, etc.). The numbers are NOT sequential,
only ordinal (I start with numbers at intervals of ten, but inevitably new files
get added between existing files, so that approach allows for insertions without
renumbering everything).

When it was all said and done, this project used a combination of Python, Julia,
and Stata, so you will find `.py`, `.jl`, and `.do` files depending on where you
look.


Replication
===========

The portion of the code that can be run with included data is the folder
`70_analyze_individual`. This folder -- which contains only Stata dofiles --
generates most of the plots and figures in our paper, and all files within
can be run using the `MASTER_DO_FILE.do` file located at the top level of this
replication package. Simply open that file, set the path saved as the global
`barrio_dir`, install the packages described below, and hit run! All
tables and figures will then be saved to the `results` folder, and if you compile
the copy of the manuscript located in `docs` folder, all updated figures will
be automatically imported.

(We recommend deleting everything in the `results` folder before running so you
know everything in there is fresh, but the code will overwrite old files so
that's not strictly necessary).

All results we cannot provide the data to replicate are located in the folder
`results_nonpublicsource`.

Language Specific Notes
=======================

Stata
-----
All stata files rely the global `barrios_dir` be set to the location of this
repository.

In addition, the code uses some installable convenience **functions**, which can be
installed with the following code:

```
ssc install dm88_1
ssc install outtable
ssc install zipsave
ssc install savesome
ssc install lincomest
ssc install mvfiles
```

Code was last run in Stata 16. 

Python
------

- This analysis was run using Python 3.6.
- There's a file called `barrio_directories.py` in `code/modules` that allows for easy import of file paths.

Julia
-----

Julia analysis was run using Julia v1.0, and relies primarily on the LightGraphs.jl package.
# EubankKronick_FriendsDontLetFriendsFreeRide
