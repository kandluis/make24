'''
Online difficulty analyzer for 24 Game.

Users results from http://www.4nums.com/game/difficulties/

# @Author: Luis Perez
# @Date:   2016-10-15 19:56:11
# @Last Modified by:   Luis Perez
# @Last Modified time: 2016-10-15 23:04:34
'''
import requests

from lxml import html

URL = "http://www.4nums.com/game/difficulties/"


def findResults(tree):
    """Returns a zipped list [(problem, difficulty)]"""
    xpath = '//*[@id="page_body"]/table/tr/td[{}]/text()'

    # Based on column path.
    puzzlesPath = xpath.format(2)
    scorePath = xpath.format(3)

    puzzles = [tuple(int(num) for num in problem.split())
               for problem in tree.xpath(puzzlesPath)[1:]]
    scores = [float(score) for score in tree.xpath(scorePath)[1:]]
    maxScore = max(scores)

    return zip(puzzles, scores)


def onlineResultSet(options=None):
    """
    Returns the result set

    options['maxInt'] [10] - problems only contain numbers <
    options['minInt'] [1] - problems only contain numbers >=
    """
    options = {} if options is None else options
    maxInt = options['maxInt'] if "maxInt" in options else 10
    minInt = options['minInt'] if "minInt" in options else 1
    possible = set(range(minInt, maxInt))

    def containsInvalidValue(tup):
        """ Returns true if the tuple contains an invalid value"""
        numbers = set(tup)
        return len(numbers.intersection(possible)) != len(numbers)

    results = {}

    page = requests.get(URL)
    tree = html.fromstring(page.content)

    results = [(problem, difficulty) for (problem, difficulty)
               in findResults(tree) if not containsInvalidValue(problem)]

    # Sort from easiest to hardest.
    results = sorted(results, key=lambda x: x[1])
    return results
