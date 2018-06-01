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


@("quote() builds an endpoint for a single stock symbol")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL").quote();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/quote", stock.toURL());

    stock = Stock("AAPL").quote(true);
    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/AAPL/quote");
    assert(actual[1].hasParameters(["displayPercent=true"]));
}

@("quote() builds an endpoint for multiple stock symbols")
unittest {
    import std.string : split;
    auto stock = Stock("AAPL", "BDC").quote();
    assert(stock.toURL() == iexPrefix ~ "stock/market/batch?symbols=AAPL,BDC&types=quote", stock.toURL());

    stock = Stock("AAPL", "BDC").quote(true);
    auto actual = stock.toURL().split('?');
    assert(actual[0] == iexPrefix ~ "stock/market/batch");
    assert(actual[1].hasParameters(["symbols=AAPL,BDC", "types=quote", "displayPercent=true"]));
}

@("chart() builds an endpoint for pre-defined date ranges")
unittest {
    auto stock = Stock("AAPL").chart(ChartRange.YearToDate);
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/chart/"  ~ ChartRange.YTD,
            stock.toURL());

    stock = Stock("AAPL").chart(ChartRange.YearToDate, false, true, 3);

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
