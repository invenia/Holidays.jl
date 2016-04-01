x = UInt64(0)

while true
    weekday = Dates.Monday
    date = Date(1990, 1, 1)

    temp = Dates.tonext(x->Dates.dayofweek(x) == weekday, date)

    x = x + 1

    # When x reaches 65267, this will break.
    if x >= 65266
        println("temp   : ",temp)
        println("Count  : ",x)
    end
end
