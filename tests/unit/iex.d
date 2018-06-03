module unit.iex;

import unit_threaded : HiddenTest;

import iex;

version(unittest) {
    /**  Check that a string has the provided parameters in unittests.

        Parameters in a URL may be in any order, so a simple equality check is
        insufficient.
    */
    bool hasParameters(string input, string[] parameters) {
        import std.algorithm.searching : canFind;
        foreach (parameter; parameters) {
            if (! canFind(input, parameter)) return false;
        }
        return true;
    }

    @("hasParameters() checks for substrings")
    unittest {
        assert("some-url?one=two&three=four".hasParameters(["one=two","three=four"]));
        assert(! "some-url?one=two".hasParameters(["three=four"]));
    }
}


@("book() builds an endpoint for a single stock symbol")
unittest {
    auto stock = Stock("AAPL").book();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/book", stock.toURL());
}

@("book() builds an endpoint for multiple stock symbols")
unittest {
    auto stock = Stock("AAPL", "BDC").book();
    assert(stock.toURL() == iexPrefix ~ "stock/market/batch?symbols=AAPL,BDC&types=book", stock.toURL());
}


@("chart() builds an endpoint for pre-defined date ranges")
unittest {
    auto stock = Stock("AAPL").chart(ChartRange.YearToDate);
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/chart/"  ~ ChartRange.YTD,
            stock.toURL());

    stock = Stock("AAPL")
            .chart(ChartRange.YearToDate, No.resetAtMidnight, Yes.simplify, 3);

    import std.string : split;
    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/AAPL/chart/" ~ ChartRange.YTD,
            actual[0]);
    assert(actual[1].hasParameters(["chartSimplify=true", "chartInterval=3"]),
            actual[1]);
}

@("chart() builds an endpoint for custom dates")
unittest {
    auto stock = Stock("AAPL").chart("20180531");
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/chart/date/20180531",
            stock.toURL());
}

@("chart() builds an endpoint for multiple stock symbols")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL", "BDC").chart("1y");
    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/market/batch", actual[0]);
    assert(actual[1].hasParameters(["symbols=AAPL,BDC", "types=chart", "range=1y"]),
            actual[1]);

    stock = Stock("AAPL", "BDC").chart("20180531");
    actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/market/batch", actual[0]);
    assert(actual[1].hasParameters(
            ["symbols=AAPL,BDC", "types=chart", "range=20180531"]),
            actual[1]);
}

@("historicalPrices() is equivalent to chart()")
unittest {
    auto chart = Stock("AAPL").chart(ChartRange.OneYear);
    auto history = Stock("AAPL").historicalPrices(ChartRange.OneYear);
    assert(chart == history, history.toURL());
}

@("timeSeries() is equivalent to chart()")
unittest {
    auto chart = Stock("AAPL").chart(ChartRange.OneYear);
    auto series = Stock("AAPL").timeSeries(ChartRange.OneYear);
    assert(chart == series, series.toURL());
}


@("company() builds an endpoint for a single stock symbol")
unittest {
    auto stock = Stock("AAPL").company();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/company", stock.toURL());
}

@("company() builds an endpoint for multiple stock symbols")
unittest {
    auto stock = Stock("AAPL", "BDC").company();
    assert(stock.toURL() == iexPrefix ~ "stock/market/batch?symbols=AAPL,BDC&types=company", stock.toURL());
}


@("delayedQuote() builds an endpoint for a single stock symbol")
unittest {
    auto stock = Stock("AAPL").delayedQuote();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/delayed-quote", stock.toURL());
}

@("delayedQuote() builds an endpoint for multiple stock symbols")
unittest {
    auto stock = Stock("AAPL", "BDC").delayedQuote();
    assert(stock.toURL() ==
            iexPrefix ~ "stock/market/batch?symbols=AAPL,BDC&types=delayed-quote",
            stock.toURL());
}


@("dividends() builds an endpoint for a single stock symbol")
unittest {
    auto stock = Stock("AAPL").dividends(DividendRange.TwoYears);
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/dividends/2y", stock.toURL());
}

@("dividends() builds an endpoint for multiple stock symbols")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL", "BDC").dividends(DividendRange.TwoYears);
    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/market/batch", actual[0]);
    assert(actual[1].hasParameters(["symbols=AAPL,BDC", "types=dividends", "range=2y"]),
            actual[1]);
}


@("earnings() builds an endpoint for a single stock symbol")
unittest {
    auto stock = Stock("AAPL").earnings();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/earnings", stock.toURL());
}

@("earnings() builds an endpoint for multiple stock symbols")
unittest {
    auto stock = Stock("AAPL", "BDC").earnings();
    assert(stock.toURL() ==
            iexPrefix ~ "stock/market/batch?symbols=AAPL,BDC&types=earnings",
            stock.toURL());
}


@("effectiveSpread() builds an endpoint for a single stock symbol")
unittest {
    auto stock = Stock("AAPL").effectiveSpread();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/effective-spread",
            stock.toURL());
}

@("effectiveSpread() builds an endpoint for multiple stock symbols")
unittest {
    auto stock = Stock("AAPL", "BDC").effectiveSpread();
    assert(stock.toURL() ==
            iexPrefix ~ "stock/market/batch?symbols=AAPL,BDC&types=effective-spread",
            stock.toURL());
}


@("financials() builds an endpoint for a single stock symbol")
unittest {
    auto stock = Stock("AAPL").financials();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/financials",
            stock.toURL());
}

@("financials() builds an endpoint for multiple stock symbols")
unittest {
    auto stock = Stock("AAPL", "BDC").financials();
    assert(stock.toURL() ==
            iexPrefix ~ "stock/market/batch?symbols=AAPL,BDC&types=financials",
            stock.toURL());
}


@("thresholdSecurities() builds an endpoint for a single stock symbol")
unittest {
    import std.string : split;
    auto stock = Stock("market").thresholdSecurities();
    assert(stock.toURL() == iexPrefix ~ "stock/market/threshold-securities/",
            stock.toURL());

    stock = Stock("market").thresholdSecurities("20180531");
    assert(stock.toURL() ==
            iexPrefix ~ "stock/market/threshold-securities/" ~ "20180531",
            stock.toURL());
}

@("thresholdSecurities() ignores specific stock symbols passed to it")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL").thresholdSecurities();
    assert(stock.toURL() == iexPrefix ~ "stock/market/threshold-securities/",
            stock.toURL());
}

@("thresholdSecurities() builds an endpoint as part of a batch")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL", "BDC")
            .chart(ChartRange.YTD)
            .thresholdSecurities();

    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/market/batch", actual[0]);
    assert(actual[1].hasParameters(
            ["symbols=AAPL,BDC", "types=threshold-securities,chart", "range=ytd"]),
            actual[1]);
}


@("shortInterest() builds an endpoint for a single stock symbol")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL").shortInterest();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/short-interest/",
            stock.toURL());

    stock = Stock("AAPL").shortInterest("20180531", ResponseFormat.csv);
    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/AAPL/short-interest/20180531",
            actual[0]);
    assert(actual[1].hasParameters(["format=csv"]), actual[1]);
}

@("shortInterest() builds an endpoint for the market")
unittest {
    auto stock = Stock("").shortInterest();
    assert(stock.toURL() == iexPrefix ~ "stock/market/short-interest/",
            stock.toURL());

    stock = Stock("market").shortInterest();
    assert(stock.toURL() == iexPrefix ~ "stock/market/short-interest/",
            stock.toURL());
}


@("keyStats() builds an endpoint for a single stock symbol")
unittest {
    auto stock = Stock("AAPL").keyStats();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/stats",
            stock.toURL());
}

@("keyStats() builds an endpoint for multiple stock symbols")
unittest {
    auto stock = Stock("AAPL", "BDC").keyStats();
    assert(stock.toURL() ==
            iexPrefix ~ "stock/market/batch?symbols=AAPL,BDC&types=stats",
            stock.toURL());
}


@("largestTrades() builds an endpoint for a single stock symbol")
unittest {
    auto stock = Stock("AAPL").largestTrades();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/largest-trades",
            stock.toURL());
}

@("largestTrades() builds an endpoint for multiple stock symbols")
unittest {
    auto stock = Stock("AAPL", "BDC").largestTrades();
    assert(stock.toURL() ==
            iexPrefix ~ "stock/market/batch?symbols=AAPL,BDC&types=largest-trades",
            stock.toURL());
}


@("list() builds an endpoint for a single symbol")
unittest {
    import std.string : split;
    auto stock = Stock("").list(MarketList.MostActive);
    assert(stock.toURL() == iexPrefix ~ "stock/market/list/mostactive",
            stock.toURL());

    stock = Stock("").list(MarketList.MostActive, Yes.displayPercent);
    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/market/list/mostactive", actual[0]);
    assert(actual[1].hasParameters(["displayPercent=true"]), actual[1]);
}

@("list() ignores individual stock symbols passed to it")
unittest {
    auto stock = Stock("AAPL").list(MarketList.MostActive);
    assert(stock.toURL() == iexPrefix ~ "stock/market/list/mostactive",
            stock.toURL());
}


@("logo() builds an endpoint for a single symbol")
unittest {
    auto stock = Stock("AAPL").logo();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/logo",
            stock.toURL());
}

@("logo() builds an endpoint for multiple symbols")
unittest {
    auto stock = Stock("AAPL", "BDC").logo();
    assert(stock.toURL() ==
            iexPrefix ~ "stock/market/batch?symbols=AAPL,BDC&types=logo",
            stock.toURL());
}


@("news() builds an endpoint for a single symbol")
unittest {
    auto stock = Stock("AAPL").news();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/news", stock.toURL());

    stock = Stock("market").news();
    assert(stock.toURL() == iexPrefix ~ "stock/market/news", stock.toURL());

    stock = Stock("AAPL").news(5);
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/news/last/5", stock.toURL());
}

@("news() builds an endpoint for multiple symbols")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL", "BDC").news();
    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/market/batch", actual[0]);
    assert(actual[1].hasParameters(["symbols=AAPL,BDC", "types=news"]), actual[1]);

    stock = Stock("AAPL", "BDC").news(5);
    actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/market/batch", actual[0]);
    assert(actual[1].hasParameters(["symbols=AAPL,BDC", "types=news", "last=5"]),
            actual[1]);
}


@("ohlc() builds an endpoint for a single stock symbol")
unittest {
    auto stock = Stock("AAPL").ohlc();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/ohlc", stock.toURL());

    stock = Stock("market").ohlc();
    assert(stock.toURL() == iexPrefix ~ "stock/market/ohlc", stock.toURL());
}

@("ohlc() builds an endpoint for multiple symbols")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL", "BDC").ohlc();
    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/market/batch", actual[0]);
    assert(actual[1].hasParameters(["symbols=AAPL,BDC", "types=ohlc"]), actual[1]);
}

@("openclose() is equivalent to ohlc()")
unittest {
    auto ohlc = Stock("AAPL").ohlc();
    auto openclose = Stock("AAPL").openclose();
}


@("peers() builds an endpoint for a single stock symbol")
unittest {
    auto stock = Stock("AAPL").peers();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/peers", stock.toURL());
}

@("peers() builds an endpoint for multiple symbols")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL", "BDC").peers();
    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/market/batch", actual[0]);
    assert(actual[1].hasParameters(["symbols=AAPL,BDC", "types=peers"]), actual[1]);
}


@("previous() builds an endpoint for a single stock symbol")
unittest {
    auto stock = Stock("AAPL").previous();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/previous", stock.toURL());

    stock = Stock("market").previous();
    assert(stock.toURL() == iexPrefix ~ "stock/market/previous", stock.toURL());
}

@("ohlc() builds an endpoint for multiple symbols")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL", "BDC").previous();
    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/market/batch", actual[0]);
    assert(actual[1].hasParameters(["symbols=AAPL,BDC", "types=previous"]),
            actual[1]);
}


@("price() builds an endpoint for a single stock symbol")
unittest {
    auto stock = Stock("AAPL").price();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/price", stock.toURL());
}

@("price() builds an endpoint for multiple symbols")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL", "BDC").price();
    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/market/batch", actual[0]);
    assert(actual[1].hasParameters(["symbols=AAPL,BDC", "types=price"]),
            actual[1]);
}


@("quote() builds an endpoint for a single stock symbol")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL").quote();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/quote", stock.toURL());

    stock = Stock("AAPL").quote(Yes.displayPercent);
    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/AAPL/quote");
    assert(actual[1].hasParameters(["displayPercent=true"]));
}

@("quote() builds an endpoint for multiple stock symbols")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL", "BDC").quote();
    assert(stock.toURL() == iexPrefix ~ "stock/market/batch?symbols=AAPL,BDC&types=quote", stock.toURL());

    stock = Stock("AAPL", "BDC").quote(Yes.displayPercent);
    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/market/batch");
    assert(actual[1].hasParameters(["symbols=AAPL,BDC", "types=quote", "displayPercent=true"]));
}


@("relevant() builds an endpoint for a single stock symbol")
unittest {
    auto stock = Stock("AAPL").relevant();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/relevant", stock.toURL());
}

@("relevant() builds an endpoint for multiple symbols")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL", "BDC").relevant();
    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/market/batch", actual[0]);
    assert(actual[1].hasParameters(["symbols=AAPL,BDC", "types=relevant"]), actual[1]);
}


@("splits() builds an endpoint for a single stock symbol")
unittest {
    auto stock = Stock("AAPL").splits(SplitRange.TwoYears);
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/splits/2y", stock.toURL());
}

@("splits() builds an endpoint for multiple stock symbols")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL", "BDC").splits(SplitRange.TwoYears);
    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/market/batch", actual[0]);
    assert(actual[1].hasParameters(["symbols=AAPL,BDC", "range=2y", "types=splits"]),
            actual[1]);
}


@("volumeByVenue() builds an endpoint for a single stock symbol")
unittest {
    auto stock = Stock("AAPL").volumeByVenue();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/volume-by-venue", stock.toURL());
}

@("volumeByVenue() builds an endpoint for multiple stock symbols")
unittest {
    auto stock = Stock("AAPL", "BDC").volumeByVenue();
    assert(stock.toURL() ==
            iexPrefix ~ "stock/market/batch?symbols=AAPL,BDC&types=volume-by-venue",
            stock.toURL());
}


@("Build multiple-symbol batch endpoints")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL", "BDC")
            .quote()
            .news(5) // Last 5 items.
            .chart(ChartRange.OneMonth);

    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/market/batch", actual[0]);
    assert(actual[1].hasParameters(
            ["symbols=AAPL,BDC", "types=quote,chart,news", "range=1m", "last=5"]),
            actual[1]);
}

@HiddenTest("waiting until most endpoints are ready to determine desired API")
@("TODO: Determine desired behavior when chart and dividend have different ranges")
/+ I don't think I like this, but it's better than allowing inconsistency.

    auto stock = Stock("AAPL")
                .chart()
                .dividends()
                    .sharedParams("1y");
+/
unittest {
    assert(false, "not implemented");
}
