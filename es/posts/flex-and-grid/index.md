<!--
.. title: Flex and grid
.. slug: flex-and-grid
.. date: 2020-11-24 19:47:10 UTC
.. tags:
.. status: draft
.. category:
.. link:
.. description:
.. type: text
-->

This is a quick explanation to flex and grid.

I'll try to explain some basic concepts so you can dig deeper later on.

Flex and grid are 2 types of modern CSS display properties.

In the past we had `block` or `inline`, now we can do

```css
display: flex;
```

or

```css
display: grid;
```

But how does this work?

It took me some time to realize this, but the basic idea is that anything inside
a HTML attribute with either `flex` or `grid` will behave with the given "effect".

Let me show what I mean with this.

## Grid

I'll begin with `grid` because I think it can help make a mental model.

Let's create a class (they are all compatible with tailwind by the way).

```css
.grid {
  display: grid;
}
```

Now we are gonna use a `div` as a container of this grid.

```html
<div class="grid"></div>
```

And I say container, because anything it contains will be

<div class="grid border-black">
holis
</div>
