# Holidays.jl
Julia library for handling holidays

## Example Usage

## Install

The library will need to be on Julia's search path, which can be done by creating a symlink, EX:

`~/.julia/v$julia_version/Holidays -> /path/to/Holidays.jl`

## Available Countries

Currently only Canada is supported. Other countries will be added soon.

## API

## Running Tests

#### Preparing for Tests

If testing, you will need to install python, and pip install holidays

#### Verify that julia and python agree

To run the default tests:

`julia comparison.jl`

This test has three configurable constants you may want to change.

    # Add regions to test here
    regions = Dict(
        "CA"=>["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YU"]
    )
    
    # Set first and last date in loop
    start_date = Date(1970, 1, 1)
    last_date = Date(2030, 1, 1)

'regions' should be a dict mapping country codes to a list of provinces / states which you want to test. For every single region available, the test will then loop over every date from start_date to end_date comparing the python holidays output to the julia holidays output. To be more thorough you can expand the range of dates available and include all regions in the dict. However if you are debugging the script and only care about results for a few regions or dates you can easily narrow down the tests for speed.

#### Check julia library speed and allocation vs python:

Useful for checking if this library is performing well in the version of julia installed:

`julia benchmark.jl`

Currently, the julia implementation is roughly twice as fast and creates 1/4 the allocations of the python version on a given system.
