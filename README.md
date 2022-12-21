# what is this?
Some missing features from the aws cli like pulling all permissions from a role or fuzzy searching the profile and name of a log group (these are often way too long to remember). I'm totally dog fooding this.

# requirements
- [aws cli](https://github.com/aws/aws-cli/tree/v2)
- [jq](https://stedolan.github.io/jq/download/)
- [peco](https://github.com/peco/peco)

# tools
````bash
# stream lambda logs
$ ./logs.sh
$ ./logs.sh | peco
$ ./logs.sh | grep <detail>
$ ./logs.sh | tee <file>
# pull all permissions for a role
$ ./role.sh
# pull all data for an iot core thing
$ ./thing.sh <thing>
````

# cache
Each script will create a local cache (role names, log_groups etc) for future lookups. To bust the cache - simply remove the file `cache/$type/$aws_profile` and it will be re-created on next run.

# todos
- [x] cache
- [x] set pipefail
- [x] role
- [x] logs
- [x] thing
- [ ] role: lambda resource-based policy
- [ ] logs: ignore log_group prefix for lookup 

# license
MIT
