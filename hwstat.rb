#!/usr/bin/ruby

require 'json'

STDOUT.sync = true

NETDEV_NAME = ARGV[0]
INTERVAL = 1
NR_CORES = `cat /proc/cpuinfo | grep '^processor' | wc -l`.to_i

class Integer
    def diff(given)
        self - given
    end
end

class Array
    def diff(given)
        Array.new(self.length) { |i|
            self[i].diff(given[i])
        }
    end

    def to_i
        self.map { |x| x.to_i }
    end
end

class Hash
    def diff(given)
        self.keys.inject({}) { |ret, key|
            ret[key] = self[key].diff(given[key])
            ret
        }
    end
end

def get_hwstat
    hwstat = {}
    hwstat[:cpu] = open('/proc/stat') { |f|
        f.to_a[1..NR_CORES].map { |line|
            Hash[[:user, :nice, :system, :irq, :softirq].zip(line.split(' ').values_at(1, 2, 3, 6, 7).to_i)]
        }
    }
    hwstat[:netsnmp] = open('/proc/net/snmp') { |f|
        Hash[[:InSegs, :OutSegs, :RetransSegs].zip(f.select { |line| line.include?('Tcp:') }[1].split(' ').values_at(10, 11, 12).to_i)]
    }
    if NETDEV_NAME != nil
        hwstat[:netdev] = open('/proc/net/dev') { |f|
            items = [:bytes, :packets, :drop]
            tmp = f.find { |line| line.include?("#{NETDEV_NAME}") }.split(' ').values_at(1, 2, 4, 9, 10, 12).to_i
            {
                receive:
                Hash[items.zip(tmp[0, 3])],
                transmit:
                Hash[items.zip(tmp[3, 3])],
            }
        }
        hwstat[:interrupts] = open('/proc/interrupts') { |f|
            f.select { |line| line.include?("#{NETDEV_NAME}") }.inject({}) { |h, line|
                tmp = line.split(' ')
                h[tmp[NR_CORES + 2]] = tmp[1, NR_CORES].to_i
                h
            }
        }
    end
    hwstat
end

crr = get_hwstat
while true
    sleep INTERVAL
    prv, crr = crr, get_hwstat
    puts JSON.generate(crr.diff(prv))
end
