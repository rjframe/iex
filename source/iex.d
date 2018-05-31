module iex;

import vibe.data.json;

enum iexPrefix = "https://api.iextrading.com/1.0/";

enum EndpointType : string {
    Book = "book",
    Chart = "chart",
    HistoricalPrices = "chart",
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

alias ParamSet = string[string];

/** Build a query on the Stock endpoint of the IEX API.

    The string created by calling toURL() is an IEX API-compatible URL.
*/
// TODO: There is a maximum of 10 endpoints in a query.
struct Stock {
    this(string symbol) {
        this.symbols ~= symbol;
    }

    this(string[] symbols) in {
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
        } else {
            queryString = "stock/" ~ symbols[0] ~ "/";
        }

        if (paramSet.length == 1) {
            queryString ~= buildEndpoint(paramSet.keys()[0], paramSet[paramSet.keys()[0]]);
        } else
            assert(0, "Not implemented");

        return prefix ~ queryString;
    }

    private:

    void addQueryType(EndpointType type, string[string] params = null) {
        this.paramSet[type] = params;
    }

    string buildEndpoint(EndpointType type, ParamSet params) {
        if (params.length == 0) {
            return type;
        } else {
            string endpoint = type ~ "?";
            foreach (param, value; params) {
                endpoint ~= param ~ "=" ~ value ~ "&";
            }
            return endpoint[0..$-1];
        }
    }

    @property bool queriesMultipleSymbols() { return symbols.length > 1; }

    string[] symbols;

    ParamSet[EndpointType] paramSet;
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
    auto stock = Stock("AAPL").quote();
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/quote", stock.toURL());

    stock = Stock("AAPL").quote(true);
    assert(stock.toURL() == iexPrefix ~ "stock/AAPL/quote?displayPercent=true",
            stock.toURL());
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

