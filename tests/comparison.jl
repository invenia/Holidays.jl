using PyCall

#Force load of python module in current directory
unshift!(PyVector(pyimport("sys")["path"]), "")

# Shall need to loop over the following:
# Australia     AU  prov = ACT (default), NSW, NT, QLD, SA, TAS, VIC, WA
# Austria   AT  prov = B, K, N, O, S, ST, T, V, W (default)
# Canada    CA  prov = AB, BC, MB, NB, NL, NS, NT, NU, ON (default), PE, QC, SK, YU
# Germany   DE  BW, BY, BE, BB, HB, HH, HE, MV, NI, NW, RP, SL, SN, ST, SH, TH
# Mexico    MX  None
# NewZealand    NZ  prov = NTL, AUK, TKI, HKB, WGN, MBH, NSN, CAN, STC, WTL, OTA, STL, CIT
# UnitedStates  US  state = AL, AK, AS, AZ, AR, CA, CO, CT, DE, DC, FL, GA, GU, HI, ID, IL, IN, IA, KS, KY, LA, ME, MD, MH, MA, MI, FM, MN, MS, MO, MT, NE, NV, NH, NJ, NM, NY, NC, ND, MP, OH, OK, OR, PW, PA, PR, RI, SC, SD, TN, TX, UT, VT, VA, VI, WA, WV, WI, WY

# Then loop by date to compare holiday names for each.

regions = Dict(
    "CA"=>["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YU"]
)


@pyimport pyholiday

# date = Date(1700, 1, 1)
# last_date = Date(2100, 1, 1)

date = Date(1980, 1, 1)
last_date = Date(2020, 1, 1)

# 2.79 seconds for USA from 1700 to 2100
# 0.385139 seconds

@time while date < last_date
    x = pyholiday.get(date)
    date = date + Dates.Day(1)
end


