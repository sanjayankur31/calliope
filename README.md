# calliope

 [![CI](https://github.com/sanjayankur31/calliope/actions/workflows/ci.yml/badge.svg)](https://github.com/sanjayankur31/calliope/actions/workflows/ci.yml)

A simple script that makes it easy to use LaTeX for journal keeping - most useful for keeping research journals!

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

I test this out on a Fedora installation, and Travis does Ubuntu. If you test
it out on other machines, please open a pull request with instructions and the
sort.

## Usage

```
usage: ./calliope.sh options

Master script file that provides functions to maintain a journal using LaTeX.

OPTIONS:
-h  Show this message and quit

-t  Add new entry for today

-l  Compile latest entry

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
repository and then make their fork private. However, one will have to update
the name of the repository and so on there too.

### Customising the scripts/templates

Please remember to update the files in the `templates/` folder and make
the necessary changes there.

In `entry.tex`:

- update the `userName` variable
- update the `projectName` variable

In `research_diary.sty`:

- update the path to the bibliography file that would be used
- add/remove any packages as needed.


### Keeping up to date

Since I'll keep updating the main `calliope` script and templates, the
easiest way is to copy over the script from this repository from time to time,
and then pick selected changes (using `git add -i`). With the templates,
this would be the suggested way of going about it too.

Tracking this repository and merging changes would work too, but it would
usually result in some conflicts because the commit trees would have diverged,
and so would the template files after they've been customised.
