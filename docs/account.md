# Account

Browse the organizations and projects you belong to, and the products you can use and
their prices. These commands use your Personal Access Token.

```sh
neev-cli org get                          # organizations you belong to
neev-cli project get                      # projects in the current organization
neev-cli project get --org <org-id>       # projects in another one
neev-cli billing products get             # products and their prices
```

To work in a project without passing `--org` and `--project` each time, save it as a
context; see [Contexts](./configuration.md#contexts). To find your IDs in the console, see
[Organizations and projects](https://docs.ai.neevcloud.com/getting-started/org-and-project#find-your-organization-id-and-project-id).

See the [command reference](./command-reference.md#account) for every flag.
