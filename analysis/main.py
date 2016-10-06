# -*- coding: utf-8 -*-
# @Author: Luis Perez
# @Date:   2016-10-04 17:43:01
# @Last Modified by:   Luis Perez
# @Last Modified time: 2016-10-06 00:47:17

from analysis import generateResultSet
from pprint import pprint
import argparse
import numpy as np
import csv

from solver import numberOfSolutions

parser = argparse.ArgumentParser(description='Solver for Make24 Game')
parser.add_argument('--print-results', dest='print_results', type=bool,
                    help='specify whether or not to pretty print results')
parser.add_argument('--solve', dest='solve', nargs='+',
                    help="Solve the specified problem")
parser.add_argument('--filename', dest='outname', type=str,
                    help='specify a filename for output')

args = parser.parse_args()

if __name__ == '__main__':
    if not args.solve:
        # TODO -- modify so that we can add more complexity to the result set.
        # We must also modify the printing to csv
        # Note that results is already sorted from easy to hard
        # [(problem, difficulty)]
        results = generateResultSet()
        if args.print_results:
            pprint(results)

        solvable = len(filter(lambda x: x[1] != 1, results))
        print "Percent with feasible solution {}.".format(
            100 * solvable / float(len(results)))

        if args.outname:
            with open('{}.csv'.format(args.outname), 'w') as csvfile:
                writer = csv.writer(csvfile, delimiter=',',
                                    quoting=csv.QUOTE_MINIMAL)

                columnNames = ['id', 'int1', 'int2',
                               'int3', 'int4', 'difficulty']
                writer.writerow(columnNames)
                for (i, (problem, score)) in enumerate(results):
                    row = [i] + list(problem) + [score]
                    writer.writerow(row)

    else:
        _, ways = numberOfSolutions([int(x)
                                     for x in args.solve], returnWays=True)
        pprint(ways)
