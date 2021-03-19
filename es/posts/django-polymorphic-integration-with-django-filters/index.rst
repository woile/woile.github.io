.. title: How to filter Polymorphic Models with Django Filters
.. slug: django-polymorphic-integration-with-django-filters
.. date: 2017-03-02 20:58:22 UTC-03:00
.. tags: python, django, drf, django-rest-framework, api, polymorphic, filters
.. category: python
.. link:
.. description: Integration of two python/django libraries
.. type: text

As the title says, I needed a way to filter my polymorphic models using my already defined
:code:`rest_framework.FilterSet`, and as I didn't find much resources about it I'm sharing my experience here.

First, let's talk about :code:`django-polymorphic` and :code:`django-filters`, what are these libraries for.

.. TEASER_END

Django-polymorphic [#]_
-----------------------

::

    Simplifies using inherited models in Django projects. When a query is made at the base
    model, the inherited model classes are returned.

One of the most important things to understand of polymorphic is, that when you ask for the queryset of the parent, every element is represented with its children classes. Let's see this.

I'll use the models examples provided by the `docs <https://django-polymorphic.readthedocs.io/en/stable/>`__.

.. code-block:: python

    from polymorphic.models import PolymorphicModel

    class Project(PolymorphicModel):
        topic = models.CharField(max_length=30)
        start_date = models.DateField(null=True, blank=True)
        finish_date = models.DateField(null=True, blank=True)

    class ArtProject(Project):
        artist = models.CharField(max_length=30)

    class ResearchProject(Project):
        supervisor = models.CharField(max_length=30)


.. code-block:: python

    >>> Project.objects.create(topic="Department Party")
    >>> ArtProject.objects.create(topic="Painting with Tim", artist="T. Turner")
    >>> ResearchProject.objects.create(topic="Swallow Aerodynamics", supervisor="Dr. Winter")


.. code-block:: python

    >>> Project.objects.all()
    [ <Project:         id 1, topic "Department Party">,
      <ArtProject:      id 2, topic "Painting with Tim", artist "T. Turner">,
      <ResearchProject: id 3, topic "Swallow Aerodynamics", supervisor "Dr. Winter"> ]

As you can see, this can be really helpful when using Django Rest Framework (DRF) and model inheritance.
It allows to use just one model, in this case :code:`Project`, in a :code:`ModelViewSet` and you will receive all the instances for :code:`Project`, :code:`ArtProject` and :code:`ResearchProject`. Take into account
that your serializer will have to handle the representation of each of the models.


Django-filter [#]_
------------------

::

    Is a generic, reusable application to alleviate writing some of the more mundane bits of view code. Specifically, it allows users to filter down a queryset based on a model’s fields.

Fundamentally, when using django filters you'll want to create a class specifying the model's
fields by which a queryset can be filtered.

Let's modified a bit the example of the `docs <https://django-filter.readthedocs.io/en/latest/guide/usage.html>`__:

.. code-block:: python

    import django_filters

    class ProjectFilter(django_filters.FilterSet):
        topic = django_filters.CharFilter(lookup_expr='iexact')

        class Meta:
            model = Project
            fields = ['start_date', 'finish_date']

And the view should look something like:

.. code-block:: python

    def project_list(request):
        f = ProjectFilter(request.GET, queryset=Project.objects.all())
        return render(request, 'my_app/template.html', {'filter': f})

Obviously, this will help reduce the amount of code written, and will be way easier to mantain.
The good thing about this library, and what matters to me the most, is that it has a great `integration with DRF <https://django-filter.readthedocs.io/en/latest/guide/rest_framework.html>`_ by providing a DRF-specific FilterSet and a filter backend.


Filtering by a polymorphic model
--------------------------------

As we stated at the beginning what I wanted to do is filter by a **polymorphic model**, because we have different types of projects. This can be easily achieved by reading the docs, no seriously, by essentially using the :code:`rest_framework.FilterSet` and using a customized filter with `Filter.method <https://django-filter.readthedocs.io/en/latest/guide/usage.html#customize-filtering-with-filter-method>`_ in our FilterSet.

.. code-block:: python

    import django_filters


    def get_subclasses_as_choice(klass):
        choices = {subclass.__name__.lower(): subclass
                   for subclass in klass.__subclasses__()}
        return choices


    class ProjectFilter(django_filters.rest_framework.FilterSet):
        project_type = django_filters.MultipleChoiceFilter(
            method='project_type_filter', choices=get_subclasses_as_choice(Project))

        class Meta:
            model = Project
            fields = ['topic', 'start_date', 'end_date']

        def project_type_filter(self, queryset, name, value):
            project_choices = get_subclasses_as_choice(Project)
            selected_projects = [value for key, value in project_choices.items()
                                 if key in value]
            return queryset.instance_of(*selected_projects)

Now, if our querystring includes a key :code:`project_type`, it will check if the values match any of
the choices and it will return the queryset filtered by the specified choices.
And that's it, we have successfully filtered polymorphic models. Now we just need to add :code:`ProjectFilter` to the :code:`filter_class` in the :code:`viewsets.ModelViewSet`.

Cheers!


.. [#] https://github.com/django-polymorphic/django-polymorphic
.. [#] https://github.com/carltongibson/django-filter
