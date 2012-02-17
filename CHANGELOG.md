### 2.0.3 / 2012-02-17

* Added ability to override local queue name (example scenario: using
  two different queues for different mail priority levels)

### 2.0.2 / 2011-08-20

* Fixed deliver vs deliver! issue so mail interceptors will work as
  expected

### 2.0.1 / 2011-08-19

* Restore the mailer proxy object so mailer method bodies never get
  invoked more than once accidentally (not required to be idempotent)

### 2.0.0 / 2011-06-24

* Removed support for legacy Rails 2.x applications (please use v1.x)
* Removed mailer proxy, return Mail::Message object
* Reorganize and modernize gem structure, add bundler and move to RSpec 2.x
* Queue target (::Resque) can now be overridden for testing (Joshua
  Clayton)

### 1.0.1 / 2010-12-21

* Respect ActionMailer::Base.perform_deliveries

### v1.0.0 / 2010-07-28

* Added support for Rails 3.x (Marcin Kulik)
