class GoogleAnalytics

  # You must have setup your google analtyics config with
  # the normal snipet so that window._gaq is defined and setup
  constructor: (options) ->
    @sampleRate = options?.rate || _ga_ajax_sample_rate || 10

  logTiming: (category, url, timeSpent, label) ->
    @logCustomTiming(category, url, timeSpent, label)

  logCustomTiming: (category, url, timeSpent, label) ->
    @logToGA category, url, timeSpent, label

  logToGA: (category, url, timeSpent, label) ->
    if window._gaq
      window._gaq.push(['_trackTiming', category, url, timeSpent, label, @sampleRate])
    else
      console.log "WOULD HAVE LOGGED TO GOOGLE", category, url, timeSpend, label, @sampleRate
