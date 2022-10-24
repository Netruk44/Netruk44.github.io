---
title: "My First Nix Derivation: OpenStreetMap Overpass Server"
date: 2022-10-23T11:08:52-04:00
draft: false
tags: ["Nix", "OpenStreetMap", "Docker", "Apache"]
---

I stumbled upon [Nix](https://nixos.org/) recently and I thought it was a very interesting project. If you've managed to find this post, then I imagine you already have an idea of what Nix is. But if not, they've provided a [handy page](https://nixos.org/explore.html) describing exactly what makes it so convenient for developers.

One of the things you find out very quickly when you start learning Nix is that a lot of information teaching Nix is in the form of blog posts from random people sharing what they're doing to learn Nix. All of the blog posts seem to be called "Learning Nix" or "Teaching Myself Nix", and so on. I figured I might as well add to the noise here with my own story on learning Nix 😊.

This post is pretty rambly, and not really edited for concise teaching. This post is mainly intended as a 'public journal' of the tasks and problems I faced while trying to accomplish my goals. Don't take it as a Nix tutorial (or a Docker tutorial, or Apache tutorial, etc.). I hope you find it useful in some way, but I'm well aware it's not ideal as a learning resource. I mainly wrote it for myself, to help wrap up what I've learned so far.

{{< contact-me box="nix" is-mid-article=true >}}

## Background

I've been working on an [app](/project/2022-walking-app), intended mainly for my own usage (currently, anyway). It acts as kind of a repository of GPX traces I take while I'm out on walks. The app reads the GPS positions from the traces, then cross references my traversed points with roads on a map. The app highlights which roads I've never walked on before, and I use that to vaguely direct my daily walking exercises.

One of the things this app needs is a source of map information, and I've found that [OpenStreetMap's Overpass API](https://wiki.openstreetmap.org/wiki/Overpass_API) to be exactly the thing I need. So I did some research and came up with a basic Overpass query that'll return me the roads within any given GPS coordinates. I select some coordinates in an area I've walked on before and where I know I'll already have walking data for. I stick it into my app and it works well!

Well, it works well *most of the time*, anyway. The public Overpass servers can get periodically overloaded. It's a free public resource for anybody to use, so you sometimes have to deal with congestion. Sometimes you'll request a part of the map and get ignored due to the load. Or it'll take over 15 seconds to get a response from the server.

The wiki provides instructions to [set up your own server](https://wiki.openstreetmap.org/wiki/Overpass_API/Installation) if you have the hardware to run it. I found the instructions to be pretty straightforward, so I decided to put some of my Azure credits to use and spun up a small VM and set up an Overpass server. It was straightforward enough that I chose to extend the project a bit, and make some Nix scripts that would both:

  > 1. Build the server binaries for Overpass
  > 2. Create a Docker image that would run the server.

It seemed like a pretty lofty goal to accomplish for someone who had never even read a single line of Nix script, however I was equipped with the knowledge that [most of the work was done for me already](https://grahamc.com/blog/nix-and-layered-docker-images). Nix already has the ability to generate intelligently-layered Docker images where each layer is a completely self-contained binary dependency. This leads to much smaller `docker push` runs, as you can *actually* share a significant amount of layers between vastly different containers. Read the linked blog post if that sounds interesting, I didn't find it too hard to understand.

So, I didn't even need to do much to get a Docker image built! The hard part of my plan, it seemed, would be learning Nix enough to make my first derivation.

## Creating the osm-3s derivation

First things first, in order to learn you need something to learn from. So I googled for a Nix "getting started" guide, and eventually got to the [NixOS Website's "Nix Pills" series](https://nixos.org/guides/nix-pills/). 

<!-- 
I initially dove in head first with a full-blown NixOS VM, but I'm not sure I would recommend that path for a beginner. It's a lot to learn a new linux distro on top of Nix itself. If you're just starting out with Nix, I would recommend installing Nix on top of a Linux distribution you're already familiar with. That way you can learn Nix in isolation, and once you're ready for more you can take the next step to NixOS.
-->

The guide has a page called "Our First Derivation", however the end result isn't what you should be using for real "production" work. The guide essentially shows you how the build scripts work by writing parts of them yourself. So what you wind up with is your own handwritten version of the builtin build scripts. For "real" work, you should just use those instead.

In the end, my best learning resource was the [nixpkgs repository](https://github.com/NixOS/nixpkgs) itself. After enough monkey-see-monkey-do, I managed to [produce a script](https://github.com/Netruk44/nix-scripts/blob/main/openstreetmaps_overpass/osm-3s.nix) that Nix would run:

```nix
{ pkgs ? import <nixpkgs> {}
}:

pkgs.stdenv.mkDerivation rec {
  pname = "osm-3s";
  version = "0.7.59";
  buildInputs = [pkgs.expat pkgs.zlib];
  enableParallelBuilding = true;
  src = pkgs.fetchurl {
    url = "http://dev.overpass-api.de/releases/osm-3s_v${version}.tar.gz";
    sha256 = "02jk3rqhfwdhfnwxjwzr1fghr3hf998a3mhhk4gil3afkmcxd40l";
  };
  CXXFLAGS = "-O2";
  meta = {
    description = "OpenStreetMaps Overpass API Server";
    longDescription = ''
      The OSM Overpass service provides an API to serve up
      selected parts of the complete Open Street Map dataset.
    '';
    homepage = "http://overpass-api.de/";
    license = pkgs.lib.licenses.agpl3Only;
  };
}
```

If you're interested, I've described the process of making this script in the section below:

{{< collapse summary="**Script Development Process**" >}}

Browsing the nixpkgs repository and looking at random packages reveals a common structure to the attribute set passed to `mkDerivation`. First I started with the pname and version, which was the easiest part as those can come from the overpass archive name. The first roadblock was actually successfully downloading that archive.

#### Downloading the source archive
There were two issues downloading the source archive, so let's tackle them in order.

The first was making sure the version numbers don't drift out of sync between `version =` and the version in the url string. We can do that by using interpolation. But there's a problem, if you try to reference `version` from in the string, you get this error:

```bash
error: undefined variable 'version'

       at /home/danielperry/repos/nix-scripts/openstreetmaps_overpass/osm-3s.nix:10:58:

            9|   src = pkgs.fetchurl {
           10|     url = "http://dev.overpass-api.de/releases/osm-3s_v${version}.tar.gz";
             |                                                          ^
           11|     sha256 = "02jk3rqhfwdhfnwxjwzr1fghr3hf998a3mhhk4gil3afkmcxd40l";
```

The trick is to make the attribute set you pass into `mkDerivation` recursive, by adding `rec` before the `{`:
> pkgs.stdenv.mkDerivation **rec** {

---

The second issue I ran into was trying to come up with the `sha256` value. At some point in my learning I read that "most people just throw in 0's and let Nix tell you the correct value", however I must have been mixing that advice up with advice for some other part of Nix, as that doesn't work here.

If we go with that approach:
```nix
  src = pkgs.fetchurl {
    url = "http://dev.overpass-api.de/releases/osm-3s_v${version}.tar.gz";
    sha256 = "0000000000000000000000000000000000000000000000000000";
  };
```

```bash
error: hash mismatch in fixed-output derivation '/nix/store/n5qkklx87s1fqccxi9dw12y8iy4igr8q-osm-3s_v0.7.59.tar.gz.drv':
         specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
            got:    sha256-FJDWWZ1ODRofmRDWoVBKDo4Mnwv5c9m5dbBxB3EeUwo=
```
You can see the hash in 'specified' isn't the 0's we supplied. This hash is clearly in a different format than what we entered, so we can't expect the 'got' value to work inside the nix script. We'll need to try something else.

Instead, the suggestion is to use `nix-prefetch-url` to download the tar.gz and let *it* tell me what the sha is:

```bash
$ nix-prefetch-url http://dev.overpass-api.de/releases/osm-3s_v0.7.58.tar.gz
path is '/nix/store/alvjh48vhar8js00vrmb56q0qnb4ws9m-osm-3s_v0.7.58.tar.gz'
1ipig0w3327nhl7dldcgkcm3fyhrib6h82n030rkb32bj9zr0g92
```

And indeed, this (`1ipig...`) is the value that needs to be given for Nix to be happy with the downloaded gzip archive.

---

With these changes, we now have something for Nix to build. But the build fails pretty quickly due to missing dependencies.

```bash
error: builder for '/nix/store/v1bxx04iix74x6xqx75sb8s195ipdy1m-osm-3s-0.7.59.drv' failed with exit code 2;
       last 10 log lines:
       > overpass_api/data/../statements/../dispatch/../../template_db/zlib_wrapper.h:22:10: fatal error: zlib.h: No such file or directory
       >    22 | #include "zlib.h"
       >       |          ^~~~~~~~
```

> **Side Note**: I'm recreating most of these errors long after the fact, Nix's reproducibility has been a boon here to help simulate the experience 😊

These errors aren't unexpected. After all, the Overpass Installation wiki page clearly lists the dependencies needed to build, and we haven't done that yet:

>Install the following packages: g++, make, expat, libexpat1-dev and zlib1g-dev.

#### Determining Build Inputs
g++ and make are used by `mkDerivation` by default, so all that was needed was to figure out how to make expat and zlib available during the build. Luckily, other packages in nixpkgs already reference both of these libraries, so it was as simple as figuring out how they did that and copying it into my script:

```nix
  buildInputs = [pkgs.expat pkgs.zlib];
```

We complete that, and it turns out that's all we needed! We have a building derivation:

```bash
$ time nix-build ./osm-3s.nix
...
/nix/store/sbj1c6cjjbh97gn9zrhz2g2b4hns0v2i-osm-3s-0.7.58

real    8m29.319s
user    0m0.135s
sys     0m0.032s
```

But...it's kinda slow, though. It took my Ryzen 5800X over 8 full minutes to compile everything. When I built this outside of Nix, it was much faster. What gives? A quick look at `htop` shows the issue: compiling only uses a single thread. There must be a way to enable multithreaded compiling.

A quick google search shows the answer, we just need to give the `mkDerivation` function `enableParallelBuilding = true`. Re-run the build and now:

```bash
/nix/store/sbj1c6cjjbh97gn9zrhz2g2b4hns0v2i-osm-3s-0.7.58

real    1m26.673s
user    0m0.139s
sys     0m0.025s
```

Great! We now have a reproducible build of the Overpass server binaries. The only final thing remaining is the Overpass wiki suggests compiling with `CXXFLAGS=O2`. A quick search on Nix documentation suggests that this flag might be supplied to g++ by default, however you can also explicitly supply it by simply adding `CXXFLAGS = "02"` into the attribute set you pass to `mkDerivation`.

You can view the current version of that script on my GitHub [here](https://github.com/Netruk44/nix-scripts/blob/main/openstreetmaps_overpass/osm-3s.nix). I may eventually merge this into the nixpkgs repository, though I have some personal legal issues that might prevent me from doing so. So, if someone happens to steal my nix script wholesale and puts it into the nixpkgs repository, I probably wouldn't be upset about it.

{{</collapse>}}

With the nix script in hand, we can now set about the process of making a nix script for the docker container which contains this executable!

## Creating the Docker image script

At this point in time, I had been running my own Overpass server for a while, so I already had some expectations about how the Docker image would work. One of the first problems I knew I was going to need to solve was how to get Apache running in the Docker image to serve the output of the `cgi-bin` executables produced by the build.

<!-- I personally have very little experience with Docker. My only history with it was for a personal ML project, I deployed a Flask application using Docker to an Azure VM as a learning project. So while I have *some* experince with Docker, it certainly wasn't a lot. At the time of me writing this post, I still don't have much experience with Docker. Don't take this as a Docker tutorial, because I barely know how to make a container 😊. In fact, I barely know how Apache, or really any of this stuff works. I said this was like a journal more than a tutorial, right? -->

From the outset, I imagined two approaches to creating an Apache + OSM Docker container with Nix.

### Approach 1: Full Nix
The first approach I imagined I called the 'Full Nix' approach.

Using Alpine Linux as the base for the Docker image, I would have Nix then layer both Apache and OSM Overpass on top of it. This way, Nix would be responsible for managing almost everything inside the container.

I primarily wanted to go this route to build my experience with Nix. And I did make a script that generated this Docker image, however I quickly ran into problems with getting Apache to run. Configuration files weren't where I expected them to be, so I didn't know how to set up a `VirtualHost` for the OSM executables.

<!-- From what I can see in online discussion boards, the Nix community doesn't like Apache much, and instead prefers to use Nginx. This doesn't help me, a person who's unfamiliar with both of them. I have experience with running OSM under Apache, so that's what I'd prefer to stick with. -->

In the end, I wasn't able to find much help with getting Apache to run from Nix. Most of the discussion that I *could* find about Apache was specific to NixOS and not Nix in general.

> As a side note, googling anything about Nix is tough, Google wants to autocorrect it to "Unix". My technique has been to google for "NixOS" even when I'm looking for Nix-specific things, to help Google understand I'm not just constantly missing the letter 'U'.
>
> It's possible that *this* is the reason why I couldn't find anything Nix-specific, however searching for `nix apache modules` didn't turn anything up, either.

Theoretically, instead of Alpine Linux I could base the Docker image off NixOS, somehow (Apparently the `nixos/nix` Docker image *isn't* NixOS). However NixOS doesn't seem to be recommended for use under Docker, and also I didn't want to dive into the specifics of configuring Apache under NixOS.

Instead, I went with plan B.

### Approach 2: Nix only for Overpass

Plan B is to base the docker image off of the Apache [httpd](https://hub.docker.com/_/httpd) Docker image, and just layer OSM Overpass + dependencies on top of that.

To make up for not going 'Full Nix', I decided to do some extra credit work to make Nix also produce a Docker image that could run on my ARM-based M1 MacBook Pro.

In the end, this approach was successful, and I wound up with a Nix script for a static (as in, not self-updating) Overpass server. [Here it is](https://github.com/Netruk44/nix-scripts/blob/main/openstreetmaps_overpass/docker/osm_static.nix):

```nix
{ pkgs ? import <nixpkgs> { }
}:

let
  osm3s = import ../osm-3s.nix {};
  # OSM Settings
  osmDataDir = "/mnt/osm"; # Where in the docker image the root OSM directory is located.
  osmRelativeDbDir = "db"; # Where, relative to osmDataDir, the db directory is located.
  logDir = "/mnt/log"; # Where in the docker image logs should be written to.

  startupScript = pkgs.writeTextFile {
    name = "start_server.sh";
    executable = true;
    text = ''
    echo "Starting OSM Dispatcher..."
    rm ${osmDataDir}/${osmRelativeDbDir}/osm3s_v* || true
    ${osm3s}/bin/dispatcher --osm-base --db-dir=${osmDataDir}/${osmRelativeDbDir} 1>${logDir}/dispatcher.log 2>&1 &

    echo "Starting httpd..."
    /usr/local/bin/httpd-foreground
    '';
  };
  
  # Base docker image configuration
  # Using apache/httpd as a base, as it includes apache utility binaries and configuration already setup.
  basePlatformImages = {
    "x86_64" = {
      imageName = "httpd";
      imageDigest = "sha256:15515209fb17e06010fa5af6fe15fa0351805cc12acfe82771c7724f06c34ae4";
      sha256 = "1r3zvfas5nb757z26gjmmdkk4hzbrglmj2q9ckhkhdjf77c29qzr";
      finalImageName = "httpd";
      finalImageTag = "2.4.54";
    };
    "arm64" = {
      imageName = "httpd";
      imageDigest = "sha256:8b449db91d13460b848b60833cad68bd7f7076358f945bddf14ed4faf470fee4";
      sha256 = "1a0b23pk5lf0fa2z1shggzmcskmj378rafdpfppwg8id6kfwfcgj";
      finalImageName = "httpd";
      finalImageTag = "2.4.54";
    };
  };
  currentBasePlatformImage = basePlatformImages."${pkgs.stdenv.hostPlatform.linuxArch}";
in
pkgs.dockerTools.buildLayeredImage {
  name = "osm-3s-static";
  tag = "latest";
  contents = [
    osm3s
    pkgs.nano     # Useful for debugging, not necessary
    pkgs.wget     # Required for download_clone.sh and fetch_osm.sh
    ./image_root  # Apache host configuration
  ];
  fromImage = pkgs.dockerTools.pullImage currentBasePlatformImage;
  config = {
    Cmd = ["${pkgs.bash}/bin/bash" "-c" startupScript];
  };
}
```

Note that this script references a few things not included in this snippet. First is:

```nix
  osm3s = import ../osm-3s.nix {};
```

Which is just the script I created above. And the second is:

```nix
  contents = [
    osm3s
    pkgs.nano     # Useful for debugging, not necessary
    pkgs.wget     # Required for download_clone.sh and fetch_osm.sh
    ./image_root  # Apache host configuration
  ];
```

The `./image_root` is a folder alongside the Nix script. The script should work as-is when cloned from the link.

Again, if you'd like to read the development process of this script, you can find that in this section below.

{{< collapse summary="**Docker Script Development Process**" >}}

The most helpful resource I could find for examples making Docker images from Nix came, probably unsurprisingly, from the [nixpkgs repository](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/docker/examples.nix). The Docker examples.nix file was invaluable in trying to figure out how to get the right parameters to `pkgs.dockerTools.buildLayeredImage`.

The first step is to generate a Docker image based on `httpd`, containing the Overpass binaries.

#### First Steps
Using that repository as a resource, I was able to get an image that contained the Overpass binaries, and had an idea on how to pull `httpd`. The tricky part was, as always, getting the `sha256`.

Starting simply with only x86_64 support, I had the [docker image](https://hub.docker.com/layers/library/httpd/2.4.54/images/sha256-15515209fb17e06010fa5af6fe15fa0351805cc12acfe82771c7724f06c34ae4?context=explore) ready to pass to `pullImage`. I could fill in most of the blanks, but how do I get the `sha256`? There's no url to give to `nix-prefetch-url` this time!

Google to the rescue, there's a tool called `nix-prefetch-docker` you can use for Docker images. How convenient! How do we run it? The same way you run any Nix-specific tool, with `nix-shell`.

```bash
$ nix-shell -p nix-prefetch-docker

$ nix-prefetch-docker --image-name httpd --image-tag 2.4.54 --image-digest sha256:15515209fb17e06010fa5af6fe15fa0351805cc12acfe82771c7724f06c34ae4

...
{
  imageName = "httpd";
  imageDigest = "sha256:15515209fb17e06010fa5af6fe15fa0351805cc12acfe82771c7724f06c34ae4";
  sha256 = "1r3zvfas5nb757z26gjmmdkk4hzbrglmj2q9ckhkhdjf77c29qzr";
  finalImageName = "httpd";
  finalImageTag = "2.4.54";
}
```

Simple enough. And it works! Well, it builds. We get a .tar.gz that contains a docker image split out into intelligent layers, which contains the Overpass binaries and Apache. However, nothing runs in the docker image yet. Until you specify `config.Cmd` in the nix script, Docker won't automatically run anything. That's okay for now, though. One step at a time.

At this point, the call to `buildLayeredImage` looks roughly (not exactly) like this:
```nix
pkgs.dockerTools.buildLayeredImage {
  name = "osm-3s-static";
  tag = "latest";
  contents = [
    osm3s
  ];
  fromImage = {
      imageName = "httpd";
      imageDigest = "sha256:15515209fb17e06010fa5af6fe15fa0351805cc12acfe82771c7724f06c34ae4";
      sha256 = "1r3zvfas5nb757z26gjmmdkk4hzbrglmj2q9ckhkhdjf77c29qzr";
      finalImageName = "httpd";
      finalImageTag = "2.4.54";
    }
}
```

Now, let's add multi-architecture support!

#### Arm64 Support

First off, we need the info for the arm64 version of httpd, which is simple enough to retrieve. Just swap the image digest you pass to `nix-prefetch-docker` to the arm64 version of the same image. It'll spit out another attribute set for that version.

Next, how do we make Nix choose appropriately? For now, just to learn how this works, I decided that this script will build the docker image for the architecture you're running the script on. If you want an arm64 image, run the script on arm64.

> **Note**: It's important to know that cross-building is possible with Nix. There's no reason you couldn't make an arm64 docker image from an x86_64 processor. This script doesn't do that, though. Again, this is more of a journal than a tutorial 😊.

I managed to accomplish this through the variable `pkgs.stdenv.hostPlatform.linuxArch`. As expected, this variable contains a string with the architecture of the host platform. I use this string to index into another attribute set I define with all of the platform docker images.

Abbreviated to just the relevant code, this is what it looks like in Nix:

```nix
let
  basePlatformImages = {
    "x86_64" = {
      imageName = "httpd";
      imageDigest = "sha256:15515209fb17e06010fa5af6fe15fa0351805cc12acfe82771c7724f06c34ae4";
      sha256 = "1r3zvfas5nb757z26gjmmdkk4hzbrglmj2q9ckhkhdjf77c29qzr";
      finalImageName = "httpd";
      finalImageTag = "2.4.54";
    };
    "arm64" = {
      imageName = "httpd";
      imageDigest = "sha256:8b449db91d13460b848b60833cad68bd7f7076358f945bddf14ed4faf470fee4";
      sha256 = "1a0b23pk5lf0fa2z1shggzmcskmj378rafdpfppwg8id6kfwfcgj";
      finalImageName = "httpd";
      finalImageTag = "2.4.54";
    };
  };
  currentBasePlatformImage = basePlatformImages."${pkgs.stdenv.hostPlatform.linuxArch}";
in
pkgs.dockerTools.buildLayeredImage {
  fromImage = pkgs.dockerTools.pullImage currentBasePlatformImage;
}
```

With this, I can make both x86_64 and arm64 images with the same Nix script. Now, let's make it run!

#### Getting Overpass running
When you run an Overpass server for yourself, you first need to seed the database somehow. Let's ignore this initial step for now, and assume there exists a database ready to go somewhere on disk. Thanks to my prior experience with Overpass, I know bootstrapping is as simple as running a single shell script.

Let's assume the database is available under `/mnt/osm/db`. I chose this location because I imagined this database should be contained within a Docker volume, and I like to keep mount points under `/mnt/` as a matter of personal preference. In addition, let's assume logs should be written to `/mnt/log`.

> **Note**: The Overpass build process generates a `reboot.sh` script you can use to start all the overpass binaries automatically. I chose not to use this script, as I wanted to have a more 'hands-on' knowledge of how the server runs. It's possible this script might run as-is without many major modifications, however I haven't tried it.

To run a full self-updating Overpass server, we need to run multiple OSM binaries in addition to the Apache httpd process. For this simple static Overpass server, we only need to start a single Overpass binary + Apache. Either way, we should make a shell script inside the image to hold the logic for starting everything, then we can invoke that script in the `config.Cmd` attribute.

<!--In order for the Apache server to process incoming Overpass requests, we first need to start the dispatcher process. From prior experience, you should also attempt to remove a temporary file in the db directory that gets generated by the dispatcher. This temporary file prevents a new dispatcher from running, but never gets cleaned up automatically. Then, once the dispatcher is running, we can start the apache http daemon.

To accomplish all of this, we should use a shell script. -->

But how do we make a shell script in the container? Initially, I used the attribute `extraCommands` passed to `pkgs.dockerTools.buildLayeredImage` to run some shell commands in the docker container to create a shell script that did what I needed. However, that's excessively complicated. It's hard to keep track of where and when everything is executing, and it's hard to imagine what the final state of things looks like.

Instead, we can have Nix create a script file for us with `pkgs.writeTextFile`. We can make that file executable, then we can include that script in the image just by referencing it in the `config.Cmd`.

Again an abbreviated Nix script to illustrate the point:

```nix
let
  startupScript = pkgs.writeTextFile {
    name = "start_server.sh";
    executable = true;
    text = ''
    echo "Starting OSM Dispatcher..."
    rm /mnt/osm/db/osm3s_v* || true
    ${osm3s}/bin/dispatcher --osm-base --db-dir=/mnt/osm/db 1>/mnt/log/dispatcher.log 2>&1 &

    echo "Starting httpd..."
    /usr/local/bin/httpd-foreground
    '';
  };
in
pkgs.dockerTools.buildLayeredImage {
  config.Cmd = ["${pkgs.bash}/bin/bash" "-c" startupScript];
}
```

And that's about it for OSM startup. Now let's come back around to the idea of starting a new server.

#### Database Bootstrapping

The Overpass Wiki provides a script you can run to clone the database files from a server: `bin/download_clone.sh --db-dir=/mnt/osm/db --source=http://dev.overpass-api.de/api_drolbr/ --meta=no`.

If we add `osm` to the `contents = [` of the nix script, then the mentioned script `download_clone.sh` will exist in the docker image under the root bin folder, under `/bin/download_clone.sh`.

Let's run that script in our docker image:

```
$ docker run --rm -v /mnt/ext/osm_db/:/mnt/osm osm-3s-static:latest /bin/download_clone.sh --db-dir=/mnt/osm/db/ --source=...
/bin/download_clone.sh: line 82: wget: command not found
/bin/download_clone.sh: line 82: wget: command not found
```

Oh, well that's simple enough to fix. Just add `pkgs.wget` to the `contents` as well and we're up and running!

Well, except for the Apache configuration.

#### Configuring Apache Modules
The Overpass Wiki mentions [some setup for Apache](https://wiki.openstreetmap.org/wiki/Overpass_API/Installation#Setting_up_the_Web_API). Let's go one by one and see if we can't replicate the steps.

First up, we need to enable some modules:
> `sudo a2enmod cgi ext_filter`

`a2enmod` doesn't seem to exist on this docker image. But after much googling, I found out you can enable these modules by changing the config file `/usr/local/apache2/conf/httpd.conf`. I created a temporary container and ran `docker cp` to copy that file out of the container and onto my dev machine to modify it locally. To enable the cgi module, you need to uncomment the line in the httpd.conf that looks like this:

```
<IfModule !mpm_prefork_module>
	#LoadModule cgid_module modules/mod_cgid.so
</IfModule>
```

The ext_filter module looks like this:

```
#LoadModule ext_filter_module modules/mod_ext_filter.so
```

So I uncommented those two lines and saved it under a similar directory tree relative to my nix script. Alongside the docker Nix script I created a `image_root` folder, which emulates the root of the docker container. I can then tell Nix to copy that folder to the root of the docker container in the build script.

In other words, in my `docker` folder, I have this directory tree:

```
- osm_static.nix
- image_root/
  - usr/
    - local/
      - apache2/
        - conf/
          - httpd.conf
```

And in my `osm_static.nix` script, I have this (abbreviated)

```nix
pkgs.dockerTools.buildLayeredImage {
  contents = [
    osm3s
    pkgs.wget
    ./image_root
  ]
}
```

And it works as expected, Nix creates a new layer specifically for these files, and it gets included in the Docker image.

One final step from the Wiki and we've got ourselves an Overpass server!

#### Configuring Apache Virtual Host
The Overpass Wiki provides a virtual host file:

```
<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	ExtFilterDefine gzip mode=output cmd=/bin/gzip
	DocumentRoot [YOUR_HTML_ROOT_DIR]

	# This directive indicates that whenever someone types http://www.mydomain.com/api/ 
	# Apache2 should refer to what is in the local directory [YOUR_EXEC_DIR]/cgi-bin/
	ScriptAlias /api/ [YOUR_EXEC_DIR]/cgi-bin/


	# This specifies some directives specific to the directory: [YOUR_EXEC_DIR]/cgi-bin/
	<Directory "[YOUR_EXEC_DIR]/cgi-bin/">
                AllowOverride None
                Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
                # For Apache 2.2:
                #  Order allow,deny
                # For Apache >= 2.4:  
                Require all granted
                #SetOutputFilter gzip
                #Header set Content-Encoding gzip
	</Directory>

	ErrorLog /var/log/apache2/error.log

	# Possible values include: debug, info, notice, warn, error, crit, alert, emerg
	LogLevel warn

	CustomLog /var/log/apache2/access.log combined

</VirtualHost>
```

For our usage, `[YOUR_EXEC_DIR]` can be removed completely, as the overpass binaries get installed into the root `/bin` and `/cgi-bin` folders. And `[YOUR_HTML_ROOT_DIR]` can be just the httpd docker image default: `"/usr/local/apache2/htdocs"` (or whatever you like, as Overpass doesn't use it).

I also changed the `ErrorLog` and `CustomLog` to point to `/mnt/log` instead.

Save that under the path `image_root/usr/local/apache2/conf/extra/httpd-vhosts.conf`. Next, we need to change the `httpd.conf` to read the vhosts file we made. Uncomment the line:

```
# Virtual hosts
#Include conf/extra/httpd-vhosts.conf
```

Save, build and deploy. And that's about it, a fully functional Overpass server! I'm sure more than a few things could be improved about the scripts, but I'm pretty proud that I was able to get to this point.

{{< /collapse >}}


## Next Steps

And that's it for now. I took a break from working on these scripts to write up this post, since I thought it would be worth sharing with others. The next step for this project is to make a self-updating Docker image. It's possible that I've already done that, and it's available [in my Git repository](https://github.com/Netruk44/nix-scripts/tree/main/openstreetmaps_overpass).

The self-updating server shouldn't be too difficult to make a Docker container for. All that's involved is starting two more executables in addition to the OSM dispatcher. One executable downloads incoming updates, and the other script applies them to the server.

In my experience, the self-updating part of hosting an Overpass server is very compute-heavy. When I tried setting this up on my Azure server, I needed to drop down from minutely updates to hourly updates so that I could run the Overpass server on a cheap enough class of VM for my Azure credits (Burstable class, which means I can't use the CPU all the time or else I get majorly throttled). In practice, that means my server maps are lagging from anywhere between 30m to 1h30m.

If you're interested in hosting your own Overpass server, the static server is perfectly fine if you don't need your maps with live updates from OpenStreetMap. The only reason I want updates is because I make updates to OSM in areas I walk in, and I want my app updated with those changes I make 😊.

{{< contact-me box="nix" >}}
