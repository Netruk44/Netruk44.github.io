---
title: "Steam Game Search Overview"
date: 2023-11-20T10:33:44-05:00
draft: false
tags: ["Python", "Instructor", "Application", "Docker", "CSS", "React", "Sqlite", "Machine Learning", "Embeddings"]
summary: "This post contains definitions, background information, and a broad overview of how the Steam Game Search project works."
---

{{% series-nav name="Steam Game Search" next="part1-obtaining-data" nextTitle="Part 1: Obtaining Data" include-explanation="true" %}}

---

This post contains definitions, background information, and a broad overview of how the Steam Game Search project works. Feel free to skip any sections that you're already familiar with.

### Background Information and Definitions

#### Tokens and tokenization
Machine learning models don't look at text the same way we do. Words are broken down into common sequences of characters and assigned a numeric value from 0 to as large as a model's dictionary size. These numbers are called "tokens".

There are also special tokens that represent things like the end of a sequence or padding (a placeholder value that is used to make all input sequences the same length when batching multiple sequences together into a single call to the model)

As a hypothetical example, you might break down the string "Hello, how are you?" into the 6 tokens [`Hello`, `,`, `<space>how`, `<space>are`, `<space>you`, `?`, `<end_of_sequence>`].

A vague rule of thumb is that one token is about equivalent to 4 characters of text.

#### Embeddings
An embedding is basically an array of numbers (usually floating point values) that effectively represent a piece of text. You can then use math on these numbers to accomplish a variety of things. The most common use case is to figure out how similar two pieces of text are to each other (you might be familiar with the concept of `cosine_similarity`). But you can also do other things with these embeddings, as I'll show later.

Embeddings from one model are generally not transferrable to another model.

#### Instructor

[Instructor](https://huggingface.co/hkunlp/instructor-large) is a text embedding model that can be used to generate embeddings for text.

Instructor has a max sequence length of 512 tokens (< 2000 characters), which means if you want to encode something longer than that you need to break it up into smaller pieces and encode each piece separately. This is called "chunking".

Instructor outputs a 768-dimensional embedding for each chunk of input text. This means that the embedding array will be 768 elements long.

There are two 'sizes' of Instructor. `instructor-large` and `instructor-xl`. The size of the model determines how accurate the embeddings are, but also how long it takes to generate them. The size of the model does *not* affect the size of the embeddings themselves.


### Overview

---

{{% series-nav name="Steam Game Search" next="part1-obtaining-data" nextTitle="Part 1: Obtaining Data" %}}