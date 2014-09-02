#### 2.0.0
- **Breaking change**: readonly properties (final fields and getters without
  a corresponding setter) are no longer encoded. Only public read/write
  properties are encoded.
- Added indentation support during encoding through `encode`, `JsonxEncoder`,
  or `JsonxCodec`

#### 1.2.7
- Fixed a small formatting error in README.md

#### 1.2.6
- Updated the documentation for decoding to generics

#### 1.2.5
- Added [propertyNameDecoder] and [propertyNameEncoder]

#### 1.2.4
- Added @jsonIgnore, @jsonObject, and @jsonProperty annotations

#### 1.2.3
- Fixed a typo in [_getPublicGetters]

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