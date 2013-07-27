class Result extends Backbone.Model

class Results extends Backbone.Collection
  url: 'https://api.github.com/gists?callback=?'
  model: Result

  parse: (resp) ->
    console.log resp
    resp.data

class ResultView extends Backbone.View
  tagName: 'div'

  render: ->
    template = _.template($('#result-template').html(), @model.attributes)
    @.$el.html(template)
    console.log "ITEM RENDERED"

class ResultsView extends Backbone.View
  tagName: 'div'

  render: ->
    @collection.each (result) =>
      item_view = new ResultView
        model: result
      item_view.render()
      @.$el.append(item_view.el)

something = new Results
something.fetch().done =>
  console.log something
  results_view = new ResultsView
    el: $('#results')
    collection: something
  results_view.render()
  console.log "Render done"

console.log "OK"
