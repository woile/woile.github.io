<!--
.. title: Guide to Sublime like a normal person
.. slug: guide-to-sublime-like-a-normal-person
.. date: 2017-06-08 16:46:15 UTC-03:00
.. tags: sublime, linters, python, programming
.. category: programming
.. link:
.. description: Installing and configuring Sublime Text 3
.. type: text
-->

First of all, verify that you have installed the latest version of [Sublime Text 3](https://www.sublimetext.com/3).

## General settings

Add the following settings in `Preferences > Settings > User Tab`

```
"trim_trailing_white_space_on_save": true,
"auto_complete": false,
"translate_tabs_to_spaces": true,
"word_wrap": "false",
```

The first one will delete the trailing spaces. This is useful to select text properly and sometimes is required by many languages.

The second one is intended to improve performance of sublime. If the project is huge sublime will get slow with this feature on, but if you press tab while you are writing, sublime will try to autocomplete.

The third forces to always use spaces when tabbing, as most of programmers do.

The forth helps avoid problems when using features like multiline select.


## Installing packages

Install the [package control](https://packagecontrol.io/installation) as explained there.

To use it go to `Tools > Command Palette` or by default the shortcut keys are:

```
Linux: `ctrl+shit+P`
Os X: `cmd+shift+p`
```

Finally, the steps to install a new package are:

1. Select the option: `Package Control: install package`.
2. Wait until the packages are loaded.
3. Write the name of the package you want to install.


## Linters

A lint tool performs static analysis of source code and flags patterns that might be errors or otherwise cause problems for the developer.
In other words, it will tell you where you are writing incorrect code.
Usually, a linter is a software that receives the files to analyze as paramters, and the will give you an output indicating in which lines somethings is weird.


## Sublime Linter

In my opinion, this is the **most important package** we should install, it provides an interface to communicate with the linters, and the errors will be displayed in the editor in an elegant manner.
This means that Sublime Linter will talk with the linter you have installed in your system, and will display in the editor the errors reported by the linter.

As the site reads:
> SublimeLinter is a plugin for Sublime Text 3 that provides a framework for linting code. Whatever language you code in, SublimeLinter can help you write cleaner, better, more bug-free code. SublimeLinter has been designed to provide maximum flexibility and usability for users and maximum simplicity for linter authors.

The concept behind it is very simple:
    1. Install globally in your system a linter for the language of your choice (pep8, eslint, csslint, rubocop, etc).
    2. Install the corresponding sublime linter through the **package control**.


### Useful linters

Choose the one that suits you more, and install it through the package manager of the corresponding language. Eg: pip for python, gem for ruby, etc.

| Language        | Linter           | Sublime package name  | Description |
| ------------- |:-------------:|:-----:| -- |
| python | pep8 | SublimeLinter-pep8 | tool to check your Python code against some of the style conventions in PEP 8 |
| python| pep257 | SublimeLinter-pep257 | static analysis tool for checking compliance with Python docstring conventions |
| python | pyflakes | SublimeLinter-pyflakes | checks Python source files for errors |
| python | flake8 | SublimeLinter-flake8 | **[recommended]** includes lint checks provided by the PyFlakes project, PEP-0008 inspired style checks provided by the PyCodeStyle project, and McCabe complexity checking provided by the McCabe project |
| javascript | jshint | SublimeLinter-jshint | JSHint is a program that flags suspicious usage in programs written in JavaScript |
| javascript | eslint | SublimeLinter-eslint | **[recommended]** tool for identifying and reporting on patterns found in ECMAScript/JavaScript code. In many ways, it is similar to JSLint and JSHint with a few exception |
| css | csslint | SublimeLinter-csslint | open source CSS code quality tool |
| sass | sass-lint | SublimeLinter-contrib-sass-lint | A Node-only Sass linter for both sass and scss syntax! |
| ruby | rubocop | SublimeLinter-rubocop | A Ruby static code analyzer, based on the community Ruby style guide. |
| golang | golint | Sublime​Linter-contrib-golint | Golint is a linter for Go source code. |

Note: I work with python and javascript so I've marked those which I consider good for those languages.


### Tips to configure sublime linter

* If your sublime linter user settings are empty, copy the default ones, because if you overwrite the default, everytime SL is updated, the settings will be reseted.
* After installing a custom language that wraps another language, link it in sublimelinter, so the linter still works. For example, for python/django put in your sublime linter settigns:
```
"syntax_map": {
    "python (django)": "python",
    "python django": "python"
}
```
* To change the mark style, open the package control and type **Choose Mark Style**, I like the Squiggly underline.
* You can ignore rules, in the settings of the linter inside the sublime linter settings.


## Another useful Packages

`DockBlockr` Helps commenting (go to the web for more information)

`Colorhighlighter` Highlights hexa colors, useful for CSS

`SidebarEnhancements` Allows options as move, copy, remove, etc in the side bar

`Emmet` Write HTML faster, introduces many sweet snippets.

`Djaneiro` Add django support with many many snippets.


## MUST KNOW SHORTCUTS

Using this shortcuts will make your life much easier. I will include some gifs eventually, but trust me, search them in your key bindin settings, and observe the keys.

`toggle_comment`

`select_lines`

`find_under_expand` to filter with case, open the search panel and enable the "Case Sensitive" option.


## RECOMMENDED THEME

This awesome theme also includes those cool icons which appear in the image.

[SoDaReloaded-Theme](https://github.com/Miw0/SoDaReloaded-Theme)
![](https://raw.githubusercontent.com/Miw0/sodareloaded-theme/master/dark/example.png)
