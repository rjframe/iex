module iex;

import vibe.data.json;

enum iexPrefix = "https://api.iextrading.com/1.0/";

enum EndpointType : string {
    Book = "book",
    Chart = "chart",
    HistoricalPrices = EndpointType.Chart,
    Company = "company",
    DelayedQuote = "delayed-quote",
    Dividends = "dividends",
    Earnings = "earnings",
    EffectiveSpread = "effective-spread",
    Financials = "financials",
    ThresholdSecuritiesList = "threshold-securities",
    ShortInterestList = "short-interest",
    LargestTrades = "largest-trades",
    List = "list",
    Logo = "logo",
    News = "news",
    OHLC = "ohlc",
    OpenClose = EndpointType.OHLC,
    Peers = "peers",
    Previous = "previous",
    Price = "price",
    Quote = "quote",
    Relevant = "relevant",
    Splits = "splits",
    TimeSeries = "time-series",
    VolumeByVenue = "volume-by-venue",
}

struct Endpoint {
    string urlString;
    string[string] params;
}

/** Build a query on the Stock endpoint of the IEX API.

    The string created by calling toURL() is an IEX API-compatible URL.
*/
// TODO: There is a maximum of 10 endpoints in a query.
struct Stock {
    this(string[] symbols...) in {
        assert(symbols.length > 0);
    } do {
        this.symbols = symbols;
    }

    @property
    string toURL(string prefix = iexPrefix) {
        string queryString;

        if (this.queriesMultipleSymbols()) {
            queryString = "stock/market/batch?symbols=" ~ symbols[0];
            for (int i = 1; i < symbols.length; ++i) {
                queryString ~= "," ~ symbols[i];
            }

            queryString ~= "&types=";
            foreach (type, params; this.endpoints) {
                 queryString ~= type ~ ",";
            }
            queryString = queryString[0..$-1];
        } else {
            queryString = "stock/" ~ symbols[0] ~ "/";
        }

        if (this.endpoints.length == 1) {
            queryString ~= buildEndpoint(
                    this.endpoints.keys()[0],
                    this.endpoints[this.endpoints.keys()[0]],
                    this.queriesMultipleSymbols());
        } else
            assert(0, "Not implemented");

        return prefix ~ queryString;
    }

    private:

    /** Add a query type to the Stock HTTP query.

        Params:
            type =          The type of the endpoint to add.
            params =        Any parameters to include.
            urlAddition =   Any necessary text to append to the endpoint.
    */
    void addQueryType(
            EndpointType type,
            string[string] params = null,
            string urlAddition = "") {
        Endpoint p = {
            urlString: type ~ urlAddition,
            params: params
        };
        this.endpoints[type] = p;
    }

    string buildEndpoint(
            EndpointType type,
            Endpoint endpoint,
            bool isContinuing = false) {

        if (endpoint.params.length == 0) {
            return isContinuing ? "" : endpoint.urlString;
        } else {
            string endpointString = isContinuing ? "&" : endpoint.urlString ~ "?";
            foreach (param, value; endpoint.params) {
                endpointString ~= param ~ "=" ~ value ~ "&";
            }
            return endpointString[0..$-1];
        }
    }

    @property bool queriesMultipleSymbols() { return symbols.length > 1; }

    string[] symbols;

    Endpoint[EndpointType] endpoints;
}

/** Send a Query object to the IEX API and return the JSON results. */
Json query(Stock query) {
    import std.conv : to;
    import requests : getContent;
    return getContent(query.toURL()).to!string().parseJsonString();
}

/** Make an arbitrary call to the IEX API.

    This is here to allow retrieving data from currently-unsupported endpoints.
    This function is not permanent.
*/
Json query(string query, string prefix = iexPrefix) {
    import std.conv : to;
    import requests : getContent;
    return getContent(prefix ~ query).to!string().parseJsonString();
}

/// ditto
Json query(string query, string[string] params, string prefix = iexPrefix) {
    import std.conv : to;
    import requests : getContent;
    return getContent(prefix ~ query, params).to!string().parseJsonString();
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

/** Request a quote for the stock(s).

    Params:
        stock =             The Stock object to manipulate.
        displayPercent =    If true, percentage values are multiplied by 100.

    See_Also:
        https://iextrading.com/developer/docs/#quote
*/
Stock quote(Stock stock, bool displayPercent = false) {
    string[string] params;
    if (displayPercent) params["displayPercent"] = "true";
    stock.addQueryType(EndpointType.Quote, params);
    return stock;
}

/** Values for the date range in a chart query. A custom date can be used
    instead.
*/
enum ChartRange : string {
    FiveYears = "5y",
    TwoYears = "2y",
    OneYear = "1y",
    YearToDate = "ytd",
    YTD = ChartRange.YearToDate,
    SixMonths = "6m",
    ThreeMonths = "3m",
    OneDay = "1d",
    Dynamic = "dynamic"
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
}

@("chart() builds an endpoint for multiple stock symbols")
unittest {
}

bool hasEnumMember(E, T)(T value) if (is(E == enum)) {
    import std.traits : EnumMembers;
    foreach (member; EnumMembers!E) {
        if (member == value) return true;
    }
    return false;
}

// TODO Doc: date currently only supports last 30 days.
Stock chart(Stock stock, string range,
        bool resetAtMidnight = false, bool simplify = false, int interval = -1,
        bool changeFromClose = false, int last = -1) {
    import std.conv : text;
    import std.string : isNumeric;

    string[string] params;
    if (! (hasEnumMember!ChartRange(range)
            || (range.isNumeric && range.length == 8))) {
        throw new Exception("Invalid range for chart: " ~ range);
    }

    if (resetAtMidnight) params["chartReset"] = "true";
    if (simplify) params["chartSimplify"] = "true";
    if (interval > 0) params["chartInterval"] = interval.text;
    if (changeFromClose) params["changeFromClose"] = "true";
    if (last > 0) params["chartLast"] = last.text;

    stock.addQueryType(EndpointType.Chart, params, "/" ~ range);
    return stock;
}

private:

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
