# Chartboost Mediation SDK Test Plans

Our unit tests are run in Xcode Test Plans. This allows us to configure what tests are run and how.
We currently have two test plans:

## All Tests

This is the test plan intended to be run by CI.
Includes all the tests, and runs them 3 times each.
It is run by our fastlane 'tests' lane.

## Fast Tests

This is the test plan intended to be run locally to validate changes before pushing them.
Includes only tests that run quickly, and runs them only once.
It is default test plan (the one run when you hit ⌘U if the HeliumSdk scheme is selected).
