---
title: "A Kopia Maintenance Warning"
date: 2025-09-09T20:23:21-04:00
draft: false
tags: ["Kopia", "Backup", "Application"]
summary: "A quick warning if you're using Kopia to manage backups for multiple machines with a single repository."
---

{{< storage-img src="./bb_dashboard.png" center=true />}}

> **💬 Note:**  
> This post is accurate as of Kopia version **0.21.1**, and as of the date of this post. Future versions of Kopia may change the behavior described below.

Here's a quick FYI.

If you're using [Kopia](https://kopia.io/) to manage your backups for multiple machines, with them all connecting to a single repository, you should be careful if you **ever stop** using one of those machines to backup to the repository. You might notice that your repository size starts to grow rapidly.

When you set up a new Kopia repository, it assigns one machine (the machine creating the repository) to be the maintenance owner. The maintenance owner is responsible for the garbage collection for the repository.

If you ever *stop* backing up that machine to the repository, garbage collection stops happening and so **old backup data will never be deleted**.

So, if you ever notice your communal Kopia repository size growing rapidly, consider checking the maintenance owner for the repository with:

```bash
kopia maintenance info 
```

It'll be the first line of the output, that says `Owner:`. If that machine is no longer connecting to your repository, you've found the problem. You can resolve the issue by reassigning the maintenance owner with:

```bash
kopia maintenance set --owner=user@hostname
```

Where `user@hostname` is the name of the user connecting to the repository (by default it's your username and hostname, but you can change it when you're connecting to the repository).

Then, once the owner has been updated, you'll have to start the process of expiring old data within the repository. However, it won't be deleted right away. It'll take **approximately 3 days** before the data will finally be deleted. You can start the expiration process with:

```bash
kopia maintenance run --full
```

This will start the process of garbage collection. If your machine regularly connects to and backs up to that repository, the old data should be gone in roughly 3 days.

> **💬 Note:**  
> You might see some mention of a different command that will force the deletion to happen immediately instead of over 3 days.
> 
> That command is unsafe to run if there are multiple machines connecting to a single repostiory (which is one of the prerequisites for this problem!)
>
> So, don't use that command. `maintenance run --full` is 100% safe to use.


----

If you're curious about why the expiration process takes 3 days, you can read more about that [in this GitHub issue](https://github.com/kopia/kopia/issues/1439#issuecomment-950225541).

In the meantime, I've managed to save myself a cool $2/month on my Backblaze B2 bill by deleting that old, inaccessible backup data.