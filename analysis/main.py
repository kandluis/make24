# -*- coding: utf-8 -*-
# @Author: Luis Perez
# @Date:   2016-10-04 17:43:01
# @Last Modified by:   Luis Perez
# @Last Modified time: 2016-10-04 17:53:57

from analysis import generateResultSet
from pprint import pprint
import argparse
import numpy as np

from solver import numberOfSolutions

parser = argparse.ArgumentParser(description='Solver for Make24 Game')
parser.add_argument('--output-results', dest='output', type=bool,
                    help='specify whether or not to pretty print results')
parser.add_argument('--solve', dest='solve', nargs='+', help="Solve the specified problem")

args = parser.parse_args()

if __name__ == '__main__':
	if not args.solve:
	    results = generateResultSet()
	    if args.output:
	        pprint(results)

	    solvable = len(filter(lambda x: x[1] != 0, results))
	    print "Percent with feasible solution {}.".format(
	        100 * solvable / float(len(results)))
	else:
		_, ways = numberOfSolutions(args.solve, returnWays=True)
		pprint(ways)
