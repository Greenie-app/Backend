# Greenie.app

Greenie.app is an online "Greenie Board" for carrier-based virtual squadrons,
especially squadrons that operate in Digital Combat Simulator: World. Squadrons
can add passes manually or by uploading dcs.log files, and track the performance
of their pilots.

Greenie.app consists of an API back-end, written in Ruby on Rails (this
repository) and a tightly-coupled front-end, written in TypeScript and Vue.js.
Along with these two processes, the website also uses a GoodJob process to
execute background tasks, and a separate instance of the Rails server to send
and receive data via WebSockets (Action Cable).

### Limitations

The DCS: Supercarrier add-on is a work-in-progress. Currently, logging of LSO
grades is sporadic and not all passes are guaranteed to result in a grade being
logged. Furthermore, these grades are not associated with the pilot who made
the pass, so Greenie.app has to "guess" which pilot flew the pass by associating
the LSO grades with nearby "landing" events. Obviously, if the pass was a bolter
or waveoff, no landing event is logged, and the pass is not associated with a
pilot.

For this reason, proper logging of a squadron's passes requires a hands-on
approach. Upload the dcs.log soon after flying your mission or carrier quals,
and then compare the resulting passes with your real LSO's notes. Edit, move, or
remove passes as needed.

You can also use the website without uploading dcs.log files at all. Simply have
your real paddles (or their assistant) keep the website open while your pilots
are making their passes. The LSO will be able to quickly log the grades for each
pass. You can also record your missions to track logs and input the grades
later.

## Development

### Installation and Running

Greenie.app required Ruby 3.3, PostgreSQL, and Redis. (If you use Homebrew,
you can install those dependencies with `brew install`.) After cloning the
repository, run `bundle install` to install all gem requirements. Run
`rails db:create db:migrate` to create the development database.

Run the development server with `rails server`. Note that you will need to also
run the front-end, the GoodJob host, and the WebSockets server in order to use
the complete website. The development server also assumes a Mailcatcher process
is running on port 1025 to receive emails sent in development. (Mailcatcher is
not part of the Gemfile and should be `gem install`ed manually.)

An example Foreman script that accomplishes all of this:

```
backend: cd Backend && rvm 3.3.5@greenie exec rails server
frontend: cd Frontend && yarn serve
workers: cd Backend && rvm 3.3.5@greenie exec bundle exec good_job start
cable: cd Backend && rvm 3.3.5@greenie exec ./bin/cable
mail: mailcatcher -f
```

(This script assumes that the back-end is checked out into a folder called
"Backend", the front-end into a folder called "Frontend", that you use RVM to
manage gemsets).

#### Documentation

Comprehensive API documentation can be generated by running `rake yard`. HTML
docs are generated into the `doc/` directory.

#### Testing

Unit tests can be run with `rspec spec`. End-to-end testing is also implemented
using Cypress; you will need the front-end checked out to run E2E tests as well.
An example Foreman script that launches all necessary processes and starts the
E2E test application:

```
backend: cd Backend && rvm 3.3.5@greenie exec rails server -e cypress -b localhost
frontend: cd Frontend && yarn run test:e2e
workers: cd Backend && RAILS_ENV=cypress rvm 3.3.5@greenie exec bundle exec good_job start
cable: cd Backend && rvm 3.3.5@greenie exec ./bin/cable -e cypress
```

#### Deployment

The application is deployed using Capistrano by running `cap production deploy`.

## Architecture

### Data Model

The core class of Greenie.app is the {Squadron}. Each Squadron has only a single
user account, whose username and password is shared by all squadron members who
have permission to add, edit, and remove passes.

A Squadron has zero or more {Pass}es. Each Pass records the time and location of
the pass, its grade and score, which wire was caught, etc. Each Pass is linked
to a {Pilot}. Pilots are uniquely identified by name and have no other
attributes.

The {LogfileProcessor} class parses dcs.log files and scans them for LSO grades.
When logs are uploaded, {Logfile} records are created, and the GoodJob job
processes them by calling LogfileProcessor.

### Authorization

Authentication is handled by Devise. The {Squadron} class is the user model for
Devise, and users are authenticated by the squadron's username and password.

Front-end authorization state is handled using JSON Web Tokens. Upon logging in,
the front-end is given a JWT that is used as a bearer token for subsequent
authorized reuqests.
