# Holidays.jl
Julia library for handling holidays

## Example Usage

    country = "CA"
    println(Holidays.countryRegions(country))
    # --> ["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YU"]
    
    province = "MB"
    dates = Holidays.Cache(country=country, region=province)
    println(dayName(dates, Date(2011, 1, 1))
    # --> "New Year's Day"
    
## Install

The library will need to be on Julia's search path, which can be done by creating a symlink, EX:

`~/.julia/v$julia_version/Holidays -> /path/to/Holidays.jl`

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

Presently, there are only a few functions exported by this module by default. countryRegions, holidayCache, and dayName

*    `holidayCache(; country::AbstractString="CA", region::AbstractString="MB", expand::Bool=true, observed::Bool=true, years::Array{Int}=Int[])`:
    
    Populates holiday cache for the given years, country, and region. If observed is true, then
    alternative observed dates will be set as well. If expand is true, then whenever a lookup
    is made for a non cached date, that year of holidays will be populated in the cache.
    
    Returns:
    - `HolidayBase`: The cache for future calls to lookup dates.

*   `dayName(date::Date, holidays::HolidayBase)`: Find corresponding holiday names for a date. If
    the given date is in the holiday cache this is a simple lookup. If it is not in cache, and
    expand is enabled, then the new year will be populated. Otherwise this will just return nothing.
    
    Returns:
    - `AbstractString`: Holiday name for the given date, or Void if there is no corresponding holiday name.

*   `countryRegions(country::AbstractString)`: For lookup of regions in a country

    Returns:
    - `Array{AbstractString,N}`: Recognized regions within a given country



## Running Tests

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

Julia should be about 8 times faster than python. For longer benchmarks this advantage increases.

    Python: 13.841760 seconds (9.23 M allocations: 218.168 MB, 0.76% gc time)
    Julia : 1.773025 seconds (3.06 M allocations: 93.850 MB, 1.53% gc time)