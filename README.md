# SOGo-updater

This program is a set of scripts aimed to automate the update of SOGo Integrator Plugin
for thunderbird in an enterprise environment.

The program is essentially composed of two parts:

1. A script (release_builder) that prepares extensions file.

2. The updater (update.php) that talks with SOGo Integrator Plugin for Extensions Update

# release-builder

Release Builder does follwing tasks:

1. Downloads SOGo-Integrator Extension from SOGo Website
2. Customizes SOGo-Integrator Extension: changes UpdateUrl, creates the extensions database
3. Downloads other extensions to be shipped

# Getting started
Download and unpack the zip in a directory served by a web server.

Take a look to command-line parameters by calling updater_build.sh -h
Take a look in configuration files updater_build.conf and extensions-test.conf
