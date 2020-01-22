
# tm.plugin.risjbot

<!-- badges: start -->
<!-- badges: end -->

tm.plugin.risjbot provides a `tm` Source function for creating
corpora from articles scraped by the
[RISJbot webcrawler](https://github.com/pmyteh/RISJbot). RISJbot is a
Scrapy/Python project designed to collect the full text and metadata of news
articles from the web, using sites' own sitemaps and RSS feeds as a source. It
produces a number of output formats, including JSONLines files which this
package can read into `tm` sources.

## Installation

You can install the development version of tm.plugin.risjbot from
[Github](https://github.com/pmyteh/tm.plugin.risjbot) with:

``` r
devtools::install_github("pmyteh/tm.plugin.risjbot")
```

## Example

This example shows you how to create a `tm` object usin this package's source
function:

``` r
library(tm)
library(tm.plugin.risjbot)
corp <- VCorpus(RISJbotSource('/path/to/file/data.jl'))
```

