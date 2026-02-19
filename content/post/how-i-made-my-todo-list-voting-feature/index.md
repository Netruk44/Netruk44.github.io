---
title: "How I Made My Todo List Voting Feature"
date: 2026-02-16T10:25:09-05:00
draft: false
tags: ["tutorial", "Sqlite", "Python", "Flask"]
---

Many of my projects eventually reach a point where I have a large list of things I'd like to add or implement, but not much of an idea how to prioritize the list, or if users will even find what I'm thinking of useful.

For these cases, I like to implement my work item voting mechanism. Here's a brief overview of how I've implemented it. Maybe you can take the idea and apply it to a workflow of your own.

{{% toc %}}

## Back End Implementation

### Vikunja, The Task List Source
{{< storage-img src="./vikunja.png" center=true  border="true" />}}

- I use [Vikunja](https://vikunja.io/) as my self-hosted web-based todo list.
- Within Vikunja, I have a project set up for each of my apps.
  - (Not to get too sidetracked, but...) One of the reasons why I decided to use Vikunja is because most other todo list apps require a subscription for more than a small handful of projects. Lame!
- For tasks I want to let users vote on, I apply a `vote` tag. That's all that's required for the next part.
- I can also apply extra tags or mark tasks as 'done' in Vikunja to give extra info to users.
  - Sometimes I like to tag tasks with "Up Next" so users can know what I'm actively working on.
  - And tasks marked as "Done" can give users an idea of what to expect from the next update.

### Custom Workitem Voting API
{{< storage-img src="./api.png" center=true  border="true" />}}
- I obviously need a custom endpoint in order to implement user voting, since that's not something Vikunja has built-in.
- For the API, I created a small Flask-based app.
- The app has a few responsibilities
  - Fetch the current list of "vote-able" work items (for a given project ID).
    - It queries the Vikunja API to see which work items in the specified project have the 'vote' tag applied.
  - Accept new votes and keep track of the current counts
    - It uses a small sqlite database which maps work items to vote counts.
  - Keep a vote history so I can review votes
    - Every 24 hours a timer triggers which captures the current vote count for all work items and puts those into a separate table.
  - Provide an easy way to mark a task as 'complete'
    - This is mostly a utility for myself so that I can clear the vote count once I ship an update.
    - (This endpoint is also secret key protected, just in case it gets discovered)

## The User Experience
{{< storage-img src="./in-app2.png" center=true  border="true" />}}
- Users are presented with a list of features I had the thought of implementing
- They can see the title and a description of the feature, as well as how many votes it currently has.
- Finally, there is a button to add a vote to the work item.
- The user can hit the button as many times as they want to increase the vote count on any work item.
- There is also a message indicating that they are allowed to do this.
  - I got a few bug reports from users who thought that being able to add multiple votes to an item was a bug.
- The goal of the design was to allow for users who care a lot about a particular feature to be able to express that.
- But I also didn't want the votes of the users who choose to vote once or twice on a work item to be lost, either.
  - And launching apps to view the current voting counts becomes tedious incredibly quickly...
  - I need a dashboard.

## My Voting Dashboard
{{< storage-img src="./dashboard.png" center=true  border="true" />}}

- I added a dashboard endpoint, which generates an HTML page on-request of the current vote counts for all (two) of my apps.
- My primary view is a 'popularity' metric, which uses a custom formula to determine how popular work items are.
  - Popularity prioritizes "increase-days" over pure vote count, which are days when the count for a work item increases.
    - "Increase-days" act as a stand-in for "number of unique voters", because I do not have a way to track who has voted for which item (and do not intend to implement one).
    - And, if this formula is discovered, it provides incentive for the users to come back and vote daily, which is good for my app metrics 😊.
  - Why?
    - (By design) users can intentionally bombard a single work item with hundreds of votes to get it to the top of the list displayed in the app.
    - Other users just hit the upvote button once or twice on a couple of work items to signal support of various features.
    - I wanted a formula which took into consideration the very strong "interested" signal the bombarder provides (it takes time to hit the upvote button hundreds of times) while also making sure they don't drown out the signal from the single vote some other users choose to make.
- Additionally, I can also view the top 10 work items by vote count, as they are displayed in the app.
  - With this, I don't need to launch the app to see what the users are seeing.
- I also have a section for new votes added in the past 24 hours
  - Handy for figuring out what's recently changed

{{< storage-img src="./vote-history.png" center=true  border="true" />}}
{{% img-subtitle %}}
*Please ignore how long these work items have been sitting around for.*
{{% /img-subtitle %}}

- Finally, I have graphs of the vote counts over time
  - I use a logarithmic Y-scale for vote counts, since items tend to have anywhere between 1-150 votes. The log scale helps to add space between items, which tend to clump around the current high-vote count.
  - This graph helps me to see how the votes have shifted over time, and to ensure the 'popularity' metric seems correct.

### How I Use The Information
- I like to rotate through several projects, going between them one after another. I find it helps keep my interest maintained.
- When I get back around to one of these projects, I take a look at the dashboard voting history to see what votes have been added since last I looked.
- I generally like to have a 'plan' for things I want to learn, and use these votes as inspiration for guiding the direction of that learning.
- I don't strictly hold myself to what the votes suggest, but I always consider what users are asking for when planning my next updates.

- And that's pretty much all there is to it.
- Maybe know that you know how it's done, you can go and make your own voting mechanisms in your own apps.