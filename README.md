# what is this?
A cli tool to pull aws lambda logs in a nice way by fuzzy searching the profile to use and name of the log group (these are often way too long to remember). I'm totally dog fooding this.

# requirements
- [aws cli](https://github.com/aws/aws-cli/tree/v2)
- [jq](https://stedolan.github.io/jq/download/)
- [peco](https://github.com/peco/peco)

# usage
$ ./fuzzy.sh -h [| peco]

# todos
- [x] use LOG_GROUP cache
- [x] update cache
- [ ] check commands
- [ ] fetch multiple groups?
- [ ] check expired sso session
- [ ] add logs if follow is set
- [ ] is there a kinder signal to stop following? SIGINT produces a BrokenPipeError

# license
MIT
