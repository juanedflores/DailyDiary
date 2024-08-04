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
        self.nvim.out_write('started plugin')
        self.nvim.out_write("\n")

    @pynvim.autocmd('BufNewFile', pattern='~/*.wiki', eval=None, sync=False)
    def test(self):
        global diaryPath
        self.nvim.command_output("echom g:vimwikidiaryPath")
        self.nvim.command_output("\n")
        buf = self.nvim.current.buffer

        dow = calendar.day_name[datetime.date.today().weekday()]
        m = datetime.datetime.now().strftime("%b")
        day = datetime.datetime.today().day
        d = ordinal(day)

        today_date = (datetime.date.today())

        line1 = "# " + dow + ", " + m + " " + d
        line2 = ""
        line3 = "## Due Soon | due:({})".format(today_date)
        line4 = ""
        line5 = "## Goals for Today | status:pending".format(today_date)
        line6 = ""
        line7 = "## Issues Encountered"
        line8 = ""
        line9 = "## Notes"
        line10 = ""
        line11 = '![[{}-canvas.canvas]]'.format(today_date)

        buf[0] = line1
        buf.append(line2, index=-1)
        buf.append(line3, index=-1)
        buf.append(line4, index=-1)
        buf.append(line5, index=-1)
        buf.append(line6, index=-1)
        buf.append(line7, index=-1)
        buf.append(line8, index=-1)
        buf.append(line9, index=-1)
        buf.append(line10, index=-1)
        buf.append(line11, index=-1)
        # self.nvim.out_write('loaded diary template!')
        # self.nvim.out_write("\n")

    @pynvim.autocmd('BufNewFile', pattern=diaryPath+'/*.md', eval=None, sync=False)
    def testmd(self):
        global diaryPath
        self.nvim.command_output("echom g:vimwikidiaryPath")
        self.nvim.command_output("\n")
        buf = self.nvim.current.buffer

        dow = calendar.day_name[datetime.date.today().weekday()]
        m = datetime.datetime.now().strftime("%b")
        day = datetime.datetime.today().day
        d = ordinal(day)

        today_date = (datetime.date.today())

        line1 = "# " + dow + ", " + m + " " + d
        line2 = ""
        line3 = "## Due Soon | due:({})".format(today_date)
        line4 = ""
        line5 = "## Goals for Today | status:pending".format(today_date)
        line6 = ""
        line7 = "## Issues Encountered"
        line8 = ""
        line9 = "## Notes"
        line10 = ""
        line11 = '![[{}-canvas.canvas]]'.format(today_date)

        buf[0] = line1
        buf.append(line2, index=-1)
        buf.append(line3, index=-1)
        buf.append(line4, index=-1)
        buf.append(line5, index=-1)
        buf.append(line6, index=-1)
        buf.append(line7, index=-1)
        buf.append(line8, index=-1)
        buf.append(line9, index=-1)
        buf.append(line10, index=-1)
        buf.append(line11, index=-1)
        # self.nvim.out_write('loading diary template!')
        # self.nvim.out_write("\n")


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
