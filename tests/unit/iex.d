module unit.iex;

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
    assert(actual[1].hasParameters(["symbols=AAPL,BDC", "range=2y"]), actual[1]);
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


@("TODO: Determine desired behavior when chart and dividend have different ranges")
unittest {
    assert(false);
}
