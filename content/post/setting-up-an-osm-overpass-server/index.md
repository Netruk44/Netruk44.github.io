---
title: "Setting Up an OpenStreetMaps Overpass Server"
date: 2022-10-06T21:38:41-04:00
draft: true
tags: ["OpenStreetMaps"]
---

As part of my development on my [walking app](/project/2022-walking-app), I wanted to try setting up my own OpenStreetMaps Overpass server. Thinking aspirationally for a minute, if I ever wanted to share this app with others it would be best if I used my own compute to serve the app. But, truth be told, I have some free Azure credits I'm not using. So I'm looking for ways to spend the credits on interesting projects that serve no real purpose.

Additionally, I've noticed that the main shared Overpass server can be heavily loaded at points in the day, sometimes taking upwards of 10-15 seconds to respond to a query. It can feel quite slow when all I want to do is see a quick change I made. If nothing else, I'll improve my own development experience and help reduce the load on a shared resource I'm generating by testing my app.

{{< contact-me box="overpass" is-mid-article=true >}}

## Background
What is Overpass? The [Overpass API](https://wiki.openstreetmap.org/wiki/Overpass_API) is the API developers should use if all they need is read-only access to the complete OpenStreetMaps database. Which is the case for developers not developing an editor for the OSM database, like me and my app. The API is designed to be easy to self-host, which is what I'm interested in doing.

Helpfully, OSM has a [wiki page](https://wiki.openstreetmap.org/wiki/Overpass_API/Installation) dedicated to getting your own instance of the Overpass API up and running. There's also additional documentation available at the [Overpass API](https://overpass-api.de/no_frills.html) website. Let's follow the instructions and see what happens.

## Installing osm-3s
First things first, you need to build and install the binaries used to run the server. Which means I'll need a server with which to build the binaries.

### Azure Provisioning
> **Note**: I'll be putting costs in this post. The prices were accurate at the time of writing, but they're probably different by the time you're reading this!

As previously mentioned, I have free Azure credits I'm trying to spend, so that's where I'll be making my server. For the initial build, I'll be allocating a `D2as v4` size Linux virtual machine with Ubuntu 20.04 in Azure. This tier of virtual machine is allocated 2 cores of an AMD EPYC 7452 processor, along with 8 GiB of RAM. It costs $70.08/month, but we'll only be using it for a few hours.

Attached to the machine will be 256 GiB of storage to store the OpenStreetMaps database (Which costs $19.20/month for SSD, or $11.33/month for HDD).

> **Note**: It's important to note that the total cost of the this experiment won't be anywhere near the $70 quoted for the VM. You only pay for the time you use, and Azure makes it easy to resize the virtual machine after the fact.
>
> Though, if cost is a concern, I've noticed that Azure is very rarely the cheapest of the major cloud providers. The only reason I'm putting things there is because I have a monthly Azure credit. If you're looking for something similar but less expensive, I would recommend looking into Hetzner's [cloud offerings](https://www.hetzner.com/cloud).

> **Why did you choose `D2as V4` for the initial build?** 
> 
> I chose this class of machine because it was the cheapest dedicated compute available in the region I created the machine in (East US 2). D-series v5 would have been cheaper, but it's not available in East US 2.
>
> The only cheaper compute available were the B-series 'burstable' virtual machine. As the name implies, these machines are meant to be idle most of the time, with only occasional bursts of activity above a baseline percentage. This doesn't match what we're using the machine for at this stage, which is to compile the overpass api. B-series machines are only allocated 30 minutes of full processing speed on allocation. Compiling the API will likely take longer than this, and once the limit is hit your processing speed is severely limited.
>
> Instead the D-series was chosen, as this class of machine is allocated dedicated core time.

> **How much storage does an Overpass server need?**
>
> Documentation of the amount of storage you need seems to vary quite a bit, primarily depending on how out-of-date the documentation you're reading is. There doesn't seem to be a reliable source of how much space you'll need anywhere out there. Maybe this will change in the future?
>
> For a *rough* estimate, you can see how large the [planet file](https://planet.openstreetmap.org/) is. Currently, the planet size is 120 GB, and the OSM database size on disk is ~150 GB. You can possibly draw some conclusions with this data.

### Build
Once I had a machine, I followed the instructions written on [the wiki](https://wiki.openstreetmap.org/wiki/Overpass_API/Installation#Setup) for building the latest osm release. The build went smoothly, so I have nothing much to report here. I eventually had a build of osm available under `/opt/osm-3s/v0.7.54/`

> **Note**: I picked the location given as reference in the wiki without realizing Ubuntu doesn't have an `opt` folder by default. So as a result, osm is the only folder within `opt`. You may or may not want to use a different folder for your own installation.

### Database Population
The next step after building is somehow obtaining a copy of the OSM database. When populating the database, you need to decide if you want metadata in your database or not. For my purposes, I'm only interested in physical roads on the map. I don't need metadata tags, so for my commands I use `meta=no` or omit the `--meta` flag. However, your use case may differ. 

#### Populate by planet file
The Overpass API documentation mentions that you need a planet file to run the server, so I downloaded it in preparation for running my server. This then made me want to *use* the dang 120 GB file I had downloaded, so I decided to use the planet file to generate my own database to set up the server. However I **do not** recommend going with this approach.

To keep things brief here, due to the aforementioned issues with not knowing exactly how much space I would need to store the database files, I wasted a lot of time re-extracting the planet file multiple times. The extraction process **cannot be resumed** if there is an issue at some point (like if you run out of space).

If you're going this route, keep in mind that you will need storage for the planet file **in addition** to the space you'll need for the database files. You'll also need quite a bit of time, the process seems to be mostly I/O bound, which is not an area where cloud excels.

After failing to extract the database a few times, I gave up and went with the wiki-recommended approach

#### Populate by OSM server

The second approach I tried, and the approach I would recommend you go with, is to use a different OSM server to populate the database files directly. This worked on basically the first try, and in no time at all I had the database files ready to go and start querying.

## Running the dispatcher
At this point you have everything you need to run a static OSM Overpass server. The docs recommend you set up something to apply daily/hourly/minutely diffs to your database, but you don't have to. I decided I wanted to see my app querying my server ASAP, so I elected to avoid applying diffs right away, and instead moved onto running the dispatcher.

> **OSM Daemon Processes**:
> The OSM docs recommend you use `nohup [command] &` to start running the various OSM daemon programs. `nohup` lets the command you ran continue even after you disconnect from the machine, and `&` runs your command in the background and returns shell command back to you immediately.
>
> As an alternative, I would suggest you consider using tmux instead to run the programs instead. If you've never used it before, it's got a bit of a learning curve, but the payoff has been worth it in my experience.

Running the dispatcher proved unexciting. You can verify the dispatcher is working by attempting to run `osm3s_query` without specifying `--db-dir=`. If it works, your dispatcher is running correctly.

## Setting up the HTTP server
Next step is setting up Apache to host the Overpass HTTP API. The instructions in the Wiki were almost all I needed to get things working. I initially wanted to have responses gzip compressed, so I uncommented the lines related to gzip compression in the example apache default file. However, I wasn't able to ever get this working as I wanted it to. I had incorrectly assumed that the data would only be compressed for transmission, and when I received the data in the HttpClient on the other end, it would be decompressed for me automagically. However, this turns out to not be the case, or at least not in Godot. So, in the end, I didn't enable compression.

Looking back over my `bash_history`, I notice that I also ran a `a2enmod mod_header` command as well. I remember some errors that needed this module to be installed. My memory is a bit foggy at this point, but I believe this was related to my compression issues, however it's possible that I needed this in order to start the server at all. Unfortunately I don't have the logs, so I don't remember exactly what problem I was solving with this command. If you're hitting an error related to headers, try running that command and see if it helps.

## Performance testing and VM scaling
<TODO>

## Setting up diff applications 
The process has two halves covered by two different shell scripts. First you need to download the diffs to disk somewhere (`fetch_osc.sh`), then you have to apply the diffs to the database (`apply_osc_to_db.sh`).

> **Should I use daily, hourly, or minutely diffs?**
>
> The documents make it seem like you have a choice, but if you clone from another OSM Overpass server it doesn't seem like you get to choose. When you clone, it appears that you have to use the same diff method the original server used, as the `replicate_id` file gets cloned to your server. The `replicate_id` file holds the latest diff that has been applied, and the id is unique for daily/hourly/minutely diffs.
>
> If you made your own database from a planet file, you can use whichever method you like, you aren't restricted in the same way.

### Fetching diffs
<TODO>

### Applying diffs
<TODO>

## Open Questions

* What does long-term maintenance for running this application look like?
    * Do old minutely update files (.gz) get deleted eventually? Or am I responsible for removing those?
    * When is it safe to remove the old .gz files?
* When restarting the OSM server's minutely updates script, do I use the original sequence id of the original clone? Or the latest sequence id in 

{{< contact-me box="overpass" >}}