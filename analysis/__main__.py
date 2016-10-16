"""
Problem difficulty generator for 24 Game
# @Author: Luis Perez
# @Date:   2016-10-04 17:43:01
# @Last Modified by:   Luis Perez
# @Last Modified time: 2016-10-15 21:59:31
"""

import argparse
import csv

from pprint import pprint

from .analysis import localResultSet
from .online import onlineResultSet
from .solver import numberOfSolutions


def generateParser():
    """Generates argument parser"""
    parser = argparse.ArgumentParser(description='Solver for Make24 Game')
    parser.add_argument('--hide-results', dest='print_results',
                        default=True, action="store_false",
                        help='Hide the results from stdout.')
    parser.add_argument('--solve', dest='solve', nargs='+',
                        help="Solve the specified problem.")
    parser.add_argument('--filename', dest='outname', type=str,
                        help='specify a filename for output.')
    parser.add_argument('--true-rank', dest="normalize",
                        default=True, action="store_false",
                        help="Display the true rank returned by ranking \
                        method")
    parser.add_argument('--all-problems', dest='filter',
                        default=True, action="store_false",
                        help="Report all problems, even unsolvable ones.")
    parser.add_argument('--min-integer', type=int, default=1, dest="min",
                        help="Problems generated containing an integer less \
                        than the specified value are thrown out from the \
                        analysis and results. [1]")
    parser.add_argument('--max_integer', type=int, default=10, dest="max",
                        help="Problems generated containing an integer greater \
                        than the specified value are thrown out from the \
                        analysis and results [10].")
    # TODO: Add ability to mix local and online results.
    # If both or only online: take online
    # If only local: Figure out a way to inject into online results based on
    # local ranking.
    parser.add_argument('--local', dest="local", default=True,
                        action="store_true", help="Performed difficulty \
                        analysis using our in-house problem generation and \
                        difficulty scoring system found in analysis.py.")
    parser.add_argument('--online', dest="local", default=True,
                        action="store_false", help="If true, difficulty \
                        analysis is performed using our in-house problem \
                        generation and difficulty scoring system found in \
                        analysis.py. Otherwise, problems are queried remotely \
                        from http://www.4nums.com/game/difficulties/. Note \
                        that such remote querying will necessarily limit \
                        problems.")

    return parser


def main(args):
    """Main function"""
    if not args.solve:
        # TODO -- modify so that we can add more complexity to the result set.
        # We must also modify the printing to csv
        # Note that results is already sorted from easy to hard
        # [(problem, difficulty)]
        options = {
            'maxInt': args.max + 1,
            'minInt': args.min
        }
        if args.local:
            results = localResultSet(options)
        else:
            results = onlineResultSet(options)
        totalResults = len(results)
        solvable = [result for result in results if result[1] != 1]

        if args.filter:
            results = solvable
        if args.normalize:
            results = [(problem, float(i) / len(results))
                       for (i, (problem, _)) in enumerate(results)]

        print "Percent with feasible solution {}.".format(
            100 * len(solvable) / float(totalResults))

        if args.print_results:
            pprint(results)

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
        _, ways = numberOfSolutions([int(num)
                                     for num in args.solve], returnWays=True)
        pprint(ways)


if __name__ == '__main__':
    main(generateParser().parse_args())
