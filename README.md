# Holidays.jl

[![Build Status](https://travis-ci.org/invenia/Holidays.jl.svg?branch=master)](https://travis-ci.org/invenia/Holidays.jl)
[![Coverage Status](https://coveralls.io/repos/github/invenia/Holidays.jl/badge.svg?branch=master)](https://coveralls.io/github/invenia/Holidays.jl?branch=master)
[![codecov.io](https://codecov.io/github/invenia/Holidays.jl/coverage.svg?branch=master)](https://codecov.io/github/invenia/Holidays.jl?branch=master)

Julia library for handling holidays

## Example Usage

    using Holidays
    country = "CA"
    println(country_regions(country))
    # --> ["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YU"]

    province = "MB"
    dates = holiday_cache(country=country, region=province)
    println(day_name(Date(2011, 1, 1), dates))
    # --> "New Year's Day"

## Available Countries

All currently available country codes and their correspondign lists of regions are listed below.

    Country |   Regions:
    "CA"    |   ["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YU"]
    "US"    |   ["AL", "AK", "AS", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "GU",
                "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MH", "MA", "MI",
                "FM", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND",
                "MP", "OH", "OK", "OR", "PW", "PA", "PR", "RI", "SC", "SD", "TN", "TX", "UT",
                "VT", "VA", "VI", "WA", "WV", "WI", "WY"]
    "MX"    |   [""]
    "NZ"    |   ["NTL", "AUK", "TKI", "HKB", "WGN", "MBH", "NSN", "CAN", "STC", "WTL", "OTA", "STL", "CIT"]
    "AU"    |   ["ACT", "NSW", "NT", "QLD", "SA", "TAS", "VIC", "WA"]
    "AT"    |   ["B", "K", "N", "O", "S", "ST", "T", "V", "W"]
    "DE"    |   ["BW", "BY", "BE", "BB", "HB", "HH", "HE", "MV", "NI", "NW", "RP", "SL", "SN", "ST", "SH", "TH"]


## API

Presently, there are only a few functions exported by this module by default. country_regions, holiday_cache, and day_name

*    `holiday_cache(; country::AbstractString="CA", region::AbstractString="MB", expand::Bool=true, observed::Bool=true, years::Array{Int}=Int[])`:

    Populates holiday cache for the given years, country, and region. If observed is true, then
    alternative observed dates will be set as well. If expand is true, then whenever a lookup
    is made for a non cached date, that year of holidays will be populated in the cache.

    Returns:
    - `HolidayBase`: The cache for future calls to lookup dates.

*   `day_name(date::Date, holidays::HolidayBase)`: Find corresponding holiday names for a date. If
    the given date is in the holiday cache this is a simple lookup. If it is not in cache, and
    expand is enabled, then the new year will be populated. Otherwise this will just return nothing.

    Returns:
    - `AbstractString`: Holiday name for the given date, or Void if there is no corresponding holiday name.

*   `country_regions(country::AbstractString)`: For lookup of regions in a country

    Returns:
    - `Array{AbstractString,N}`: Recognized regions within a given country



## Running Tests

There is a build script for appveyor, but currently appveyor is disabled. PyCall in windows has some critical issues which makes the tests impossible to run.

#### Preparing for Tests

If testing, you will need to install python, and pip install holidays

#### Verify that julia and python agree

To run the default tests:

`Pkg.test("Holidays")`

This test has three configurable constants you may want to change.

regions:
The keys of this dict are all country codes to test against. The corresponding Array is a list of province codes to test with this country.

    const regions = Dict(
        "CA"=>["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YU"],
        "US"=>["AL", "AK", "AS", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "GU", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MH", "MA", "MI", "FM", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "MP", "OH", "OK", "OR", "PW", "PA", "PR", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "VI", "WA", "WV", "WI", "WY"],
        "MX"=>[""],
        "NZ"=>["NTL", "AUK", "TKI", "HKB", "WGN", "MBH", "NSN", "CAN", "STC", "WTL", "OTA", "STL", "CIT"],
        "AU" => ["ACT", "NSW", "NT", "QLD", "SA", "TAS", "VIC", "WA"],
        "AT" => ["B", "K", "N", "O", "S", "ST", "T", "V", "W"],
        "DE" => ["BW", "BY", "BE", "BB", "HB", "HH", "HE", "MV", "NI", "NW", "RP", "SL", "SN", "ST", "SH", "TH"],
    )

start and end date:

    # Set first and last date in loop
    start_date = Date(1970, 1, 1)
    last_date = Date(2030, 1, 1)

When tests are run, the program will loop through every region of every country. In each of these regions, it will loop all days from start_date to end_date and verify that this program has output matching holidays.py. Extensive testing (Over several centuries) can be rather slow, so configure the parameters according to what regions and times you need to verify succeed.

#### Check julia library speed and allocation vs python:

This script is useful for checking if this library is performing well in the version of julia installed.

`julia benchmark.jl`

This program loops from start_date to end_date querying the name of every date on the way. With a relatively light load:

    start_date = Date(2010, 1, 1)
    last_date = Date(2020, 1, 1)

Julia should be about 64 times faster than python, after it has been run once.

    Python: 16.329613 seconds (9.10 M allocations: 212.836 MB, 0.74% gc time)
    Julia : 0.264640 seconds (1.53 M allocations: 25.844 MB, 3.74% gc time)
