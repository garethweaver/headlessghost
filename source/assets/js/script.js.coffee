#= require angular-scroll
#= require_self

# application - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

app = angular.module 'app', ['ngAnimate', 'smoothScroll']


# directives - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

.directive 'escFn', [ ->
  restrict: 'A'
  scope:
    fn: '=escFn'
  link: (scope, element) ->
    document.onkeyup = (e) -> if e.keyCode is 27 then scope.$apply -> scope.fn()
    return
]

.directive 'scrollClass', ['$window', ($window) ->
  restrict: 'A'
  link: (scope, element) ->
    scope.scrolled = $window.pageYOffset
    angular.element($window).bind 'scroll', ->
      scope.scrolled = @pageYOffset
      scope.$apply()
    return
]


# services - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

.service 'Overlay', [ ->
  {
    overlays: []

    openOverlay: (str) ->
      @overlays.push(str)
      @overlayOpen = !@overlayOpen
      @[str] = true

    closeOverlays: ->
      @overlayOpen = false
      @[overlay] = false for overlay in @overlays
      @overlays = []
  }
]

.service 'Util', [ ->
  {
    dhms: (t) ->
      days = Math.floor t / 86400
      t -= days * 86400
      hours = Math.floor(t / 3600) % 24
      t -= hours * 3600
      minutes = Math.floor(t / 60) % 60
      t -= minutes * 60
      seconds = t % 60
      [ days + 'd', hours + 'h', minutes + 'm', seconds + 's' ].join ' '
  }
]

# controllers - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

.controller 'OverlayController', [ '$scope', 'Overlay', ($scope, Overlay) ->
  $scope.Overlay = Overlay
  $scope.escOverlays = -> Overlay.closeOverlays()
  # Overlay.preOrder = Overlay.overlayOpen = true
]
