
<!--
* I originally wrote this section mostly to prove to myself I could still read and understand math, especially since math pages on Wikipedia have always read like hieroglyphics to me. I wanted to poke fun a little bit at it.
* But you really don't need to read or understand it to implement the gestures.
* I spent...a while on it, so it's hard for me to just completely remove it (despite it being unnecessary).
* You don't really need to read or understand any of this section, you just need to know what the formula is for projecting a point onto a 1D line:
  * \( P_A(\mathbf{v}) = \frac{\mathbf{u} \cdot \mathbf{v}}{\mathbf{u} \cdot \mathbf{u}} \mathbf{u} \)
* If you'd like to see how it's derived, click to expand. It's quite a long read.
* Otherwise, feel free to skip to the next section.
-->


This section is optional because you don't really need to be able to derive the 1D line projection formula from the generic projection formula to implement the gestures. You just need to know that the formula to project a point onto a 1-dimensional line is:

\[ P_A(\mathbf{v}) = \frac{\mathbf{u} \cdot \mathbf{v}}{\mathbf{u} \cdot \mathbf{u}} \mathbf{u} \]

Even if you don't understand what this means, in the next section I explain the above formula step-by-step.

What I *wanted* to do was link to a Wikipedia page on projection and be done with it, but then I *looked* at the [Wikipedia page for projection](https://en.wikipedia.org/wiki/Projection_%28linear_algebra%29#Formulas) and I still have no idea how anyone can understand Mathematical Wikipedia. It's like reading hieroglyphics.

So I took what Wikipedia wrote and re-derived the line projection formula for myself. I guess I mostly wanted to prove to myself that I could do it.

If you want to read out an overly long derivation of how you go from the Wikipedia page on "Projection" to an actual, usable formula for projecting a point onto a 1D line, click to expand the section below. It's quite a long read, though. And there are no pictures.

{{<collapse summary="**Optional Math:** The derivation">}}
<!--
* > This section is tongue-in-cheek, and is going to be a whirlwind tour of deriving a formula. I'm definitely not the best person to be teaching math concepts, so unfortunately there will be a lot of detail-skipping involved.
* > Don't worry if a lot of this goes over your head. This section is here to explain the logic behind the math we're about to implement. I'll explain the details we need in more detail next.
* [Wikipedia](https://en.wikipedia.org/wiki/Projection_%28linear_algebra%29#Formulas) tells us all we need to know about projection. Give it a glance, and tell me that it isn't simplicity itself.
* ...
* What do you mean you don't understand? It's right there, clear as day:
  * \( P_A = \sum_i \langle \mathbf u_i, \cdot \rangle \mathbf u_i \)
  * In this formula:
    * \( P_A \) is "the projection onto subspace A"
    * \( \sum_i \) is a sum (using the placeholder variable \( _i \)). You figure out all the terms of the sum, then add them together. A single term is defined by what's after the \( \sum_i \) symbol, and you replace all placeholder \( _i \) after the \( \sum_i \) with 0, 1, 2 ... up to the number of terms you have.
    * \( \langle x , y \rangle \) is an inner product. It's essentially a way to compare two things (vectors, in this case) to see how much they "point in the same direction".
    * \( \mathbf{u} \) (without the \( _i \)) defines the basis of the space we're projecting onto. Depending on the number of dimensions of the space you're projecting onto, this could be 1 to n (orthogonal!) vectors.
      * (The basis of our space will be the 1-dimensional line from the user's middle finger tip to their middle finger knuckle.)
    * So then, it follows that \( \mathbf{u}_i \) is the basis vector for a single dimension of the space.
    * Finally, the \( \cdot \) inside the angled brackets is a placeholder for the vector we're projecting.
    * Also, keep in mind that multiplication is usually not written out like \( x*y \) or similar. It's just implied when you have two things next to each other.
  * (Collapse: "But there's a simpler formula!")
    * Yes, I can see that formula for projecting onto a line:
      * \( P_\mathbf{u} = \mathbf u \mathbf u^\mathsf{T} \)
    * Both of these are correct. 
    * The one I'm using is generalized and will lead us to something we're looking for.
    * Whereas this specialized formula doesn't do that. So...I'm not going to explain it.
    * Being good at math is recognizing which formulas to apply and when. Some lead you to a more helpful place, others don't.
  * Let's rewrite this formula just a little bit so we can introduce \( \mathbf{v} \), the vector we're going to project, as well as \( \mathbf{d} \), the number of dimensions of the space we're projecting onto (both of which are already in the formula implicitly, we're just going to make them explicit):
  * \( P_A(\mathbf{v}) = \sum_{i=1}^{d} \langle \mathbf{u}_i, \mathbf{v} \rangle \mathbf{u}_i \)
  * This is the exact same formula, just rewritten for clarity.
  * Let's start massaging this formula to suit our specific needs.
  * Now, obviously since we're projecting onto a one-dimensional line, d = 1:
  * \( P_A(\mathbf{v}) = \sum_{i=1}^{1} \langle \mathbf{u}_i, \mathbf{v} \rangle \mathbf{u}_i \)
  * A sum from i = 1 to 1 is just one term, so let's simplify:
  * \(  P_A(\mathbf{v}) = \langle \mathbf{u}_1, \mathbf{v} \rangle \mathbf{u}_1 \)
  * We can rename \( \mathbf{u}_1 \) to just \( \mathbf{u} \) now as we only have the one basis vector (the line we're projecting onto):
  * \( P_A(\mathbf{v}) = \langle \mathbf{u}, \mathbf{v} \rangle \mathbf{u} \)
  * By default it's assumed that basis vectors are normalized, but we may not be working with a normalized basis vector (most people's fingers aren't exactly 1 meter long). It's not harmful to normalize an already-normalized vector, so let's normalize. Divide by the length of the basis vector (\(\mathbf{u} \cdot \mathbf{u}\)):
  * \( P_A(\mathbf{v}) = \frac{\langle \mathbf{u}, \mathbf{v} \rangle \mathbf{u}}{\mathbf{u} \cdot \mathbf{u}} \)
  * Let's re-order this a little bit. Remembering our elementary math classes, multiplication and division are associative. In other words, \( \frac{xy}{z} \) is equal to \( \frac{x}{z}y \):
  * \( P_A(\mathbf{v}) = \frac{\langle \mathbf{u}, \mathbf{v} \rangle}{\mathbf{u} \cdot \mathbf{u}} \mathbf{u} \)
  * And, continuing to remember our math classes, we know we can replace the inner product with a dot product (since we're dealing with vectors and not, say functions or complex numbers):
  * \( P_A(\mathbf{v}) = \frac{\mathbf{u} \cdot \mathbf{v}}{\mathbf{u} \cdot \mathbf{u}} \mathbf{u} \)
* **There we have it, the projection formula for projecting a point `v` onto a one-dimensional space `A` defined by a potentially un-normalized vector `u`.**
* This is the standard formula you'll see if you look up how to project a point onto a line orthogonally. We just derived it ourself.
* Wikipedia couldn't have made it any simpler for us.
* ...
* What do you mean you still don't understand?
  * You know how to do a dot product, right?
* Alright, fine. I guess I can explain a *little* bit more.
-->
> If you haven't already, do take a look at the page on Wikipedia for [projection](https://en.wikipedia.org/wiki/Projection_%28linear_algebra%29#Formulas), and tell me that it isn't simplicity itself.
>
> Go ahead, look!
>
> ...
>
> What do you mean you don't understand? It's right there, clear as day:
>
> \[ P_A = \sum_i \langle \mathbf u_i, \cdot \rangle \mathbf u_i \]
>
> In this formula:
> 
> \( P_A \) is "the projection onto subspace A"
> 
> \( \sum_i \) is a sum (using the placeholder variable \( _i \)). You figure out all the terms of the sum, then add them together. A single term is defined by what's after the \( \sum_i \) symbol, and you replace all placeholder \( _i \) after the \( \sum_i \) with 0, 1, 2 ... up to the number of terms you have.
> 
> \( \langle x , y \rangle \) is an inner product. It's essentially a way to compare two things (vectors, in this case) to see how much they "point in the same direction".
> 
> \( \mathbf{u} \) (without the \( _i \)) defines the basis of the space we're projecting onto. Depending on the number of dimensions of the space you're projecting onto, this could be 1 to n (orthogonal!) vectors.
> > The basis of our space will be the 1-dimensional line from the user's middle finger tip to their middle finger knuckle.
> 
> So then, it follows that \( \mathbf{u}_i \) is the basis vector for a single dimension of the space.
> 
> Finally, the \( \cdot \) inside the angled brackets is a placeholder for the vector we're projecting.
> 
> Also, keep in mind that multiplication is usually not written out like "\( x*y \)". It's just implied when you have two things next to each other.
>
> ---
> 
> Let's rewrite this formula just a little bit so we can introduce \( \mathbf{v} \), the vector we're going to project, as well as \( \mathbf{d} \), the number of dimensions of the space we're projecting onto (both of which are already in the formula implicitly, we're just going to make them explicit).
>
> \[ P_A(\mathbf{v}) = \sum_{i=1}^{d} \langle \mathbf{u}_i, \mathbf{v} \rangle \mathbf{u}_i \]
>
> Now, let's start massaging this formula to suit our specific needs.
>
> First, obviously since we're projecting onto a one-dimensional line, \( d = 1 \):
>
> \[ P_A(\mathbf{v}) = \sum_{i=1}^{1} \langle \mathbf{u}_i, \mathbf{v} \rangle \mathbf{u}_i \]
>
> A sum from \( i = 1 \) to 1 is just one term, so let's simplify:
>
> \[  P_A(\mathbf{v}) = \langle \mathbf{u}_1, \mathbf{v} \rangle \mathbf{u}_1 \]
>
> We can rename \( \mathbf{u}_1 \) to just \( \mathbf{u} \) now as we only have the one basis vector (the line we're projecting onto):
>
> \[ P_A(\mathbf{v}) = \langle \mathbf{u}, \mathbf{v} \rangle \mathbf{u} \]
> **TODO:** This isn't right, I don't think you can just normalize by dividing the whole thing by the length of the basis vector. Why doesn't the part inside the inner product get normalized? 
> Now, by default it is assumed that basis vectors are normalized, but we may not be working with a normalized basis vector (most people's fingers aren't exactly 1 meter long, after all). It's not harmful to normalize an already-normalized vector, so let's normalize. Divide by the length of the basis vector (\( \mathbf{u} \cdot \mathbf{u} \)):
>
> \[ P_A(\mathbf{v}) = \frac{\langle \mathbf{u}, \mathbf{v} \rangle \mathbf{u}}{\mathbf{u} \cdot \mathbf{u}} \]
>
> Let's re-order this a little bit. Remembering our elementary school math classes, multiplication and division are associative. In other words, \( \frac{xy}{z} \) is equal to \( \frac{x}{z}y \):
>
> \[ P_A(\mathbf{v}) = \frac{\langle \mathbf{u}, \mathbf{v} \rangle}{\mathbf{u} \cdot \mathbf{u}} \mathbf{u} \]
>
> And while we're remembering our elementary math lessons, let's remember our linear algebra ones as well. We know we can replace the inner product with a dot product (since we're dealing with vectors and not, say functions or complex numbers):
>
> \[ P_A(\mathbf{v}) = \frac{\mathbf{u} \cdot \mathbf{v}}{\mathbf{u} \cdot \mathbf{u}} \mathbf{u} \]
> --
>
> **There we have it, the projection formula for projecting a point \( v \) onto a one-dimensional space \( A \) defined by a potentially un-normalized vector \( u \).**
>
> This is the standard formula you'll see if you look up how to project a point onto a line orthogonally. We just derived it ourself. And I think we can agree that Wikipedia couldn't have made it any simpler for us.
>
> ...
>
> What do you mean you still don't understand?
>
> You know how to do a dot product, right?
>
> Alright, fine. I guess I can explain a *little* bit more.

{{</collapse>}}