---
title: "Steam Game Search: Using Instructor for Searching"
date: 2023-11-20T10:33:44-05:00
draft: true
tags: ["Python", "Instructor", "Application", "Docker", "CSS", "React", "Sqlite", "Machine Learning", "Embeddings"]
---


<!-- TODO: Some kind of picture -->

I recently had the idea of using machine learning text embedding models to generate embeddings for [Steam](https://store.steampowered.com/) game descriptions and their reviews. Theoretically, you can compare these embeddings to a stand-alone text description of a game and figure out which games are most similar to it. This can be used to find games that Steam's built-in search tool might not bring up for you.

I've been working on this project for a few days now, and I've gotten to the point where I have a web UI used for querying a database of embeddings, so I thought I would write up a series of blog posts about how it's all implemented and the challenges I faced along the way. I hope that this can be useful to anyone who wants to do something similar.

To check out the final product, head over to the [search page](https://netrukpub.z5.web.core.windows.net/steamvibes/build/index.html) to see it for yourself. You can also see the complete source code for every part of this project on [GitHub](https://github.com/Netruk44/steam-text-search).

Check out the individual parts below for all the details of how it was made.

{{< contact-me box="steamsearch" is-mid-article=true >}}