# sogo-updater

This program is a set of scripts aimed to automate the update of SOGo Integrator Plugin
for thunderbird in an enterprise environment.

The program is essentially composed of two parts:

1. A script (release_builder) that prepares extensions file.

2. The updater (update.php) that talks with SOGo Integrator Plugin for Extensions Update

# release_builder

Release Builder does follwing tasks:

1. Downloads SOGo-Integrator Extension from SOGo Website
2. Customizes SOGo-Integrator Extension: changes UpdateUrl, creates the extensions database
3. Downloads other extensions to be shipped

For usage refer to command help and look in configuration file updater_build.conf.
