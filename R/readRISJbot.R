#' A Reader function generator for RISJbot JSONLines data
#'
#' @inheritParams RISJbotSource
#' @return A [tm::Reader] function which returns objects inheriting from
#'   [tm::PlainTextDocument]
#' @seealso [RISJbotSource]
#' @importFrom tm PlainTextDocument
#' @export
readRISJbot <- function(mappings) {
  if(!is.null(mappings) && is.null(mappings[["content"]])) {
    stop("If provided, the mappings list must have a mapping for 'content'.")
  }
  
  function(elem, language, id) {
    d <- jsonlite::fromJSON(elem$content)
    
    if (is.null(mappings)) {
      mappings <- names(d)[names(d) != "bodytext"]
      names(mappings) <- mappings
      contentfield <- "bodytext"
    } else {
      contentfield <- mappings[["content"]]
      mappings <- mappings[names(mappings) != "content"]
    }
    
    content <- d[[contentfield]]
    m <- sapply(names(mappings),
                function(x) d[[mappings[[x]]]],
                simplify=FALSE,
                USE.NAMES=TRUE)
    
    if(is.null(m[["id"]])) {
      # Generate a unique id. This is the source name plus the object's date, plus
      # the file sequence number, plus a shortened hash of the metadata to ensure
      # it is actually unique.
      datestamp <- d[["modtime"]]
      if (is.null(datestamp)) datestamp <- d[["firstpubtime"]]
      if (is.null(datestamp)) datestamp <- d[["fetchtime"]]
      if (is.null(datestamp)) {
        warning(elem$uri, ":", id, ": No modtime, firstpubtime, or fetchtime field found. Using today's date to make the document ID.")
        datestamp <- Sys.Date()
      }
      
      m[["id"]] <- paste0(gsub("[^[:alnum:]]", "", substr(d[["source"]], 1, 10)),
                          strftime(datestamp, format="%Y%m%d"),
                          id,
                          "-",
                          substr(digest::digest(m, algo="md5", raw=FALSE), 1, 8)
      )
    }

    PlainTextDocument(x = content, meta = m)
  }
}
class(readRISJbot) <- c("FunctionGenerator", "function")
