# Replication Package for "Friends Don't Let Friends Free Ride"

By Nicholas Eubank and Dorothy Kronick

This package contains all code used to complete the analyses in
"Friends Don't Let Friends Free Ride." It also contains our final analysis data
set. However, the original identified source data is too sensitive
to publish; doing so would violate the agreement through which 
we obtained the data.

**Note that git-lfs is required to clone this repository!**
[You can install it here.](https://git-lfs.github.com/)

## Replication

The portion of the code that can be run with included data is the folder
`code/code_publicdata`. This folder generates most of the tables and figures 
in our paper, and all files are called within `code/00_MASTER_DO_FILE.do`.
All tables and figures will then be saved to the `results` folder, and if you compile
the copy of the manuscript located in `docs` folder, all updated figures will
be automatically imported.

All results we cannot provide the data to replicate are located in the folder
`results_nonpublicsource`. You can tell which results in the
manuscript are generated in `code/00_MASTER_DO_FILE.do` by looking at 
the `input` paths in the TeX document.

All other code (that unfortunately relies on data we can't provide) is in
`code/code_privatedata`. The code in `code_publicdata` slots in between
`65_centro_characteristics` and `72_eigenvector_centrality`.

## Organization

All code for this project is run in the sequence implied by file- and
folder-name prefixes in a depth-first manner (i.e. begin by running all the files
in folder `10_network_summary_stats` in the implied sequence, then all
the files in folder `50_identify_political_activities`, etc.). 

This project used a combination of Python, Julia, and Stata, so you will find 
`.py`, `.jl`, and `.do` files depending on where you look. 

Note that if you're here to find code for running diffusions, we
recommend just going to the LightGraphs.jl documentation and using
the diffusion function we published there (rather than wrestling with our 
idiosyncratic code).

## Language-Specific Notes

### Stata

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
```

Code was last run in Stata 16.

### Python

- This analysis was run using Python 3.6. Most analyses relied on Pandas 0.22 and python-igraph 0.7.
- There's a file called `barrio_directories.py` in `code/modules` that allows for easy import of file paths.

### Julia

Julia analysis was run using Julia v1.0 and relies primarily on the LightGraphs.jl package.
