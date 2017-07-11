#' Classifies ecg data imported with dr_read_ecgxml
#'
#' @param data of class data.table
#'
#' @return data.table with new columns added for classification of ecg based on diagnosis statements.
#' @export
#' @import data.table
#' @examples
#'
dr_classify_ecg <- function(data){


  if(! "data.table" %in% class(data)){
    stop("As of now, data has to be of class data.table", call. = FALSE)
  }

  if(! "diagnosis" %in% colnames(data)){
    stop("The column diagnosis doesn't exist", call. = FALSE)
  }

  lbbb_pattern <- "(.*lbbb|.*left.?.?bundle|(.*bbb|bundle branch block).{1,8}?left)"

  rbbb_pattern <- "(.*rbbb|.*right.?.?bundle|(.*bbb|bundle branch block).{1,8}?right)"

  ivcd_pattern <- "(.*ivcd|.*int(ra|er).?vent.{1,10}?cond.{1,10}?delay)"

  lafb_pattern <- "(.*lafb|.*left.{1,3}?ant.{1,10}?(fasc|hem))"

  lpfb_pattern <- "(.*lpfb|.*left.{1,3}?post.{1,10}?(fasc|hem))"

  afib_pattern <- ".*fib"

  pace_pattern <- "(?<!junctional).(pac(i|e)|fus(ed|ion)|native|capture|sens(e|ing)|tracking|spike|magne?t?|escape)"

  wpw_pattern <- ".*(wolf|pree?xc)"

  svt_pattern <- "(.*atrial.?reen|.*(svt|flut)|.*supra.?vent|.*atrial.?tach)"

  sinus_pattern <- "^.*sinus"

  junctional_pattern <- ".*junctional(?!.?.?(escape|beat))"

  exclude_pattern <- "(\\bstrip|\\blvad|\\bidioventricular rhythm|\\bventricular tach|\\bisorhyth|\\bventricular escape|\\basys|\\bventricular rhyt|\\batrial lead|\\bstemi)"


  data <- data[, `:=` (Normal_conduction = NA,
                       QRSDuration       = as.numeric(QRSDuration),
                       Sinus_rhytm       = as.numeric(stringr::str_detect(diagnosis, sinus_pattern)),
                       SVT               = as.numeric(stringr::str_detect(diagnosis, svt_pattern)),
                       Junctional_rhythm = as.numeric(stringr::str_detect(diagnosis, junctional_pattern)),
                       LBBB              = as.numeric(stringr::str_detect(diagnosis, lbbb_pattern)),
                       RBBB              = as.numeric(stringr::str_detect(diagnosis, rbbb_pattern)),
                       RBBB_LAFB         = NA,
                       RBBB_LPFB         = NA,
                       IVCD              = as.numeric(stringr::str_detect(diagnosis, ivcd_pattern)),
                       LAFB              = as.numeric(stringr::str_detect(diagnosis, lafb_pattern)),
                       LPFB              = as.numeric(stringr::str_detect(diagnosis, lpfb_pattern)),
                       AFIB              = as.numeric(stringr::str_detect(diagnosis, afib_pattern)),
                       PACE              = as.numeric(stringr::str_detect(diagnosis, pace_pattern)),
                       WPW               = as.numeric(stringr::str_detect(diagnosis, wpw_pattern)),
                       Exclude           = as.numeric(stringr::str_detect(diagnosis, exclude_pattern))),
               by = .I]

  data[, `:=` (diagnosis          = NULL,
              original_diagnosis = NULL)]


  data <- dplyr::mutate(data, RBBB = dplyr::if_else(RBBB == 1 & QRSDuration >= 120,
                        true  = 1,
                        false = 0),

                       RBBB_LAFB = dplyr::if_else(RBBB == 1 & LAFB == 1,
                                           true  = 1,
                                           false = 0),

                       RBBB_LPFB = dplyr::if_else(RBBB == 1 & LPFB == 1,
                                           true  = 1,
                                           false = 0),

                       RBBB = dplyr::if_else(RBBB_LAFB == 1 | RBBB_LPFB == 1,
                                      true  = 0,
                                      false = RBBB),

                       LBBB = dplyr::if_else(LBBB == 1 & QRSDuration >= 120,
                                      true  = 1,
                                      false = 0),

                       IVCD = dplyr::if_else(IVCD == 1 & QRSDuration >= 110 &
                                        LBBB == 0 &
                                        RBBB == 0 &
                                        RBBB_LAFB == 0 &
                                        RBBB_LPFB == 0,
                                      true  = 1,
                                      false = 0),

                       LAFB = dplyr::if_else(LAFB == 1 & QRSDuration <120 & IVCD == 0,
                                      true  = 1,
                                      false = 0),

                       LPFB = dplyr::if_else(LPFB == 1 & QRSDuration <120 & IVCD == 0,
                                      true  = 1,
                                      false = 0),

                       Normal_conduction = dplyr::if_else(LBBB      == 0 &
                                                     LAFB      == 0 &
                                                     LPFB      == 0 &
                                                     RBBB      == 0 &
                                                     RBBB_LAFB == 0 &
                                                     RBBB_LPFB == 0 &
                                                     IVCD      == 0 &
                                                     PACE      == 0 &
                                                     QRSDuration < 120,

                                                   true  = 1,
                                                   false= 0))


  return(data)
}
