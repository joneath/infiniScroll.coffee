###
Created by Jonathan Eatherly, (https://github.com/joneath)
MIT license
Version 0.1
###

Backbone.InfiniScroll = (collection, options = {}) ->
  fetchOn = false
  page = 1
  prevScrollY = 0
  $target = null

  @options = _.defaults(options,
    success: ->,
    error: ->,
    onFetch: ->,
    target: $(window),
    param: "until",
    untilAttr: "id",
    pageSize: collection.length || 25,
    scrollOffset: 100,
    add: true,
    strict: false,
    includePage: false
  )

  @destroy = =>
    $target.off("scroll", @watchScroll)

  @enableFetch = ->
    fetchOn = true

  @disableFetch = ->
    fetchOn = false

  @fetchSuccess = (collection, response) =>
    if (@options.strict && collection.length >= (page + 1) * @options.pageSize) || (!@options.strict && response.length > 0)
      @enableFetch()
      page += 1
    else
      @disableFetch()

    @options.success(collection, response)

  @fetchError = (collection, response) =>
    @enableFetch()

    @options.error(collection, response)

  @watchScroll = (e) =>
    scrollY = $target.scrollTop() + $target.height()
    docHeight = $target.get(0).scrollHeight

    docHeight = $(document).height() if !docHeight

    if scrollY >= docHeight - @options.scrollOffset && fetchOn && prevScrollY <= scrollY
      lastModel = collection.last()
      return if !lastModel

      @options.onFetch()
      @disableFetch()
      collection.fetch(
        success: @fetchSuccess,
        error: @fetchError,
        add: @options.add,
        data: @buildQueryParams(lastModel)
      )
    prevScrollY = scrollY;

  @buildQueryParams = (model) =>
    params = {}
    params[@options.param] = if model[@options.untilAttr]?() then model[@options.untilAttr]() else model.get(@options.untilAttr)

    if (@options.includePage)
      params["page"] = page + 1;

    return params;

  do =>
    $target = $(@options.target)
    fetchOn = true
    page = 1

    $target.on("scroll", @watchScroll)

  this
