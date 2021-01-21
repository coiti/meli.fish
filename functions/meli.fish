function meli --description "Interact with the Mercado Libre API"
    function _meli_usage
        echo "\
Usage: meli [OPTION]... [VERB] URL [--PARAM=VALUE]... [REQUEST_ITEM]...
       meli help"

        test "$argv[1]" != full && return

        echo "Fetch resources from Mercado Libre's API.

OPTION:
  -T --access-token=ACCESS_TOKEN  Access token to fetch private resources.

VERB:
  HTTP method to use. Can be one of:

    DELETE GET HEAD OPTIONS PATCH POST PUT

  Defaults to GET.

URL
  The full URL or pathname from which to fetch.

  Examples:

    sites
    /users/me
    \"https://api.mercadolibre.com/users/\$user_id/items/search?status=active\"

PARAM=VALUE
  You can specify URL search/query parameters as arguments to this command.

  Example:

    --status=active --include-filters -v 3
    Becomes: ?status=active&include_filters=true&v=3

REQUEST_ITEM
  Can be a key-value pair specifying a header, query param, or body field.

    HEADER:VALUE  A request header, eg. Content-Type:application/json
    PARAM==VALUE  A query parameter, eg. include_filters==true
    FIELD=VALUE   A string body field, eg. title='Thinkpad T200'
    FIELD:=VALUE  A JSON object field, eg. ids:='[\"MLU1234\", \"MLU5678\"]'

  See http(1) for usage info on REQUEST_ITEM.

Examples

  # Get all items by their ids
  meli items --ids=MLU1234,MLU5678

  # Get private user information
  meli --access-token=\$access_token users/me

  # You can save the token on a special varible that's picked up by this script.
  set MELI_ACCESS_TOKEN \$access_token
  meli users/me
  meli --access-token='' \"users/\$some_other_user\" # ignore the variable

  # Search your items with status=active
  meli \"users/\$user_id/items/search\" --status=active --limit=100 --offset=0

  # Edit an item
  meli put \"items/\$item_id\" title='New Title' price=4000
  # or
  echo '{\"title\": \"Hello World\"}' | meli put \"items/\$item_id\"

  # Publish an item
  meli post items <item.json

CAVEATS
  The PATCH, POST and PUT operations have not been tested and bugs are to be
  expected. In fact, bugs are to be expected all around, but I especially would
  not use these operations in any production quality whatsoever."
    end

    set --local access_token $MELI_ACCESS_TOKEN
    set --local method
    set --local request_items
    set --local url

    if test (count $argv) -eq 0
        _meli_usage
        return
    end

    if test "$argv" = help
        _meli_usage full
        return
    end

    getopts $argv | while read --local key value
        switch $key
            case _
                if echo "$value" | egrep --ignore-case --quiet '^(delete|get|head|options|patch|post|put)$'
                    if test -n "$method"
                        echo Too many HTTP verbs. &>2
                        _meli_usage &>2
                        return 1
                    end

                    set method (echo $value | tr a-z A-Z)
                else
                    if test -z "$url"
                        set url "$value"
                    else
                        set --append request_items "$value"
                    end
                end
            case help
                if test "$value" = true
                    _meli_usage full
                    return
                else
                    _meli_usage >&2
                    return 1
                end
            case T access-token
                set access_token "$value"
            case '*'
                set --append request_items (echo "$key" | sed s/-/_/g)"==$value"
        end
    end

    if test -z "$url"
        echo An URL is required. >&2
        _meli_usage &>2
        return 1
    end

    set --local http_opts --check-status --default-scheme=https

    if test "$method" = HEAD
        set --append http_opts --headers
    else
        set --append http_opts --body
    end

    set url (echo "$url" | sed --regexp-extended \
        's/^((((https?:)?\/\/)?api\.mercadolibre\.com\.?)?\/*)?(.*)$/api.mercadolibre.com\/\5/')

    if test -n "$access_token"
        set --prepend request_items "Authorization:Bearer $access_token"
    end

    http $http_opts $method "$url" $request_items
end
