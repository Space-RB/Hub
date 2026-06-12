local Event = "13.06"

local d,m = Event:match("(%d+)%.(%d+)")
return os.time() <= os.time{year=os.date("*t").year, month=m, day=d};
