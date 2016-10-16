'''
Online difficulty analyzer for 24 Game.

Users results from http://www.4nums.com/game/difficulties/

# @Author: Luis Perez
# @Date:   2016-10-15 19:56:11
# @Last Modified by:   Luis Perez
# @Last Modified time: 2016-10-15 22:51:09
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

    return zip(puzzles, scores)


def onlineResultSet(options=None):
    """Returns the result set"""
    options = {} if options is None else options
    results = {}

    page = requests.get(URL)
    tree = html.fromstring(page.content)

    results = findResults(tree)

    # Sort from easiest to hardest.
    results = sorted(list(results.iteritems()), key=lambda x: x[1])
    return results
