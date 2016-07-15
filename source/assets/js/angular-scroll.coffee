### =============================================================
/*
/*   Angular Smooth Scroll 1.7.1
/*   Animates scrolling to elements, by David Oliveros.
/*
/*   Callback hooks contributed by Ben Armston
/*   https://github.com/benarmston
/*
/*   Easing support contributed by Willem Liu.
/*   https://github.com/willemliu
/*
/*   Easing functions forked from Gaëtan Renaudeau.
/*   https://gist.github.com/gre/1650294
/*
/*   Infinite loop bugs in iOS and Chrome (when zoomed) by Alex Guzman.
/*   https://github.com/alexguzman
/*
/*   Influenced by Chris Ferdinandi
/*   https://github.com/cferdinandi
/*
/*
/*   Free to use under the MIT License.
/*
/* =============================================================
###

do ->
  'use strict'
  module = angular.module('smoothScroll', [])

  resolveOffset = (offset, element, options) ->
    if typeof offset == 'function'
      offset = offset(element, options)
    if angular.isElement(offset)
      offsetEl = angular.element(offset)[0]
      if typeof offset != 'undefined'
        offset = offsetEl.offsetHeight
    offset

  # Smooth scrolls the window to the provided element.
  #

  smoothScroll = (element, options) ->
    options = options or {}
    # Options
    duration = options.duration or 800
    offset = resolveOffset(options.offset or 0, element, options)
    easing = options.easing or 'easeInOutQuart'
    callbackBefore = options.callbackBefore or ->
    callbackAfter = options.callbackAfter or ->

    getScrollLocation = ->
      if window.pageYOffset then window.pageYOffset else document.documentElement.scrollTop

    setTimeout (->
      startLocation = getScrollLocation()
      timeLapsed = 0
      percentage = undefined
      position = undefined
      # Calculate the easing pattern

      easingPattern = (type, time) ->
        if type == 'easeInQuad'
          return time * time
        # accelerating from zero velocity
        if type == 'easeOutQuad'
          return time * (2 - time)
        # decelerating to zero velocity
        if type == 'easeInOutQuad'
          return if time < 0.5 then 2 * time * time else -1 + (4 - 2 * time) * time
        # acceleration until halfway, then deceleration
        if type == 'easeInCubic'
          return time * time * time
        # accelerating from zero velocity
        if type == 'easeOutCubic'
          return --time * time * time + 1
        # decelerating to zero velocity
        if type == 'easeInOutCubic'
          return if time < 0.5 then 4 * time * time * time else (time - 1) * (2 * time - 2) * (2 * time - 2) + 1
        # acceleration until halfway, then deceleration
        if type == 'easeInQuart'
          return time * time * time * time
        # accelerating from zero velocity
        if type == 'easeOutQuart'
          return 1 - --time * time * time * time
        # decelerating to zero velocity
        if type == 'easeInOutQuart'
          return if time < 0.5 then 8 * time * time * time * time else 1 - 8 * --time * time * time * time
        # acceleration until halfway, then deceleration
        if type == 'easeInQuint'
          return time * time * time * time * time
        # accelerating from zero velocity
        if type == 'easeOutQuint'
          return 1 + --time * time * time * time * time
        # decelerating to zero velocity
        if type == 'easeInOutQuint'
          return if time < 0.5 then 16 * time * time * time * time * time else 1 + 16 * --time * time * time * time * time
        # acceleration until halfway, then deceleration
        time
        # no easing, no acceleration

      # Calculate how far to scroll

      getEndLocation = (element) ->
        location = 0
        if element.offsetParent
          loop
            location += element.offsetTop
            element = element.offsetParent
            unless element
              break
        location = Math.max(location - offset, 0)
        location

      endLocation = getEndLocation(element)
      distance = endLocation - startLocation
      # Stop the scrolling animation when the anchor is reached (or at the top/bottom of the page)

      stopAnimation = ->
        currentLocation = getScrollLocation()
        if position == endLocation or currentLocation == endLocation or window.innerHeight + currentLocation >= document.body.scrollHeight
          clearInterval runAnimation
          callbackAfter element
        return

      # Scroll the page by an increment, and check if it's time to stop

      animateScroll = ->
        timeLapsed += 16
        percentage = timeLapsed / duration
        percentage = if percentage > 1 then 1 else percentage
        position = startLocation + distance * easingPattern(easing, percentage)
        window.scrollTo 0, position
        stopAnimation()
        return

      # Init
      callbackBefore element
      runAnimation = setInterval(animateScroll, 16)
      return
    ), 0
    return

  # Expose the library via a provider to allow default options to be overridden
  #
  module.provider 'smoothScroll', ->
    defaultOptions =
      duration: 800
      offset: 0
      easing: 'easeInOutQuart'
      callbackBefore: noop
      callbackAfter: noop

    noop = ->

    {
      $get: ->
        (element, options) ->
          smoothScroll element, angular.extend({}, defaultOptions, options)
          return
      setDefaultOptions: (options) ->
        angular.extend defaultOptions, options
        return

    }
  # Scrolls the window to this element, optionally validating an expression
  #
  module.directive 'smoothScroll', [
    'smoothScroll'
    (smoothScroll, smoothScrollProvider) ->
      {
        restrict: 'A'
        scope:
          callbackBefore: '&'
          callbackAfter: '&'
        link: ($scope, $elem, $attrs) ->
          if typeof $attrs.scrollIf == 'undefined' or $attrs.scrollIf == 'true'
            setTimeout (->

              callbackBefore = (element) ->
                if $attrs.callbackBefore
                  exprHandler = $scope.callbackBefore(element: element)
                  if typeof exprHandler == 'function'
                    exprHandler element
                return

              callbackAfter = (element) ->
                if $attrs.callbackAfter
                  exprHandler = $scope.callbackAfter(element: element)
                  if typeof exprHandler == 'function'
                    exprHandler element
                return

              options =
                callbackBefore: callbackBefore
                callbackAfter: callbackAfter
              if typeof $attrs.duration != 'undefined'
                options.duration = $attrs.duration
              if typeof $attrs.offset != 'undefined'
                options.offset = $attrs.offset
              if typeof $attrs.easing != 'undefined'
                options.easing = $attrs.easing
              smoothScroll $elem[0], options
              return
            ), 0
          return

      }
  ]
  # Scrolls to a specified element ID when this element is clicked
  #
  module.directive 'scrollTo', [
    'smoothScroll'
    (smoothScroll) ->
      {
        restrict: 'A'
        scope:
          callbackBefore: '&'
          callbackAfter: '&'
        link: ($scope, $elem, $attrs) ->
          targetElement = undefined
          $elem.on 'click', (e) ->
            e.preventDefault()
            targetElement = document.getElementById($attrs.scrollTo)
            if !targetElement
              return

            callbackBefore = (element) ->
              if $attrs.callbackBefore
                exprHandler = $scope.callbackBefore(element: element)
                if typeof exprHandler == 'function'
                  exprHandler element
              return

            callbackAfter = (element) ->
              if $attrs.callbackAfter
                exprHandler = $scope.callbackAfter(element: element)
                if typeof exprHandler == 'function'
                  exprHandler element
              return

            options =
              callbackBefore: callbackBefore
              callbackAfter: callbackAfter
            if typeof $attrs.duration != 'undefined'
              options.duration = $attrs.duration
            if typeof $attrs.offset != 'undefined'
              options.offset = $attrs.offset
            if typeof $attrs.easing != 'undefined'
              options.easing = $attrs.easing
            smoothScroll targetElement, options
            false
          return

      }
  ]
  return
