#!/usr/bin/env ruby

require 'curses'

TABLE_COLUMN_WIDTH = 12

Curses.init_screen
Curses.noecho
Curses.curs_set(0)
Curses.start_color
Curses.init_pair(1, Curses::COLOR_WHITE, Curses::COLOR_BLACK)
Curses.init_pair(2, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
Curses.init_pair(3, Curses::COLOR_CYAN, Curses::COLOR_BLACK)
Curses.init_pair(4, Curses::COLOR_RED, Curses::COLOR_BLACK)
Curses.init_pair(5, Curses::COLOR_MAGENTA, Curses::COLOR_BLACK)
Curses.init_pair(6, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)

while true
    hwstat = eval Curses.getstr
    Curses.clear
    Curses.setpos(0, 0)

    Curses.attron(Curses.color_pair(1))
    Curses.addstr("[CPU]\n")
    Curses.attroff(Curses::A_COLOR)
    hwstat[:cpu].each_with_index { |percpu, id|
        Curses.attron(Curses.color_pair(1))
        Curses.addstr("cpu#{id}: #{sprintf('%3d', percpu.each_value.inject(0) { |s, x| s + x })} ")
        Curses.attroff(Curses::A_COLOR)
        [:user, :nice, :system, :irq, :softirq].each_with_index { |key, i|
            Curses.attron(Curses.color_pair(i + 2))
            Curses.addstr('|' * percpu[key])
            Curses.attroff(Curses::A_COLOR)
        }
        Curses.addstr("\n")
    }

    Curses.attron(Curses.color_pair(1))
    Curses.addstr("\n" <<
                  "[TCP]\n" <<
                  hwstat[:netsnmp].inject('') { |s, (k, v)| s << sprintf("%#{TABLE_COLUMN_WIDTH}s", k) } << "\n" <<
                  '-' * TABLE_COLUMN_WIDTH * hwstat[:netsnmp].length << "\n" <<
                  hwstat[:netsnmp].inject('') { |s, (k, v)| s << sprintf("%#{TABLE_COLUMN_WIDTH}s", v) } << "\n" <<
                  "\n" <<
                  "[Network]\n" <<
                  '        type |         Mb/s' <<
                  (hwstat[:netdev][:receive].keys - [:bytes]).inject('') { |s, item| s << sprintf("%#{TABLE_COLUMN_WIDTH}s", item) } << "\n" <<
                  '-' * (3 + TABLE_COLUMN_WIDTH * (hwstat[:netdev][:receive].keys.length + 1)) << "\n" <<
                  hwstat[:netdev].inject('') { |s, (k, v)|
                      s << sprintf("%#{TABLE_COLUMN_WIDTH}s", k) << " | " <<
                      sprintf("%#{TABLE_COLUMN_WIDTH}.3f", v[:bytes] * 8 / 1000000.0) <<
                      (v.keys - [:bytes]).inject('') { |s, item| s << sprintf("%#{TABLE_COLUMN_WIDTH}d", v[item]) } << "\n"
                  } <<
                  "\n" <<
                  "[Interrupts]\n" <<
                  '        name | ' << hwstat[:cpu].length.times.inject('') { |s, i| s << "        cpu#{i}" } << "\n" <<
                  '-' * (15 + 12 * hwstat[:cpu].length) << "\n" <<
                  hwstat[:interrupts].inject('') { |s, (k, v)|
                      s << sprintf("%#{TABLE_COLUMN_WIDTH}s", k) << " | " <<
                      v.inject('') { |s, x| s << sprintf("%#{TABLE_COLUMN_WIDTH}d", x) } << "\n"
                  })
    Curses.attroff(Curses::A_COLOR)

    Curses.refresh
end

Curses.close_screen
