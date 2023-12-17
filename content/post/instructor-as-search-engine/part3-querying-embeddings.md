---
title: "Part 3: Querying the Embeddings"
date: 2023-11-20T10:33:41-05:00
draft: false
tags: ["Python", "Machine Learning", "Embeddings"]
summary: "Covering the math behind embedding comparisons, how to create an index for the embeddings, and providing some examples of the results from my testing database."
---

{{% series-nav name="Embedding-Based Search" previous="part2-creating-embeddings" previousTitle="Part 2: Creating Embeddings" next="part4-create-api" nextTitle="Part 4: Create an API" %}}

---

This is the third part in a series that covers how I created a custom search engine for Steam games using embeddings.

At this point, we have a database of embeddings for Steam game descriptions and reviews. We now need to do a bit of a 'spot check' to make sure that querying the embeddings with a game description actually works, and works well enough to be useful.

> **Source for this section**: Available on [GitHub](https://github.com/Netruk44/steam-embedding-search/tree/main/04_querydataset)


{{% toc %}}

## How to Query the Embeddings?

The first challenge is figuring out the implementation details of actually searching through the database. We want some kind of measure of 'closeness' between two embeddings, so that we can find the closest match for any given query. The method I've chosen to use here is called cosine similarity.

Google has some [educational material](https://developers.google.com/machine-learning/clustering/similarity/measuring-similarity) discussing some alternatives you can use, but I was most familiar with cosine similarity, so I went with that. It's easy enough to swap out for something else later if I want to.

### Cosine Similarity

Cosine similarity essentially measures the 'angle' between two vectors, or embeddings. The closer the angle is to 0, the more similar the two vectors are. The resulting value is between -1 and 1, with 1 being the most similar.

This isn't a math blog, so I won't go into the details of how it works, but you can read more about it [here](https://en.wikipedia.org/wiki/Cosine_similarity). All that you really need to know is that you can use it to measure the similarity between two embeddings.

If you're using PyTorch, you can use the `torch.nn.functional.cosine_similarity` function to calculate the cosine similarity between two tensors. You can also implement it yourself pretty easily in numpy:

```python
import numpy as np

def cosine_similarity(a: List[float], b: List[float]) -> float:
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
```

Now all we have to do is take in a query, convert it to an embedding, then calculate the cosine similarity between that embedding and every other embedding in the database.

{{<collapse summary="Won't the O(N) approach to searching be too slow to be usable?">}}
> For large numbers of embeddings, yes. But during my development, searching through 50,000 embeddings took 3 seconds in total. It's not ideal, but certainly isn't slow enough to worry about for now.
>
> Later on in this post I'll discuss creating an index for the embeddings that will make searching much faster.
{{</collapse>}}

But Steam reviews can be a little noisy as far as data goes. It's not uncommon for meme/joke reviews that don't discuss much of the actual game to be the top review for a given game. It's tempting to try and filter those kinds of reviews out, but I think there's an easier solution.

An individual review can highlight some unique aspects of a game while leaving other information out. Instead of looking at reviews individually, how can we combine all of the reviews for a game into a single embedding that might better represent the game as a whole?

### Mean Pooling

Mean pooling is a fancy name for creating a new embedding where each dimension is the mean (average) of the corresponding dimension of all of the embeddings you're combining. It's what I would think of as 'getting the average' of a bunch of embeddings.

In terms of Python code, it's pretty simple:

```python
import numpy as np

def mean_pooling(embeddings: List[List[float]]) -> List[float]:
    # Option 1
    return np.mean(embeddings, axis=0)

    # Option 2
    return np.sum(embeddings, axis=0) / len(embeddings)
```

Surprisingly, this does pretty much what you'd expect it to. It takes the 'meaning' of all the embeddings and combines them into a single embedding that represents the whole. You can weight the embeddings differently if you want, too. But in our case since we can't know which review is more important than another, we'll just use the mean.

## Indexing the Embeddings

At this point in development, my database is only populated with the embeddings for ~10,000 game descriptions and reviews. Doing a O(N) search through the whole thing took just 3 seconds, which was fast enough for me to not worry about making searching faster.

However, once the database is fully populated that will no longer be the case. So how do you search through... `150,000 games * (1 game description embedding + 45 reviews on average per game) = 6,900,000` embeddings without looking at each one individually?

### FAISS

[FAISS](https://github.com/facebookresearch/faiss), or "Facebook AI Similarity Search", is a library that can be used to create indexes for embeddings. It's designed to be used with embeddings generated by neural networks, which just so happens to be exactly what we're using.

The tutorial I followed to learn how to use FAISS was the Pinecone tutorial [Introduction to Facebook AI Similarity Search (Faiss)](https://www.pinecone.io/learn/series/faiss/faiss-tutorial/). It builds knowledge from the ground up in an intuitive way, and I highly recommend it if you're interested in learning more about how searching can be done quickly.

As of the time of writing, I haven't yet added the index to my project, but I will be doing so soon. I suspect it will be pretty straightforward. If I have any additional thoughts on it, I'll add them here.

## Spot Check

With the implementation finally complete, I was able to check the results for the first time. I was a little disappointed, but not surprised, to find that the results were not amazing. Let's take a look at some examples.

### Query 1 - "An incremental / idle game with a medieval fantasy theme"

![Example results 1](../vibe_search_1.png#center)

Here are the links to the games in the above image so you can evaluate the results for yourself.

{{<collapse summary="**Results Table (click to expand)**">}}

<!--
  1635800: Dungeon Warriors (description)
    Match: 84.17%
  1013320: Firestone: Online Idle RPG (description)
    Match: 82.91%
  1887930: Idle Monster TD: Evolved (description)
    Match: 81.64%
  842150: Wild West Saga (review)
    Match: 81.21%
  759160: Dungeons&Vampires (review)
    Match: 80.56%
  547980: Equin: The Lantern (review)
    Match: 80.40%
  2450480: 放置修仙世界 (description)
    Match: 80.38%
  1241020: Idle Warrior (review)
    Match: 80.37%
  2216750: Clay Soldiers (description)
    Match: 80.34%
  1056350: Wizard Warfare (review)
    Match: 80.27%
-->

| Title | Banner | Description |
| --- | --- | --- |
| [Dungeon Warriors](https://store.steampowered.com/app/1635800/Dungeon_Warriors/) | ![Dungeon Warriors](https://cdn.cloudflare.steamstatic.com/steam/apps/1635800/header.jpg) |  It is a 3D RPG idle game. The game integrates RPG elements, with skill system, achievement system and very rich equipment system, so that players can experience diversified role-playing fun. |
| [Firestone: Idle RPG](https://store.steampowered.com/app/1013320/Firestone_Online_Idle_RPG/) | ![Firestone: Idle RPG](https://cdn.cloudflare.steamstatic.com/steam/apps/1013320/header.jpg) |  Firestone: Online Idle RPG is a multiplayer fantasy game with idle rpg mechanics. Collect heroes🧙‍♂️, upgrade their gear & skills, and sent them in idle battles or go on an incremental clicker frenzy to beat monstrous bosses! Chat with guild friends or engage in PVP⚔️- the choice is in your hands! |
| [Idle Monster TD: Evolved](https://store.steampowered.com/app/1887930/Idle_Monster_TD_Evolved/) | ![Idle Monster TD: Evolved](https://cdn.cloudflare.steamstatic.com/steam/apps/1887930/header.jpg) |  Evolve epic monsters and crush puny humans in this endless idle tower defense game! Unlock, upgrade, and evolve over 150 unique monsters and pets, ranging from cute and colorful flower creatures to epic fire breathing dragons, to assemble the ultimate team against the endless waves of enemies. |
| [Wild West Saga](https://store.steampowered.com/app/842150/Wild_West_Saga/) | ![Wild West Saga](https://cdn.cloudflare.steamstatic.com/steam/apps/842150/header.jpg) |  Wild West Saga is an idle game where you click to make money and build a business fortune! Hundreds of Towns to explore and Patent Cards to collect, dozens of Businesses to upgrade and Outlaws to hire. The end goal? To become the richest Pioneer in the Wild West! So, are you up for it? |
| [Dungeons&Vampires](https://store.steampowered.com/app/759160/DungeonsVampires/) | ![Dungeons & Vampires](https://cdn.cloudflare.steamstatic.com/steam/apps/759160/header.jpg) |  Dungeons & Vampires- addictive step-by-step role-playing role-playing Roguelike-game with a gothic atmosphere, combining Dungeon Crawler and Clicker mechanics. Teach your hunters to vampires, clearing the way through dangerous procedurally-generated dungeons. |
| [Equin: The Lantern](https://store.steampowered.com/app/547980/Equin_The_Lantern/) | ![Equin: The Lantern](https://cdn.cloudflare.steamstatic.com/steam/apps/547980/header.jpg) |  Equin: The Lantern is a challenging roguelike that's easy to get into but tough to master. Conquer the huge 50 floor dungeon and its evil inhabitants in a quest to the bottom of the joint to find the mysterious lantern itself. |
| [放置修仙世界](https://store.steampowered.com/app/2450480/Idle_Magic_Legend/) (Idle Magic Legend) | ![放置修仙世界](https://cdn.cloudflare.steamstatic.com/steam/apps/2450480/header.jpg) |  Team up to kill monsters and explode equipment. Through the program, thousands of people practice, make friends, and get married. You can also participate. You can become friends with her and learn magic together. Bring your dog to battle |
| [Idle Warrior](https://store.steampowered.com/app/1241020/Idle_Warrior/) | ![Idle Warrior](https://cdn.cloudflare.steamstatic.com/steam/apps/1241020/header.jpg) |  Idle Warrior is a little idle/clicker game in which you play an warrior who has to fight against an unlimited number of enemies. |
| [Clay Soldiers](https://store.steampowered.com/app/2216750/Clay_Soldiers/) | ![Clay Soldiers](https://cdn.cloudflare.steamstatic.com/steam/apps/2216750/header.jpg) |  The war rages on, choose to side with the Mercenaries, the Undead, the Angels, and more! Play through the single-player campaign, unifying the factions. Fight against other players and AI in the battleground's mode! Or strive for a conquest that takes you through the ages in war mode. |
| [Wizard Warfare](https://store.steampowered.com/app/1056350/Wizard_Warfare/) | ![Wizard Warfare](https://cdn.cloudflare.steamstatic.com/steam/apps/1056350/header.jpg) |  Wizard Warfare is a fantasy-themed, 4X-style, turn-based strategy game with a strategic empire management layer supported by a detailed tactical battle simulation layer. |

{{</collapse>}}

Looking at the top results, things seem to at least match up pretty well. They're at least idle games. But starting about halfway down the list of results, things start to get a little weird. We take a slight detour into turn based roguelikes before another idle game, and wrapping up with some strategy games.

At this point, it's clear there's at least some promise here. But it's hard to tell if the poor results are a result of the model, the implementation, or the lack of data in the dataset. Let's try some more queries.

### Query 2 - "A calming first-person, 3D exploration based game with a relaxing, cozy atmosphere in the outdoors"

![Example results 2](../vibe_search_2.png#center)

{{<collapse summary="**Results Table (click to expand)**" >}}

<!--
  1120940: Forgotten Passages (review)
    Match: 85.77%
  1408810: Manalith (review)
    Match: 85.56%
  1758320: Lofty Quest (review)
    Match: 84.87%
  2644960: Edge Of Survival (review)
    Match: 84.35%
  1783370: Aery - Dreamscape (review)
    Match: 84.25%
  509160: Gebub's Adventure (review)
    Match: 84.11%
  2563300: Dream #46 (review)
    Match: 84.07%
  360840: Lumini (review)
    Match: 84.01%
  464960: Hiiro (review)
    Match: 83.97%
  2490630: Summer Valley Hike (review)
    Match: 83.95%
-->

| Title | Banner | Description |
| --- | --- | --- |
| [Forgotten Passages](https://store.steampowered.com/app/1120940/Forgotten_Passages/) | ![Forgotten Passages](https://cdn.cloudflare.steamstatic.com/steam/apps/1120940/header.jpg) |  100 Tiny Levels. Stumble down a surreal rabbit hole and explore an atmospheric world composed of one hundred visually rich dreamscapes. This micro adventure takes about one hour to play straight through. Follow a girl and a mysterious bird through the wormholes of an eclectic universe. |
| [Manalith](https://store.steampowered.com/app/1408810/Manalith/) | ![Manalith](https://cdn.cloudflare.steamstatic.com/steam/apps/1408810/header.jpg) |  Set off on a calm and beautiful adventure exploring a vast mystical island in search of the lost Manaliths. Walk, climb, swim, and glide through valleys, woods, caverns, and coves discovering the island's secrets as you go. |
| [Lofty Quest](https://store.steampowered.com/app/1758320/Lofty_Quest/) | ![Lofty Quest](https://cdn.cloudflare.steamstatic.com/steam/apps/1758320/header.jpg) |  Lofty Quest is a narrative-driven hidden object adventure game where you search and explore beautiful, hand-crafted 3D dioramas to topple an evil King. |
| [Edge Of Survival](https://store.steampowered.com/app/2644960/Edge_Of_Survival/) | ![Edge Of Survival](https://cdn.cloudflare.steamstatic.com/steam/apps/2644960/header.jpg) |  Escape to a relaxing, survival sandbox surrounded by wildlife and nature. Scavenge materials and craft tools to turn your base into a warm, well-supplied home. Survive by fishing, hunting, cooking, and growing your own food. |
| [Aery - Dreamscape](https://store.steampowered.com/app/1783370/Aery__Dreamscape/) | ![Aery - Dreamscape](https://cdn.cloudflare.steamstatic.com/steam/apps/1783370/header.jpg) |  In Aery - Dreamscape you play as a bird like spirit who can enter the minds of other people in order to explore their thoughts, their secrets and their imagination. Experience the feeling of flying, immerse into beautiful and atmospheric landscapes and enjoy the unique storytelling of the game... ​ |
| [Gebub's Adventure](https://store.steampowered.com/app/509160/Gebubs_Adventure/) | ![Gebub's Adventure](https://cdn.cloudflare.steamstatic.com/steam/apps/509160/header.jpg) |  Gebub finds himself in a large peaceful world, filled with colorful orbs and many creatures who need his help. |
| [Dream #46](https://store.steampowered.com/app/2563300/Dream_46/) | ![Dream #46](https://cdn.cloudflare.steamstatic.com/steam/apps/2563300/header.jpg) |  Chill exploration, contemplative ride game with a boat. |
| [Lumini](https://store.steampowered.com/app/360840/Lumini/) | ![Lumini](https://cdn.cloudflare.steamstatic.com/steam/apps/360840/header.jpg) | A long-forgotten species, a hostile planet and a journey of discovery! Welcome to the world of Lumini – split and reform your swarm, evolve and discover new abilities to bring the Lumini back to their former glory... |
| [Hiiro](https://store.steampowered.com/app/464960/Hiiro/) | ![Hiiro](https://cdn.cloudflare.steamstatic.com/steam/apps/464960/header.jpg) |  Hiiro is a 2D platform game focused on ambient exploration and puzzle solving. Discover a grand world filled with mysterious artifacts and forgotten ruins. Become immersed in relaxing gameplay and meditative music. Remain observant as you unravel an explanation for your solitude. |
| [Summer Valley Hike](https://store.steampowered.com/app/2490630/Summer_Valley_Hike/) | ![Summer Valley Hike](https://cdn.cloudflare.steamstatic.com/steam/apps/2490630/header.jpg) | Embark on a soul-soothing journey through the captivating Summer Valley. Leave your worries behind and let the beauty of this peaceful world envelop you. Summer Valley Hike is your ticket to a serene escape from the chaos of everyday life. 

{{</collapse>}}

The results could be better here, too. There's lots of issues with the results. Many of these games, including the top result, aren't first person. Some of them aren't 3D. But at least they all have a relaxing atmosphere and seem to be exploration focused.

### Query 3 - "A fast-paced, action-packed, multiplayer, first-person shooter with a focus on team-based tactics and unique abilities."

![Example results 3](../vibe_search_3.png#center)

{{<collapse summary="**Results Table (click to expand)**">}}

<!--
  861290: Shooter Game (description)
    Match: 87.21%
  761300: Horde Of Plenty (review)
    Match: 86.12%
  1924510: Parabellum (description)
    Match: 85.95%
  1850930: Camp Wars (description)
    Match: 85.20%
  946070: Abstract (description)
    Match: 85.17%
  916100: Telefrag VR (review)
    Match: 84.52%
  366620: Broken Bots (review)
    Match: 83.92%
  758560: Versus World (review)
    Match: 83.90%
  2219150: MUA (description)
    Match: 83.67%
  1606570: Nokta (description)
    Match: 83.60%
-->

| Title | Banner | Description |
| --- | --- | --- |
| [Shooter Game](https://store.steampowered.com/app/861290/Shooter_Game/) | ![Shooter Game](https://cdn.cloudflare.steamstatic.com/steam/apps/861290/header.jpg) |  Shooter Game is a Multiplayer FPS . Fight in various maps with different weapons in both single and team death matches . |
| [Horde Of Plenty](https://store.steampowered.com/app/761300/Horde_Of_Plenty/) | ![Horde Of Plenty](https://cdn.cloudflare.steamstatic.com/steam/apps/761300/header.jpg) | In this action-packed twin-stick shooter, construction worker Ron Mayhem's beloved pet, Puffy, a rather round and yellow puffer fish, has been captured by the forces of evil. Slay the hordes, collect mad loot, and bring Puffy back! |
| [Parabellum](https://store.steampowered.com/app/1924510/Parabellum/) | ![Parabellum](https://cdn.cloudflare.steamstatic.com/steam/apps/1924510/header.jpg) | A semi sci-fi online PVP FPS shooter game with multiple maps, various weapon categories to master, incredibly fast paced movement with cool futuristic jetpack and jumppads around the map. Pickup armors and take control over enemy spawn to completely annihilate them |
| [Camp Wars](https://store.steampowered.com/app/1850930/Camp_Wars/) | ![Camp Wars](https://cdn.cloudflare.steamstatic.com/steam/apps/1850930/header.jpg) | First-person shooter, science fantasy. Slime Weapons. No deaths. |
| [Abstract](https://store.steampowered.com/app/946070/Abstract/) | ![Abstract](https://cdn.cloudflare.steamstatic.com/steam/apps/946070/header.jpg) | Abstract is a third person, cooperative or player versus player online action game set in an evolving sci-fi world. Yes, we have rockets and lasers! Yes, we have kill-streaks! Of course we have zombies! Why not? |
| [Telefrag VR](https://store.steampowered.com/app/916100/Telefrag_VR/) | ![Telefrag VR](https://cdn.cloudflare.steamstatic.com/steam/apps/916100/header.jpg) | Telefrag VR is a hellishly fast-paced shooter with visceral movement and combat mechanics. Dash, shoot, and teleport around unique arenas that feature impossible geometry where there is no right side up and death can come from any direction. |
| [Broken Bots](https://store.steampowered.com/app/366620/Broken_Bots/) | ![Broken Bots](https://cdn.cloudflare.steamstatic.com/steam/apps/366620/header.jpg) | Bestow double fire rate to your comrade or bastardize your enemy with reverse controls! Broken Bots is arcade style multiplayer robot warfare where players dish out power-ups to teammates & glitches to foes. Customize weapons, passives, & skills then battle it out in CTF, Team Deathmatch & KOTH! |
| [Versus World](https://store.steampowered.com/app/758560/Versus_World/) | ![Versus World](https://cdn.cloudflare.steamstatic.com/steam/apps/758560/header.jpg) | Welcome to Versus World! Shoot, stab, snipe, and 'splode your opponents to victory in this fast-paced multiplayer FPS. Here, the afterlife of a respawning immortal is seasoned by an up-down crouch. |
| [MUA](https://store.steampowered.com/app/2219150/MUA/) | ![MUA](https://cdn.cloudflare.steamstatic.com/steam/apps/2219150/header.jpg) | This is a team online battle game. Use various characters to win the battle! |
| [Nokta](https://store.steampowered.com/app/1606570/Nokta/) | ![Nokta](https://cdn.cloudflare.steamstatic.com/steam/apps/1606570/header.jpg) | Nokta is an online competitive FPS game that aims to give players fun and unique experience. |

{{</collapse>}}

Again, many issues with this list. First, a positive. They're at least all related to shooting things 😊. However many of these games aren't first person, and not many of them have any form of unique abilities.

A separate issue is that a fair number of these games feel very...low-effort. I don't want to be too harsh, but some of these appear to be just simple asset flips. I wonder if it might be because the prompt here used very common marketing terms like "action-packed" and "fast-paced", so the model returned very generic-appearing games. Either way, I'm not sure if the bad results are because Steam is just full of generic games, or if the model could be doing something better.


## Conclusion

So, how did it go? Well, I think it suffices to say that the results could be better. But on the bright side, throughout writing this blog series I've been able to identify a few areas where I think I can improve the results.

The results aren't completely useless, though. I've shown this to a couple people, and while they agree the results aren't amazing, they were also able to find some niche games they hadn't heard of before and were interested in. So I think there's at least some promise here.

Enough promise, at least, that I wanted to put it on the internet and write a blog series about it 😊. Even if things don't work great here, maybe someone else can learn something and make a better next version.

So, now that we have something that works (vaguely), the next step is to show someone else and get some feedback. These days, that means making a website. But we aren't going to have the user's browser do the search through the database, so that means we're going to need to create an API that can be used to query the database.

{{<collapse summary="Database progress report?">}}
> We've moved onto review gathering. Currently 35 hours in and 36% complete. Things aren't looking good for my 'write one post every other day' technique. I may not finish the series before it's done!
>
> In total, the application details took 108 hours and 51 minutes to complete.
{{</collapse>}}

---

{{% series-nav name="Embedding-Based Search" previous="part2-creating-embeddings" previousTitle="Part 2: Creating Embeddings" next="part4-create-api" nextTitle="Part 4: Create an API" %}}