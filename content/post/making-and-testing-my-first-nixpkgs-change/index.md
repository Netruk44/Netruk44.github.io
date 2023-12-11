---
title: "Making and Testing My First nixpkgs Change"
date: 2023-03-13T14:59:00-04:00
draft: false
tags: ["Nix", "OpenMW", "Mac"]
---

I have [a little](../my-first-nix-derivation-openstreetmap-overpass/) experience with Nix, but not a whole lot. Recently a post popped up on Hacker News about *[Zero to Nix](https://zero-to-nix.com/)*, which I decided to run through on my MacBook.

After [fixing](https://github.com/DeterminateSystems/nix-installer/issues/254#event-8735447050) a minor Mac-specific bug (specific to the *Zero to Nix* installer), I had a Nix installation ready to go! All I needed was something to do with it.

I eventually managed to [make a PR](https://github.com/NixOS/nixpkgs/pull/220750) to [nixpkgs](https://github.com/NixOS/nixpkgs) (basically Nix's package manager) for something I personally would find useful, so I thought I would stop and write about something small I struggled with along the way, being new to Nix.

How do you even build a change to nixpkgs, anyway?

{{% toc %}}

## The Motivation
I have some projects in mind I'd like to make involving [OpenMW](https://openmw.org/en/), an open-source ~~recrea~~ game engine that is able to play The Elder Scrolls III: Morrowind. These future projects will likely require source modifications to create.

> **Note**: Looking at the head version of OpenMW, it looks like a Lua modding API is in the works! Interesting!
> 
> However that won't work for what I want to use it for. What I need goes beyond the scope of an in-engine Lua script.

In preparation for the projects, I've gotten OpenMW building on my MacBook. Their [instructions](https://wiki.openmw.org/index.php?title=Development_Environment_Setup) were very helpful in getting my build up and running!

However, the process does include some manual steps to install dependencies. Mac even has a separate repository to build them! It would be nice for future-me if I didn't have to go through the process of re-learning how to build OpenMW from scratch. Having OpenMW on Mac in Nix would get me exactly that. In addition, using Nix would give me a pretty easy way to 'redistribute' my projects by having users use Nix to build it themselves.

Luckily, OpenMW is [already in nixpkgs](https://github.com/NixOS/nixpkgs/blob/master/pkgs/games/openmw/default.nix)! But the version of OpenMW in nixpkgs only has Linux support. Here's the relevant section of the derivation:

```nix
  meta = with lib; {
    description = "An unofficial open source engine reimplementation of the game Morrowind";
    homepage = "https://openmw.org";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ abbradar marius851000 ];
    platforms = platforms.linux;
  };
```

## Adding Mac Build Support

Most of the hard work is done for me here, really.
* OpenMW supports Mac, and so all of their build scripts know how to build for it.
* OpenMW is already being built in nixpkgs.
* Which means all of OpenMW's dependencies are *also* already in nixpkgs.

All I need to do is tell Nix to build for Mac and see what happens!

I clone `nixpkgs`, make a branch, and quickly make the change:

```diff
diff --git a/pkgs/games/openmw/default.nix b/pkgs/games/openmw/default.nix
index 8df88c92ff1..5a2dcd383e0 100644
--- a/pkgs/games/openmw/default.nix
+++ b/pkgs/games/openmw/default.nix
@@ -94,6 +94,6 @@ mkDerivation rec {
     homepage = "https://openmw.org";
     license = licenses.gpl3Plus;
     maintainers = with maintainers; [ abbradar marius851000 ];
-    platforms = platforms.linux;
+    platforms = platforms.linux ++ platforms.darwin;
   };
 }
```

> **Note**: `platforms` is an array of string values, `++` is array concatenation.

...but now what? How do I run a build from this local repository?

All the documentation I've read so far explains how to get up and running quickly by building something from the nixpkgs repository directly (Nix goes out to GitHub to get the files), but nothing I've read so far says how to build a package from a local clone.

*Zero to Nix* provides a way to build a package from nixpkgs:

```bash
nix build "nixpkgs#bat"
```

But this change doesn't exist in nixpkgs yet (and nor should it, because it doesn't build as-is)! 

It wasn't obvious to me from just staring at the command how I could use my own repository here, either local or remote.

> **Note**: If I had bothered to read the output of `nix build --help` I would have received some pointers:
>
> ```txt
>       It is also possible to match paths against a prefix. For example, passing
> 
>           | -I nixpkgs=/home/eelco/Dev/nixpkgs-branch
>           | -I /etc/nixos
> 
>       will cause Nix to search for <nixpkgs/path> in /home/eelco/Dev/nixpkgs-branch/path and /etc/nixos/nixpkgs/path.
> ```
> ```txt
>           | -I nixpkgs=flake:github:NixOS/nixpkgs/nixos-22.05
> 
>       makes <nixpkgs> refer to a particular branch of the NixOS/nixpkgs repository on GitHub.
>
> ```
>
> However, there's an easier way I discovered without too much struggling.

## Building the change
Doing a search on the internet for anything Nix related is a little bit confusing. Google sometimes blurs the line between `Nix` the package manager and `NixOS` the operating system. Search results are often for both of these things at the same time, with the articles for one usually not being helpful for the other. Not to mention that sometimes Google thinks you mean *U*nix instead of just Nix.

Further confusing things a little bit, *Zero to Nix* sets you up with a Nix environment set up solely for flakes, which everybody is quick to note are 'experimental'. So the documentation I found is mixed between the 'current' way of doing things and the 'flakes' way of doing things.

In the end, I gave up on Google and instead took a leap of faith. I guessed that instead of doing `nix build nixpkgs#openmw` like in the *Zero to Nix* tutorial, I could try this instead:

```bash
nix build .#openmw
```

And what do you know? It works!

> **Note**: If you're not currently using flakes, but would like to be for just this one command, you can add some extra arguments: 
> 
> ```bash
> nix build .#openmw --extra-experimental-features nix-command --extra-experimental-features flakes`.
> ```
>
> Quite easy to remember, I'm sure you'll agree!
> 
> Alternatively, you can just use `nix-build` (which also works with flakes, but I didn't know this incantation at the time):
>
> ```bash
> nix-build /path/to/your/local/nixpkgs -A openmw
> ```

Run the command...

```bash
> nix build .#openmw
evaluating derivation 'git+file:///Users/danielperry/Developer/nix/nixpkgs#openmw'

```

Nix spins for a bit, then finally...

```bash
error: Package ‘unshield-1.5.1’ in /nix/store/12lsghi0yj7fjna6rdz9l1vnfxilnfcv-source/pkgs/tools/archivers/unshield/default.nix:18 is not supported on ‘aarch64-darwin’, refusing to evaluate.
```

We hit an error.

Now we're making progress!

## Conclusion

At this point, it's just a matter of peeling the error-onion one layer at a time. Maybe I'll write about the full process of making the entire fix later. But if you're curious, as I mentioned before, you can take a look at my [pull request](https://github.com/NixOS/nixpkgs/pull/220750) for the change. I wrote pretty detailed commit descriptions of the issues I encountered along the way.

Looking back while writing this, it feels so obvious in retrospect that `nix build .#openmw` should have worked. Obvious enough that I feel it doesn't even warrant a post, but also that I probably won't forget how to build my local repository ever again.

Which is the real point of writing this blog post, anyway 😊.

But even though it feels obvious to me *now*, I also remember how I felt before I figured out the answer. The feeling of being overwhelmed with so much information you're not even sure is relevant to what you're trying to do.

In the end though, I managed to peel back the onion of the Mac-specific build errors of OpenMW in nixpkgs, and made my first contribution. Maybe my rambling on how I struggled past the first step can be helpful to somebody.


{{< contact-me box="nix" >}}