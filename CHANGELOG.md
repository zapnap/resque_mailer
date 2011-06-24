### 2.0.0

* Removed support for legacy Rails 2.x applications (please use v1.x)
* Removed mailer proxy, return Mail::Message object
* Reorganize and modernize gem structure, add bundler and move to RSpec 2.x
* Queue target (::Resque) can now be overridden for testing (Joshua
  Clayton)

### 1.0.1 / 2010-12-21

* Respect ActionMailer::Base.perform_deliveries

### v1.0.0 / 2010-07-28

* Added support for Rails 3.x (Marcin Kulik)
