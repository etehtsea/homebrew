# Homebrew

Features, usage and installation instructions are [summarized on the homepage][home].

## Fork aims:
*  *Make homebrew modular*;
  *   **(done)** *Extract formulas to* [own repository][formulary].
      This idea was declined a couple of times [mxcl/homebrew#3991][issue3991],
      [mxcl/homebrew#236][issue236]. Keeping formulas in the core makes
      homebrew a little bit harder to maintain and contribute;
  *   **(done)** Introduce `homebrew selfupdate` and `homebrew repoupdate`
      commands which update core and repos separately (`homebrew update`
      still updates both);
  *   **(done)** *Extract 'Contributions' to 'homebrew-contrib'
      [repo][contrib]*. 'Contributions' is now available through the
      `brew install homebrew-contrib`;
  *   Get rid of **everything in `Object`** approach.
* **(In progress)** *Improve tests*. You need to install `rspec` to run new tests;
* **(mostly done)** *3rd party formulas repos support*;
* **(partially done)** *Use rugged (or another ruby-git library)* (I
  decided to just extract *git*-related code to `Utils::Git` module);
* *Improve core documentation*;
* *Be helpful*. Make usual (and useful) help output. Like `brew install -h`;
* **(done)** *Fix ccache support*;
* **(done)** Respect user choice and don't override `ENV` variables, such as (`CC`, `CXX`, `MAKEFLAGS`, `CFLAGS` and other)

[Current progress](https://github.com/etehtsea/homebrew/blob/master/CHANGELOG.md)

## How to install

``` sh
$ git clone https://github.com/etehtsea/homebrew.git <Whatever you want
dir, for example ~/homebrew>
$ export PATH=$PATH:$HOME/homebrew/bin
$ brew formulary init
```

## What Packages Are Available?
1. You can [browse the Formulary repository on GitHub][formulary].
2. Or type `brew search` for a list.
3. Or visit [braumeister.org][braumeister] to browse packages online.

## More Documentation
`brew help` or `man brew` or check our [wiki][].

## Who Are You?
I'm [Max Howell][mxcl] and I'm a splendid chap.


[home]:http://mxcl.github.com/homebrew
[wiki]:http://wiki.github.com/mxcl/homebrew
[mxcl]:http://twitter.com/mxcl
[formulary]:https://github.com/etehtsea/formulary
[contrib]:https://github.com/etehtsea/homebrew-contrib
[braumeister]:http://braumeister.org
[issue3991]:https://github.com/mxcl/homebrew/issues/3991
[issue236]:https://github.com/mxcl/homebrew/issues/236
