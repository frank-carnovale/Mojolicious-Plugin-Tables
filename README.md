
[![Build Status](https://travis-ci.org/frank-carnovale/Mojolicious-Plugin-Tables.svg?branch=master)](https://travis-ci.org/frank-carnovale/Mojolicious-Plugin-Tables)

Running the Test application
----------------------------

The test scripts run a minimal app called 'blah',
against a sample SQLite database.

To actually run the test app, do this:

EXAMPLEDB=t/example.db t/blah/script/blah daemon

Building a distribution
-----------------------
perl Makefile.PL
make test
make manifest
make dist
mojo cpanify -u USER -p PASS *Tables*tar.gz

