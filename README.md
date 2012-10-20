RISG: The Ruby IRC Statistics Generator
=======================================

Despite the similar name, this is a completely new project, and not a port of PISG. It may and/or will have very similar functions though. *The name may or may not be temporary.*

## (Rough) Development process

*(in order, may change as project progresses):*

- single log parser (zcbot-based)
  - determine kick/ban/action/message, and group into channels.
  - channel whitelist
- spin off single log parser into base logparser and zcbotparser, provide standard attributes
  - gem-based loading of third-party parsers via require if not found? (*will look for `risg-logparser-%<parsername>s`?*)
- Error raising; It should bubble up into the client (script or binary) and report errors to the user.
- Parse data provided by log parser
  - stats categories (*yelling, attacks*)
  - more categories (*swearing, now playing, kicks by nicks, attacks, # of words in capitals*)
  - number of lines and words per user
  - number of normal messages
  - number of actions
  - anything else that may be useful (***please suggest them!***)
- Automatic aliasing of nicks by tracking `/nick` and alias only if said nick was in use for a day or more(*?*)
- Basic terminal output of data before moving onto page generation (*for verification*)
- HTML5 page generator
  - `<canvas>`-based charts
    - fallback?
  - page generation options?
  - nice design, but should be fairly simple.
  - *Alternative stats generation?* (*Do we really need anything but HTML?*)
- Provide a binary that accepts a config file for loading settings; if not, the binary should not run, and provide an error message.
  - Config file. (*Custom DSL? That would be super neat.*)
    - Global options for parsing and generating the page?
    - Channel whitelist (*will only parse channels that are passed in*)
    - Multiple log files globally/per-channel (*should be able to merge and sort by date?*)
    - Offer switching log parser (zcbot by default)
    - Custom user properties (*`url`, `pic`, `email`, `???`*)

## Installation

Add this line to your application's Gemfile:

    gem 'risg'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install risg

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
