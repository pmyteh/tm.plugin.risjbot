#'A Source to handle JSONLines output from RISJbot
#'
#'@description Constructs a Source to handle JSONLines output from RISJbot. For
#'  better integration with corpora built using other sources, it allows
#'  arbitrary mappings between field names in the RISJbot JSONLines file and
#'  metadata field names in the eventual [tm::PlainTextDocument].
#'
#'@param x A filename string or connection
#'@param mappings An optional named list mapping input JSONLines field names to
#'  metadata fields in the output documents. If mappings are provided, it must
#'  include a mapping for `content`, to indicate which part of the input
#'  JSONLines file should be used for the main text of the output document.
#'
#'  If mappings are not provided, `content` is collected from the `bodytext`
#'  field, all other input fields are carried over to the output document with
#'  their original names.
#'@param dateprefer A character vector setting the priority for which input
#'  field is used to generate the `datetimestamp` output field. The earliest
#'  field present will be used. Default:
#'  `c("datetimestamp", "modtime", "firstpubtime", "fetchtime")`
#'@param datedefault Boolean. If true, the current date will be used with a
#'  warning message if none of the fields in `dateprefer` produce a valid
#'  result. If false, we will stop with an error. Default: `TRUE`.
#'
#'@details An attempt is made to fill up the standard `tm` metadata fields if
#'  explicit mappings are not provided (or produce NULL). The `datetimestamp`
#'  output field is taken as the first available of the fields given in the
#'  `dateprefer` parameter, falling back to the current date if the
#'  `datedefault` parameter is true and otherwise stopping with an error.
#'  `author` is taken by concatenating (with commas) the `bylines` input field.
#'  `description` is taken from the input `summary` field, and `heading` from
#'  `headline`. `origin` is taken from `source`, failing which the filename of
#'  the input file is used.
#'
#'  The returned documents have IDs constructed to be unique under all normal
#'  circumstances. This is based on the input file's `source` field (if
#'  available), the document date (drawn from the input file's `modtime`,
#'  failing that `firstpubtime`, failing that `fetchtime`, failing that the
#'  current date with a warning), the document's sequence number in the input
#'  file, and an 8 character MD5 digest of the document's metadata list.
#'
#'@return An object of class `RISJbotSource`, inheriting from
#'  [tm::SimpleSource].
#'
#' @examples
#' \dontrun{
#'
#' mappings <- list(content="bodytext", dt="firstpubtime", heading="headline")
#' s <- RISJbotSource('input.jl', mappings=mappings)
#' corp <- VCorpus(s)
#'}
#'@importFrom tm getElem
#'@export
RISJbotSource <- function(x,
                          mappings=NULL,
                          dateprefer=c("datetimestamp", "modtime",
                                       "firstpubtime", "fetchtime"),
                          datedefault=TRUE) {
  content <- readLines(x, encoding="UTF-8")
  
  tm::SimpleSource(encoding='UTF-8', length=length(content), content=content,
                   uri=x, reader=readRISJbot(mappings, dateprefer, datedefault),
                   class="RISJbotSource")
}

#' @export
getElem.RISJbotSource <- function(x) list(content = x$content[[x$position]], uri = x$uri)
