## swabseqr: SwabSeq Analysis R package for the swabseq covid detection assay

### Installation

The swabseqr package can be downloaded and installed by running the following command from the R console:

```r
devtools::install_github("joshsbloom/swabseqr" ,ref="main")
```

Make sure you have the `rsync` command line tool available and `pandoc` installed. Consider using `devtools::install_version()` if you encounter dependency issues'

Additionally you must install `bcl2fastq` ,for converting bcl to fastq.gz files, and `bs` , the Basespace CLI tool

The `bs` CLI config file in ~/.basespace/default.cfg should be setup and workspaces can be made accessible with:
`bs auth --scopes "BROWSE GLOBAL,READ GLOBAL,CREATE GLOBAL,MOVETOTRASH GLOBAL,START APPLICATIONS,MANAGE APPLICATIONS" --force`

### Usage
see [main.R](examples/main.R) for example usage

### Additional Background
see [medrxiv preprint](https://www.medrxiv.org/content/10.1101/2020.08.04.20167874v2) and [Octant Notion SwabSeq page](https://www.notion.so/Octant-SwabSeq-Testing-9eb80e793d7e46348038aa80a5a901fd) for information about technology and licensing

### Directory Structure


#### bcl.dir
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
