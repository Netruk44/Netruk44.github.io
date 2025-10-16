---
title: "GPT-4V - High Resolution vs Low Resolution"
date: 2023-11-09T14:01:47-05:00
draft: true
tags: ["OpenAI", "GPT", "GPT-4", "GPT-4V", "Machine Learning", "Text Generation"]
---

[GPT-4 with Vision](https://platform.openai.com/docs/guides/vision) (or GPT-4V) is now available to use via the OpenAI API. I'm personally interested to see how this model performs since I don't pay for ChatGPT Plus. In particular, I want to see how good it is at...well, 'seeing' things in images.

Also of interest to me, the documentation has notes about [low or high fidelity image understanding](https://platform.openai.com/docs/guides/vision/low-or-high-fidelity-image-understanding).

* The low fidelity mode uses a 512x512 pixel representation of the input image and uses 86 tokens to represent it to the model.
* High fidelity mode then adds on top of that a further multiple 512x512 crops of the original image each represented with twice the data (or 172 tokens per crop).

The trade-off being that the high fidelity mode is more accurate but slower and more expensive to use.

All very well and good, but not much as far as concrete details. I want to see what the difference is when the model only has the limited low fidelity information to work with vs high fidelity. What data gets left out or made incorrect?

I also want to see what happens when the model is presented with unusual imagery. How does it fail? Does it hallucinate things that aren't actually in the picture? Or does it just not see those things at all?

## The Setup

For each of these tests, I'm going to use the same prompt. The current preview of GPT-4V doesn't support system prompts. So the first prompt will always be from the user:

> **User:** Please describe what you can see in this image. Start with a description of what the image is of, then describe every detail you can see in the image. Be thorough and provide as much detail as you can. Go through the image from top to bottom, left to right, describing everything you can see.  
> \<Image\>

The OpenAI documentation indicates these caveats:

> The model is best at answering general questions about what is present in the images. While it does understand the relationship between objects in images, it is not yet optimized to answer detailed questions about the location of certain objects in an image. For example, you can ask it what color a car is or what some ideas for dinner might be based on what is in you fridge, but if you show it an image of a room and ask it where the chair is, it may not answer the question correctly.

I'm hoping that asking it to go from top to bottom, left to right won't be too much to ask. One of my initial tests showed that the model will tend to miss things if not prompted to review the entire image.

When reviewing the output of the model, I'm going to break it up into sections and add notes to point out issues with the output.

## Test 1 - A video game screenshot

This is a screenshot of [*TrackMania*](https://store.steampowered.com/app/2225070/Trackmania/) taken directly from my Steam Deck.

{{< storage-figure src="trackmania.jpg" alt="TrackMania" link=self />}}
{{% img-subtitle %}}
*The full-resolution image (1280x800), click to enlarge*
{{% /img-subtitle %}}

There's lots to look at and describe here, and I'm curious to see what the model makes of it. This image is interesting, because most of the detail in it happens to be in the UI. The gameplay of the screenshot is fairly simple.

I'm looking to see how well the model can 'read' the text off a screenshot like this. There's fonts of all sizes here, and some of them are quite small (The chatbox) or hard to read due to poor contrast (the labels at the top of the screen).

For a human, this screenshot is quite a lot to take in if you aren't used to looking at and reading video game interfaces. There's text and numbers *everywhere* on the screen, what does it all mean? Let's see if GPT-4V can help us out here.

### Low Fidelity
{{< storage-img src="trackmania_500.jpg" alt="TrackMania at 500 pixels" center=true />}}
{{% img-subtitle %}}
*What the model receives with low fidelity*
{{% /img-subtitle %}}

>This image appears to be a screenshot from a racing video game. The game's interface suggests a high emphasis on time trial performance, likely from a title within the "TrackMania" series, known for its racing and track editing features.
>
>At the top of the screen, we see a status bar with various pieces of information:
>- "BATT" followed by a percentage (98%), which could symbolize the battery charge of a device, but more likely is an in-game element.
>- A gauge icon next to a percentage (2.5%), the meaning of which is unclear but could represent some form of resource or capacity within the game.
>- Numerical values such as "51", "9.0", "10", "1.8", and "60°/S" are displayed across the top, which likely pertain to in-game metrics such as speed, distance, or other performance indicators.
>- **A stopwatch icon with "02:07.865" indicating a time, which is likely the current lap or segment time.**

Off to a pretty good start. It seems to believe that the Steam performance overlay is part of the game, though. With that misjudgement, it then goes on to try to explain what the numbers mean incorrectly.

The model appears to be able to read the larger, high-contrast text and numbers, but misreads or outright ignores the smaller and/or low-contrast text. "60 FPS" gets read as "60°/S" and with low fidelity it just doesn't seem to be able to read the labels for "GPU", "CPU" and "RAM".

Interestingly, it bunches the stopwatch in the middle of the screen with the performance numbers up at the top of the screen. It also misreads the stopwatch as "02:07.865" instead of "00:37.865".


>To the **top right**, a leaderboard is seen with rankings, user names, and times:
>- A list of names with associated times denoting their performance or rankings in the current race or challenge.
>- **The term "respawn" suggests that players can reset their position on the track after a crash or mistake.**

The leaderboard isn't in the top right, it's in the bottom right. But the word "respawn" doesn't appear anywhere in the screenshot. It appears to be hallucinated.

I believe that the term 'respawn' may be something the model has memorized about TrackMania. Because while it's not visible in the screenshot I gave to GPT-4V, if you get stuck and stop moving for a while then you get this text on screen:

{{< storage-img src="trackmania_extra_ui.jpg" alt="Launched Respawn and Give Up options" center=true />}}

I think the model may have been trained on images of TrackMania with these options visible on screen, and it's just something GPT-4V has memorized about the game.

{{< storage-img src="trackmania_500.jpg" alt="TrackMania at 500 pixels" center=true />}}
{{% img-subtitle %}}
*Just so you don't have to keep scrolling up for reference*
{{% /img-subtitle %}}

>The central portion of the image displays the back of a racing car with the number "243" on it. **The car is adorned with a checkered pattern, traditionally associated with racing, and red coloring**. The game's graphics render the car with a good level of detail and dynamic lighting, **illustrating motion blur effects that indicate high speed**. The car is on a racing track made of **smooth tarmac** with **white lines marking the driving lanes**.

* The model does not recognize the pattern on the car as red and white stripes, instead opting to call it "checkered" with red coloring.
* If you look at the full resolution screenshot, there's no motion blur in the image.
* I don't think the road material is tarmac. It's more pale like concrete (though I think it's supposed to be a fictional racing-optimized surface). No mention of the dirt road further down the track, either.
* And finally, there's no driving lanes marked on the track, but you might consider the white edges of the track to be the driving lanes.

>Beneath the car, a transparent overlay showing "**02:39.10**" is likely the current time or duration of the race attempt. **Additional numeric value "02:55.499" which is probably the player's best time or a target time to beat.**

At low fidelity, the model appears to struggle with reading numbers. "00:39.10" is misread as "02:39.10".

Interestingly, it was able to correctly read the milliseconds of the stopwatch time in the center of the screen, even though that font is much smaller than the one used for the time in the bottom center of the screen. I wonder how large the numbers have to be before GPT-4V can reliably read them at low fidelity?

The "additional numeric value" I believe is referring to the number labeled "Best" along the right edge of the screen. Once again, hallucinating an "02" at the front, but otherwise correct. However, this number does not appear 'below the car' as the model claims.

In addition, the model never remarks on the number labeled "Previous", possibly because the label is hard to read against the background, or because the number is the same as the "Best" number.

{{< storage-img src="trackmania_500.jpg" alt="TrackMania at 500 pixels" center=true />}}
{{% img-subtitle %}}
*For Reference*
{{% /img-subtitle %}}

>The environment of the track seems to be **industrial, with a structure resembling a crane or loading mechanism in the center-right of the image. It's constructed out of metal, with beams and platforms, and there appears to be a cargo container suspended in the air, suggesting a setting such as a port or industrial area.** The background shows a gray sky that blends with the industrial surroundings.

TrackMania features pretty abstract scenery, so the model mistakes an elevated road for a crane. Once it's decided that the thing it's looking at is a crane, the rest of the description is naturally going to be wrong.

The sky *is* gray, though.

>At the bottom of the image, more player interface elements are visible:
>- **"TrackMania" watermark logo, indicating the game title.**
>- In-game chat messages from players "**Amasyi**" and "**LEMGO**" with typical multiplayer chat interactions, indicating some form of community or multiplayer engagement.
>- A time indicator **at the bottom right corner**, saying "08:21" which could denote the time left in the session or a real-world time.

* The text "TrackMania" appears many places in the image, none of them at the bottom of the image.
* The names of players are misread, it's actually "AnasynD" and "IamG30".
* The time indicator is along the right edge of the screen.

>Overall, the image captures a moment of gameplay from a racing simulation game, highlighting the competitive and immersive aspects of the gameplay such as speed, precision, and interaction among players.

That's a nice bit of fluff about a pretty uninteresting screenshot.

In summary, at low fidelity the model is able to recognize quite a lot. But (as expected) low fidelity is not enough to represent all the finer details of the image like the text and numbers.

In addition, as OpenAI mentioned, the model has trouble with the relationship between objects in the image. This has lead to some inaccurate descriptions of where items are in an image, and leading to some descriptions that awkwardly group together visually distant elements.
