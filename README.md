# Research Data York

[![Code Climate](https://codeclimate.com/github/digital-york/researchdatayork/badges/gpa.svg)](https://codeclimate.com/github/digital-york/researchdatayork)
[![Issue Count](https://codeclimate.com/github/digital-york/researchdatayork/badges/issue_count.svg)](https://codeclimate.com/github/digital-york/researchdatayork)

University of York research data deposit, access and management application. This application is a prototype built for
phase three of the 'Filling the Digital Preservation Gap' project of the Jisc Research Data Spring.

## About the prototype

This prototype provides a deposit, request and administration front end for research data. It integrates with the PURE
research information systems to retrieve metadata for datasets and with the Archivematica digital preservation system to
send research data for long-term preservation. The prototype assumes that only metadata (ie. not files themselves) are
being added to PURE.

### Features

* A research data administration interface.
* A deposit form for the upload of research data. The form supports single files, multiple files, folders and
files/folder from Google drive.
# An automated process for transferring data to Archivematica for archival storage,
and for requesting dissemination copies on demand.
* A form for requesting access to a dataset that is not yet available.
* A download interface for downloading individual files or the whole dataset.

## Pre-requisites

Using this application requires:
* Access to the REST web services of an instance of the PURE research information system via basic auth
* A running instance of the Fedora 4 repository (tested with version 4.5)
* A running instance of Apache Solr (tested with version 6.1.0)
* A running instance of Archivmatica with this fork of Automation Tools: ( https://github.com/digital-york/automation-tools ) installed

## Try it out

```
git checkout https://github.com/digital-york/researchdatayork
```

* copy .sample-env to .env and fill out all of the information


```ruby
bundle install
```

```ruby
rake db:migrate
```

```ruby
git checkout https://github.com/digital-york/researchdatayork
```

```ruby
rails server
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/researchdatayork/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


