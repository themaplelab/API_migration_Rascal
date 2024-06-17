import re
import subprocess
import sys


def wrk_data(wrk_output):
    return str(wrk_output.get('lat_count')) + ',' + str(wrk_output.get('lat_avg')) + ',' + str(wrk_output.get('lat_stdev')) + ',' + str(
        wrk_output.get('lat_max')) + ',' + str(wrk_output.get('req_count')) + ',' + str(wrk_output.get('req_avg')) + ',' + str(
        wrk_output.get('req_stdev')) + ',' + str(wrk_output.get('req_max')) + ',' + str(
        wrk_output.get('tot_requests')) + ',' + str(wrk_output.get('tot_duration')) + ',' + str(
        wrk_output.get('read')) + ',' + str(wrk_output.get('req_sec_tot')) + ',' + str(
        wrk_output.get('read_tot'))


def get_bytes(size_str):
    x = re.search("^(\d+\.*\d*)(\w+)$", size_str)
    if x is not None:
        size = float(x.group(1))
        suffix = (x.group(2)).lower()
    else:
        return size_str

    if suffix == 'b':
        return size
    elif suffix == 'kb' or suffix == 'kib':
        return size * 1024
    elif suffix == 'mb' or suffix == 'mib':
        return size * 1024 ** 2
    elif suffix == 'gb' or suffix == 'gib':
        return size * 1024 ** 3
    elif suffix == 'tb' or suffix == 'tib':
        return size * 1024 ** 3
    elif suffix == 'pb' or suffix == 'pib':
        return size * 1024 ** 4

    return False


def get_number(number_str):
    x = re.search("^(\d+\.*\d*)(\w*)$", number_str)
    if x is not None:
        size = float(x.group(1))
        suffix = (x.group(2)).lower()
    else:
        return number_str

    if suffix == 'k':
        return size * 1000
    elif suffix == 'm':
        return size * 1000 ** 2
    elif suffix == 'g':
        return size * 1000 ** 3
    elif suffix == 't':
        return size * 1000 ** 4
    elif suffix == 'p':
        return size * 1000 ** 5
    else:
        return size

    return False


def get_ms(time_str):
    x = re.search("^(\d+\.*\d*)(\w*)$", time_str)
    if x is not None:
        size = float(x.group(1))
        suffix = (x.group(2)).lower()
    else:
        return time_str

    if suffix == 'us':
        return size / 1000
    elif suffix == 'ms':
        return size
    elif suffix == 's':
        return size * 1000
    elif suffix == 'm':
        return size * 1000 * 60
    elif suffix == 'h':
        return size * 1000 * 60 * 60
    else:
        return size

    return False


def parse_wrk_output(wrk_output,retval,j):
    #retval = {}
    for line in wrk_output.splitlines():
        x = re.search("^\s+Latency\s+(\d+\.\d+\w*)\s+(\d+\.\d+\w*)\s+(\d+\.\d+\w*).*$", line)
        if x is not None:
            #print(x.group(1))
            #retval['lat_count'] = get_number(x.group(1))
            retval['lat_avg'] = get_ms(x.group(1))
            retval['lat_stdev'] = get_ms(x.group(2))
            retval['lat_max'] = get_ms(x.group(3))
        x = re.search("^\s+Req/Sec\s+(\d+\.\d+\w*)\s+(\d+\.\d+\w*)\s+(\d+\.\d+\w*).*$", line)
        if x is not None:
            #retval['req_count'] = get_number(x.group(1))
            retval['req_avg'] = get_number(x.group(1))
            retval['req_stdev'] = get_number(x.group(2))
            retval['req_max'] = get_number(x.group(3))
        x = re.search("^\s+(\d+)\ requests in (\d+\.\d+\w*)\,\ (\d+\.\d+\w*)\ read.*$", line)
        if x is not None:
            if j > 1:
                retval['tot_requests'] += get_number(x.group(1))
            else:
                retval['tot_requests'] = get_number(x.group(1))
            #retval['tot_requests'] = get_number(x.group(1))
            retval['tot_duration'] = get_ms(x.group(2))
            retval['read'] = get_bytes(x.group(3))
        x = re.search("^LatencySampleSize\:\s+(\d+\.*\d*).*$", line)
        if x is not None:
            retval['lat_count']=get_number(x.group(1))
        x = re.search("^RequestsSampleSize\:\s+(\d+\.*\d*).*$", line)
        if x is not None:
            if j > 1:
                retval['req_count'] += get_number(x.group(1))
            else:
                retval['req_count'] = get_number(x.group(1))
            #retval['req_count']=get_number(x.group(1))
        x = re.search("^Requests\/sec\:\s+(\d+\.*\d*).*$", line)
        if x is not None:
            if j > 1:
                retval['req_sec_tot'] += get_number(x.group(1))
            else:
                retval['req_sec_tot'] = get_number(x.group(1))
            #retval['req_sec_tot'] = get_number(x.group(1))
        x = re.search("^Transfer\/sec\:\s+(\d+\.*\d*\w+).*$", line)
        if x is not None:
            retval['read_tot'] = get_bytes(x.group(1))
    return retval


def readFile(n, fileName):
    file1 = open("/home/data/experiments/scripts/Data/undertow/" + n + "/" + fileName, "r+")
    return file1.read()


def writeFile(n, data):
    file1 = open("/home/data/experiments/scripts/Data/undertow/" + n + "/transformed_final_output_" + n +".csv", "w+")
    return file1.write(data)


def main(n):
    wrk_csv = '\'latency_count\',\'latency_avg\',\'latency_stdev\',\'latency_max\',\'req_count\',\'req_avg\',\'req_stdev\',\'req_max\', \'Total requests\'' \
              ',\'duration\',\'read\', \'reqests/sec\', \'transfers/sec\''
    for i in range(1, 21):
        retval = {}
        for j in range(1, 9):
        #for j in range(1,11):
            wrk_output = readFile(n,"output-" + str(i) + "-2-8098-" + str(j) + ".txt")
            print(str(wrk_output) + "\n\n")
            print("****wrk output dict: \n\n")
            wrk_output_dict = parse_wrk_output(wrk_output,retval,j)
            print(str(wrk_output_dict) + "\n\n")
        print("****wrk output csv line: \n\n")
        wrk_output_csv = wrk_data(wrk_output_dict)
        print(str(wrk_output_csv))
        wrk_csv += '\n'
        wrk_csv += wrk_output_csv
    writeFile(n,wrk_csv)


if __name__ == '__main__':
    n = str(sys.argv[1])
    main(n)
