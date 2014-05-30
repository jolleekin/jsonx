#### 1.2.2
- Added a work-around to bug [#15942](https://code.google.com/p/dart/issues/detail?id=15942)
#### 1.2.1
- Changed [_jsonToObject] to instantiate [List] and [Map] using
  [ClassMirror.newInstance]
- Added [TypeHelper] to retrieve the runtime type of a generic type

#### 1.2.0
- Added [jsonToObjects] and [objectToJsons]
   
#### 1.1.1
- Added JsonxCodec, JsonxDecoder, and JsonxEncoder
-	Added TypeMirror caching to improve the performance of `decode`

#### 1.0.9
-	Changed fixed length lists into growable lists in decoded objects

#### 1.0.8
-	Added support for encoding/decoding memmbers of superclasses (which
	include mixins also)

#### 1.0.[1-7]
-	Updated dartdoc and README

#### 1.0.0
-	Initial version