---
title: "My Thoughts on Vibe Coding"
date: 2025-10-16T17:05:47-04:00
draft: true
tags: ["Vibe Coding", "Programming", "Thoughts"]
summary: "My thoughts and personal experiences with vibe coding on four different projects."
---

Vibe coding has become a bit of a thing over the past year, hasn't it? With Claue Code kicking things off (at least for me personally) at the end of February (2025). Today, there's a plethora of tools to vibe your own apps from little more than a vague idea of what you want to accomplish.

Since then, I've tried things out on four of my projects so far, and I'd like to share what I wanted to do, what actually happened, and what I've learned from the experience, as well as some lessons learned.

{{% toc %}}


# Lessons Learned

## Vibe coding is for disposable code only

## For best results, stay within the AI comfort zone

## Context management is your primary responsibility

## Git is not optional

## It's still easy to bump into usage limits

# My Workflow

- Start with an idea of the task you want to accomplish.
  - It should be about 'one commit' worth of work. 
  - The size of that, I leave up to you.
- Begin by asking the agent to review the current codebase, keeping in mind the given task at hand. Ask it for plan on how to accomplish the task, along with potential alternative approaches.
  - Make sure to emphasize that it should not yet begin implementing a solution. The current goal is to understand and then make a plan.
  - Make sure to point out any specific files that are relevant to the task.
  - Make sure to specifically ask the model to read the AGENTS.md (or whatever) file for context on how the codebase is structured and how it should behave.
    - If this file doesn't exist, consider asking the model to help make one. It should mention everything you keep needing to point out to the model repeatedly
      - Always use the python in the `venv` directory, not the system python.
      - Validate your change by running this command `...` .
      - Before you commit, let me run things to make sure they work.
      - etc.
- Review the plan
  - Make sure you understand how the model intends to accomplish the task.
  - Does the approach make sense? Does it seem technically feasible?
  - Is the proposed solution over-engineered or overly complex for what you need?
- Once you're satisfied with the plan, ask the model to begin implementing it.
  - While it's working, observe the output it's producing. Review the changes it's making via git diff.
  - Sometimes the model can get stuck when it believes code should behave one way, but in reality it behaves differently.
    - Often the model will enter a loop of attempting fixes and failing to resolve the issue.
    - To prevent this from using up all of your usage limits, you should stop the model and consider if there's an alternative approach the model isn't considering which might work better.
    - Ideally, you come up with this approach yourself (since you hopefully have a better understanding of the overall goals for the project than what the model is assuming)
    - However, if you don't have any ideas, you can also try asking the model to stop its current approach and brainstorm alternative approaches.
- Once the model has finished implementing the solution, review the work.
  - Run the project and see what the changes are.
  - Oftentimes, there's glaringly obvious issues with the solution.
  - Your primary task here is to identify those issues and bring them to the model's attention.
  - Repeat until there are no more obvious issues.
    - (This leaves only the subtle issues 😊)
  - If the approach winds up being a dead end, consider reverting everything back to the original state and attempting a different approach.
    - Agents seem to tend to want to pigeonhole on one solution for any given repository and task. You'll probably need to tell the model "No, don't do it that way, I was thinking something like..."
- Once you're satisfied, commit the changes.
  - Personally, I always do the commit step myself.
  - However, I'm sure you could also ask your agent to do the commits for your.
- Repeat until your project is done.

# The Projects

## Claude Code - Video Game Options Menu

## Codex - Nginx Log Dashboard

## Codex - 360 Degree Video AI Upscaler

## Codex - Build some Hugo tooling to make linking easier

