


#' Read ecg xml files
#'
#' Extracts ecg data from xml files from
#' Duke University Hospital MUSE version 9.0.4.16760
#'
#' @param filepath path to file inside quotes
#'
#' @return A dataframe with the ecg data
#' @export
#' @importFrom magrittr %>%
#' @examples
#'
dr_read_ecgxml <- function(filepath) {

  # Read the xml document.

  xml_file <- xml2::read_xml(filepath)

  # Use xpath to find precise parameters and get content.

  acquisition_time <- xml_file %>%
    xml2::xml_find_first("/RestingECG/TestDemographics/AcquisitionTime") %>%
    xml2::xml_contents() %>%
    xml2::xml_text()

  acquisition_date <- xml_file %>%
    xml2::xml_find_first("/RestingECG/TestDemographics/AcquisitionDate") %>%
    xml2::xml_contents() %>%
    xml2::xml_text()

  # We want date in one column and formatted as POSIXct

  acquisition_date_time <- as.POSIXct(paste(acquisition_date,
                                            acquisition_time,
                                            sep = " "),
                                      format = "%m-%d-%Y %H:%M:%S")

  demographics <- xml_file %>%
    xml2::xml_find_all("/RestingECG/PatientDemographics") %>%
    xml2::xml_contents()

  ecg_measurements <- xml_file %>%
    xml2::xml_find_all("/RestingECG/RestingECGMeasurements") %>%
    xml2::xml_contents()

  # Read the leaf names to use for column names later on.

  demographics_column_names <- xml2::xml_name(demographics)
  ecg_column_names          <- xml2::xml_name(ecg_measurements)

  demographics <- demographics %>%
    xml2::xml_text() %>%
    unlist() %>%
    t() %>%
    data.frame(stringsAsFactors = FALSE)

  colnames(demographics) <- demographics_column_names

  ecg_measurements <- ecg_measurements %>%
    xml2::xml_text() %>%
    unlist() %>%
    t() %>%
    data.frame(stringsAsFactors = FALSE)

  colnames(ecg_measurements) <- ecg_column_names

  clean_dx_statement <- function(data) {

    # Function to clean the diagnosis statements.

    #Args:
    #x: Diagnosis statment node

    data <-  data %>%
      xml2::xml_text() %>% # Get the text from the node.
      stringr::str_replace_all(.,stringr::regex(("(userinsert)"), ignore_case = TRUE), "") %>%
      stringr::str_split("ENDSLINE") %>% # Split text into vectors.
      unlist() %>%
      stringr::word(1, sep = "\\.") %>%
      stringr::str_split(",") %>%
      unlist() %>%
      subset(stringr::str_detect(.,stringr::regex(("(absent|\\bno\\b|\\bsuggests?\\b|\\bprobabl(e|y)\\b|\\bpossible\\b|\\brecommend\\b|\\bconsider\\b|\\bindicated\\b|resting)"),
                                ignore_case = TRUE)) == FALSE) %>%
      stringr::str_c(collapse = ", ") %>%
      tolower()

    return(data)

  }

  diagnosis <- xml_file %>%
    xml2::xml_find_all("/RestingECG/Diagnosis")%>%
    clean_dx_statement()

  original_diagnosis <- xml_file %>%
    xml2::xml_find_all("/RestingECG/OriginalDiagnosis") %>%
    clean_dx_statement()



  patient_ecg <- cbind(demographics,
                       acquisition_date_time,
                       ecg_measurements,
                       diagnosis,
                       original_diagnosis,
                       as.data.frame(filepath, stringsAsFactors = FALSE),
                       stringsAsFactors = FALSE)

  return(patient_ecg)

}
