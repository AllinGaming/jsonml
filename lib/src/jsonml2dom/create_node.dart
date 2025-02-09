part of jsonml2dom;

/// The workhorse function.
Node _createNode(Object? jsonMLObject,
    {bool unsafe = false,
    Map<String, CustomTagHandler>? customTags,
    bool svg = false,
    bool allowUnknownTags = false}) {
  if (unsafe == false) {
    throw UnimplementedError("Safe operation (no script tags, etc.) is "
        "not supported yet. Currently, you _must_ specify `unsafe: true`. "
        "In the future, the default operation will be in safe mode "
        "(unsafe: false), which will strip all tags and attributes that "
        "could be exploited by malicious users. Only use unsafe mode for "
        "input which you are absolutely certain is safe (= no user input.");
  }
  Node node;
  if (jsonMLObject is String) {
    node = Text(jsonMLObject);
  } else if (jsonMLObject is List) {
    assert(jsonMLObject[0] is String);
    var tagName = jsonMLObject[0] as String;
    Element? element;
    DocumentFragment? documentFragment;
    if (tagName == "svg" || svg) {
      // SVG elements are different, need another constructor.
      element = SvgElement.tag(tagName);
      svg = true;
    } else if (tagName == "") {
      documentFragment = DocumentFragment();
    } else {
      if (customTags != null && customTags.containsKey(tagName)) {
        element = customTags[tagName]!(jsonMLObject) as Element;
      } else if (!allowUnknownTags &&
          !VALID_TAGS.contains(tagName.toLowerCase())) {
        throw JsonMLFormatException("Tag '$tagName' not a valid HTML5 tag "
            "nor is it defined in customTags.");
      } else {
        element = Element.tag(tagName);
      }
    }
    if (jsonMLObject.length > 1) {
      var i = 1;
      if (jsonMLObject[1] is Map) {
        if (element != null) {
          element.attributes = (jsonMLObject[1] as Map).cast<String, String>();
        } else {
          assert(documentFragment != null);
          throw JsonMLFormatException("DocumentFragment cannot have "
              "attributes. Value of currently encoded JsonML object: "
              "'$jsonMLObject'");
        }
        i++;
      }
      for (; i < jsonMLObject.length; i++) {
        var newNode = _createNode(jsonMLObject[i],
            unsafe: unsafe, svg: svg, customTags: customTags);
        if (newNode == null) {
          continue; // Some custom tag handlers can choose not to output
          // elements.
        }
        if (element != null) {
          element.append(newNode);
        } else {
          documentFragment?.append(newNode);
          // documentFragment.append(newNode);
        }
      }
    }
    if (element != null) {
      node = element;
    } else {
      assert(documentFragment != null);
      node = documentFragment as Node;
    }
  } else {
    throw JsonMLFormatException("Unexpected JsonML object. Objects in "
        "JsonML can be either Strings, Lists, or Maps (and Maps can be only "
        "on second positions in Lists, and can be only <String,String>). "
        "The faulty object is of runtime type ${jsonMLObject.runtimeType} "
        "and its value is '$jsonMLObject'.");
  }
  return node;
}
