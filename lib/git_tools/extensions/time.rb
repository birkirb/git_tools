require 'time'
require 'git_tools/extensions/string'

class Time

  DAYS_IN_YEAR = 365.2424
  SECONDS_IN_MINUTE =         60
  SECONDS_IN_HOUR   =      3_600
  SECONDS_IN_DAY    =     86_400
  SECONDS_IN_WEEK   =    604_800
  SECONDS_IN_YEAR   = 31_556_736 # AVERAGE
  SECONDS_IN_MONTH  = SECONDS_IN_YEAR/12 # AVERAGE

  HUMAN_TIMES  = [
    [SECONDS_IN_MINUTE, 120, "minutes"],
    [SECONDS_IN_HOUR  ,  72, "hours"],
    [SECONDS_IN_DAY   ,  21, "days"],
    [SECONDS_IN_WEEK  ,  12, "weeks"],
    [SECONDS_IN_MONTH ,  12, "months"]
    #[SECONDS_IN_YEAR  ,  10, "years"]
  ]

  def relative(t0 = Time.now)
    dt = self - t0

    if dt < 0
      tense = 'ago'
      dt = dt.abs - 1
    else
      tense = 'from now'
    end

    if dt < SECONDS_IN_MINUTE
      return 'now'.t
    else
      HUMAN_TIMES.each do |time|
        seconds    = time[0]
        limit      = time[1]
        time_unit  = time[2]

        if dt < seconds * limit
          return "{time} #{time_unit} #{tense}".multi_gsub!(:time => (dt/seconds).ceil.to_i)
        end
      end
      # Above the higest limit
      "over a year #{tense}".t
    end
  end

end
