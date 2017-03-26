
from __future__ import print_function

import re
import sys
import json
import pytest

# exitcodes for the command line
EXIT_OK = 0
EXIT_TESTSFAILED = 1
EXIT_INTERRUPTED = 2
EXIT_INTERNALERROR = 3
EXIT_USAGEERROR = 4
EXIT_NOTESTSCOLLECTED = 5


def printJson(obj):
    print(json.dumps(obj))


class LattePlugin:
    ERROR_LOC_REGEX = re.compile("(.+):([0-9]+): in (.+)\n", re.MULTILINE)
    EXTRA_ERROR_REGEX = re.compile("\nE[ ]+(.*?)($|\n)")

    def pytest_configure(self, config):
        # simply default output
        self.config = config
        self.config.option.tbstyle = "short"

    def pytest_report_teststatus(self, report):
        # prevent the dots
        return report.outcome, "", report.outcome.upper()

    def pytest_runtest_logreport(self, report):
        if report.failed:
            extra = error = str(report.longrepr)
            m = LattePlugin.ERROR_LOC_REGEX.search(error)
            name = m.group(1)
            line = int(m.group(2))
            error = error[len(m.group(0)):]

            m = LattePlugin.EXTRA_ERROR_REGEX.search(error)
            if m:
                error = m.group(1).strip()

            resultDict = {
                't': 'test',
                'pass': False,
                'line': line,
                'name': name,
                'error': error,
                'extra': '\n' + extra,
            }

            if report.capstdout:
                resultDict['extra'] += "stdout>>\n" + report.capstdout
            if report.capstderr:
                resultDict['extra'] += "stderr>>\n" + report.capstderr

            printJson(resultDict)

        elif report.when == 'teardown':
            printJson({'t': 'test', 'pass': True})

    def pytest_sessionfinish(self, exitstatus):
        # hacks: if we disable this earlier, the error message is much
        # shorter, so we disable now to suppress the trailing report
        self.config.option.tbstyle = "no"

        allPassed = exitstatus == EXIT_OK
        extra = ''
        if exitstatus == EXIT_NOTESTSCOLLECTED:
            extra = ">> No Tests Collected!"
        elif exitstatus == EXIT_INTERNALERROR:
            extra = ">> Internal Error"
        elif exitstatus == EXIT_USAGEERROR:
            extra = ">> Usage Error"

        printJson({'t': 'done', 'allPassed': allPassed, 'extra': extra})

    def pytest_terminal_summary(self, terminalreporter):
        # do nothing
        pass

testFile = sys.argv[1]
pytest.main(['-qq', testFile], plugins=[LattePlugin()])
