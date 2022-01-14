<!--
.. title: The Layout Team
.. slug: the-layout-team
.. date: 2021-11-08 07:05:42 UTC
.. tags: architecture, javascript, html
.. category: frontend
.. link:
.. description: The Layout Team maintains the layout, and checks that everyone operates inside the boundaries created by this team
.. type: text
-->

For the last couple of months I've had this idea spinning in my head, which I'm
calling:

**The Layout Team**

Is a work in progress and I'll try to update it when new things come to my mind.
The topic can be discussed forever, I will try to formalize the idea while keeping
it short.

I see how the frontend industry is led mostly by hype, and this time I'm not fond of the
direction we are going, specifically with micro-frontends. This pattern,
spite of its benefits, I don't think it can be
implemented properly by most teams, and it's not an idea we should keep suggesting.

Instead, I'm going to propose an alternative, mostly in the middle.
And as you probably guessed... it's "The Layout Team".

As far as I'm concerned, the ultimate goal of a frontend is to deliver a good
user experience, and this includes being fast.

Micro-frontends, make this target hard to achieve.
If you pull parts from all around it will take longer than pulling from a single
place. Of course some teams can accomplish this (out of the question), and they may need it,
but most of the time, is not required, but... what do we do then?

The main issue to me, is that a frontend application has to be **glued together** at
some point, or somewhere. Whether you use a micro-frontend architecture or a monorepo, the final
user has to experience one cohesive app, this is **different** to backends, there's no UI there,
mostly machines talk with APIs. Your frontend talks with the API, but the human interacts with
the frontend.

Hence the introduction of **"The Layout Team"** (I'm giving it a formal name)

This team could have many different flavours.
But ideally, it should be an independent team, holding ownership of the layout of the app.

Yes, there's nothing fancy here, and the title is self-explanatory.

The Layout Team maintains the layout, and checks that everyone operates inside the
boundaries created by this team.

Its responsibilities include:

- Monitor styles to prevent overlapping components or breaking issues
- Review Pull Requests
- Train other developers, whether through quarterly presentations or one-to-one coaching, but
do it consistently over time. Not fire and forget.
- Maintain *some* shared state (logged user or is_authenticated or any other herbs).
But most of the times teams should be able to add and manage their own global state
- Write tools to assist other teams, like linters to prevent CSS or JS, where
- Identify CSS or JS code that may affect the whole app, and potentially code them
into the linters. Example:
    - Do not use fixed/absolute because... (unless approved to do so)
    - Do not use negative margins because we found that no one knows who to...
- Write tests for the layout

One easy way to do this, is by having a monorepo (recommended). The layout for the different pages
is defined by "The Layout Team", and the rest of the teams write components,
which can be later placed in the places designated by the layout team.

By doing this, it becomes very easy to produce a small bundle. Because the dependencies
are shared. It's then potentially easier, to identify shared code and cache it in a
separate bundle across the application.

One of the "benefits" of micro-frontend is supposed to be the freedom for teams to
choose what framework to use, but you end up sending bigger assets to the end user.
This goes against optimizing for the best user experience. So ideally, stick
to a single framework, and deliver it once.

If you are using React in your monorepo, it means everyone will stick to that
version. If you have multiple repos, even if everyone uses the same framework,
you may end up with different versions, or even the same and still delivering them
as part of each apps bundle!

Finally, **The Layout Team** leverages the use of `flex` and `grid` heavily.
They shape the app over time. And create *slots* for each team.

Let's see an example:

```html
<div class="box grid grid-cols-2">
  <div maintainer="teamA">
    <ComponentFromTeamA/>
  </div>
  <div>
    <div maintainer="teamB">
      <ComponentFromTeamB/>
    </div>
    <div maintainer="teamC">
      <ComponentFromTeamC/>
    </div>
  </div>
</div>
```

<style>
  .grid-cols-2 {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .grid {
    display: grid;
  }
  .box {
    margin: 0.75rem;
    width: 90%;
    border-width: 4px;
    border-style: solid;
    --tw-border-opacity: 1;
    border-color: rgba(107, 114, 128, var(--tw-border-opacity));
    padding: 0.75rem;
  }
  .teamBox {
    margin: 0.25rem;
    border-width: 4px;
    border-style: dashed;
    padding: 0.5rem;
  }
  .border-indigo-500 {
    --tw-border-opacity: 1;
    border-color: rgba(99, 102, 241, var(--tw-border-opacity));
  }
  .border-red-500 {
    --tw-border-opacity: 1;
    border-color: rgba(239, 68, 68, var(--tw-border-opacity));
  }
  .border-green-500 {
    --tw-border-opacity: 1;
    border-color: rgba(16, 185, 129, var(--tw-border-opacity));
  }
</style>

<div class="box grid grid-cols-2">
  <div class="teamBox border-indigo-500" maintainer="teamA">TEAM A</div>
  <div>
    <div class="teamBox border-red-500" maintainer="teamB">TEAM B</div>
    <div class="teamBox border-green-500" maintainer="teamC">TEAM C</div>
  </div>
</div>

\- Hey! It's almost the same example as a micro-frontend!

\- Well... yes, what did you expect?

Each team now has a space to place their components, and there's full visibility
over who maintains what.

It is very important, that the people, that are part of this team,
understand `flex` and `grid` very well.


Useful layout resources

- [guide to flexbox](https://css-tricks.com/snippets/css/a-guide-to-flexbox/)
- [1linelayouts](http://1linelayouts.glitch.me/)
- [csslayout](https://csslayout.io/)

I would very much like your feedback.

- What has been your experience with micro-frontends?
- Do you think "the layout team" would work?
- What do you think of this proposal?

Thanks for reading

## Update 2022

Seems like there are already some good tools designed for monorepos architecture,
where you can use micro-frontends safely.

See:

- [turborepo](https://turborepo.org/)
- [nx.dev](https://nx.dev/)
