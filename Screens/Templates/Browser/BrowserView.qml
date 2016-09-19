import CSI 1.0
import QtQuick 2.0
import Traktor.Gui 1.0 as Traktor

import './../' as Templates
import './../../Views/Browser' as BrowserView
import './../../Views/Widgets' as Widgets

//----------------------------------------------------------------------------------------------------------------------
//                                            BROWSER VIEW
//
//  The Browser View is connected to traktors QBrowser from which it receives its data model. The navigation through the
//  data is done by calling funcrtions invoked from QBrowser.
//----------------------------------------------------------------------------------------------------------------------

Templates.View {
  id: qmlBrowser

  property string propertiesPath: ""
  property bool  isActive:      false
  property bool  enterNode:     false
  property bool  exitNode:      false
  property int   increment:     0
  property color focusColor:    (screen.focusDeckId < 2) ? colors.colorDeckBlueBright : "white" 
  property int   speed:         150
  property real  sortingKnobValue:  0
  property int   pageSize:          9
  property int   fastScrollCenter:  4

  readonly property int  maxItemsOnScreen: 10

  // This is used by the footer to change/display the sorting!
  property alias sortingId:         browser.sorting
  property alias sortingDirection:  browser.sortingDirection
  property alias isContentList:     browser.isContentList

  anchors.fill: parent

  //MappingProperty { id: browserViewMode; path: "mapping.state.browser_view_mode" }
  AppProperty { id: deckAKeyDisplay; path: "app.traktor.decks.1.track.key.key_for_display" }
  AppProperty { id: deckBKeyDisplay; path: "app.traktor.decks.2.track.key.key_for_display" }
  AppProperty { id: deckCKeyDisplay; path: "app.traktor.decks.3.track.key.key_for_display" }
  AppProperty { id: deckDKeyDisplay; path: "app.traktor.decks.4.track.key.key_for_display" }
  AppProperty { id: masterDeckId; path: "app.traktor.masterclock.source_id" }

  //--------------------------------------------------------------------------------------------------------------------

  onIncrementChanged: {
    if (qmlBrowser.increment != 0) {
      var newValue = clamp(browser.currentIndex + qmlBrowser.increment, 0, contentList.count - 1);
  
      // center selection if user is _fast scrolling_ but we're at the _beginning_ or _end_ of the list
      if(qmlBrowser.increment >= pageSize) {
        var centerTop = fastScrollCenter;

        if(browser.currentIndex < centerTop) {          
          newValue = centerTop;
        }
      }
      if(qmlBrowser.increment <= (-pageSize)) {
        var centerBottom = contentList.count - 1 - fastScrollCenter;

        if(browser.currentIndex > centerBottom) {          
          newValue = centerBottom;
        }
      }
      
      browser.changeCurrentIndex(newValue);
      qmlBrowser.increment = 0;
      doScrolling();
    }      
  }

  //--------------------------------------------------------------------------------------------------------------------

  onExitNodeChanged: {
    if (qmlBrowser.exitNode) {
      browser.exitNode()
    }
    
    //showHeaderFooterAnimated(false); // see comment at function declaration
    qmlBrowser.exitNode = false;
  }

  //--------------------------------------------------------------------------------------------------------------------

  onEnterNodeChanged: {
    if (qmlBrowser.enterNode) {
      var movedDown = browser.enterNode(screen.focusDeckId, contentList.currentIndex);
      if (movedDown) { 
        browser.relocateCurrentIndex()
      }
    }
    //showHeaderFooterAnimated(false); // see comment at function declaration
    qmlBrowser.enterNode = false;
  }

  function clamp(val, min, max){
    return Math.max(min, Math.min(val, max));
  }

  //--------------------------------------------------------------------------------------------------------------------
  // Behavior on scrolling
  //
  // On Scrolling, show scrolling-bar and hide header/footer. After some seconds, go back to initial state.
  //--------------------------------------------------------------------------------------------------------------------

  function doScrolling() { 
    scrollbar.opacity = 1; 
    //hideHeaderFooterAnimated(true); // see comment at function declaration
    opacityTimer.restart(); 
  }

  //--------------------------------------------------------------------------------------------------------------------

  Timer {
    id: opacityTimer
    interval: 800  // duration of the scrollbar opacity
    repeat:   false
  
    onTriggered: { 
      scrollbar.opacity = 0; 
      //showHeaderFooterAnimated(true); // see comment at function declaration
    }
  }


  //--------------------------------------------------------------------------------------------------------------------
  // VIEWS / ITEMS
  //--------------------------------------------------------------------------------------------------------------------

  Traktor.Browser
  {
    id: browser;
    isActive: qmlBrowser.isActive
  }
 
  //--------------------------------------------------------------------------------------------------------------------
  //  LIST VIEW -- NEEDS A MODEL CONTAINING THE LIST OF ITEMS TO SHOW AND A DELEGATE TO DEFINE HOW ONE ITEM LOOKS LIKE
  //-------------------------------------------------------------------------------------------------------------------

  // zebra filling up the rest of the list if smaller than maxItemsOnScreen (= 8 entries)
  Grid {
    anchors.top:            contentList.top
    anchors.topMargin:      contentList.topMargin +  contentList.contentHeight + 1 // +1 = for spacing
    anchors.right:          parent.right
    anchors.left:           parent.left
    anchors.leftMargin:     1
    columns:                1
    spacing:                1  

    Repeater {
      model: (contentList.count < qmlBrowser.maxItemsOnScreen) ? (qmlBrowser.maxItemsOnScreen - contentList.count) : 0
      Rectangle { 
        color: ( (contentList.count + index)%2 == 0) ? colors.colorGrey08 : "transparent"
        width: qmlBrowser.width; 
        height: 26 }
    }
  }

  //--------------------------------------------------------------------------------------------------------------------

  ListView {
    id: contentList
    anchors.fill: parent
    verticalLayoutDirection: ListView.TopToBottom
    // the top/bottom margins are applied only at the beginning/end of the list in order to show half entries while scrolling 
    // and keep the list delegates in the same position always.

    // the commented out margins caused browser anchor problems leading to a disappearing browser! check later !?
    anchors.topMargin:       15 // ( (contentList.count <  qmlBrowser.maxItemsOnScreen ) || (currentIndex < 4                     )) ? 17 : 0
    anchors.bottomMargin:    15 // ( (contentList.count >= qmlBrowser.maxItemsOnScreen) && (currentIndex >= contentList.count - 4)) ? 18 : 0 
    clip:                    false
    spacing:                 1
    preferredHighlightBegin: 26 * 4 + 4 // -17 because of the reduced height due to the topMargin
    preferredHighlightEnd  : 26 * 5 + 4 // -17 because of the reduced height due to the topMargin
    highlightRangeMode :     ListView.ApplyRange
    highlightMoveDuration:   0
    delegate:                BrowserView.ListDelegate  {id: listDelegate; screenFocus: screen.focusDeckId; }
    model:                   browser.dataSet
    currentIndex:            browser.currentIndex 
    focus:                   true 
    cacheBuffer:             6
  }

  //--------------------------------------------------------------------------------------------------------------------

  Widgets.ScrollBar {
    id: scrollbar
    flickable:    contentList
    opacity:      0
    handleColor:  parent.focusColor
    Behavior on opacity { NumberAnimation { duration: (opacity == 0) ? 0 : speed; } }
  }


  //--------------------------------------------------------------------------------------------------------------------

  BrowserView.BrowserHeader {
    id: browserHeader
    nodeIconId:     browser.iconId
    currentDeck:    screen.focusDeckId
    state:          "show"
    pathStrings:    browser.currentPath 

    Behavior on height { NumberAnimation { duration: speed; } }
   
  }

  //--------------------------------------------------------------------------------------------------------------------

  BrowserView.BrowserFooter {
    id: browserFooter
    state:        "show"
    propertiesPath: qmlBrowser.propertiesPath
    sortingKnobValue: qmlBrowser.sortingKnobValue

    Behavior on height { NumberAnimation { duration: speed; } }
  }


  //--------------------------------------------------------------------------------------------------------------------
  // NOTE: Supress show/hide for now, but KEEP this code. 
  //       The "come back" is planned for a later release!
  //--------------------------------------------------------------------------------------------------------------------
  /*
  function showHeaderFooterAnimated(animated) {
    var defaultSpeed = qmlBrowser.speed;
    qmlBrowser.speed = (animated) ? qmlBrowser.speed : 0
    browserHeader.state = "show"
    browserFooter.state = "show"
    qmlBrowser.speed = defaultSpeed;
  }

  //--------------------------------------------------------------------------------------------------------------------

  function hideHeaderFooterAnimated(animated) {
    var defaultSpeed = qmlBrowser.speed;
    qmlBrowser.speed = (animated) ? qmlBrowser.speed : 0
    browserHeader.state = "hide"
    browserFooter.state = "hide"
    qmlBrowser.speed = defaultSpeed;
  }
  */

  function getMasterKey() {
    switch (masterDeckId.value) {
      case 0: return deckAKeyDisplay.value;
      case 1: return deckBKeyDisplay.value;
      case 2: return deckCKeyDisplay.value;
      case 3: return deckDKeyDisplay.value;
    }

    return "";
  }

  function isNearMasterKey(trackKey) {
    var masterKey = getMasterKey();
    if (masterKey == trackKey) return true;

    switch (masterKey) {
      case "1m":  return (trackKey == "1d"  || trackKey == "2m"  || trackKey == "12m");
      case "2m":  return (trackKey == "2d"  || trackKey == "3m"  || trackKey == "1m");
      case "3m":  return (trackKey == "3d"  || trackKey == "4m"  || trackKey == "2m");
      case "4m":  return (trackKey == "4d"  || trackKey == "5m"  || trackKey == "3m");
      case "5m":  return (trackKey == "5d"  || trackKey == "6m"  || trackKey == "4m");
      case "6m":  return (trackKey == "6d"  || trackKey == "7m"  || trackKey == "5m");
      case "7m":  return (trackKey == "7d"  || trackKey == "8m"  || trackKey == "6m");
      case "8m":  return (trackKey == "8d"  || trackKey == "9m"  || trackKey == "7m");
      case "9m":  return (trackKey == "9d"  || trackKey == "10m" || trackKey == "8m");
      case "10m": return (trackKey == "10d" || trackKey == "11m" || trackKey == "9m");
      case "11m": return (trackKey == "11d" || trackKey == "12m" || trackKey == "10m");
      case "12m": return (trackKey == "12d" || trackKey == "1m"  || trackKey == "11m");
      case "1d":  return (trackKey == "1m"  || trackKey == "2d"  || trackKey == "12d");
      case "2d":  return (trackKey == "2m"  || trackKey == "3d"  || trackKey == "1d");
      case "3d":  return (trackKey == "3m"  || trackKey == "4d"  || trackKey == "2d");
      case "4d":  return (trackKey == "4m"  || trackKey == "5d"  || trackKey == "3d");
      case "5d":  return (trackKey == "5m"  || trackKey == "6d"  || trackKey == "4d");
      case "6d":  return (trackKey == "6m"  || trackKey == "7d"  || trackKey == "5d");
      case "7d":  return (trackKey == "7m"  || trackKey == "8d"  || trackKey == "6d");
      case "8d":  return (trackKey == "8m"  || trackKey == "9d"  || trackKey == "7d");
      case "9d":  return (trackKey == "9m"  || trackKey == "10d" || trackKey == "8d");
      case "10d": return (trackKey == "10m" || trackKey == "11d" || trackKey == "9d");
      case "11d": return (trackKey == "11m" || trackKey == "12d" || trackKey == "10d");
      case "12d": return (trackKey == "12m" || trackKey == "1d"  || trackKey == "11d");
    }

    return false;
  }
}

