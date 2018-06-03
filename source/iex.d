/** Wrapper for the IEX trading API.

    Documentation for the API is at https://iextrading.com/developer/docs/
*/
module iex;

import std.typecons : Flag;
public import std.typecons : Yes, No;

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
    KeyStats = "stats",
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

/** Specify response formats for endpoints that support alternatives to JSON. */
enum ResponseFormat : string {
    json = "json",
    csv = "csv",
    psv = "psv"
}

/** Build a query on the Stock endpoint of the IEX API.

    The string created by calling toURL() is an IEX API-compatible URL.
*/
// TODO: There is a maximum of 10 endpoints in a query.
struct Stock {

    @disable this();

    this(string[] symbols...) in {
        assert(symbols.length > 0);
    } do {
        this.symbols = symbols;
    }

    @property
    string toURL(string prefix = iexPrefix) {
        string queryString;

        if (this.queriesMultipleSymbols() || this.endpoints.length > 1) {
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
        } else {
            foreach (type, endpoint; this.endpoints) {
                foreach (key, val; endpoint.params) {
                    queryString ~= "&" ~ key ~ "=" ~ val;
                }
            }
        }

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

/+ TODO: I'd like to do this but can't generate docs for it.
    https://issues.dlang.org/show_bug.cgi?id=2420

string GenerateSimpleEndpoint(string endpoint, string type) {
    return
        "/** Test comment */" ~
        "Stock " ~ endpoint ~ "(Stock stock) {\n"
      ~ "    stock.addQueryType(" ~ type ~ ");\n"
      ~ "    return stock;\n"
      ~ "}";
}
mixin(GenerateSimpleEndpoint("book", "EndpointType.Book"));
+/


/** Get the book for the specified stock(s).

    The data returned includes information from both the "deep" and the "quote"
    endpoints.

    Notes:
        It appears that "deep" is undocumented and forbidden; legacy endpoint?
*/
Stock book(Stock stock) {
    stock.addQueryType(EndpointType.Book);
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
    OneMonth = "1m",
    OneDay = "1d",
    Dynamic = "dynamic"
}

/** Request historical prices for a stock.

    Params:
        range =             The date range for which to retrieve prices. A custom
                            date may be passed in the format "YYYYMMDD" within
                            the last thirty days.
        reset =             If Yes, the 1 day chart will reset at midnight
                            instead of 9:30 AM ET.
        simplify =          If Yes, runs a polyline simplification using the
                            Douglas-Peucker algorithm.
        changeFromClose =   If Yes, "changeOverTime" and "marketChangeOverTime"
                            will be relative to the previous day close instead of
                            the first value.
        last =              Return the last n elements.
*/
Stock chart(
        Stock stock,
        string range,
        Flag!"resetAtMidnight" resetAtMidnight = No.resetAtMidnight,
        Flag!"simplify" simplify = No.simplify,
        int interval = -1,
        Flag!"changeFromClose" changeFromClose = No.changeFromClose,
        int last = -1) {
    import std.conv : text;
    import std.string : isNumeric;
    // TODO: Enforce custom date is within last thirty days.
    // TODO: I think last overrides range; test this, and if so, only take one
    // or the other.

    string[string] params;

    if (resetAtMidnight) params["chartReset"] = "true";
    if (simplify) params["chartSimplify"] = "true";
    if (interval > 0) params["chartInterval"] = interval.text;
    if (changeFromClose) params["changeFromClose"] = "true";
    if (last > 0) params["chartLast"] = last.text;

    if (stock.queriesMultipleSymbols()) {
        params["range"] = range;
    }

    if (range.isNumeric && range.length == 8)
        stock.addQueryType(EndpointType.Chart, params, "/date/" ~ range);
    else if (hasEnumMember!ChartRange(range))
        stock.addQueryType(EndpointType.Chart, params, "/" ~ range);
    else
        throw new Exception("Invalid range for chart: " ~ range);

    return stock;
}

/// ditto
Stock historicalPrices(
        Stock stock,
        string range,
        Flag!"resetAtMidnight" resetAtMidnight = No.resetAtMidnight,
        Flag!"simplify" simplify = No.simplify,
        int interval = -1,
        Flag!"changeFromClose" changeFromClose = No.changeFromClose,
        int last = -1) {
    return chart(stock, range,
            resetAtMidnight, simplify, interval, changeFromClose, last);
}

/// ditto
Stock timeSeries(
        Stock stock,
        string range,
        Flag!"resetAtMidnight" resetAtMidnight = No.resetAtMidnight,
        Flag!"simplify" simplify = No.simplify,
        int interval = -1,
        Flag!"changeFromClose" changeFromClose = No.changeFromClose,
        int last = -1) {
    return chart(stock, range,
            resetAtMidnight, simplify, interval, changeFromClose, last);
}


/** Retrieve information about the specified company. */
Stock company(Stock stock) {
    stock.addQueryType(EndpointType.Company);
    return stock;
}


/** Retrieve the 15-minute delayed market quote. */
Stock delayedQuote(Stock stock) {
    stock.addQueryType(EndpointType.DelayedQuote);
    return stock;
}

/** Values for the date range in a dividend query. */
enum DividendRange : string {
    FiveYears = "5y",
    TwoYears = "2y",
    OneYear = "1y",
    YearToDate = "ytd",
    YTD = ChartRange.YearToDate,
    SixMonths = "6m",
    ThreeMonths = "3m",
    OneMonth = "1m"
}

/** Request dividend distribution history.

    Params:
        range = The range for which the list of distributions is desired.
*/
Stock dividends(Stock stock, DividendRange range) {
    string[string] params;
    if (stock.queriesMultipleSymbols()) {
        params["range"] = range;
    }
    stock.addQueryType(EndpointType.Dividends, params, "/" ~ range);
    return stock;
}


/** Request earnings from the four most recent quarters. */
Stock earnings(Stock stock) {
    stock.addQueryType(EndpointType.Earnings);
    return stock;
}


/** Return the effective spread of a stock.

    Returns an array of effective spread, eligible volume, and price improvement.
*/
Stock effectiveSpread(Stock stock) {
    stock.addQueryType(EndpointType.EffectiveSpread);
    return stock;
}


/** Request a company's financial data.

    Retrieves the company's income statement, balance sheet, and cash flow
    statement from the four most recent quarters.
*/
Stock financials(Stock stock) {
    stock.addQueryType(EndpointType.Financials);
    return stock;
}

/** Request threshold securities.

    Params:
        date =  List data for the specified date in YYYYMMDD format, or "sample"
                for sample data.
        token = Your IEX account token; if not specified, the CUSIP field will
                be excluded from the results.
*/
Stock thresholdSecurities(
        Stock stock,
        string date = "",
        ResponseFormat format = ResponseFormat.json,
        string token = "") {
    string[string] params;
    if (token.length > 0) params["token"] = token;

    if (stock.queriesMultipleSymbols()) {
        if (date.length > 0) params["date"] = date;
    } else {
        stock.symbols[0] = "market";
    }

    if (format != ResponseFormat.json) {
        params["format"] = format;
    }

    stock.addQueryType(EndpointType.ThresholdSecuritiesList, params, "/" ~ date);
    return stock;
}


Stock shortInterest(
        Stock stock,
        string date = "",
        ResponseFormat format = ResponseFormat.json,
        string token = "") {
    string[string] params;
    if (token.length > 0) params["token"] = token;

    if (stock.queriesMultipleSymbols() && date.length > 0) {
        params["date"] = date;
    } else {
        if (stock.symbols[0] == "")
            stock.symbols[0] = "market";
    }

    if (format != ResponseFormat.json) {
        params["format"] = format;
    }

    stock.addQueryType(EndpointType.ShortInterestList, params, "/" ~ date);
    return stock;
}


/** Retrieve current stock information. */
Stock keyStats(Stock stock) {
    stock.addQueryType(EndpointType.KeyStats);
    return stock;
}


/** Retrieve 15-minute delayed last sale eligible trades. */
Stock largestTrades(Stock stock) {
    stock.addQueryType(EndpointType.LargestTrades);
    return stock;
}


enum MarketList : string {
    MostActive = "mostactive",
    Gainers = "gainers",
    Losers = "losers",
    volume = "iexvolume",
    percent = "iexpercent"
}

Stock list(
        Stock stock,
        MarketList list,
        Flag!"displayPercent" displayPercent = No.displayPercent) {
    string[string] params;
    if (stock.queriesMultipleSymbols())
        params["list"] = list;
    else
        stock.symbols[0] = "market";

    if (displayPercent) params["displayPercent"] = "true";

    stock.addQueryType(EndpointType.List, params, "/" ~ list);
    return stock;
}


/** Retrieve the URL to the company's logo. */
Stock logo(Stock stock) {
    stock.addQueryType(EndpointType.Logo);
    return stock;
}


/** Retrieve news about the specified stocks or the market.

    Params:
        last =  The number of news results to return, between 1 and 50 inclusive.
                The default is 10.
*/
Stock news(Stock stock, int last = 10) in {
    assert(last > 0 && last < 51, "last must be between 1 and 50 inclusive.");
} do {
    import std.conv : text;
    string[string] params;

    if (stock.queriesMultipleSymbols() && last != 10)
        params["last"] = last.text;

    if (last != 10)
        stock.addQueryType(EndpointType.News, params, "/last/" ~ last.text);
    else
        stock.addQueryType(EndpointType.News, params);

    return stock;
}


/** Retrieve the open and close for the specified symbol(s) or the market. */
Stock ohlc(Stock stock) {
    stock.addQueryType(EndpointType.OHLC);
    return stock;
}

// ditto
Stock openclose(Stock stock) { return ohlc(stock); }


/** Retrieve a list of IEX-defined peers for a stock. */
Stock peers(Stock stock) {
    stock.addQueryType(EndpointType.Peers);
    return stock;
}


/** Retrieve  the previous day adjusted price data for a stock or the market. */
Stock previous(Stock stock) {
    stock.addQueryType(EndpointType.Previous);
    return stock;
}


/** Retrieve the EIX real time price, the 15 minute delayed price, or previous
    close price.
*/
Stock price(Stock stock) {
    stock.addQueryType(EndpointType.Price);
    return stock;
}


/** Request a quote for the stock(s).

    Params:
        stock =             The Stock object to manipulate.
        displayPercent =    If Yes, percentage values are multiplied by 100.

    See_Also:
        https://iextrading.com/developer/docs/#quote
*/
Stock quote(Stock stock, Flag!"displayPercent" displayPercent = No.displayPercent) {
    string[string] params;
    if (displayPercent) params["displayPercent"] = "true";
    stock.addQueryType(EndpointType.Quote, params);
    return stock;
}


/** Retrieve a list of most active market symbols when peers are not available.
*/
Stock relevant(Stock stock) {
    stock.addQueryType(EndpointType.Relevant);
    return stock;
}


alias SplitRange = DividendRange;

/** Request a stock's split history.

    Params:
        range = The range for which the split history is desired.
*/
Stock splits(Stock stock, SplitRange range) {
    string[string] params;
    if (stock.queriesMultipleSymbols()) {
        params["range"] = range;
    }
    stock.addQueryType(EndpointType.Splits, params, "/" ~ range);
    return stock;
}


/** Retrieve the 15 minute delayed and 30 day average consolidated volume
    percentage of a stock by market.
*/
Stock volumeByVenue(Stock stock) {
    stock.addQueryType(EndpointType.VolumeByVenue);
    return stock;
}


private:

bool hasEnumMember(E, T)(T value) if (is(E == enum)) {
    import std.traits : EnumMembers;
    foreach (member; EnumMembers!E) {
        if (member == value) return true;
    }
    return false;
}
