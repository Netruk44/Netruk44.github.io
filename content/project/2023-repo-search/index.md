---
title: "Repo Search"
date: 2023-07-08T14:58:13-04:00
draft: false
tags: ["Python", "OpenAI", "OpenAI Embeddings"]
---

Repo Search is a tool for searching for code by what it does using natural language queries, based on OpenAI's embeddings. Use it to help figure out what file you need to be working on!

It happens to me pretty often when working with medium to large repositories that I have no clue what file I need to be looking at to make a particular change I'm trying to create. Repo Search is a tool I made to help me figure that out quicker.

Repo Search isn't limited to just code, either. You could just as easily use this to search through text-based repositories based on the content of the file you're looking for. You can search your notes stored in [Obsidian](https://obsidian.md/), [Zim](https://zim-wiki.org/), [Joplin](https://joplinapp.org/), [Dendron](https://www.dendron.so/), or whatever other note-taking app you use, as long as the files are stored in UTF-8.


{{< contact-me box="repo-search" is-mid-article=true >}}

# Info
* **Source/Download**: [GitHub](https://github.com/Netruk44/repo-search)
* **Technologies & Languages**: Python, OpenAI API

### Install
1. `pip install git+https://github.com/Netruk44/repo-search`
2. `export OPENAI_API_KEY=sk-...`
3. `repo_search --help`

## Example Usage

Let's say we're working on [OpenMW](https://gitlab.com/OpenMW/openmw), an open source game engine. Our goal is to figure out how to make an NPC navigate to an arbitrary location in the game world. How can we figure out where to start looking?

We already have a copy of the repository checked out locally, so let's first create a dataset of embeddings from the repository. To speed things up, we'll only generate embeddings for the C++ files in the repository.

```
$ repo_search generate openmw ~/Developer/openmw/apps --verbose
```

```txt
Loading libraries...
Generating embeddings from local directory /Users/danielperry/Developer/openmw/apps for openmw...
WARNING: Could not read as text file: /Users/danielperry/Developer/openmw/apps/openmw_test_suite/toutf8/data/french-win1252.txt
WARNING: Could not read as text file: /Users/danielperry/Developer/openmw/apps/openmw_test_suite/toutf8/data/russian-win1251.txt
100%|██████████████████████████████| 1386/1386 [05:53<00:00,  3.92it/s]
```

Now that we have a dataset of embeddings, we can query it for the information we're looking for.

```
$ repo_search query openmw "NPC navigation code and examples on making an NPC navigate towards a specific destination."
```

```txt
Loading libraries...
Querying embeddings...
100%|██████████████████████████████| 1386/1386 [00:00<00:00, 3375.94it/s]
0.7708185244777552: openmw/mwmechanics/aiwander.cpp
0.7648722322559: openmw/mwmechanics/obstacle.cpp
0.7593991785701977: openmw/mwmechanics/aipursue.cpp
0.7570192805465497: openmw/mwmechanics/aiescort.cpp
0.7540042527421098: openmw/mwmechanics/aiescort.hpp
0.7534971127334509: openmw/mwmechanics/aitravel.cpp
0.7531876754013663: openmw/mwmechanics/aiface.cpp
0.7529779124249095: openmw/mwmechanics/aipackage.cpp
0.7527566874958713: openmw/mwworld/actionteleport.cpp
0.7491856749386254: openmw/mwmechanics/pathfinding.cpp
```