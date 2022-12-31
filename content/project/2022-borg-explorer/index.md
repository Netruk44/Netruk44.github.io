---
title: "Borg Explorer"
date: 2022-12-30T15:07:55-05:00
draft: false
tags: ["Electron", "Javascript", "Borg", "CSS", "HTML"]
---

A simple GUI for looking through [Borg Backup](https://borgbackup.readthedocs.io/en/stable/) repositories in a file-browser-like manner, without needing to mount them, instead parsing the output from `borg list`.

# Info
![](./icon.png#center)
{{% img-subtitle %}}
**Icon**  
{{% /img-subtitle %}}

![](./ss1.png#center)
{{% img-subtitle %}}
**Screenshot**
{{% /img-subtitle %}}

* **Status**: Semi-Active Development (Updates when and if I need them 😊)
* **Source/Download**: https://github.com/Netruk44/borg-repository-explorer
* **Technologies & Languages**: Electron, HTML, Javascript, CSS

# Why
I began using Borg this year (2022) to manage my machine archives. Currently, my 'main' machine is my M1 MacBook Pro. MacOS doesn't natively support FUSE mounts, which is how one usually browses Borg archives after creation (through use of `borg mount`). Therefore, I was in need of a GUI for Borg that didn't rely on the `mount` subcommand.

I did some searching, but couldn't find anything that fit the bill. The recent trend when I started this project was to have [GPTChat](https://chat.openai.com/chat) design and implement entire websites and applications for you. So I thought I would give that a shot on my own, and ask it for guidance how to make a cross-platform GUI application.

GPTChat recommended some GUI frameworks like QT and wxWidgets, as well as Electron. Electron seemed like the easiest fit for GPTChat to help me with, so I decided to embark on making a GUI app in Electron with the assistance of GPTChat.

Eventually, I got tired of trying to form my code queries in the form of a chat message, so I decided to use [Copilot](https://github.com/features/copilot) instead.

# Screenshots
*Also available in the [GitHub Repository](https://github.com/Netruk44/borg-repository-explorer). Screenshots below may be out of date.*

{{<collapse summary="**Version 0.0.4**">}}

![](./ss1.png#center)
{{% img-subtitle %}}
*The initial screen of the application.*
{{% /img-subtitle %}}

![](./ss2.png#center)
{{% img-subtitle %}}
*Browsing a Borg archive.*
{{% /img-subtitle %}}

![](./ss4.png#center)
{{% img-subtitle %}}
*Loading an archive from the repository.*
{{% /img-subtitle %}}

![](./ss3.png#center)
{{% img-subtitle %}}
*Browsing an individual backup.*
{{% /img-subtitle %}}

![](./ss5.png#center)
{{% img-subtitle %}}
*Previewing an image from the backup.*
{{% /img-subtitle %}}

![](./ss7.png#center)
{{% img-subtitle %}}
*Previewing a text file from the backup.*
{{% /img-subtitle %}}

![](./ss6.png#center)
{{% img-subtitle %}}
*Extract dialogue.*
{{% /img-subtitle %}}