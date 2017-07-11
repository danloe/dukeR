
# dukeR
Tools for analysing Duke University Hospital data.

### Description
The idea behind this package is to gather data analysis tools for the R statistical system to help facilitate collaboration when analyzing data from Duke Univeristy Hospital.

### Disclaimer
This package is not officially affiliated with Duke University Hospital. The author assumes no responsibility or liability for the use of the package.

### Installation

If not installed, install `devtools` package.
```r
install.packages("devtools")
```
Continue on to install `dukeR`
```r
devtools::install_github("danloe/dukeR")
```
Done.

### Usage
#### Analysing ecg .xml files
Below follows an example of how to read xml files from a folder and merge them to a dataframe, which if necessary can be exported to a .csv or .xslx file.
Load the package.
```r
require("dukeR")
```
Create a variable holding paths to the xml files.
```r
xml_files <- list.files("./your_xml_folder", full.names = TRUE)
```
If you only have one .xml file then you could directly apply the `dr_read_ecgxml()` function. However, most probably you have multiple .xml files that you want to read in which case you can make use of the `map()` function from the `purrr` package.
```r
ecg_list <- purrr::map(xml_files, dr_read_ecgxml)
```
This will result in a list of dataframes, one for each ecg. If reading a large number of ecgs it's recommended to make use of the `data.table` package. Below follows an example of how to merge the list of dataframes to one.
```r
ecg_data <- data.table::rbindlist(ecg_list, fill = TRUE)
```
You now have a dataframe (or rather a data.table) suitable for analysis, however `dukeR` also contains the function `dr_classify_ecg()` which will perform a simple form of text analysis on the diagnosis statements using regex expressions and in combination with QRS duration criteria classify the ecg according to the following: 
- Sinus rhytm, 
- Supra ventricular tachycardia (SVT), 
- Junctional rhythm, 
- Left bundle branch block (LBBB), 
- right bundle branch block (RBBB), 
- RBBB + left anterior fascicular block (LAFB), 
- RBBB + left posterior fascicular block (LPFB), 
- atrial fibrillation (AFIB), 
- pacemaker rhythm (PACE), 
- wolf parkinson white (WPW).
```r
ecg_classified <- dr_classify_ecg(ecg_data)
```

You have just finished analysing your ecgs, congratulations.
