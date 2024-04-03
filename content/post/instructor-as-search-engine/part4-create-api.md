---
title: "Part 4: Create an API"
date: 2023-11-20T10:33:40-05:00
draft: false
tags: []
summary: "The first step in sharing the project with others. In this post, we'll create a simple API that can be used to query the embeddings we've created."
---

{{% series-nav name="Embedding-Based Steam Search" previous="part3-querying-embeddings" previousTitle="Part 3: Querying Embeddings" next="part5-create-webapp" nextTitle="Part 5: Create a Web App" %}}

---

This is the fourth part in a series of five that covers how I created a custom search engine for Steam games using embeddings.

In the previous post, we created a simple script that could query the embeddings we created previously. However, expecting people to run a Python script is not a great way to share a project. In this post, we'll create a simple API that can be used to query the embeddings we've created.

> **Source for this section**: Available on [GitHub](https://github.com/Netruk44/steam-embedding-search/tree/main/10_flask-embedding-api)

{{% toc %}}

## How to host the API?

The first challenge is to decide where the API is going to be running. I don't want to have to keep a server running on my own computers at home, so I needed to decide first where I was going to host the API.

I receive free Azure credits every month because of my previous employment at Microsoft, so I decided to look at the options available there. I considered two options:

### Azure Functions

My initial thought was to somehow use Azure Functions to run the API. They have a pretty generous free tier (so I wouldn't have to worry about running out of credits), and I've used them before for other simple projects where I didn't want to have to care about the server.

But I pretty quickly ran into a problem. Azure Functions have a memory limit of 1.5 GB. `instructor-large`, the smaller of the two instructor models, requires 2 GB on its own. There are ways around this, but they require paying for a virtual machine to dedicate to the API. If I'm going that route, I don't want to be tied to Azure Functions.

### Docker

The other option I considered was to use Docker. As far as my experience with Docker, I'm pretty new. But I can cobble together a Dockerfile pretty well. I also have some limited experience using Docker to host things on some of my machines, so I decided to look into making a Docker image that could host the API.

In Azure, I set up a new App Service Plan, which is basically a virtual machine that can host web applications. For the host, I went with a `Premium v3 P1mv3` machine, which has 2 vCPUs and (more importantly) 16 GB of memory. The cost of this machine is about $100 USD per month, but with my credits it'll be free.

Now I just need to implement the API.

## Which API framework to use?

But what framework should I use to implement the API? I'm no expert here, but I've used Flask exactly one time in the past to implement a similar API, so that's what I went with.

I'm obviously not in a position to give a comprehensive reasoning behind why Flask is better or worse than any other framework. However, another option available out there you might want to consider is FastAPI. I haven't tried it myself, but it seems to be another popular choice for Python APIs.

### Flask

Flask is a lightweight web framework for Python. It's pretty easy to get something up and running, all you need to do is implement an `app.py` file that defines the route you want.

I was able to lift-and-shift my query function into my `app.py` file. All I had to do was write a function that would take the query parameters from the request and pass them to the query function, then return the results as JSON.

## Issues encountered

But of course, it's never *just* that simple. I ran into a few issues that I had to solve along the way.

### Instructor model loading
To start with, I knew the naive approach of loading instructor on each request was going to be problematic. We don't need to be constantly loading and unloading the model from memory on every request. So I made some code that ran on startup to load the model into a global variable.

```python
instructor_model = None
app = Flask(__name__)

# Startup code
with app.app_context():
    logging.basicConfig(level=logging.INFO)
    print('Loading instructor model...')
    instructor_model = InstructorModel(instructor_model_name)
```

I then accessed this global variable in my endpoint instead of loading the model each time.

### Preloading the instructor model

Running the model in Docker on my computer revealed another problem. Running locally outside of Docker, I already had the instructor model downloaded to a temporary directory. But when the API ran in Docker, it first needed to download the instructor model before being able to serve API requests.

This meant that the first request to the API would take a long time to respond, sometimes over 30 seconds. It also meant a lot of bandwidth usage every time I restarted the API.

To solve this, I decided that this download should really happen during the Docker build instead. So I created a simple python script with just a call to the `Instructor` constructor. The model code would then go download the model if it wasn't already available and cache it for the next time the API started up.

#### Avoiding code synchronization

But how do I know which model to download inside the preload script? Currently, that information only exists as a string in my `app.py` file.

Hardcoding the model name into the preload script was an option. But I wanted to avoid that if possible, for the simple reason that I didn't want to have to remember to update the model name in two places if I ever changed the model.

I considered just referencing `app.py` from my preload script, but thought that sounded weird. Instead, I extracted the model name from `app.py` into a `config.py` script. This config script then gets loaded by both the preload script and the `app.py` script for determining the model name. This felt like a much cleaner solution.

### Dealing with large Docker images

The next problem was that this Docker image took way too long to rebuild, and quickly became too large for my US residential internet to upload to Azure in a reasonable amount of time.

#### Slow Builds

Remember how I mentioned that I'm not a Docker expert? Well, I learned that the layout of your Dockerfile can have a pretty big impact on how long it takes to rebuild your image.

To address the build time issue, I restructured the Docker file so that it performed actions in this order:

1. Copy the requirements file, and use pip to install them.
2. Copy just `config.py` and `preload.py`, then run `preload.py` to download the instructor model.
3. Copy the database file.
4. Copy the rest of the `.py` files.

Structuring the Dockerfile this way meant that the layers for the instructor model and database could be reused between builds, since they don't change often.

#### Slow Uploads

But even with this optimization, the image was still too large to upload from my home internet. It would have taken over 6 hours to upload everything. I needed to find a way to upload less.

Thankfully, Azure offers their own Docker container registry service, which you can upload your Dockerfile to and it will build the image for you. This way, you don't have to upload the complete image, just the files needed to build it.

That fixed the requirement for me to upload the instructor models, Azure can now download them itself. To address the embedding database file, I uploaded it to Azure Blob Storage and modified the Dockerfile to download it from there instead.

Now I'm uploading just kilobytes of text files instead of gigabytes of model and database files. Problem solved, right?

#### Running out of memory during the build

Well it turns out that the image build was failing due to out of memory errors. Looking at the logs, I saw that it was the preload script that was failing. To accomplish the task of preloading, I simply instantiated the `Instructor` class, which obviously loads the model into memory as well as downloads it. The container build machines apparently don't have enough memory to do this.

I decided that I probably should find some way to download the model files without actually loading them into memory. However, the code in instructor itself doesn't support this. So I looked into how the model files were being downloaded automatically and extracted that logic into my preload script.

## Conclusion

With this final hurdle overcome, I was able to successfully build and run the API in Azure. I was able to query the API and get results back, and it was fast enough that I didn't have to worry about timeouts.

Now we need to build a UI to display the results from the query nicely. That's what we'll cover in the next post.

{{<collapse summary="How's the database population going?">}}
> 86% and 85 hours in, with an estimated 13 hours remaining. I'm probably not going to make it 😅.
>
> Ah, well. It's better to have the database populated before this series goes live, anyway. That way people can actually use it when I share the link to the series.
{{</collapse>}}

---

{{% series-nav name="Embedding-Based Steam Search" previous="part3-querying-embeddings" previousTitle="Part 3: Querying Embeddings" next="part5-create-webapp" nextTitle="Part 5: Create a Web App" %}}