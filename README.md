# Homebrew

Features, usage and installation instructions are [summarized on the homepage][home].

## Fork aims:
*  *Make homebrew modular*;
  *   **(done)** *Extract formulas to* [own repository][formulary].
      This idea was declined a couple of times [mxcl/homebrew#3991](https://github.com/mxcl/homebrew/issues/3991),
      [mxcl/homebrew#236](https://github.com/mxcl/homebrew/issues/236). Keeping formulas
      in the core makes homebrew a little bit harder to maintain and contribute;
  *   **(done)** *`homebrew selfupdate` command*; After extracting formulas to own
      repository will be easy to update them and core separately.
  *   *Split-up core and cmd app*. Library should provide
      an API that could be used by other application (GUI, for example);
  *   **(done)** *Extract 'Contributions' to 'homebrew-contrib'
      [repo][contrib]*. 'Contributions' is now available through the `brew install homebrew-contrib`;
* **(In progress)** *Improve tests*. You need to install `rspec` to run new tests;
* **(mostly done)** *3rd party formulas repos support*;
* **(partially done)** *Use rugged (or another ruby-git library)*;
* *Improve core documentation*;
* **(done)** *Fix ccache support*;
* **(done)** Respect user choice and don't override ENV variables, such as (CC, CXX, MAKEFLAGS, CFLAGS and other)

[Current progress](https://github.com/etehtsea/homebrew/blob/master/CHANGELOG.md)

## How to install

``` sh
$ git clone https://github.com/etehtsea/homebrew.git /usr/local/
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
