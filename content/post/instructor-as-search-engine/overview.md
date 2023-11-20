---
title: "Steam Game Search Overview"
date: 2023-11-20T10:33:44-05:00
draft: false
tags: ["Python", "Instructor", "Application", "Docker", "CSS", "React", "Sqlite", "Machine Learning", "Embeddings"]
summary: "This post contains definitions, background information, and a broad overview of how the Steam Game Search project works."
---

{{% series-nav name="Steam Game Search" next="part1-obtaining-data" nextTitle="Part 1: Obtaining Data" include-explanation="true" %}}

---



### Definitions

[Instructor](https://huggingface.co/hkunlp/instructor-large) is a text embedding model that can be used to generate embeddings for text. If you aren't familiar, an embedding is basically an array of numbers (usually floating point values) that effectively represent a piece of text. You can then use math on these numbers to accomplish a variety of things. The most common use case is to figure out how similar two pieces of text are to each other. But you can also do other things with these embeddings, as I'll show later.

---

{{% series-nav name="Steam Game Search" next="part1-obtaining-data" nextTitle="Part 1: Obtaining Data" %}}