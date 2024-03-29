## swabseqr: SwabSeq Analysis R package for the swabseq covid detection assay

### Installation

The swabseqr package can be downloaded and installed by running the following command from the R console:

```r
devtools::install_github("joshsbloom/swabseqr" ,ref="main")
```

Make sure you have the `rsync` command line tool available and `pandoc` installed. Consider using `devtools::install_version()` if you encounter dependency issues'

Additionally you must install `bcl-convert` ,for converting bcl to fastq.gz files, and `bs` , the Basespace CLI tool

The `bs` CLI config file in ~/.basespace/default.cfg should be setup and workspaces can be made accessible with:
`bs auth --scopes "BROWSE GLOBAL,READ GLOBAL,CREATE GLOBAL,MOVETOTRASH GLOBAL,START APPLICATIONS,MANAGE APPLICATIONS" --force`

### Usage
see [main.R](examples/main.R) for example usage
___

#### `seq/config.yaml` monitors and controls state of the processing pipeline

each sequencing run contains an entry like this

```yaml
210122_NB552456_0043_AHM5M5AFX2:
     Analyzed: yes
     Bcl2fastq: yes
     Demuxed: yes
     Downloaded: yes
     Flowcell: HM5M5AFX2
     Hname: T72
     ID: '200170974'
     Reported: yes
     Status: Complete
     Experiment: 01222021_JC_AM_N_1
     Keyfile: 01222021_JC_AM_N_1.csv
```
The following entries can be modifed to control pipeline state:

* `Downloaded: (yes/no)` tracks/controls whether a sequencing run has been downloaded from Illumnia Basespace CLI `bs` to bcls/ see bcl.dir below

* `Bcl2fastq: (yes/no)` tracks/controls whether `bcl-convert` has been run to generate Undetermined.*.fastq.gz files for each run in bcls/${Name}/out/

* `Demumxed: (yes/no)` tracks/controls whether amplicon and index matching has been performed. Note this step depends only on the expected molecular barcodes and runs without sample matrix tube information. 

* `Analyzed: (yes/no)` tracks/controls whether seq/results/${Experiment}_report.csv has been generated 
(this file merges swabseq results with order IDs) and whether seq/results/${Experiment}.html 
has been generated (this is an html report for each sequencing run)
    - at this step matrix tube barcodes are merged with the expected molecular barcodes, and orders are merged with the matrix tube barcodes 

* `Reported: (yes/no)` tracks/controls whether csv files per ordering institute and inconclusives/postitives to pull, the file tracking missing orders 
(orders in preciseQ but not received by the lab) are updated at missing/${Date}_orders_not_accession.csv, and the file tracking completed orders are updated at completed/${Date}_current_results.csv

___

The most common intervention is to set the following for a run, note the space between the colon and the lowercase yes/no:

```yaml
 Analyzed: no
 Reported: no
```

Set this if the csv keyfile in swabseqsampletracking/ is updated after a run finishes (for example, for quadrant nullification or rotation), or if orders in precisemdx_sftp_orders/ 
updates after a run finishes and you need to generate the csv results files for preciseQ import.


### Directory Structures

#### Remote directory structure for shared drive: `remote.dir`
```bash
├── completed
│   ├── 2021-01-22_current_results.csv
│   ├── 2021-01-23_current_results.csv
│   └── 2021-01-23_current_results.csv
├── duketracking
├── exportedorders
├── missing
│   ├── 2021-01-21_orders_not_accessioned.csv
│   ├── 2021-01-22_orders_not_accessioned.csv
│   ├── 2021-01-23_orders_not_accessioned.csv
│   └── reformatted
├── precisemdx_sftp_orders
├── precisemdx_sftp_results
├── receivedsamples
│   ├── 01122021_JC_PM_MA_2.csv
├── seq
│   ├── config.yaml
│   ├── runs
│   └── water_tubes
├── swabseqsampletracking
│   ├── 01222021_JC_PM_MB_1
│   └── 01222021_MA_MD_MA_1
│       ├── 01222021_MA_MD_MA_1.csv
│       ├── flowcell_barcode_MA.txt
│       ├── results
│       └── uploaded
└── test
```



  






#### Directory structure for BCLs
 `bcl.dir`
```bash
├── 210122_MN01371_0034_A000H3F7MF
│   ├── Config
│   ├── Data
│   ├── InstrumentAnalyticsLogs
│   ├── InterOp
│   ├── out
│   │   ├── Reports
│   │   ├── Stats
│   │   ├── Undetermined_S0_I1_001.fastq.gz
│   │   ├── Undetermined_S0_I2_001.fastq.gz
│   │   └── Undetermined_S0_R1_001.fastq.gz
│   ├── Recipe
│   ├── RTAComplete.txt
│   ├── RTAConfiguration.xml
│   ├── RTALogs
│   ├── RTARead1Complete.txt
│   ├── RTARead2Complete.txt
│   ├── RTARead3Complete.txt
│   ├── RunInfo.xml
│   ├── RunParameters.xml
│   ├── SampleSheet.csv
│   └── T73_200169982.json
└── 210122_NB552456_0043_AHM5M5AFX2
    ├── Config
    ├── Data
    ├── InstrumentAnalyticsLogs
    ├── InterOp
    ├── out
    │   ├── Reports
    │   ├── Stats
    │   ├── Undetermined_S0_I1_001.fastq.gz
    │   ├── Undetermined_S0_I2_001.fastq.gz
    │   └── Undetermined_S0_R1_001.fastq.gz
    ├── Recipe
    ├── RTAComplete.txt
    ├── RTAConfiguration.xml
    ├── RTALogs
    ├── RTARead1Complete.txt
    ├── RTARead2Complete.txt
    ├── RTARead3Complete.txt
    ├── RunInfo.xml
    ├── RunParameters.xml
    ├── SampleSheet.csv
    ├── T72_200170974.json
    └── Thumbnail_Images
```

### Additional Background
see [medrxiv preprint](https://www.medrxiv.org/content/10.1101/2020.08.04.20167874v2) and [Octant Notion SwabSeq page](https://www.notion.so/Octant-SwabSeq-Testing-9eb80e793d7e46348038aa80a5a901fd) for information about technology and licensing


