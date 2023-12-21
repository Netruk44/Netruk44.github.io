---
title: "Part 2: Creating the Embeddings"
date: 2023-11-20T10:33:42-05:00
draft: false
tags: ["Python", "Instructor", "Sqlite", "Machine Learning", "Embeddings"]
summary: "This post covers how I used Instructor to create embeddings for my database. Details involved include how I implemented chunking, and how I stored embeddings in sqlite3."
---

{{% series-nav name="Embedding-Based Search" previous="part1-obtaining-data" previousTitle="Part 1: Obtaining Data" next="part3-querying-embeddings" nextTitle="Part 3: Querying Embeddings" include-explanation="true" %}}

---

This is the second part in a series that covers how I created a custom search engine for Steam games using embeddings.

This post covers some embeddings models I considered, how I used Instructor to create embeddings, and how I stored them in sqlite3.

> **Source for this section**: Available on [GitHub](https://github.com/Netruk44/steam-embedding-search/tree/main/02_embeddingdataset)

{{% toc %}}

## Embedding Models

There's different ways to come up with embeddings for text. This project was based off another project I had done that used [Instructor](https://huggingface.co/hkunlp/instructor-xl) to create embeddings for a dataset of text files on your computer, so that's what this project uses as well. However, there are plenty of other options that could be used instead, if you wanted to try something different.

### OpenAI Embeddings API

This one costs money, which is outside the realm of possibility for a little hobby project like mine (if I ever wanted to publish it to the internet, that is).

However, OpenAI's Embedding API is probably one of the more popular options for creating embeddings. It's also one of the easiest to use. It's just a simple API call, so you don't have to worry about hosting a model yourself.

This option also has the benefit of having a much larger maximum sequence length, at 8,191 tokens or about 32,000 characters. Depending on your needs, this could be a big benefit. For example, if you need to embed very long pieces of text, such as entire books.

Details on how to use this API can be found on [OpenAI's website](https://platform.openai.com/docs/guides/embeddings/what-are-embeddings).

I've used these embeddings before in the project I mentioned earlier, and they worked pretty well. However, I can't afford to pay OpenAI for a public hobby project, so I had to look elsewhere.

### Google's T5 Model

![Diagram showing uses for T5](../t5.png#center)

{{% img-subtitle %}}
*Diagram showing some uses for T5. Image from [Google's T5 paper](https://arxiv.org/pdf/1910.10683.pdf) (Figure 1).*
{{% /img-subtitle %}}

[T5](https://huggingface.co/docs/transformers/model_doc/t5) is an encoder-decoder model used in natural language processing. Typically, you'd use it to perform some kind of task like converting text from English to German, or summarizing a piece of text. However, by using the final hidden state of the encoder, you can get an embedding for a piece of text.

For example (adapted from the [t5-small](https://huggingface.co/t5-small) HuggingFace page, "How to get Started" section):

```py
from transformers import T5Tokenizer, T5Model

tokenizer = T5Tokenizer.from_pretrained("t5-base")
model = T5Model.from_pretrained("t5-base")

input_ids = tokenizer(
    "Studies have shown that owning a dog is good for you",
    return_tensors="pt"
).input_ids

outputs = model(input_ids=input_ids)
embeddings = outputs.last_hidden_state
```

The benefit of using T5 is that you can run it locally, and it comes in a wide variety of sizes. The smallest version, [`t5-small`](https://huggingface.co/t5-small), is just 242 MB large which is small enough to run locally on most computers.

There are larger versions which require more memory and compute as you scale up. It's likely that the embedding quality will also improve as you scale up, but I haven't tested this myself or seen any research on it. I've only used T5 as an embedding model through training a toy [Imagen](https://github.com/lucidrains/imagen-pytorch) image generation model.

The drawback of T5 is its smaller maximum sequence length of 512 tokens. But depending on your use case, this may not be a concern.

### University of Hong Kong's Instructor

![Diagram showing uses for Instructor](../instructor.png#center)

{{% img-subtitle %}}
*Diagram showing some uses for Instructor. Image from [Instructor's homepage](https://instructor-embedding.github.io/).*
{{% /img-subtitle %}}

[Instructor](https://huggingface.co/hkunlp/instructor-xl) is a text embedding model that was popular on HuggingFace's "sentence similarity" models hub a little while ago. It's not the most popular model anymore, but still has a decent number of downloads.

I've already explained the details of this model on the [overview](../overview/#instructor) page, so I'm not going to repeat it here. I went with `instructor-xl` for this project since I had a GPU with the memory to run it, and it wasn't that much slower than `-large`.

Instructor was the model I used for my previous project. To get things running quickly it's the model I used for this project, too. That was the main reason I chose it, expediency more than anything else.

Something I'm going to eventually do, and I would recommend you do too when starting a new project, is looking into other alternatives on [HuggingFace's sentence similarity model hub](https://huggingface.co/models?pipeline_tag=sentence-similarity&sort=trending) to see what's new and popular. New models pop up all the time, and it's worth checking out what the current state of the art is.

## Creating the Embeddings

Using Instructor is pretty straightforward, the [HuggingFace page](https://huggingface.co/hkunlp/instructor-large) provides a sample of how to use it:

```py
from InstructorEmbedding import INSTRUCTOR

model = INSTRUCTOR('hkunlp/instructor-large')

sentence = "3D ActionSLAM: wearable person tracking in multi-floor environments"
instruction = "Represent the Science title:"

embeddings = model.encode([[instruction,sentence]])

print(embeddings)
```

For instructions, I decided on having separate instructions for embedding game descriptions and reviews, and also another instruction for user queries. I'm not sure how much of a difference this makes, but I figured it couldn't hurt.

| Item | Instruction |
| --- | --- |
| Store Description | `Represent a video game that is self-described as:` |
| Review | `Represent a video game that a player would review as:` |

There were a couple of things I needed to figure out before I could start generating embeddings for my game dataset, though.

### Chunking the Data

First, I needed to figure out how to deal with long game descriptions and reviews. Instructor's maximum sequence length is 512 tokens, but how do I know how many tokens a given piece of text will be?

> **Important**: Something important to note when converting text to embeddings is to be aware that sometimes one piece of text will be split into multiple embeddings.
>
> It's easy to assume that one piece of text will always be converted into a single embedding, but this is not always the case. It can be a pain to convert code that assumes its always working with a single embedding.

In the name of expediency (and figuring out the 'better' solution later), I decided to just take a greedy approach to splitting up the text. First I convert the entire text into tokens, then I split the tokens up into groups of 512 tokens each. Finally, I convert the tokens back into text and send them to Instructor to be converted into embeddings.

This is a pretty naive approach though. Consider what happens when a review happens to be 515 tokens long. The final 3 tokens will be split off into their own embedding, which will contain barely any information in it at all. Depending on how you're using the embeddings, this could have negative impacts on the quality of the results.

A simple approach to fixing this could be to split the text into equal sizes of smaller than 512 tokens, but this too could cause splits in unfortunate locations. A more intelligent approach would be to smartly split the text into chunks of equal 'information density', splitting at a point that makes sense. But implementing something like that obviously depends on the kind of text you're working with and was too much effort for me to do all at once.

In the end, I was okay with the downsides of the greedy approach while prototyping the project out. I was more interested in getting results at all than I was in getting the best possible results right off the bat. I figured I could always come back and improve it later to see how much of a difference it made.

### Storing the Embeddings

The final problem was figuring out how to store the resulting embeddings in my database. Sqlite3 doesn't natively support storing arrays. You can work around this in a few ways.

First, just storing the array as a string. The simplest method, but also not likely to be terribly efficient.

Second, storing the array as JSON. This is a little better, but still not ideal. I don't want to have to parse text to load an embedding.

Third, storing the array as a blob, which is what I went with. I used `pickle.dumps` to convert the array into a binary string, and `pickle.loads` to convert it back into an array when loading it from the database. I'm not sure how efficient `pickle` is, but it must be faster than string parsing, right? 😅

To store the embeddings in the database, I made two new tables with similar schemas.

<!--
CREATE TABLE description_embeddings (
    appid INTEGER PRIMARY KEY,
    embedding BLOB NOT NULL
)
-->

**description_embeddings**

| Column | Type | Description |
| --- | --- | --- |
| `appid` / | `INTEGER` | The description's appid. |
| `embedding` | `BLOB` | The embedding for the description. |


<!--
CREATE TABLE revoew_embeddings (
    recommendationid INTEGER PRIMARY KEY,
    embedding BLOB NOT NULL,
    appid INTEGER NOT NULL,
)
-->

**review_embeddings**

| Column | Type | Description |
| --- | --- | --- |
| `recommendationid` / | `INTEGER` | The review's recommendationid. |
| `embedding` | `BLOB` | The embedding for the review. |
| `appid` | `INTEGER` | The appid of the game the review is for. |

The extra `appid` column in the `review_embeddings` table is so that I can easily get all reviews for a specific appid. This will be useful later when querying the database.

## Conclusion

With everything figured out, I hit start on my first run. In total, it took about 30 minutes on my RTX 3090 to generate embeddings for the small test dataset of 5,000 games I created. Much faster than querying the Steam API 😊.

{{<collapse summary="How far into querying the Steam API are you now?">}}
> 97 hours and 93% into querying for game data. Still another 100-ish hours of querying for reviews to go. 😅
>
> Will I finish writing this series before the database is fully populated? Who could say.
{{</collapse>}}

Join me in the next section where we figure out if what we made actually works or not. Are the embeddings any good? What do the results look like? Let's find out.

---

{{% series-nav name="Embedding-Based Search" previous="part1-obtaining-data" previousTitle="Part 1: Obtaining Data" next="part3-querying-embeddings" nextTitle="Part 3: Querying Embeddings" %}}