# Publisher Object:
#   Properties:
#     id (String) — The ID of the DOM element through which the Publisher stream is displayed
#     stream - The Stream object corresponding to the stream of the publisher
#     session (Session) — The Session to which the Publisher is publishing a stream. If the Publisher is not publishing a stream to a Session, this property is set to null.
#     element (Element) - HTML DOM element containing the Publisher
#   Methods: 
#     destroy():Publisher - not yet implemented
#     getImgData() : String - not yet implemented
#     getStyle() : Object - not yet implemented
#     off( type, listener )
#     on( type, listener )
#     publishAudio(Boolean) : publisher - change publishing state for Audio
#     publishVideo(Boolean) : publisher - change publishing state for Video
#     setStyle( style, value ) : publisher - not yet implemented
#
class TBPublisher
  constructor: (targetElement, properties, completionHandler) ->    
    if (not targetElement?)
      @domId = TBGenerateDomHelper()
      @element = document.getElementById(@domId)
    else if typeof(targetElement) == "string"
      @domId = targetElement
      @element = document.getElementById(@domId)  
    else
      @element = targetElement
      @domId = targetElement.id
    pdebug "creating publisher", {}
    position = getPosition(@domId)
    name=""
    publishAudio="true"
    publishVideo="true"
    cameraName = "front"
    zIndex = TBGetZIndex(@element)
    ratios = TBGetScreenRatios()
    borderRadius = TBGetBorderRadius(@element);
    if properties?
      width = properties.width ? position.width
      height = properties.height ? position.height
      name = properties.name ? ""
      cameraName = properties.cameraName ? "front"
      if(properties.publishAudio? and properties.publishAudio==false)
        publishAudio="false"
      if(properties.publishVideo? and properties.publishVideo==false)
        publishVideo="false"
    if (not width?) or width == 0 or (not height?) or height==0
      width = DefaultWidth
      height = DefaultHeight
    obj = replaceWithVideoStream(@domId, PublisherStreamId, {width:width, height:height})
    position = getPosition(obj.id)
    TBUpdateObjects()
    OT.getHelper().eventing(@)
    onSuccess = (result) ->
      if completionHandler?
        completionHandler()
      TBSuccess(result)
    onError = (result) ->
      if completionHandler?
        completionHandler(result)
      TBError(result)
    Cordova.exec(onSuccess, onError, OTPlugin, "initPublisher", [name, position.top, position.left, width, height, zIndex, publishAudio, publishVideo, cameraName, ratios.widthRatio, ratios.heightRatio, borderRadius] )
    Cordova.exec(@eventReceived, TBSuccess, OTPlugin, "addEvent", ["publisherEvents"] )
  setSession: (session) =>
    @session = session
  eventReceived: (response) =>
    pdebug "publisher event received", response
    @[response.eventType](response.data)
  streamCreated: (event) =>
    pdebug "publisher streamCreatedHandler", event
    pdebug "publisher streamCreatedHandler", @session
    pdebug "publisher streamCreatedHandler", @session.sessionConnection
    @stream = new TBStream( event.stream, @session.sessionConnection )
    streamEvent = new TBEvent( {stream: @stream } )
    @trigger("streamCreated", streamEvent)
    return @
  streamDestroyed: (event) =>
    pdebug "publisher streamDestroyed event", event
    streamEvent = new TBEvent( {stream: @stream, reason: "clientDisconnected" } )
    @trigger("streamDestroyed", streamEvent)
    # remove stream DOM?
    return @

  removePublisherElement: =>
    if(@element && @element.parentNode)
      @element.parentNode.removeChild(@element)
    @element = undefined

  destroy: ->
    onSuccess = (result) =>
      @removePublisherElement()
      TBSuccess(result)
    if(@element)
      Cordova.exec( onSuccess, TBError, OTPlugin, "destroyPublisher", [])
  getImgData: ->
    return ""
  getStyle: ->
    return {}
  publishAudio: (state) ->
    @publishMedia( "publishAudio", state )
    return @
  publishVideo: (state) ->
    @publishMedia( "publishVideo", state )
    return @
  setCameraPosition: (cameraPosition) ->
    pdebug("setting camera position", cameraPosition: cameraPosition)
    Cordova.exec(TBSuccess, TBError, OTPlugin, "setCameraPosition", [cameraPosition])
    return @
  setStyle: (style, value ) ->
    return @

  publishMedia: (media, state) ->
    if media not in ["publishAudio", "publishVideo"] then return
    publishState = "true"
    if state? and ( state == false or state == "false" )
      publishState = "false"
    pdebug "setting publishstate", {media: media, publishState: publishState}
    Cordova.exec(TBSuccess, TBError, OTPlugin, media, [publishState] )
