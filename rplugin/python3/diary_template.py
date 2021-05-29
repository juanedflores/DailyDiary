#!/usr/bin/python3
import pynvim
import sys
import datetime
import calendar

@pynvim.plugin
class DiaryTemplate(object):
    global diaryPath
    diaryPath = ""

    def __init__(self, nvim):
        global diaryPath
        self.nvim = nvim
        diaryPath = self.nvim.command_output("echom g:vimwikidiaryPath")

    @pynvim.autocmd('BufNewFile', pattern=diaryPath+'/*.wiki', eval=None, sync=False)
    def test(self):
        global diaryPath
        buf = self.nvim.current.buffer

        dow = calendar.day_name[datetime.date.today().weekday()]
        m = datetime.datetime.now().strftime("%b")
        day = datetime.datetime.today().day
        d = ordinal(day)

        today_date = (datetime.date.today())

        line1 = "== " + dow + ", " + m + " " + d + " =="
        line2 = ""
        line3 = "=== Goals for Today | due:({}) ===".format(today_date)
        line4 = ""
        line5 = "=== Issues Encountered ==="
        line6 = ""
        line7 = "=== Notes ==="

        buf[0] = line1
        buf.append(line2, index=-1)
        buf.append(line3, index=-1)
        buf.append(line4, index=-1)
        buf.append(line5, index=-1)
        buf.append(line6, index=-1)
        buf.append(line7, index=-1)
        self.nvim.out_write('loading diary template!')



def ordinal(num):
    """Returns ordinal number string from int,
       e.g. 1, 2, 3 becomes 1st, 2nd, 3rd, etc. """

    SUFFIXES = {1: 'st', 2: 'nd', 3: 'rd'}

    # 10-20 don't follow the normal counting scheme.
    if 10 <= num % 100 <= 20:
        suffix = 'th'
    else:
        # the second parameter is a default.
        suffix = SUFFIXES.get(num % 10, 'th')
    return str(num) + suffix
