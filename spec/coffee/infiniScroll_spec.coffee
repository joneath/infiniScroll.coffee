describe "InfiniScroll", ->
  PAGE_SIZE = 25

  beforeEach ->
    Collection = Backbone.Collection.extend(
      url: "/example"
    )

    Model = Backbone.Model.extend(
      calculatedParam: ->
    )

    @model = new Model(id: 1)

    @collection = new Collection([@model])
    @collection.length = 25

    @view = new Backbone.View(collection: @collection)

    @options =
      success: ->,
      error: ->,
      onFetch: ->

    @infini = new Backbone.InfiniScroll(@collection, @options)
    return

  afterEach ->
    @infini.destroy()
    return

  it "should bind to Backbone.InfiniScroll", ->
    expect(Backbone.InfiniScroll).toBeDefined()
    return

  describe "initialization", ->
    it "should have default values when no options are passed", ->
      infini = new Backbone.InfiniScroll(@collection)

      expect(infini.options.param).toEqual("until")
      expect(infini.options.untilAttr).toEqual("id")
      expect(infini.options.pageSize).toEqual(25)
      expect(infini.options.scrollOffset).toEqual(100)
      expect(infini.options.add).toEqual(true)
      expect(infini.options.includePage).toEqual(false)


  describe "#fetchSuccess", ->
    beforeEach ->
      @collection.length = PAGE_SIZE

    describe "with an included external success callback", ->
      it "should call the provided success callback", ->
        spyOn(@infini.options, "success")
        spyOn(@infini.options, "error")

        @infini.fetchSuccess(@collection, [])
        expect(@infini.options.success).toHaveBeenCalledWith(@collection, [])

    describe "when in strict mode", ->
      beforeEach ->
        @infini = new Backbone.InfiniScroll(@collection, {strict: true})
        spyOn(@infini, "enableFetch")
        spyOn(@infini, "disableFetch")

      it "should disable fetch when the response page size is less than the requested page size", ->
        @collection.length = PAGE_SIZE * 1.5;
        @infini.fetchSuccess(@collection, [{id: 1}])
        expect(@infini.disableFetch).toHaveBeenCalled()

    describe "when not in strict mode", ->
      beforeEach ->
        @infini = new Backbone.InfiniScroll(@collection, {strict: false})
        spyOn(@infini, "enableFetch")
        spyOn(@infini, "disableFetch")

      it "should disable fetch when the response page size is 0", ->
        @infini.fetchSuccess(@collection, [])
        expect(@infini.disableFetch).toHaveBeenCalled()

      it "should not disable fetch when the response size is greater than 0", ->
        @infini.fetchSuccess(@collection, [{id: 1}])
        expect(@infini.enableFetch).toHaveBeenCalled()

  describe "#fetchError", ->
    describe "with an included external error callback", ->
      it "should call the provided error callback", ->
        spyOn(@infini.options, "success")
        spyOn(@infini.options, "error")

        @infini.fetchError(@collection, null)
        expect(@infini.options.error).toHaveBeenCalledWith(@collection, null)

  describe "#watchScroll", ->
    beforeEach ->
      @event = jQuery.Event("scroll")
      spyOn(@collection, "fetch")

    describe "when the window is scrolled above the threshold", ->
      beforeEach ->
        @scrollTop = 600;

        spyOn($.fn, "scrollTop").andCallFake(=> return @scrollTop)
        spyOn($.fn, "height").andReturn(600)

        @infini.watchScroll(@event)

        @queryParams = {}
        @queryParams[@infini.options.param] = @collection.last().get(@infini.options.untilAttr)

        @collection.length = 50

      it "should call collection fetch with the query param, until offset, success, and error callbacks", ->
        expect(@collection.fetch).toHaveBeenCalledWith({success: @infini.fetchSuccess, error: @infini.fetchError, add: true, data: @queryParams})

      it "should disable scroll watch until the fetch has returned", ->
        expect(@collection.fetch).toHaveBeenCalledWith({success: @infini.fetchSuccess, error: @infini.fetchError, add: true, data: @queryParams})

        @infini.watchScroll(@event)
        expect(@collection.fetch.callCount).toEqual(1)

        @infini.watchScroll(@event)
        expect(@collection.fetch.callCount).toEqual(1)

        @infini.fetchSuccess(@collection, [{id: 1}])

        @infini.watchScroll(@event)
        expect(@collection.fetch.callCount).toEqual(2)

      describe "when given the includePage option", ->
        it "should include the page count in the query params", ->
          infini = new Backbone.InfiniScroll(@collection, {includePage: true})
          @queryParams[infini.options.param] = @collection.last().get(infini.options.untilAttr)
          @queryParams["page"] = 2

          infini.watchScroll(@event)
          expect(@collection.fetch).toHaveBeenCalledWith({success: infini.fetchSuccess, error: infini.fetchError, add: true, data: @queryParams})

      describe "when untilAttr is a function", ->
        it "should call the untilAttr function", ->
          spyOn(@model, "calculatedParam")
          @options.untilAttr = "calculatedParam"
          infini = new Backbone.InfiniScroll(@collection, @options)
          infini.watchScroll(@event)

          expect(@model.calculatedParam).toHaveBeenCalled();
          infini.watchScroll(@event);

      describe "when the window is scrolled up", ->
        it "should not call collection fetch", ->
          @infini.watchScroll(@event)
          expect(@collection.fetch).toHaveBeenCalled()

          @scrollTop = 599
          @infini.enableFetch()

          @infini.watchScroll(@event)
          expect(@collection.fetch.callCount).toEqual(1)

    describe "when the window is scrolled bellow the threshold", ->
      it "should not call collection fetch", ->
        spyOn($.fn, "scrollTop").andReturn(-101) # Crazy number for stubbing
        spyOn($.fn, "height").andReturn(200)

        @infini.watchScroll(@event)
        expect(@collection.fetch).not.toHaveBeenCalled()
