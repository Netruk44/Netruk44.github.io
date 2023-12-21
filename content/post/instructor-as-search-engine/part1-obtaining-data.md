---
title: "Part 1: Obtaining Data"
date: 2023-11-20T10:33:43-05:00
draft: false
tags: ["Python", "Sqlite", "Steam", "API", "Data Gathering"]
summary: "Covering how to query the Steam API to get game data, and how to store it in a database from Python. It also covers some issues that arose along the way."
---

{{% series-nav name="Embedding-Based Search" previous="overview" previousTitle="Steam Game Search Overview" next="part2-creating-embeddings" nextTitle="Part 2: Creating Embeddings" include-explanation="true" %}}

---

{{%banner-early%}}

This is the first part in a series of five that covers how I created a custom search engine for Steam games using embeddings.

This post in particular covers the data gathering portion of the project. How did I find the data I needed, and how did I store it for later use? And finally, I'll cover some issues I encountered while doing so.

> **Source for this section**: Available on [GitHub](https://github.com/Netruk44/steam-embedding-search/tree/main/01_gamedataset)

{{% toc %}}

## Finding the APIs
The very first step in this project was figuring out where to gather the data from. I was sure that Steam had some API's I could call, it was just a matter of finding them.

I needed three things:
* A list of all the games on Steam
* The store description text of each game
* The reviews of each game

As far as I can tell, there doesn't seem to be a single documentation page that lists all of the API's that you can call. So this required a little bit of investigation.

### App Details API
Googling for `Steam store API` returns [documentation for the Steamworks web API](https://partner.steamgames.com/doc/webapi_overview), which is intended for games that are published on Steam. It deals with things like achievements, in-game purchases, and ownership information. Useful for game developers, not so useful for what I'm looking to do.

Luckily, [Reddit](https://old.reddit.com/r/Steam/comments/yppiht/store_page_info_via_steam_api/) came to my rescue, providing the suggestion that you can use: `https://store.steampowered.com/api/appdetails?appids=<appid>` to get information about a specific game. 

> Interestingly, while writing the app, I found that Copilot is also aware of this API. If you write a comment with something like `# URL for Steam Store API App Details`, I've gotten it to come up with the correct URL on its own. It's not always perfect, though.
>
> Tip for using Copilot: If you do your own research and put your findings into a `.md` file that you keep open in another tab on VS Code, Copilot will use that file to generate suggestions. This helps Copilot generate the URLs you need much more reliably. It's not as cool as Copilot 'just knowing' the API offhand, but can be useful if you keep a braindump file of notes like I do.

The app details API returns a JSON object containing a bunch of information about the game, including the game's description, publisher, screenshots, videos, platforms, Metacritic score and more.

### User reviews API

Next, I needed reviews. Luckily, Googling for `steam review api` returned [official Valve documentation](https://partner.steamgames.com/doc/store/getreviews) that was appropriate this time: `https://store.steampowered.com/appreviews/<appid>?json=1`.

This API returns a JSON object containing a list of reviews, each with a bunch of data, but most importantly, the review text itself.

However, by default this API only returns 20 reviews. You can request up to 100 at once by specifying the `num_per_page` parameter. You can also make multiple requests and use the `cursor` parameter to specify where to start at. The JSON response provides a `cursor` field that you can use to get the next page of reviews.

### Game List API

Finally, I needed a list of game appids. Sure, I could just start from 0 and work my way up, but I wanted a definitive way of knowing when I had gotten all the games.

This time, it's [Stack Overflow](https://stackoverflow.com/questions/46330864/steam-api-all-games) to the rescue, providing me with: `http://api.steampowered.com/ISteamApps/GetAppList/v0002/?format=json` (and also the app details URL again).

You can see the example output for yourself on StackOverflow, but it's basically just a list of appids and names.

## Storing results
Now that I know where I'm getting data from, I have to figure out where to put it.

My initial thought was to just dump responses to JSON files. This way, I could create a script that could process the files without having to call the API again. This would be useful for rapid prototyping, and also to get around Steam's rate limit requirement (more on that later).

But I quickly decided having thousands of json files on disk would be cumbersome to work with. So I decided to check out sqlite3, which I had heard of before but never used.

### Sqlite3
Sqlite3 is a lightweight SQL database that stores its data in a single file. It's useful for this project because it's cross-platform, easy to set up, and Python has a built-in library for interacting with it.

The benefits of using a sqlite database to store all the data is that it's apparently [faster than writing to disk yourself](https://www.sqlite.org/fasterthanfs.html), and super easy to move around. Fast is good, since we'll need to search through the database in the not-so-distant future, and a single file is good because I want to be able to easily move this data around to, say, a server later.

### Database schema
I started off with three tables, one for each of the three APIs I mentioned above. I eventually added more tables later to keep track of the last time I queried the API for a specific piece of data, see [Issues - API errors - More Tables](#more-tables) for more info on those tables.

As mentioned, I decided that I was going to be storing the complete JSON response from the APIs that I called. This way, if I ever needed to change how I was processing the data, I could easily do so without having to re-query the API.

Sqlite has methods for working with JSON, but I wasn't sure what the performance of those would be like. So in addition to having a column for the JSON, I also include extra columns for the specific data I'm interested in.

#### Game List
The first and simplest table is the game list table. It has the following columns:

<!--
CREATE TABLE IF NOT EXISTS gamelist (
    datajson TEXT,
    appid INTEGER PRIMARY KEY,
    name TEXT
)
-->

| Column | Type | Description |
| --- | --- | --- |
| `datajson` | TEXT | The JSON dict for an appid, as returned from the API |
| `appid` | INTEGER | The app id of the game |
| `name` | TEXT | The name of the game |

#### App Details
The app details table has the following columns:

<!--
CREATE TABLE IF NOT EXISTS appdetails (
    datajson TEXT,
    appid INTEGER PRIMARY KEY,
    storedescription TEXT,
    type TEXT,
    required_age INTEGER,
)
-->

| Column | Type | Description |
| --- | --- | --- |
| `datajson` | TEXT | The complete JSON response from the API |
| `appid` | INTEGER | The app id of the game |
| `storedescription` | TEXT | The game's description as it appears on the store page |
| `type` | TEXT | The type of content (game, dlc, video, soundtrack, demo, etc.) |
| `required_age` | INTEGER | The age rating of the game |

I initially started with just the first 3 columns. However, it became clear early on that there were many appids that I would not be interested in. To save on time calling review API's and to save time generating embeddings, I decided to move a few columns out of the JSON and into the table itself. And to keep filtering fast, I added an index to the `type` column.

What kinds of appid's did I want to avoid? It used to be the case that videos were stored as separate applications within the steam database. I also had no interest in this project being used as an adult content finder, but more than that unrelated adult content kept popping up in the results for other queries. So I decided to filter out any apps that had an age restriction.

> **Note**: The proper way to do adult content filtering is to look at the `content_descriptors` array in the app details JSON. There are specific values that indicate what kind of content is present in the game.
>
> However, there's many possible values that can be in this array, and I have not yet found documentation on what they all mean. So this will be a future improvement.

#### Reviews
The reviews table has the following columns:

<!--
CREATE TABLE IF NOT EXISTS appreviews (
    datajson TEXT,
    recommendationid INTEGER PRIMARY KEY,
    appid INTEGER,
    review TEXT,
    FOREIGN KEY(appid) REFERENCES gamelist(appid)
)
-->

| Column | Type | Description |
| --- | --- | --- |
| `datajson` | TEXT | The JSON dict for a review, as returned from the API |
| `recommendationid` | INTEGER | The id of the review |
| `appid` | INTEGER | The app id of the game |
| `review` | TEXT | The text of the review |

Each review is a separate `recommendationid`, and each review is associated with a specific `appid` that I can use to join with the `gamelist` table.

To keep things performant, I decided to make the `appid` column a foreign key that references the `gamelist` table, and added an index to it.

## Issues

There's a few more pieces to this part of the project that I still need to discuss, but may not be applicable to your own project if you decide to do something similar.

### Rate limiting

The first big thing is that Steam has a pretty slow rate limit on its APIs. The [terms of use](https://steamcommunity.com/dev/apiterms) (on a completely different page from the API documentation 😤) says that you can make 100,000 calls per day. But there's conflicting information, [Stack Overflow](https://stackoverflow.com/questions/51795457/avoiding-error-429-too-many-requests-steam-web-api) suggests it's closer to 200 requests per 5 minutes.

In the end, I limited myself with the more restrictive limit of 200 requests per 5 minutes, or 1 request every 1.5 seconds. I implemented this with just a call to `time.sleep(1.5)` before calling the API. I also used the `ratelimit` library as a fallback, but I don't think it was necessary.

But this posed a problem, retrieving data for all 150,000+ games on steam would take literally days to complete, and I wanted to get a working prototype up quickly. It would be nice to be able to query for just a small number of games at a time, and then be able to pick up where I left off later.

So I changed the script to only update a customizable number of games at a time, and then exit. This way, I could rerun the script to add more games to the database later.

{{<collapse summary="**How do you know which appids need to be updated?**">}}

> I put off the task of properly keeping track of which games had been updated. Initially, I just assumed that if I didn't have data for an appid (no details in the `appdetails` table, or 0 reviews in the `appreviews` table), then it hadn't been updated yet.
>
> This turned out to be insufficient, as you'll see in the next section.

{{</collapse>}}

### API errors

Another common issue I ran into was that not every appid that gets listed in the `GetAppList` API has a valid store entry. Attempting to retrieve the app details for these appids results in an error. And there's not a small number of them, either. I found that about 1 in 10 appids would return an error.

Initially, I just ignored these errors. However I knew this would eventually be a problem. When picking appids to update, there's no difference between one that hasn't been checked yet and one that always returns an error. If I only randomly pick from appids that don't have data, eventually those that always fail will dominate the list and it'll be difficult to find the completely unchecked appids that have data but have been unlucky in the draw.

#### More tables

How to solve this problem? More tables, of course!

I added two new tables to keep track of the API calls to the app details and reviews API's. `lastupdate_appdetails` and `lastupdate_appreviews`

{{<collapse summary="**Why not a new 'lastupdate' column instead?**">}}

> That would have worked for the `appdetails` table, but not for the `appreviews` table.
>
> The primary key of the reviews table is `recommendationid`, as there can be multiple reviews per appid. I update by appid, not by individual recommendations. It wouldn't make sense to associate the individual review `recommendationid` with a `lastupdate` timestamp.

{{</collapse>}}

Both new tables have the following columns:

<!--
CREATE TABLE IF NOT EXISTS lastupdate_appdetails (
    appid INTEGER PRIMARY KEY,
    lastupdate INTEGER
)
-->

| Column | Type | Description |
| --- | --- | --- |
| `appid` | INTEGER | The app id of the game |
| `lastupdate` | INTEGER | The last time the app details were updated |

This makes it a little more complicated to query for the appid's that haven't been updated yet, but now I can ensure that every appid gets checked at least once.

## Conclusion

At this point, I have a script that can incrementally query the Steam API for game data, and store it in a database. All that's left to do is let it run for an initial small batch of games so we can move onto the next step and start making some embeddings.

Eventually, though, we'll have to come back here to get the data for the rest of the games. That'll definitely take some time.

Like a week.

{{<collapse summary="Can you guess what's happening while I write this post? 😊">}}
> As of me writing this, it's currently 49 hours and 46% complete gathering appdata.
>
> It'll be another 100 hours of gathering reviews after that.
{{</collapse>}}


---

{{% series-nav name="Embedding-Based Search" previous="overview" previousTitle="Steam Game Search Overview" next="part2-creating-embeddings" nextTitle="Part 2: Creating Embeddings" %}}