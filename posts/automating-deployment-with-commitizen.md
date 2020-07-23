<!--
.. title: Automating semver releases with commitizen
.. slug: automating-semver-releases-with-commitizen
.. date: 2020-07-15 15:27:20 UTC
.. tags: python, ci
.. category: devops
.. link:
.. description: How to make a deployment almost hassle free
.. type: text
-->

[SemVer][semver] is a great way to version an application.
Languages like rust have [fully embraced it][rust_semver].

A SemVer version looks like this: `1.2.0`

Quite simple, right?

We can map that to `MAJOR.MINOR.PATCH` where

MAJOR ➡️ BREAKING CHANGES ⚠️

MINOR ➡️ New stuff 🎉

PATCH ➡️ Security 🔒 and bug fixes 🐛

That's the highlight.

## Making a new release

Usually, when making a new semantic version (semver), you have to review your
commits, check if there's any braking changes, then check if there are new features,
otherwise, it's just a patch. This process can be tedious, but semver gives
developers a lot of information about a release, like if they can update safely,
new features, or they **must** update.

The release process can be fully automated, but it has a price.

## Price

- Write parseable commits
- Easy to map commit messages to [SemVer][semver]

## Automating release

By writing commits this way, we have to think, in that moment, what kind of change
we are introducing. And that information get's encoded in the message.

Let's see a simple rule for parseable, easy to map messages:

> Include MAJOR:, MINOR:, PATCH: at the beginning of each commit. If not present
> the commit will be skipped, and it won't be released.

Commits examples:

> MAJOR: Change public interface for class User


> MINOR: Add new type of user (employee)


> PATCH: Fix full name not being displayed properly

And that's it! The next step is to use a tool to collect the commits, and generate
the correct [semver][semver].

### Commit tips

- Talk imperative and follow this rule: `If applied, this commit will <commit message>` [0][commit-guide]
- Keep the subject short

## Introducing commitizen

[Commitizen][cz] is a tool to do exactly that.

I created it in order to automate that process. Based on existing tools from
the JS ecosystem but which I found hard to use.

By default it parses the widely popular commit rules: [conventional commits][cm].

But you can [easily extend commitizen][cz_extend] to create the example given before.

Not only it will create the version, but it can also generate the changelog.

It's really easy to use, first create a `.cz.toml` file in your project's root.

```toml
[tool.commitizen]
version = "2.5.1"
version_files = ["setup.py", "Dockerfile", "scripts/publish"]
```

And that's it, by running a single command we get the version and the changelog.

```bash
cz bump --changelog
```

The `veresion_files` will also bump the version in the specified files.

## CI/CD

![diagram of semantic release](/images/automating-deployment-with-commitizen/semantic_release.png)

In this diagram, you'd execute commitizen in the green job, during the version bump.

We push back the new commit including the changelog, the updated version in the
corresponding files and the tag.

Pushing the tag triggers another job, which will take care of the release, which can be:

- deploying to kubernetes
- publishing to pypi/npm/cargo
- deploying to a cloud service, like AWS

Done!

## Recap

### Standards

- [semver][semver]
- [conventional commits][cm]

### Price

- Write parseable commits
- Easy to map commit messages to semver

### Command

```bash
cz bump --changelog
```

## Conclusion

Try commitizen and check the [repo][cz]!

We aim for simplicity, trying to make this process as simple as possible, but
the tool is quite flexible, explore it, and see if it fits for your use cases.

> Hey, hello 👋
>
> If you are interested in what I write, follow me on [twitter][santiwilly]
>

[santiwilly]: https://twitter.com/santiwilly

[cz]: https://github.com/commitizen-tools/commitizen
[semver]: https://semver.org/
[cm]: https://www.conventionalcommits.org/en/v1.0.0/
[rust_semver]: https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#specifying-dependencies-from-cratesio
[cz_extend]: https://commitizen-tools.github.io/commitizen/customization/#2-customize-through-customizing-a-class
[commit-guide]: https://chris.beams.io/posts/git-commit/
