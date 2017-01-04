# invite new member

## requirement

- direnv

## setup

First, clone this repository and move dir.

```
$ git clone https://github.com/esminc/invite_new_member.git
$ cd invite_new_member
```

Next, you should copy .envrc.sample to .envrc and edit this.

```sh
$ cp .envrc.sample .envrc
$ $EDITOR .envrc
```

And, allow .envrc.

```sh
$ direnv allow
```

Next, make invite setting.yml with reference to sample.yml.

```sh
$ cp sample.yml new_member.yml
$ $EDITOR new_member.yml
```

Finaly, you execute script.

```sh
$ bundle install
$ bundle exec ruby invite_new_member.rb new_member.yml
```

## Support Service

- idobata
- esa
- dropbox
