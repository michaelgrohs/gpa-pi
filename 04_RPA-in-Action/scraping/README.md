# RPA Mini-Project: S&P 500 Scraping Exercise

Work through `sp500_rpa_exercise.ipynb`. Every `# TODO` cell tells you what to implement;
the docs below cover the functions you'll need for each one.

## 1. Scrape Wikipedia with `RPA.Browser.Selenium`

Docs: https://rpaframework.org/libraries/browser_selenium/index.html
Full keyword reference: https://rpaframework.org/libdoc/RPA_Browser_Selenium.html

Keywords you need:

- [`open_available_browser`](https://rpaframework.org/libdoc/RPA_Browser_Selenium.html#RPA.Browser.Selenium.Selenium.open_available_browser) — open a browser at a URL (supports `headless=True`)
- [`wait_until_element_is_visible`](https://rpaframework.org/libdoc/RPA_Browser_Selenium.html#RPA.Browser.Selenium.Selenium.wait_until_element_is_visible) — wait for an element (e.g. `TABLE_LOCATOR`) before reading the page
- [`get_source`](https://rpaframework.org/libdoc/RPA_Browser_Selenium.html#RPA.Browser.Selenium.Selenium.get_source) — return the current page's HTML
- [`close_all_browsers`](https://rpaframework.org/libdoc/RPA_Browser_Selenium.html#RPA.Browser.Selenium.Selenium.close_all_browsers) — always call this in a `finally` block

Parsing the table once you have HTML:

- [`pandas.read_html`](https://pandas.pydata.org/docs/reference/api/pandas.read_html.html) — turns an HTML string into a list of DataFrames (one per `<table>`)

## 2. Enrich with `yfinance`

Docs: https://ranaroussi.github.io/yfinance/

- [`yfinance.Ticker`](https://ranaroussi.github.io/yfinance/reference/api/yfinance.Ticker.html) — look up a single ticker symbol
- [`Ticker.info`](https://ranaroussi.github.io/yfinance/reference/api/yfinance.Ticker.info.html) — dict with fields like `marketCap` and `companyOfficers`

Supporting standard-library tools for the retry/parallel-lookup logic:

- [`time.sleep`](https://docs.python.org/3/library/time.html#time.sleep) — pause between retries
- [`concurrent.futures.ThreadPoolExecutor`](https://docs.python.org/3/library/concurrent.futures.html#threadpoolexecutor) and [`as_completed`](https://docs.python.org/3/library/concurrent.futures.html#concurrent.futures.as_completed) — run the lookups in parallel
- [`re`](https://docs.python.org/3/library/re.html) (`re.sub`, `re.search`) — clean up officer titles/names
- [`requests.HTTPError`](https://requests.readthedocs.io/en/latest/api/#requests.HTTPError) and [`Response.status_code`](https://requests.readthedocs.io/en/latest/api/#requests.Response.status_code) — `yfinance` raises this under the hood; check it to tell a rate limit apart from other errors

### `marketCap` and `companyOfficers`, in more detail

- `info["marketCap"]` is a single number (USD). It's almost always present — missing mainly for
  very recently listed or otherwise edge-case tickers.
- `info["companyOfficers"]` is a **list of dicts** (one per executive, each with at least
  `"name"` and `"title"`). There's no dedicated "CEO" field, so you find the CEO by scanning
  titles. Real examples from this dataset: `"CEO & Director"`, `"Chairman & CEO"`,
  `"Co-Founder, CEO & Director"`, `"President, Chief Executive Officer & Director"`. Match
  case-insensitively against `"chief executive"`, `"principal executive officer"`, and the
  standalone word `ceo` (use `r"\bceo\b"`, not a bare substring check). Taking the first match
  is a simplification — some companies list a segment/divisional "CEO" (e.g. "CEO of Worldwide
  Amazon Stores") before the actual group CEO — that's an acceptable limitation here, just call
  it out in your wrap-up answers.

### Why the CEO/market-cap step fails more than the rest (rate limiting)

`Ticker.info` is a heavier `yfinance` call than most — it pulls several data modules from
Yahoo's backend in one request, and Yahoo actively rate-limits it (`HTTP 429 Too Many
Requests`). This shows up more under:

- repeatedly re-running the full ~500-ticker loop while developing,
- multiple people on the same network/IP hitting Yahoo around the same time, or
- `MAX_WORKERS` set too high.

A short **fixed** retry delay usually isn't enough to recover from a 429 — you just get
rate-limited again on the next attempt. Use **exponential backoff** (`delay * 2 ** attempt`)
instead, and ideally back off harder specifically when the exception is a 429
(`requests.exceptions.HTTPError` with `exc.response.status_code == 429`) rather than some other
transient error. Develop against `sp500.head(10)` so you're not burning through your
rate-limit budget on every iteration.

### Common error: `MergeError: Passing 'suffixes' which cause duplicate columns ... is not allowed.`

You'll hit this if you re-run the enrichment/merge cell (e.g. after tweaking
`get_market_data`) without re-running the earlier scrape cell first. `sp500` already carries
`MarketCap`/`CEO` columns from the previous run, so merging again suffixes the overlap into
`MarketCap_x`/`_y`, `CEO_x`/`_y`; do that a second time and the newly-suffixed names collide
with the ones already sitting there, and pandas raises this error.

- **Right now:** re-run the section 2 scrape cell to reset `sp500`, then run the enrichment
  cell once.
- **Permanently:** make the cell idempotent by dropping any pre-existing `MarketCap`/`CEO`
  columns from `sp500` immediately before merging:
  [`DataFrame.drop(columns=[...], errors="ignore")`](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.drop.html).

## 3. Rank, summarize, and chart with `pandas` / `matplotlib`

- [`DataFrame.dropna`](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.dropna.html)
- [`DataFrame.sort_values`](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.sort_values.html)
- [`DataFrame.groupby`](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.groupby.html) + [`GroupBy.agg`](https://pandas.pydata.org/docs/reference/api/pandas.core.groupby.DataFrameGroupBy.agg.html)
- [`Series.apply`](https://pandas.pydata.org/docs/reference/api/pandas.Series.apply.html) — for `extract_state`
- [`matplotlib.pyplot.bar`](https://matplotlib.org/stable/api/_as_gen/matplotlib.pyplot.bar.html) — the sector bar chart

## 4. Export a report with `RPA.Excel.Files`

Docs: https://rpaframework.org/libraries/excel_files/index.html
Full keyword reference: https://rpaframework.org/libdoc/RPA_Excel_Files.html

- [`create_workbook`](https://rpaframework.org/libdoc/RPA_Excel_Files.html#RPA.Excel.Files.Files.create_workbook)
- [`create_worksheet`](https://rpaframework.org/libdoc/RPA_Excel_Files.html#RPA.Excel.Files.Files.create_worksheet) / [`rename_worksheet`](https://rpaframework.org/libdoc/RPA_Excel_Files.html#RPA.Excel.Files.Files.rename_worksheet)
- [`append_rows_to_worksheet`](https://rpaframework.org/libdoc/RPA_Excel_Files.html#RPA.Excel.Files.Files.append_rows_to_worksheet) — accepts a list of dicts, e.g. `df.to_dict("records")`, with `header=True`
- [`save_workbook`](https://rpaframework.org/libdoc/RPA_Excel_Files.html#RPA.Excel.Files.Files.save_workbook) / [`close_workbook`](https://rpaframework.org/libdoc/RPA_Excel_Files.html#RPA.Excel.Files.Files.close_workbook)

## General reference

- [RPA Framework](https://robocorp.com/docs/python/rpa-framework) — overview of the whole library
- [tqdm](https://github.com/tqdm/tqdm) — progress bars for the enrichment loop

## Setup

```
pip install rpaframework yfinance pandas matplotlib tqdm openpyxl
```

`rpaframework` drives a real Chrome or Firefox browser via Selenium, so one of those needs to
be installed locally.
