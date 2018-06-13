# IEX API

This uses the [IEX trading API](https://iextrading.com/)'s HTTP endpoints.
Everything in the Stock endpoint is supported.

Documentation for the API can be found at [https://iextrading.com/developer/docs/](https://iextrading.com/developer/docs/).

```d
    auto stock = Stock("AAPL", "MSFT")
            .quote()
            .news(5) // Last 5 items.
            .chart(ChartRange.OneMonth)
            .query();
```

A query returns the result as a vibe.data.json.Json object.

There is currently very little validation by iex.d; errors will return an error
Json response.

## Notes and Limitations

Although iex.d separates date range parameters, (i.e., ChartRange and
DividendRange), the IEX API uses a single parameter; if you specify two date
ranges, the last one will be used and the other ignored. For example:

```d
auto stock = Stock("AAPL")
            .chart(ChartRange.TwoYears) // Ignored.
            .dividends(DividendRange.OneYear)
            .query();
```

Both `chart()` and `dividends()` in the above example will use the one year
range, due to the upstream API design limitations. Future versions of iex.d may
make two queries and merge the results before returning.
