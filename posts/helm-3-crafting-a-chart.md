<!--
.. title: Helm 3 - Crafting a Chart
.. slug: helm-3-crafting-a-chart
.. date: 2020-07-15 13:20:41 UTC
.. tags: kubernetes, helm
.. category: devops
.. link:
.. description: create and releasing a Helm chart
.. type: text
-->

This post focuses on **creating and releasing a chart**, not consuming from a Helm Chart Repository.

Helm is an **advanced** tool used by kubernetes people, some "lingo" (jargon) is used here.
Please leave a comment if you want more information.

Helm allows to **"package"** kubernetes applications, it simplifies the distribution
and installation. While doing so, it checks dependencies versions and some other validations.

---

[Official Helm 3 Documentation](https://helm.sh/docs/intro/)

---

## Version used

```bash
$ helm version --short
v3.2.4+g0ad800e
```

## Helm Chart

> A Chart is a Helm package. It contains all of the resource definitions necessary to run an application,
> tool, or service inside of a Kubernetes cluster. Think of it as the Kubernetes equivalent of a
> Homebrew formula, an apt dpkg, or a Yum RPM file [[0]][three-big-concepts].

For OOP people:

- Chart ~= class
- Release ~= instance

This is important to remember, we are going to be building a **package**.

## Development of a Chart

### Creating a new Chart

My recommendation is to create a `charts/` folder in the root of your project(s).

This way each of your projects could become a "chart repository", similar to how hub.helm.sh consumes respositories from different sources in a descentralized way.

You could do the same for your projects. Each git project becomes a descentralized chart repository,
or you can publish to a centralized chart repository like artifactory or your own github repo.

In any case, calling it `charts/` is informative and flexible enough to choose any option.

Inside `charts/`, we are going to use `helm` to create the first boilerplate of our app.

```bash
helm create <package_name>
```

#### Example

Along the post we'll use `auth-service` as our project example name.

```bash
mkdir auth-service
cd auth-service/
mkdir charts
cd charts/
```

```bash
helm create auth-service
```

#### Structure

```bash
auth-service/
└── charts/
    └── auth-service/
        ├── charts/
        ├── Chart.yaml
        ├── templates/
        │   ├── deployment.yaml
        │   ├── _helpers.tpl
        │   ├── hpa.yaml
        │   ├── ingress.yaml
        │   ├── NOTES.txt
        │   ├── serviceaccount.yaml
        │   ├── service.yaml
        │   └── tests/
        │       └── test-connection.yaml
        └── values.yaml
```

#### Notes

- `appVersion` inside `Chart.yaml` references the **application version** [\[1\]][appVersion]
- `image.tag` inside `values.yaml` references the **docker image version/tag**.
- if `image.tag` is skipped, `appVersion` is used instead.
- **recommendation**: use a tool to automatically bump the version, like [commitizen][commitizen],
during the CI execution, and push back to the repo.
- Whether to use `image.tag` or `appVersion` is still under debate, you can read more in the
[github issue][tag_or_appVersion]
- If you use `appVersion` you can use `helm history <release_name>` to get info on the versions
per revision.

### Chart customization

I recommend to start with the default helm chart and from there, start
adding any extra stuff that you need.

### Templating

If you have used other template systems like `jinja`, or Django's template engine,
Helm's system is not that different: you can apply functions using a pipeline `|`.

```yaml
food: {{ .Values.favorite.food | upper | quote }}
```

Avoid adding complex template tags; the purpose of `yaml` is to be **readable**.
By using templates, we make things more complex, and less readable, **touch only when necessary**.

`templates/_helpers.tpl` contains custom functions for your templates, like generating the release name based on values.

To find problems with you charts, run:

```bash
helm lint <package_name>
```

### Values

Place the "configuration" that you want to expose to the users of the chart in
the `values.yaml`, even if it's you who's gonna end up using it.
There's no need to parametrize everything, and try to use sensible defaults.

A good rule is to expose only the things you are going to use and make new
parameters only when you have to.

Let developers specify unconventional aspects of the application.

You can also define a `values.schema.json` which will be used by helm to validate
the parameters given to Helm [\[2\]][schema-files].

### Using custom values

`values.yaml` is used as default and any extra values provided through `--set` or `--values`
will be merged into the default `values.yaml` inside the chart.

There are 2 approaches to deal with custom values that I know.

#### Centralized values

The first one is to have a centralized place with all the configuration. At the
moment, I know [helmfile][helmfile] is being used for this.
You'd specify every configuration per environment per chart in a `helmfile.yaml`.

#### Per repository

This is the most popular approach. Each "project" is responsible to set the values
per enviroment (`production`, `staging`).

If you are going to modify small aspects of your app, using `--set` should be enough.

A common practice, is to place the production and staging files inside the chart folder,
but in my opinion this is a kind of anti-pattern.

A Helm chart is a package: **Helm is a package manager**.
Like apt, pip or npm.
When we use tools like Docker, for example, we provide env variables from outside, they are
not packaged inside the image. This gives the container a lot of flexibility and the
same principle applies to Helm. There's an interesting [discussion in the helm repo][helm_discussion]
about this.

Ideally, your custom values shouldn't live inside the chart. They should be passed to the chart.

Let's see a setup example for the `auth-service`.

```bash
auth-service/
├── charts/
│   └── auth-service/
├── charts-values/
│   ├── production/
│   │   ├── redis.yaml
│   │   └── auth-service.yaml
│   └── staging/
│       └── auth-service.yaml
└── src/
```

I'm not 100% happy with the above setup, mainly with the naming.
But it allows having multiple values per chart per environment.
We could easily add values for a redis pulled from the official Helm hub.
I'd like to hear opinions about it. How'd you do it?

## Release

> A Release is an instance of a chart running in a Kubernetes cluster. One chart can often be installed many times into the same cluster. And each time it is installed, a **new release is created**.
> Consider a MySQL chart. If you want two databases running in your cluster, you can install that chart twice. Each one will have its own release, which will in turn have its own release name [\[3\]][three-big-concepts].

### New release

```bash
helm install <release_name> <package_name>
```

Deploy a new release to the cluster.

We can also run a dry-run to check what's going to happen:

```bash
helm install <release_name> <package_name> --dry-run
```

#### Example

```bash
helm install auth-service-prod ./auth-service
```

#### Notes

- `package_name` can be a folder, a `.tgz` or a url.
- `release_name`: the name of this particular release. If the name is different another "instance" will be deployed. So for redis instances it may be worth using different `release_name`s, but for your JavaScript app it may not.
- The output of `templates/NOTES.txt` is shown in the prompt when making a new release, useful for CI logs.
- If you don't want to provide a `<release_name>`, use `--generate-name` and it will assign a random `<release_name>`.
- Helm stores release config per namespace, so if you want to release 2 redis instances in the same namespace, they should have different `<release_name>`s [[4]][namespacing-changes].
- Helm does not wait until all of the resources are running before it exits [[5]][helm-install-package].
- **personal**: use different `release_name`s per environment (`production`, `staging`). Even though it may not be necessary, giving that extra information in the name is useful and cheap.
- Use `helm get values <release_name>` to get the values used for the release, useful to check if our custom values were applied properly.

### Check release status

After it is installed, we want to know if everything went well.

```bash
helm status <release_name>
```

#### Example

```bash
helm status auth-service-prod
```

> An upgrade takes an existing release and upgrades it according to the information you provide. Because Kubernetes charts can be large and complex, Helm tries to perform the **least invasive upgrade**. It will only update things that have changed **since the last release**. [[6]][helm-upgrade]


### Uprgrade release

```bash
helm upgrade -f <custom_values.yaml> <release_name> <package_name>
```

#### Example

```bash
helm upgrade -f values.prod.yaml auth-service-prod ./auth-service
```

### Rollback release

```bash
helm rollback <release_name> <revision>
```

#### Example

```bash
helm rollback auth-service-prod 1
```

#### Notes

- Any release version increment will produce a `revision` number. It goes from 1..N.
- Use `helm history <release_name>` to see the revisions of your `release_name`.

### Uninstall release

```bash
helm uninstall <release_name>
```

I won't go deep into this, but just know it exists, and you can remove an existing release.

### Automating release cycle

A recommended best practice to avoid running `helm install` and `helm upgrade` [[7]][install-or-upgrade-a-release-with-one-command] is to use:

```bash
helm upgrade --install <release_name> --values <custom_values.yaml> <package_name>
```

This can be a benefit in an automated CI/CD pipeline. We let Helm perform the check to know if it's a first time,
or a release upgrade.

#### Example

```bash
helm upgrade --install auth-service-prod --values charts-values/production/auth-service.yaml ./auth-service
```

#### Notes

- Use `--atomic` to get automatic rollback on failures.[[8]][Helm-Best-Practices]


### Complex Charts with Many Dependencies

> The current best practice for composing a complex application from discrete parts is to create a top-level umbrella chart that exposes the global configurations, and then use the charts/ subdirectory to embed each of the components.[5][complex-charts-with-many-dependencies]

I think this is an improving point; I haven't understood it by reading the documentation yet.


> Hey, hello!
> If you are interested in what I write, follow me on [twitter][santiwilly]
>

[three-big-concepts]: https://helm.sh/docs/intro/using_helm/#three-big-concepts
[appVersion]: https://stackoverflow.com/a/60054111/2047185
[commitizen]: https://github.com/commitizen-tools/commitizen
[helm-install-package]: https://helm.sh/docs/intro/using_helm/#helm-install-installing-a-package
[namespacing-changes]: https://github.com/helm/community/blob/master/helm-v3/003-state.md#namespacing-changes
[helm-upgrade]: https://helm.sh/docs/intro/using_helm/#helm-upgrade-and-helm-rollback-upgrading-a-release-and-recovering-on-failure
[complex-charts-with-many-dependencies]: https://helm.sh/docs/howto/charts_tips_and_tricks/#complex-charts-with-many-dependencies
[install-or-upgrade-a-release-with-one-command]: https://helm.sh/docs/howto/charts_tips_and_tricks/#install-or-upgrade-a-release-with-one-command
[Helm-Best-Practices]: https://lzone.de/blog/Helm-Best-Practices
[schema-files]: https://helm.sh/docs/topics/charts/#schema-files
[helm_discussion]: https://github.com/helm/helm/issues/6715
[helmfile]: https://github.com/roboll/helmfile
[tag_or_appVersion]: https://github.com/helm/helm/issues/8194
[santiwilly]: https://twitter.com/santiwilly
