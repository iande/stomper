# Changes

## 2.0.2 - 2011-03-01

* updated to-do's and version number in README.md

* added CHANGELOG.md

* connection's @close@ method now clears remaining subscriptions and receipt
  handlers after all events are fired. should ease the work
  the failover extension has to do to re-subscribe appropriately.
  
* corrected spec tests to handle features introduced in 2.0.1 - should not
  have pushed a new version until those specs were run.

## 2.0.1 - 2011-02-27

* connection now raises exception in threaded receiver to stop, prevents
  blocking on @receive@
  
* connection terminated event now fires properly, fixes #1

* subscription manager clears remaining subscriptions when the connection
  is closed, fixes #2

## 2.0.0 - 2011-02-22

* Rewrite of stomper