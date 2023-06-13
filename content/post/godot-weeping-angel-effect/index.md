---
title: "Weeping Angel Effect in Godot Engine"
date: 2023-06-12T16:12:46-04:00
draft: false
tags: ["godot", "gamedev", "tutorial", "C#"]
---

I've recently been working on implementing some game concepts in the [Godot game engine](https://godotengine.org/). One of the things I normally do when messing around with a game-engine is try to recreate one aspect of a game I worked on in college, [Stonewick Manor](https://old.danieltperry.me/stonewick.html).

One of the core game mechanics of that game was a little cherub statue that followed you around. But there's a catch, it can only move when you aren't looking at it. The idea was, naturally, inspired by *Dr. Who*'s [Weeping Angels](https://en.wikipedia.org/wiki/Blink_(Doctor_Who)).

So let's try to make this kind of effect happen in Godot!

**Godot Version**: 4.0.3 .NET  
**Difficulty**: Easy - Intermediate

Here's a preview of the effect we're going to be making:
{{< video source="https://storage.danieltperry.me/share/website-videos/godot-weeping-angel/StatueTest.mp4" id="intro-video" >}}

A GitHub repository with the completed sample project can be found [here](https://github.com/Netruk44/godot-tutorials/tree/weeping-angel).

> ### Tangent about Stonewick Manor
> This doesn't really have anything to do with Godot, but I wanted to provide a little insight as to how the effect was accomplished the first time I tried it in college.
>
> ![](Stonewick.jpg#center)
>
> Our very first attempt at implementing this effect was to do a dot product between the player's facing direction and the statue's current location. We checked to see if the product was lower than a certain value. If it was below that threshold, we knew that the statue was located within the player's field of view.
>
> However, we felt this approach was lacking. There's a few issues with it, but our main issue with it was that you could effectively neuter the cherub just by looking in its direction through walls (remember this for later!). We wanted something a little more robust than that.
>
> ![](Stonewick2.jpg#center)
>
> In the final version of Stonewick Manor, we accomplished this effect by rendering the frame two times, with a whole pass dedicated to figuring out what's on-screen. We felt we could get away with rendering everything twice, because as a college game the art wasn't exactly very demanding on the hardware.
>
> On the second render, we would render everything but the statue in black to a texture. Once the occluders were rendered, we then rendered the statue in a pseudorandom color (derived from its handle ID) to the texture. Finally, we then checked the texture to see if any non-black pixels were rendered. If we did find non-black pixels, the color of it told us which character was currently visible. This way, we knew when it was safe for the statue to be moving, and when the statue should stop moving.
>
> ![](Stonewick3.jpg#center)
>
> As part of the implementation, I wrote a little bit of handcrafted assembly to check the texture for non-black pixels (`repne scasb` is very fast!). I was very proud of it at the time, but I feel compilers would probably do something like that optimization for you automatically these days.
>
> This tutorial will be using a similar approach, but instead of rendering the frame twice, we will instead be using the Godot engine's built-in visibility heuristics to determine when the statue is visible.

## The Godot Way

### Step 1 - Create the object that moves offscreen

To begin, create a new scene which will contain the object that will be moving behind the player's back.

![](Step1-1.png#center)

When creating the root note, select "Other Node" and create a `CharacterBody3D`. A [CharacterBody3D](https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html) is a node that is used to represent a character in a 3D game. It has a few useful properties, such as a `velocity` property that can be used to move the character around.

![](Step1-2.png#center)

Create the root node, and change the name to something more appropriate than `CharacterBody3D`, e.g. `Statue`. For this tutorial, we're just going to make a sphere that moves itself around offscreen, so I'll name mine `Ball`.

Godot should now be warning you that you need to add a `CollisionShape` to the object. A [CollisionShape](https://docs.godotengine.org/en/stable/classes/class_collisionshape3d.html) is a node that represents the shape of an object in the game world. This is for physics collisions only, the visibility calculations use a separate shape.

![](Step1-3.png#center)

Add a `CollisionShape3D` to the object, and in the right-hand side menu create a new shape for the collision. What you should use depends on what kind of object you're going to be applying this effect to. For this simple tutorial, we're going to be making a ball, so we'll use a `SphereShape3D`.

![](Step1-4.png#center)

Now that we have a body and shape, we need to give it some kind of visual representation. Add a `MeshInstance3D` to the ball, and in the right-hand side menu create a new `SphereMesh`. Or if you're using your own model, you can load that instead.

![](Step1-5.png#center)
![](Step1-6.png#center)

And, finally, we need to add a `VisibleOnScreenNotifier3D` to the ball. This is a node that will tell us when the object is visible on-screen. We'll use this to determine when the object should be moving.

![](Step1-7.png#center)
![](Step1-8.png#center)

You'll notice the default shape for the visibilty notifier is a cube, and not a sphere like the object we made. This is because Godot uses Axis-Aligned Bounding Boxes for the visibility heuristics. As of Godot 4.0, there is no way to change the shape of the visibility notifier, so we'll have to make do with a cube.

Adjust the size of the cube to be closer to the size of the object. This will be a manual process if you are using a custom model, but if you're using a generated shape then you should be able to calculate the size of the box.

> **Note**: If you make the size of the AABB to exactly fit the object within, you may notice that you can see the shadow of the object moving off-frame. If this is undesirable for your scenario, you should make the AABB large enough to encompass the object's shadow as well.

![](Step1-9.png#center)

Save the object, and move onto creating the script.

### Step 2 - Create the script

Now that we have the object created, we need to add a script to it. This script will be responsible for moving the object around when it is not visible on-screen.

For this tutorial, I will be showing you how to do this in C#, but the same principles apply to GDScript as well.

Right click the object and select "Attach Script".

![](Step2-1.png#center)

Change the language to C# (or don't), and save the script.

> **Note**: If this is the first C# script you're making for this project, make sure to create the solution file, too. You can do this by going to `Project > Tools > C# > Generate C# Solution` in the top menu. If you don't do this, your scripts won't be compiled and nothing will work.

![](Step2-2.png#center)
![](Step2-3.png#center)

By default, the script will be created with a template specific to `CharacterBody3D`, which contains some code we won't need. Remove code in the `_PhysicsProcess` function until it looks like this (or just copy and paste this code):

```cs
public override void _PhysicsProcess(double delta)
{
    Vector3 velocity = Velocity;

    // Add the gravity.
    if (!IsOnFloor())
        velocity.Y -= gravity * (float)delta;

    Velocity = velocity;
    MoveAndSlide();
}
```

Add a new private member to the class to hold a reference to this object's `VisibleOnScreenNotifier3D`, and create a `_Ready` function that sets it:

```cs
private VisibleOnScreenNotifier3D visibleOnScreenNotifier;

public override void _Ready()
{
    visibleOnScreenNotifier = GetNode<VisibleOnScreenNotifier3D>("VisibleOnScreenNotifier3D");
}
```

Now in `_PhysicsProcess` you can check whether or not the object is visible on-screen:

```cs
public override void _PhysicsProcess(double delta)
{
    Vector3 velocity = Velocity;

    // Add the gravity.
    if (!IsOnFloor())
        velocity.Y -= gravity * (float)delta;

    // vvvv New Code vvvv
    if (!visibleOnScreenNotifier.IsOnScreen())
    {
        // TODO: Move the object
    }
    else
    {
        // Stop the object.
        velocity.X = velocity.Z = 0;
    }
    // ^^^^^^^^^^^^^^^^^^^

    Velocity = velocity;
    MoveAndSlide();
}
```

And that's really just about it. All that's left is determining *where* the object should move when it's off-screen.

For this tutorial, let's make the object just move in circles. Let's keep track of the total time elapsed since the object was created, and use that to determine the angle of movement.

Add a private member to keep track of the time elapsed, and increment it in `_PhysicsProcess`:

```cs
private double totalTime = 0.0f;
```

```cs
public override void _PhysicsProcess(double delta)
{
    totalTime += delta;
```

Now we can replace the TODO:

```cs
    if (!visibleOnScreenNotifier.IsOnScreen())
    {
        // Move in circles based on total time.
        Vector3 moveDirection = new Vector3(Mathf.Cos((float)totalTime), 0, Mathf.Sin((float)totalTime));
        velocity = moveDirection.Normalized() * Speed;
    }
```

And that's it! You should now have a ball that moves in circles behind your back. Now we have to test it out.

> **Note**: If you have a game of your own all ready to go, you should be able to drop this object in and watch it work. Skip Step 3 and move onto Step 4 to check out an improvement you can make to the effect!

### Step 3 - Make it playable

While we have an object that probably does something pretty cool, we can't actually see it in action yet. Let's create a scene and a player-controlled object to bring it to life.

Create a new scene, and create a simple environment for the player to walk around in, and to have something for the ball to hide behind. Godot has pretty good built-in tools for whiteboxing a level, which is what I'll be using.

When creating your whiteboxed level, make sure to parent all your environment objects under a single 'environment' node. This will be important for later.

Make sure all your walls and floors contain all three `StaticBody3D`, `CollisionShape3D` and `MeshInstance3D` nodes. Pillars (cylinders) that are wide enough to occlude the entire object are particularly fun to play with.

Make sure to also add a light. We'll add a camera and player-controlled object after the level is created.

This is the level I made:

![](Step3-1.png#center)

For the player-controlled object with built-in camera, I've found [FPSControllerMono](https://github.com/ismailgamedev/FPS-Controller-Mono) to be an okay starting point, but as of writing this the plugin has not yet been updated for Godot 4.0 and fails to build, so you may need to make some fixes.

You can use the `AssetLib` tab on the top, search for `FPS` and install it into the project. When installing, you should import only the `Player.tscn` and `Player.cs` files, you won't need anything else.

![](Step3-2.png#center)

> **Note**: If you attempt to open the `Player.tscn` scene, you'll get an error about a missing dependency:
>
>![](Step3-3.png#center)
>
>This error is unimportant, and can be ignored. It's complaining that we didn't import one of the environment files that was stored in the plugin we downloaded. The environment contains configuration for the camera with settings such as bloom, SSAO, and other post-processing effects. We don't need this for our purposes, so we can just ignore it.

Next, set up input bindings for your project. You can do this by going to `Project > Project Settings` in the top menu, then selecting the `Input Map` tab.

At a minimum, you will need to define the following actions before you can play the game (you can bind them however you like):

![](Step3-4.png#center)

Now import the player into your environment by dragging `Player.tscn` into the scene. Make sure to move the player out of the ground if necessary.

![](Step3-5.png#center)

Now you can hit the "Play" button in the upper right hand corner and walk around your environment.

![](Step3-6.png#center)

Add a few of the balls to the scene in the same way you added the player, and run the game again. You should be able to see, or rather *shouldn't* see, the balls moving while you look away.

{{< video source="https://storage.danieltperry.me/share/website-videos/godot-weeping-angel/complete1.mp4" id="complete1" >}}

But if you play around with it enough, you'll notice that the balls don't move when they're occluded by walls:

{{< video source="https://storage.danieltperry.me/share/website-videos/godot-weeping-angel/issue1.mp4" id="issue1" >}}

Can we improve it?

### Step 4 - Occlusion Culling

Godot uses some heuristics inside `VisibleOnScreenNotifier3D` to determine if an object is visible or not. However, with the default settings, it does not take into account occlusion by other objects. If you enable occlusion culling for your project and set up the environment correctly, you can get a much more impressive effect.

> **Note**: Occluders (the objects doing the blocking) should be **static** objects only. While it is technically possible for dynamic objects to be occluders, it is **not** recommended. There's lots of overhead processing that needs to be done every time the occlusion map changes.
>
> If dynamic occlusion must be done, then you should avoid marking *moving* objects as occluders at all costs. This will absolutely tank your framerate. You should instead limit yourself to enabling/disabling static occluders during runtime.
>
> For more information, read the [Godot Docs](https://docs.godotengine.org/en/stable/tutorials/3d/occlusion_culling.html#avoid-moving-occluderinstance3d-nodes-during-gameplay) about the topic.

To enable occlusion culling, go to `Project > Project Settings` in the top menu, then enable `Advanced Settings`. Go to `Rendering/Occlusion Culling` and set `Use Occlusion Culling` to `On`.

![](Step4-1.png#center)

Now in your environment, select the 'Environment' node you created earlier, and add an `OccluderInstance3D` node as a child, alongside your environment objects.

![](Step4-2a.png#center)

This is the node that creates the occlusion map for the scene. With the node selected, you'll notice a new button on your viewport: `Bake Occluders`.

![](Step4-2.png#center)

Click the button to generate the occlusion map. You will be asked to save the resulting file somewhere in your project folder.

Run the game again, and you should notice an improvement in the effect:

{{< video source="https://storage.danieltperry.me/share/website-videos/godot-weeping-angel/complete2.mp4" id="complete2" >}}

## Conclusion

And that's it! You should now have a working Weeping Angel effect in your game. If you want to see the full source code for this completed tutorial, you can find it on my [GitHub](https://github.com/Netruk44/godot-tutorials/tree/weeping-angel).

{{< contact-me box="godot" >}}