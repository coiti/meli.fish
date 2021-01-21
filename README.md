# meli.fish

Interact with Mercado Libre's API from your fish shell.

## Installation

With [Fisher](https://github.com/jorgebucaran/fisher):

```fish
fisher install coiti/meli.fish
```

### Requirements

- [getopts](https://github.com/jorgebucaran/getopts)
- [HTTPie](https://httpie.io/)

## Make requests

Making requests to the API is simple.

```fish
# Fetch all sites
meli sites

# Works also with a partial or full URL
meli https://api.mercadolibre.com/sites

# Fetch private user information
meli --access-token=$access_token users/me

# You can also store the access token on a variable that meli will pick up
set MELI_ACCESS_TOKEN $access_token
meli users/me

# Pass query parameters as arguments
set user_id (meli users/me --attributes=id | jq --raw-output .id)
meli "users/$user_id/items/search" --include-filters --limit=100 --status=active
```

You can also make POST requests (along with other HTTP verbs) though I have not
tested them at all.

```fish
meli get sites/MLU
meli head /
meli options users
meli put "items/$item_id" status=closed
echo '{"title": "Hello World", price: 14.50}' | meli put "items/$item_id"
meli post items <item.json
```
