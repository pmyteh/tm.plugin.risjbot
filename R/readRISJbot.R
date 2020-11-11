#' A Reader function generator for RISJbot JSONLines data
#'
#' @inheritParams RISJbotSource
#' @return A [tm::Reader] function which returns objects inheriting from
#'   [tm::PlainTextDocument]
#' @seealso [RISJbotSource]
#' @importFrom tm PlainTextDocument
#' @export
readRISJbot <- function(mappings, dateprefer, datedefault) {
  if(!is.null(mappings) && is.null(mappings[["content"]])) {
    stop("If provided, the mappings list must have a mapping for 'content'.")
  }
  
  function(elem, language, id) {
    d <- jsonlite::fromJSON(elem$content)
    
    if (is.null(mappings)) {
      mappings <- names(d)[!(names(d) %in% c("bodytext", "headline", "source"))]
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
      # Generate a unique id. This is the source name plus the object's date,
      # plus the file sequence number, plus a shortened hash of the metadata to
      # ensure it is actually unique.
      m[["id"]] <- paste0(gsub("[^[:alnum:]]", "", substr(d[["source"]], 1, 10)),
                          strftime(m[["datetimestamp"]], format="%Y%m%d"),
                          id,
                          "-",
                          substr(digest::digest(m, algo="md5", raw=FALSE), 1, 8)
      )
    }
    
    # When constructing a PlainTextDocument, tm does special handling for its
    # 'standard' metadata fields: author, datetimestamp, description, heading,
    # id, language, and origin.
    #
    # Unfortunately, it does so using "if(!is.null(meta$origin))" etc., with
    # the $ notation running the risk of partial matching against other elements
    # when the original field is absent. (In particular, where there is an
    # 'originalurl' field in the RISJbot data, but no 'origin' found). There
    # shouldn't be any other clashes in standard RISJbot output.
    # The following is a fairly gross hack to avoid this problem.
    if (is.null(m[["author"]]) & !is.null(d[["bylines"]])) 
      m[["author"]] <- paste(as.character(d[["bylines"]]), collapse=", ")
    if (is.null(m[["description"]])) 
      m[["description"]] <- d[["summary"]]
    if (is.null(m[["heading"]]))
      m[["heading"]] <- d[["headline"]]
    if (is.null(m[["origin"]])) {
      m[["origin"]] <- d[["source"]]
      if(is.null(m[["origin"]])) m[["origin"]] <- elem$uri
    }

    for (s in dateprefer) {
      m[["datetimestamp"]] <- d[[s]]
      if (!is.null(m[["datetimestamp"]])) break
    }
    
    if (is.null(m[["datetimestamp"]])) {
      if (datedefault) {
        warning(elem$uri, ":", id, ": None of the given date input fields found. Using today's date and time to make 'datetimestamp'.\n")
        m[["datetimestamp"]] <- Sys.time()
      } else stop(elem$uri, ":", id, ": Can't find any of the given date input fields.")
    }
    # m[["datetimestamp"]] <- d[["modtime"]]
    # if (is.null(m[["datetimestamp"]])) m[["datetimestamp"]] <- d[["firstpubtime"]]
    # if (is.null(m[["datetimestamp"]])) {
    #   m[["datetimestamp"]] <- d[["fetchtime"]]
    #   if (!is.null(m[["datetimestamp"]])) {
    #     warning(elem$uri, ":", id, ": No modtime or firstpubtime field found. Using fetchtime field to make the document datetimestamp, which may not be accurate.\n")
    #   } else {
    #     warning(elem$uri, ":", id, ": No modtime, firstpubtime, or fetchtime field found. Using today's date and time to make the document datetimestamp.\n")
    #     m[["datetimestamp"]] <- Sys.time()
    #   }
    # }
    m[["datetimestamp"]] <- lubridate::ymd_hms(m[["datetimestamp"]])

    PlainTextDocument(x = content, meta = m)
  }
}
class(readRISJbot) <- c("FunctionGenerator", "function")
