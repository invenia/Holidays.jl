using StackTraces

function datebreaker()
    # date = Date(2018, 1, 1)
    date = Date(2018, 1, 1)
    last_weekday = Dates.Monday

    x = UInt64(0)

    try
        # Loop until failure.
        while true
            # Loop through dates and weekdays
            # for weekday in (Dates.Monday, Dates.Tuesday, Dates.Wednesday, Dates.Thursday, Dates.Friday, Dates.Saturday, Dates.Sunday)
            for weekday in (Dates.Sunday, Dates.Monday, Dates.Saturday, Dates.Friday, Dates.Tuesday, Dates.Wednesday, Dates.Thursday)
                last_weekday = weekday

                date = Date(1967, 3, 9)
                last_date = Date(2024, 4, 2)

                while date < last_date
                    # This call is where the error will be raised from first...
                    temp = Dates.tonext(x->Dates.dayofweek(x) == weekday, date)

                    x = x + 1

                    date = date + Dates.Day(1)
                end
            end
        end
    catch e
        # Help diagnose the error by printing as much stuff as possible.
        whos()
        println(stacktrace())
        println("Error",e)
        println("Last date tried:",date)
        println("Last weekday tried:",last_weekday)
        println("Successful Runs:",x)
        return false
    end

    return true
end

# Loop this until the error happens...
@time datebreaker()
