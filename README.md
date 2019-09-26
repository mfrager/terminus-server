# TerminusDB

[![Build Status](https://travis-ci.com/terminusdb/terminusdb.svg?branch=master)](https://travis-ci.com/terminusdb/terminusdb)

TerminusDB is an open source model driven graph database for knowledge graph representation designed 
specifically for the web-age. 

TerminusDB features a RESTful API for interacting with knowledge graphs via the JSON-LD exchange 
format. This means you can easily string together applications within your own toolchain which 
utilise the powerful features of graph search and graph storage. 

## Release Schedule 

We have a v1.0.0 release schedule for October 1st, 2019. This means
that the current codebase is in a very high level of flux, and as we
have never had a prior release, there are no release labels to pull. 

Caveat Puller! 

## Latest Version 

v0.2.2

## Getting Started

### Running the Docker image

The automated build of the master branch can be run easily with:

`docker run --name terminusdb -p 6363:6363 -e SERVER_NAME=localhost -e DB_PASS=root -it terminusdb:latest`

There will be tagged versions upon release.

#### Env variables

| Env variable   | Description                      | Default   |
|----------------|----------------------------------|-----------|
| SERVER_NAME    | Location of the server           | localhost |
| SERVER_PORT    | Port of the server               | 6363      |
| WORKERS_AMOUNT | Amount of workers for the server | 8         |
| ADMIN_PASS     | Administrator password           | root      |

### Running from source

Before you can begin modeling and manipulating data in TerminusDB, you
need to get some required libraries and software.

#### SWIPL 

To use TerminusDB, you will need the SWIPL installation of prolog. To install this in Debian variants
simply use the apt package manager: 

```
apt install swi-prolog
```
Once installed, you will have to install two library dependencies from SWIPL. 

This can be done by typing: 

```
$ swipl
Welcome to SWI-Prolog (threaded, 64 bits, version 8.1.10-28-g8a26a53c1)
SWI-Prolog comes with ABSOLUTELY NO WARRANTY. This is free software.
Please run ?- license. for legal details.

For online help and background, visit http://www.swi-prolog.org
For built-in help, use ?- help(Topic). or ?- apropos(Word).

1 ?- pack_install(hdt).
% Contacting server ....
2 ?- pack_install(mavis). 
% Contacting server ....
```

#### HDT Library 

You will also need to install `hdt-cpp`. You can git clone the source tree from this repository: 

```
git clone https://github.com/rdfhdt/hdt-cpp
```

... and follow the directions contained in the repostiory for the
pre-requisites and building the code.

#### TerminusDB

The TerminusDB source tree should then be cloned from GitHub: 

```
git clone https://github.com/terminusdb/terminusdb
cd terminusdb
git submodule init
git submodule update
```

You need to set the admin user password which is used as a
super-user API key for access. This can be done with the
`initialize_database` script. The script should also be used to
configure the server name, as shown in the example.

```
utils/initialize_database -k "my_password_here" -s "my_server_name_here"
```

At this point you can enter the terminusDB directory and start the server: 

```
./start.pl
```

Now you are ready to interact with the HTTP server. 

## Documentation 

### Microservices API

TerminusDB is organised to be _web native_ which means that all actions and activities are easily 
automated via a RESTful JSON-LD API.

The Server API is documented [here](https://github.com/terminusdb/terminusdb/blob/master/API.md).

### WOQL 

WOQL, the Web Object Query Language, allows you to seemlessly traverse the graph extracting graph 
fragments, nodes, tables or JSON-LD documents. The syntax itself is in JSON-LD, making the syntax 
a native data-structure in JavaScript, Python, Prolog or any other language which has the 

The Syntax is documented [here](https://github.com/terminusdb/terminusdb/blob/master/SYNTAX.md).

## Why 

TerminusDB will: 

* Make complex data models easy, maintainable and enforced. 
* Overcome the Object Impedance mismatch without turning your Database into an incomprehensible soup. 
* Allow you to search for repeating patterns using recursion. 
* Give you powerful temporal queries using finite domain constraint logic. 
* Enable the sharing of data using linked open data formats RDF and JSON-LD making scientific or organisational information sharing easy.
* Help you automate the production of UI and data-entry by *knowing* what data *means*.

## Issues 

We currently have no client, so you'll have to use the RESTful API directly. You can find 
examples at the TerminusDB repositories...

In JavaScript: https://github.com/terminusdb/terminus-javascript-sdk

In Python: https://github.com/terminusdb/terminus-python-sdk

## Changes in this Version 

* Added additional typing information and documentation
* Added database bootstrapping for access permissions and controls using the capabilities ontology
* Added database initialisation utility 
* Added code for instance and schema checking

## TODO

* Write tests for Document API

## Authors

Gavin Mendel-Gleason <gavin@datachemist.com>

Matthijs van Otterdijk <matthijs@datachemist.com>

Put your Name here by contributing!

## Copyright

This file is part of TerminusDB.

TerminusDB is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

TerminusDB is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with TerminusDB.  If not, see <https://www.gnu.org/licenses/>.
