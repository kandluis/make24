'''
Online difficulty analyzer for 24 Game.

Users results from http://www.4nums.com/game/difficulties/

# @Author: Luis Perez
# @Date:   2016-10-15 19:56:11
# @Last Modified by:   Luis Perez
# @Last Modified time: 2016-10-15 19:58:32
'''


def onlineResultSet(options=None):
    """Returns the result set"""
    options = {} if options is None else options
    results = {}

    # Sort from easiest to hardest.
    results = sorted(list(results.iteritems()), key=lambda x: x[1])
    return results
