backbone-inspectre
==================

A simple library that can be used to inspect / spy on core backbone, or any other,
prototypes and log execution timings.
I started using this to create an activity stream for logging some
stats in an app to google analytics.  I used it to spy on core Backbone functions
as well as some application level functions.

You can also setup log point callbacks, which get checked with each monitored event.
Supply a function that returns boolean and when true, the log point will log in the
time stream.