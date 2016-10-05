# -*- coding: utf-8 -*-
# @Author: Luis Perez
# @Date:   2016-10-04 16:22:28
# @Last Modified by:   Luis Perez
# @Last Modified time: 2016-10-04 17:41:44

import solver


def generateProblem(options={}):
    '''
    A generator for Make24 problems.

    options.maxInt [10] - problems only contain numbers <
    options.minInt [1] - problems only contain numbers >=
    '''
    maxInt = options.maxInt if "maxInt" in options else 10
    minInt = options.minInt if "minInt" in options else 1
    for a in xrange(minInt, maxInt):
        for b in xrange(minInt, maxInt):
            for c in xrange(minInt, maxInt):
                for d in xrange(minInt, maxInt):
                    yield [a, b, c, d]


def easeOfSolution(problem, solutions):
    '''
    Lower the score, the easier the problem
    '''
    return len(solutions)


def generateResultSet(options={}):
    results = {}
    for problem in generateProblem(options):
        numSolutions, solutions = solver.numberOfSolutions(
            problem, returnWays=True)
        results[tuple(problem)] = easeOfSolution(problem, solutions)

    # sort from easiest to hardest (high ease to low ease)
    results = sorted(list(results.iteritems()), key=lambda x: -1 * x[1])
    return results
