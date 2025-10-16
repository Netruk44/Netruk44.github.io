---
title: "Part 5: Create a Webapp"
date: 2023-11-20T10:33:39-05:00
draft: false
tags: ["React", "Copilot", "Javascript", "Azure", "webdev"]
summary: "How to write a React app when you don't know React, using Copilot to write most of the code for you."
---

{{% series-nav name="Embedding-Based Steam Search" previous="part4-create-api" previousTitle="Part 4: Create an API" %}}

---

This is the final part in a series of five that covers how I created a custom search engine for Steam games using embeddings.

This post covers the creation of the React webapp I made that can be used to query the API we created in the previous post.

> **Note**: While it might sound like this section is going to dive into the details of web development, it's actually going to be more about how to use Copilot to write a web app for you. I'm not a web developer, and I don't know React. I wrote most of the app via Copilot, and this post will cover how I did it.

> **Source for this section**: Available on [GitHub](https://github.com/Netruk44/steam-embedding-search/tree/main/11_react-interface)

{{% toc %}}

## Which framework to use?

When it comes to web development, I don't have much experience. In the past, I've used Angular to create some simple internal tools at work, but at this point that was over 5 years ago.

So I didn't really know where to start. I consulted with Copilot Chat, and asked it for suggestions. My main requirement was that I be able to deploy the web app as static files to Azure Blob Storage, since I didn't want to have to worry about running a server.

Copilot came back with a few suggestions: React, Vue, Angular, and Svelte. Initially, I considered going with Angular due to my previous experience. However, after reviewing the Angular tutorials I remembered that I wasn't a huge fan of the way you write Angular apps.

Instead, I took the opportunity to try using Copilot to help guide me through writing a React app.

## React development with Copilot

### Getting started

Attempting to get started with this new web app, I was immediately struck with a problem. How do you start a new react app? I went to the [React website](https://react.dev/), but I couldn't find anything immediately obvious in the tutorial about creating a new app.

> Going back writing this post, I see that the section about creating a new app from scratch is part of the [Tutorial: Tic-Tac-Toe](https://react.dev/learn/tutorial-tic-tac-toe#setup-for-the-tutorial) page, which I didn't think to look at at the time.

So I did the next best thing and asked Copilot how you get started with making a new React app. It gave me a brief overview of the steps:

1. Install Node.js and NPM if you haven't already
2. Install the `create-react-app` package (`npm install -g create-react-app`)
3. Run `npx create-react-app my-app` to create a new app
4. Use a text editor such as Visual Studio Code to edit the files in the `my-app` folder
5. Run the app with `npm start`
6. You can view the app by navigating to `http://localhost:3000/`

Immediately that was a way more helpful answer than what I found by clicking around on the React website. I followed the steps, and in no time I was looking at the default React app.

### Creating the app

Creating the application was mostly a matter of deciding what I needed to change next, then asking Copilot what the best way to accomplish that task would be.

In the cases where lots of HTML or Javascript would need to be written, I asked Copilot to generate the first template for me.

{{< storage-figure src="react-dev2.png" alt="Copilot generating the first draft for the result table" link=self />}}

I would take this, then either make changes to it myself (if they were simple enough) or ask Copilot to make the changes for me. For example, after having it generate the table layout for me, I could then ask it to `add an 'icon' column to the table, and populate it with 'https://cdn.akamai.steamstatic.com/steam/apps/{appid}/header.jpg'`.

Or for another example, I asked Copilot for how I should be calling out to the query API from Javascript and it suggested I use the `fetch` API. From previous experience, I knew that URLs have a special encoding for certain characters like space

This is how development proceeded for most of the app. I would ask Copilot to generate the first draft of a component, then I would modify it to suit my needs or fix things that Copilot got wrong.

Larger revisions to the code were done the same way. I asked the GPT-vision model how I might make my app look less like a prototype, and it suggested I use result cards instead of a table. So I went back and asked Copilot to convert my table into cards.

{{< storage-figure src="react-dev1.png" alt="Making revisions to the app" link=self />}}

Eventually I got to a point where I was happy with the app, and I was ready to deploy it. I wouldn't really say that I "know" React now, but I do have at least a little bit of understanding of how to use it.

## Deploying the app

Azure Blob Storage has a built-in feature for hosting static websites. You can enable it per storage account in the Azure Portal. This creates a special blob container called `$web` that you can upload your static files to.

If I was being fancy, I could set up a GitHub action to automatically deploy the app to Azure whenever I push a new commit to the repository. However, I didn't want to spend the time to set that up right off the bat, so instead I used [Azure Storage Explorer](https://github.com/microsoft/AzureStorageExplorer/releases) to manually upload the files to the `$web` container.

{{< storage-figure src="storage_explorer.png" alt="File listing in Azure Storage Explorer" link=self />}}

After running `npm run build` to generate the static site, I uploaded the contents of the `build` folder to a `steamvibes` subdirectory in the `$web` container ("steamvibes" being kind of like a codename for the project).

> **Note**: React expects the app to be hosted at the root of the domain, so I had to add a `homepage` property to the `package.json` file to tell it to generate the correct URLs.
>
> ```json
> {
>   // ...
>   "homepage": "/steamvibes/build"
>   // ...
> }
> ```

After that, I was able to navigate to the URL of the storage account and see my app running.

{{< storage-figure src="project_preview.png" alt="The deployed app" link=self />}}

## Conclusion

This concludes the series on how I created a custom search engine for Steam games using embeddings. If you ever set out to do something similar, I hope that this series can be of some use to you.

I'd like to take a minute to re-emphasize what I wrote at the 'homepage' for this series:

> Under no circumstance should you be under the impression that what I've written here is the 'best' way of implementing all or any part of this project. I'm simply documenting how I made the thing.

Hopefully that's been made clear by the usage of Copilot to write most of the code for this app for me.

One thing I've learned is that you don't always need to make the most optimal choices if you're just making something for fun for yourself. I had a lot of fun making this project, and also challenging myself by writing about it as well. I hope you enjoyed reading it.

{{% contact-me box="steamsearch" %}}

---

{{<collapse summary="But what about your database population?">}}
> Well, it's already 24 hours after the script completed, so unfortunately I was not able to complete this series before the database was fully populated.
>
> Fun fact, during the week long process, ~1,200 games were added to the Steam store. That's an average of 7 games published every hour.
>
> In my defense, I wasn't doing unrelated work. I spent most of the day yesterday making optimizations to the scripts to fix performance issues. It turns out that some of those only pop up when you're querying through a million rows of data.
>
> Next step is publishing this series and working on indexing the embeddings with FAISS. Can't wait!
{{</collapse>}}

---

{{% series-nav name="Embedding-Based Steam Search" previous="part4-create-api" previousTitle="Part 4: Create an API" %}}