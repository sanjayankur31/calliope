# calliope

 [![CI](https://github.com/sanjayankur31/calliope/actions/workflows/ci.yml/badge.svg)](https://github.com/sanjayankur31/calliope/actions/workflows/ci.yml)

A simple script that makes it easy to use LaTeX for journal keeping---most useful for keeping research journals!

This script is based on the original project here: https://github.com/mikhailklassen/research-diary-project - do take a look!
## The name

[In Greek mythology, Calliope is the muse that presides over eloquence and epic poetry.](https://en.wikipedia.org/wiki/Calliope)

Epic poetry is exactly what our private research journals are ;)

## Requirements

- latexmk
- pdflatex
- makeindex
- biber
- packages used in templates/research_diary.sty

On a Fedora system, this should do it:

```
sudo dnf install 'tex(opensans.sty)' 'tex(framed.sty)' 'tex(multirow.sty)' 'tex(wrapfig.sty)' 'tex(booktabs.sty)' 'tex(makeidx.sty)' 'tex(listings.sty)' latexmk /usr/bin/biber 'tex(biblatex.sty)' 'tex(datetime.sty)'
```

On a Ubuntu system, this installs all of LaTeX and the required tools:

```
sudo apt-get install -y texlive-full latexmk python-pygments biber
```

I test this out on a Fedora installation, and GitHub Actions does Ubuntu.
If you test it out on other platforms, please open a pull request with instructions.

## Usage

```
usage: ./calliope.sh options

Master script file that provides functions to maintain a journal using LaTeX.

OPTIONS:
-h  Show this message and quit

-t  Add new entry for today

-l  Compile latest entry

-C  <commit message>
    Compile latest entry and commit to repository.
    An optional commit message may be given using the commit_message
    variable:
    commit_message="Test" ./calliope.sh -C
    If one is not given, the default is used: "Add new entry".


-c  Compile today's entry

-a  <year>
    Year to generate anthology of

-p  <year>
    Compile all entries in this year

-s  <entry> (yyyy-mm-dd)
    Compile specific entry

-e edit the latest entry using $MY_EDITOR

-E <entry> (yyyy-mm-dd)
    edit specific entry using $MY_EDITOR

-v view the latest entry using $MY_VIEWER

-V <entry> (yyyy-mm-dd)
    view specific entry using $MY_VIEWER

-k <search term>
    search diary for term using
    Please see the documentation of the search tool you use
    to see what search terms/regular expressions are supported.
```

## Set up

The simplest way is to clone this repository, and then change the address of
the remote to your personal (possibly private) repository:

```
git clone https://github.com/sanjayankur31/calliope.git my_research_diary
git remote remove origin
git remote add origin <address of new private git repository>
```

One can also simply [fork](https://github.com/sanjayankur31/calliope#fork-destination-box) this
repository and then make their fork private.
However, one will have to update the name of the repository and so on there too.

### Multiple journals

I tend to keep a separate journal for each project that I'm working on.
The simple way is to copy calliope multiple times, once for each new journal.
However, this means that when you update (see below), you'll need to update multiple copies of calliope.
This is quite easy to do now, given that one only has to tweak the `.callioperc` configuration file.

Another way is to download calliope only once, and then use symbolic links (`ln -s` on Linux) in each of your journals.
For example:

```
.
├── journal_1
│   ├── calliope.sh -> ../calliope/calliope.sh
│   ├── .callioperc
│   ├── diary
│   ├── pdfs
│   ├── Readme.md
│   └── templates -> ../calliope/templates
├── journal_2
│   ├── calliope.sh -> ../calliope/calliope.sh
│   ├── .callioperc
│   ├── diary
│   ├── pdfs
│   └── templates -> ../calliope/templates
├── journal_3
│   ├── calliope.sh -> ../calliope/calliope.sh
│   ├── .callioperc
│   ├── diary
│   ├── pdfs
│   └── templates -> ../calliope/templates
├── calliope
│   ├── calliope.sh
│   └── templates

```

Here, the `calliope` folder is a single copy of this repository.
Each journal then links to it in their folders, and each has a `.callioperc` file with the necessary configuration.

Both ways work well, so you can choose either.

### Configuration

Please create a `.callioperc` file in the folder and set your variables there.
The `calliope.sh` script sources this file to obtain the values of these variables:

```
ProjectName="Your project name"
author="Your name"
bibsrc="/path/to/your/bib/file"

```

Please do not use the `|` character in these fields.
It is used as the delimiter in the `sed` command that sets these values in `calliope.sh`.


#### Modifying the sty file

You can add/remove any packages as needed in the `research_diary.sty` file.
You can also include other definitions and so on there.

### Keeping up to date

Since I'll keep updating the main `calliope` script and templates, the
easiest way is to copy over the script from this repository from time to time,
and then pick selected changes (using `git add -i`). With the templates,
this would be the suggested way of going about it too.

Tracking this repository and merging changes would work too, but it would
usually result in some conflicts because the commit trees would have diverged,
and so would the template files after they've been customised.
